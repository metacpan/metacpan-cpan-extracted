##############################################################################
#
#  Config::NINI is NINI format configuration files parser.
#  2026 (c) Vladi Belperchinov-Shabanski "Cade" <cade@noxrun.com>
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Config::NINI;
use Exporter;
use Carp qw( croak );
use Storable qw( dclone );
use Data::Dumper;
use strict;

our @ISA = qw( Exporter );

our @EXPORT = qw(
                  nini_load_file

                  nini_parse_data
                );

our $VERSION = '0.11';

##############################################################################

sub nini_load_file
{
  my $fn   = shift; # file name to load
  my $opt  = shift; # options: hash ref

  my @data;

  __nini_load_file_data( \@data, $fn, $opt, {} );
  chomp( @data );

  return \@data;
}

sub __nini_load_file_data
{
  my $ar   = shift; # current data: array ref
  my $fn   = shift; # file name to load
  my $opt  = shift; # options: hash ref
  my $seen = shift; # hashref, seen files lookup, guards loops

  die "nini: error: file load: loop detected for file [$fn]\n" if $seen->{ $fn }++;

  my $dl  = $opt->{ 'DL' };
  die "nini_load_file: error: 'DL' (debug locations) must be array reference\n" if $dl and ref $dl ne 'ARRAY';

  # force every file beginning to be anchored to root section
  push @$ar, "=";
  push @$dl, "$fn top" if $dl; # this will not happen, just keeps the space

  open( my $if, $fn );

  my $ln = 0;
  while(<$if>)
    {
    $ln++;
    next unless /\S/;
    next if /^\s*#/;
    s/^\s*//;
    s/\s*$//;
    if( /^\s*\@inc(lude)?\s*(\S+)/i )
      {
      my $nf = __nini_find_file( $2, $opt );
      if( ! $nf )
        {
        # warn if debug
        next;
        }
      push @$ar, '@@@push'; # save current section
      push @$dl, "$nf top" if $dl; # this will not happen, just keeps the space
      __nini_load_file_data( $ar, $nf, $opt, $seen );
      push @$ar, '@@@pop';  # restore nini.comlast saved section
      push @$dl, "$nf bottom" if $dl; # this will not happen, just keeps the space
      }
    else
      {
      push @$ar, $_;
      }
    push @$dl, "$fn line $ln" if $dl;
    }

  close( $if );

}

# TODO: backport to Data::Tools
sub __nini_find_file
{
  my $fn  = shift; # file name to load
  my $opt = shift; # options: hash ref

  return $fn if $fn =~ /^\// and -e $fn;
  return undef unless exists $opt->{ 'DIRS' } and ref( $opt->{ 'DIRS' } ) eq 'ARRAY';

  for my $p ( @{ $opt->{ 'DIRS' } } )
    {
    my $nf = "$p/$fn";
    return $nf if -e $nf;
    }

  return undef;
}

##############################################################################

sub __nini_find_next_autoindex
{
  my $n = shift; # hashref of current NINI branch

  my $x = 0;
  while( my ( $k, $v ) = each %$n )
    {
    next unless ref $v;   # skip keys, search for branches only
    next unless $k =~ /^\d+$/; # skip non-numeric ones, '05' is non-numeric also
    $x = $k if $k > $x;
    }
  return $x + 1;
}

# parse path, current NINI data ref and takes string and returns current branch hashref
sub __nini_parse_path
{
  my $N = shift; # hashref of the result NINI structure
  my $y = shift; # path type: = regular or * abstract
  my $p = shift; # path string

  $p =~ s/^\s*//;
  $p =~ s/\s*$//;

  $y = undef unless $y eq '*';
  my $n = $N; # current branch
  my @na;     # current path names
  my @p = split /\s+/, $p;
  for my $e ( @p )
    {
    if( $e =~ /\!+/ )
      {
      my $el = length $e;
      for my $k ( keys %$n )
        {
        my $r = ref $n->{ $k };
        delete $n->{ $k } if ! $r and ( $el == 1 or $el > 2 ); # handles keys     and  ! or !!!+
        delete $n->{ $k } if   $r and (             $el > 1 ); # handles branches and !! or !!!+
        }
      }
    elsif( $e =~ /^([A-Za-z0-9:._\/-]+|[*])$/ )
      {
      if( $e eq '*' )
        {
        $e = __nini_find_next_autoindex( $n );
        }

      if( exists $n->{ $e } and ! ref $n->{ $e } )
        {
        # TODO: error, item exists but is a key
        die "path [$p] resolve hits existing key at [$e]";
        }
      else
        {
        if( $y eq '*' )
          {
          $e = $y . $e;
          $y = undef;
          }
        $n->{ $e } ||= {};
        $n = $n->{ $e };
        push @na, $e;
        }
      }
    elsif( $e =~ /^#/ )
      {
      # this is start of a comment, exit loop
      last;
      }
    else
      {
      # TODO: error
      die "path [$p] resolve hits invalid element name at [$e]";
      }
    }
  return ( $n, \@na );
}

sub __nini_find_path
{
  my $N = shift; # hashref of the result NINI structure
  my $p = shift; # path string

  $p =~ s/^\s*//;
  $p =~ s/\s*$//;

  my $n = $N;
  my @na;
  my @p = split /\s+/, $p;
  for my $e ( @p )
    {
    return undef unless exists $n->{ $e };
    return undef unless ref    $n->{ $e };
    $n = $n->{ $e };
    push @na, $e;
    }

  return ( $n, \@na );
}

# compare two paths (array refs)
# return: 1 if first  is exact subset (from pos 0) of the second
#         2 if second is exact subset (from pos 0) of the first
#         undef if any element does not match or one array has zero elements
sub __nini_compare_path
{
  my $na1 = shift;
  my $na2 = shift;

  return undef if $#$na1 < 0 or $#$na2 < 0; # one is empty, no match

  my ( $x, $rc ) = $#$na1 < $#$na2 ? ( $#$na1, 1 )  : ( $#$na2, 2 );
  for( 0 .. $x )
    {
    my $e1 = $na1->[$_];
    my $e2 = $na2->[$_];
#   print ">>>>>>>>>>>>>> comp path: $e1 === $e2\n";
    return undef unless $e1 eq $e2;
    }
#  print ">>>>>>>>>>>>>> comp rc: $rc\n";
  return $rc;
}

# NOTE: this is backported from Data::Tools::CSV
# extended with whitespace delimiters and more quote characters
sub __nini_parse_values
{ #OK
  my @line  = split //, shift();
  my $delim = shift();

  $delim = length $delim > 0 ? substr( $delim, 0, 1 ) : undef; # sanity

  my @out;
  my $fld;
  my $q;   # delimiters count in current data element
  my $u;   # if quotes used, which one is in play
  for( @line, undef )
    {
    if( ! defined $fld )
      {
      last if ! defined and ! defined $delim;
      next if /\s/;
      $u = $_ if ! $u and index( q['"|], $_ ) > -1;
      }
    $q++ if $_ eq $u;
    if( ( ( defined $delim ? $_ eq $delim : /\s/ ) and $q % 2 == 0 ) or ! defined )
      {
      $fld =~ s/\s*$//;
      $fld =~ s/^\Q$u\E(.*?)\Q$u\E$/$1/,$fld =~ s/\Q$u$u\E/$u/g if $u;
      push @out, $fld;
      $fld = $u = $q = undef;
      next;
      }
    $fld .= $_;
    }

  return \@out;
}

sub nini_parse_data
{
  my $ar  = shift;
  my $opt = shift; # options: hash ref

  my %N; # result NINI config

  my $debug  = $opt->{ 'DEBUG' };

  my $dl  = $opt->{ 'DL' };
  die "nini_load_file: error: 'DL' (debug locations) must be array reference\n" if $dl and ref $dl ne 'ARRAY';

  my $n = \%N; # current NINI branch
  my $na;

  my @stash;

  my $ssq = 1; # section sequence
  my $on = -1; # location number
  $n->{ ':ord' } = $ssq++;
  for( @$ar )
    {
    $on++;
    my $ons = $dl ? $dl->[ $on ] : "row $on";

    if( /^\@\@\@push/ )
      {
      push @stash, [ $n, $na ];
      next;
      }
    if( /^\@\@\@pop/ )
      {
      ( $n, $na ) = @{ pop @stash };
      next;
      }

    if( /^([=*])(.*)/ )
      {
      my $y = $1; # section type, "=" is regular, "*" is abstract
      my $p = $2; # section path
      ( $n, $na ) = __nini_parse_path( \%N, $y, $p );
      push @{ $n->{ ':origin' } }, $ons if $debug;
#print ">>>>>>>>>>>>> SECTION [$y$p] seq [$ssq]\n";
      $n->{ ':ord' } ||= $ssq++ if $y eq '='; # sequences for regular sections
      }
    elsif( /^([&]+)\s*(.*)/ )
      {
      my $isa  = $1; # inherit keys (&), branches (&&) or both (&&&+)
      my $isap = $2; # inherit path
      my $lisa = length $isa;
      my ( $fn, $fna ) = __nini_find_path( \%N, $isap );

      if( ! $fn )
        {
        push @{ $N{ ':warn' } }, "cannot find path to inherit [$isap] at $ons";
        next;
        }

#print ">>>>>>>>>>>>> $fn -> $n (@$fna) -> {@$na}\n";
      if( $fn eq $n )
        {
        push @{ $N{ ':warn' } }, "cannot inherit self at $ons" if $debug;
        next;
        }
      die "nini: error: cannot inherit parent branch into current (@$fna) -> (@$na) at $ons\n" if ( $lisa == 2 or $lisa > 2 ) and __nini_compare_path( $fna, $na ) == 1;

      for my $k ( grep /^[^:]/, keys %$fn )
        {
        $n->{ $k } =         $fn->{ $k }   if ! ref $fn->{ $k } and ( $lisa == 1 or $lisa > 2 );
        $n->{ $k } = dclone( $fn->{ $k } ) if   ref $fn->{ $k } and ( $lisa == 2 or $lisa > 2 );
        }
      push @{ $n->{ ':origin' } }, $ons, exists $fn->{ ':origin' } ? @{ $fn->{ ':origin' } } : () if $debug;
      }
    elsif( /^([+-])?([A-Za-z0-9_:\/][A-Za-z0-9:._\/-]*)(\[(.)?\])?(\s+(.+))?$/ )
      {
      my $o = $1; # operator, + add, - remove, etc...
      my $k = $2; # key name
      my $a = $3; # array request
      my $s = $4; # separator
      my $v = $6; # value data

      $v = '1' unless length $v;

      my $vv = __nini_parse_values( $v, $a ? $s : "\000" );
      # $n->{ $k } = $a ? __nini_parse_array( $v, $s ) : __nini_parse_scalar( $v );
      $n->{ $k } = $a ? $vv : $vv->[ 0 ];
      die "nini: error: syntax error in data [$_] at $ons\n" unless defined $n->{ $k };
      }
    else
      {
      # TODO: error
      die "nini: error: unrecognisable data [$_] at $ons";
      }
    }

  return \%N;
}

##############################################################################

1;
