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
use Storable qw( dclone );
use Data::Dumper;
use strict;

our @ISA = qw( Exporter );

our @EXPORT = qw(
                  nini_load_file

                  nini_parse_data
                );

our $VERSION = '0.12';

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

    if( /^([=*])\s*(.*)/ )
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

=pod

=head1 NAME

Config::NINI - NINI configuration format parser

=head1 SYNOPSIS

  use Config::NINI qw( nini_load_file nini_parse_data );

  # Load and parse a NINI file
  my $data   = nini_load_file('config.nini');
  my $config = nini_parse_data( $data );

  # or

  my $dl = []; # debug locations
  my $data   = nini_load_file('config.nini', { DL => $dl } );
  my $config = nini_parse_data( $data, { DL => $dl, DEBUG => 1 } );

  # Access configuration
  my $value    = $config->{section_name}{key_name};
  my $arrayref = $config->{section_name}{array_key};
  my $hashref  = $config->{section_name}{subsection_name};

=head1 DESCRIPTION

Config::NINI is a Perl module for parsing and loading configuration files in
the NINI format (Not INI). NINI extends traditional INI file concepts with
hierarchical sections, inheritance, array values, and dynamic file inclusion.

Specification, examples, notes on NINI format can be found at:

    https://github.com/cade-vs/NINI
    https://github.com/cade-vs/NINI/blob/master/nini-spec-19.txt
    https://github.com/cade-vs/NINI/blob/master/nini-examples-19.txt

=head2 Key Features

=over

=item * Trivial to write manually

=item * Allow hierarchical section organization

=item * Inheritance of keys and branches between sections

=item * Array value support with configurable delimiters

=item * Dynamic file inclusion via @include directives

=item * Loop detection for included files

=item * Debug location tracking (file and line numbers)

=item * Abstract section paths with auto-indexing

=item * Flexible path navigation and data manipulation

=back

=head1 INSTALLATION

Place Config::NINI in your Perl module search path (@INC). Typically:

  /usr/lib/perl/
  /usr/local/lib/perl/
  ~/perl5/lib/perl5/

Or reference it directly:

  use lib '/path/to/lib';
  use Config::NINI;

=head1 QUICK START

Configuration file example (config.nini):

  = Database
      host      example.com
      port      5432
      user      admin
      password  secret

  = Database Cache
      & Database
      ttl       3600
      enabled   1

Perl script:

  my $config = nini_parse_data( nini_load_file( 'config.nini' ), {} );

  print $config->{Database}{host};              # example.com
  print $config->{'Database Cache'}{host};      # inherited: example.com

=head1 FUNCTIONS

=head2 nini_load_file( FILENAME, OPTIONS )

Loads a NINI configuration file from disk, processing includes and
returning raw data as array reference.

=over

=item B<Arguments>

=over

=item FILENAME

Path to NINI file to load (string)

=item OPTIONS

Hash reference with options:

=over

=item DIRS

Array ref of directories to search for @include directives

=item DL

Array ref for debug location tracking

=back

=back

=item B<Returns>

Array reference containing parsed file lines. This must be variable, since
nini_load_file() will populate it and nini_parse_data() will use it to report
warnings and errors.

=item B<Example>

  my $dl = [];
  my $data = nini_load_file('app.nini', {
    DIRS => ['/etc/config', '/home/user/.config'],
    DL   => $dl,  # Enable and keep debug locations tracking
  });

  my $nini = nini_parse_data( $data, { DL => $dl } );

=item B<Notes>

=over

=item * Automatically anchors each file to root section (=)

=item * Detects and prevents file inclusion loops

=item * Strips trailing whitespace from all lines

=item * Returns array of configuration directives ready for nini_parse_data

=back

=back

=head2 nini_parse_data( DATA, OPTIONS )

Parses processed configuration data into hierarchical hash structure.

=over

=item amazB<Arguments>

=over

=item DATA

Array reference (output from nini_load_file)

=item OPTIONS

Hash reference with options:

=over

=item DEBUG

Enable debug information (boolean)

=item DL

Array ref for debug location tracking. See nini_load_file() for examples and
explanation how it works.

=back

=back

=item B<Returns>

Hash reference containing parsed configuration structure

=item B<Special Keys>

The result hash contains special metadata keys:

=over

=item :ord

Section sequence number (regular sections only)

=item :origin

Array of debug location strings (if DEBUG enabled). It includes all locations
in files where the parser went to gather keys information. Can be backtracked
to see when values are coming from.

=item :warn

Array of warning messages encountered

=back

=item B<Example>

  my $config = nini_parse_data($data, {
    DEBUG => 1,
    DL    => $debug_locations
  });

  # Access warnings
  if ($config->{':warn'}) {
    for my $w (@{$config->{':warn'}}) {
      warn "Config warning: $w\n";
    }
  }

=back

=head1 NINI FORMAT SPECIFICATION

=head2 Overview

NINI files consist of:

=over

=item * Sections: Hierarchical organizational units

=item * Keys: Named data elements with scalar or array values

=item * Inheritance: Section can inherit from another section

=item * Comments: Lines starting with #

=item * Includes: Dynamic file inclusion with @include

=item * Paths: Whitespace-separated hierarchical navigation

=back

File structure:

  =Section_Name
      key1    value1
      key2[,] v1, v2, v3
      key3[|] v1 | v2 | v3
      & Parent_Section

  =Section_Name  Sub_Section_Name
      & Other Sub_Section
      key4 value4
      text[]  those are space delimited 6 words

Blank lines and comment lines (starting with #) are ignored.

=head2 Comments

Lines starting with C<#> are treated as comments and ignored entirely.

Lines with content are treated as-is; there is no support for trailing/inline
comments. Unless line begins with '#', the '#' symbol is verbatim and has no
special meaning.

  # port number 5566
  port  #5566

  # anywhere in-between
  url https://www.gocomics.com/extras/first-calvin-and-hobbes-comic-strip#rulz

=head1 SECTIONS

=head2 Regular Sections

Marked with C<=> (equals sign). Create new hierarchical branch.

  = Top_Level_Section

  = Top_Level_Section Sub_Section
    (continues in parent section by default)

  = Another_Top_Level

Whitespace-separated path components create hierarchy:

  = level1 level2 level3

Creates Perl structure:

  %hash = (
    level1 => {
      level2 => {
        level3 => { ... }
      }
    }
  );

=head2 Abstract Sections

Marked with C<*> (asterisk). Used for dynamic array-indexed branches.

  * items           # Creates branch at index 0
  key1 value1

  * items           # Creates branch at index 1
  key2 value2

Creates structure:

  items => {
    *0 => { key1 => 'value1' },
    *1 => { key2 => 'value2' }
  }

Auto-indexing with C<*> wildcard in path:

  = data *
  name Widget A

Expands C<*> to next available integer index. Integer indexes are not required
to be continuous. If there are 1, 5, 16 the next auto-index will be 17 etc.

=head2 Section Modifiers

Delete section contents using C<!> operators:

=over

=item C<!>

Delete all keys.

=item C<!!>

Delete all sub-section branches.

=item C<!!!>

Delete everything (keys and branches)

=back

Example:

  = Section
  key1 value1
  branch_name branch_data

  = Section
  !!
  # only key1 left

=head1 KEYS AND VALUES

=head2 Key Syntax

  [+|-]KEY[ARRAY][WHITESPACE]VALUE

Components:

=over

=item [+|-]

Operator (optional) - Add or remove operation

=item KEY

Key name (required)

Pattern: C<[a-zA-Z0-9_:\/][a-zA-Z0-9:._\/-]*>

=item [X]

Array indicator with delimiter (optional)

=item VALUE

Data value (optional, defaults to '1' if omitted)

=back

Examples:

  key1                    # Scalar, value = '1'
  key2 hello world        # Scalar, value = 'hello world'
  key3 [,] a,b,c          # Array, comma-separated
  key4 [|] x|y|z          # Array, pipe-separated
  key5 [ ] space separated # Array, space-separated
  +key6 append_value      # Add operation (modifier)

=head2 Delimiters

Array delimiter specified in C<[X]> where X is:

=over

=item C<,>

Comma

=item C<|>

Pipe

=item C<;>

Semicolon

=item C<:>

Colon

=item (empty)

Whitespace (implicit)

=back

=head3 Quote Handling

=over

=item Single quotes (C<'>)

Preserve content, remove quotes

=item Double quotes (C<">)

Preserve content, remove quotes

=item Pipe quotes (C<|>)

Preserve content, remove quotes

=item Escaped quotes (C<"">)

Become single quote in output

=back

=head2 Value Parsing

Whitespace handling:

=over

=item * Leading/trailing whitespace stripped

=item * Quoted values preserve internal whitespace

=back

Examples:

  key1     value with spaces
  key2 "  quoted value  "
  key3 "#hash_included"

Results:

  key1 => 'value with spaces'
  key2 => '  quoted value  '
  key3 => '#hash_included'

=head1 ARRAYS

=head2 Array Declaration

Arrays specified with delimiter in brackets:

  array_name [DELIMITER] item1 DELIMITER item2 DELIMITER item3

Returns Perl array reference.

Access in code:

  my @items = @{$config->{section}{array_name}};
  my $count = scalar @{$config->{section}{array_name}};
  my $first = $config->{section}{array_name}->[0];

=head2 Whitespace-Separated Arrays

Using space as implicit delimiter:

  array_name[] one two three four

Results in:

  array_name => ['one', 'two', 'three', 'four']

=head2 Single-Character Delimiters

All delimiters are single-character:

  ports[,] 8080,8081,8082,8443
  formats[|] json|xml|csv|yaml
  paths[:] /etc:/opt:/home

=head2 Quote Handling in Arrays

Quotes included in array delimiters:

  items[,] "first item", 'second item', third

Results in:

  items => ['first item', 'second item', 'third']

=head1 INHERITANCE

=head2 Basic Inheritance

Sections can inherit from other sections using C<&> operator.

  = Base
  key1 value1
  key2 value2

  = Derived_Section
  & Base
  key3 value3

Derived Section inherits C<key1> and C<key2> from Base Section.

Result:

  'Derived_Section' => {
    key1 => 'value1',  # inherited
    key2 => 'value2',  # inherited
    key3 => 'value3'   # own
  }

=head2 Inheritance Levels

Multiple C<&> specifiers control inheritance depth:

=over

=item C<& SOURCE>

Inherit keys only

=item C<&& SOURCE>

Inherit branches only (deep copy, no keys at the same level)

=item C<&&& SOURCE>

Inherit keys AND branches. Any number of '&'s beyond 2 is the same.

=back

=head2 Selective Inheritance

  = Parent
      key1 value1
      sub_branch sub_data

  = Child
      & Parent                # Inherits key1 only
      && Parent               # Inherits sub_branch only
      &&& Parent              # Inherits both

=head2 Inherited Branch Structure

When inheriting branches (C<&&>), nested structures are deep-copied:

  = Source
      nested parent_value

  = Target
      && Source               # Copies entire nested structure

Resulting structure:

  Target => {
    nested => { ... }     # Deep copy, modifications don't affect Source
  }

=head2 Inheritance Loops

Since inheritance is a deep copy, loops are allowed but may lead to not
obvious results.

  = A
      asd 999
      & A
      # no-op, silent, warning if debug

  = B
      qwe 333
      & A
      # ok

  = A
      & B
      # still ok since deep copy, now both A and B will have asd and qwe keys

=head1 INCLUDE DIRECTIVES

=head2 File Inclusion

Include other NINI files with C<@include>:

  @include filename.nini
  @include /path/to/config.nini

Syntax variations:

  @include filename.nini
  @include path/to/file.nini
  @include /absolute/path/file.nini

=head2 Directory Search

Specify search directories in OPTIONS:

  my $config = nini_parse_data(
    nini_load_file('main.nini', {
      DIRS => [
        '/etc/app',
        '/opt/app/config',
        '/home/user/.app'
      ]
    }),
    {}
  );

If C<@include> uses relative path, directories are searched in order.
First match wins. Absolute paths (starting with C</>) used directly.

=head2 Include Context


When including a file, the context will be forced to be the root section.
When exit included file, the previous secont will be restored. This is needed
so that all keys at the beginning of the included file will not be injected
into the current section of the base file and all keys after the include
will not be attached into the last section of the include file:

  = Mid_Section
      # all leading keys of included.nini will be forced to be in the root
      @include included.nini
      # key1 will be into "Mid_Section", not in the last open section in
      # included.nini
      key1 value1

This behaviour was selected to match close the "what you (probably) expect is
what you get" :)

=head2 Loop Detection

Circular includes are detected and prevented:

  # file1.nini
  @include file2.nini

  # file2.nini
  @include file1.nini

Attempting to load file1.nini will error:

  nini: error: file load: loop detected for file [file1.nini]

=head2 Include Failure Handling

If included file not found:

=over

=item * Silent skip (no error, warning if debug)

=item * Processing continues with next line

=item * No explicit error message (can enable via DEBUG)

=back

=head1 PATH RESOLUTION

=head2 Path Navigation

Paths are whitespace-separated section names:

  = level1 level2 level3
  key value

Creates:

  level1/level2/level3/key => value

=head2 Path Syntax

Valid path elements:

  [A-Za-z0-9:._\/-]+       # Alphanumeric with special chars
  *                        # Auto-index wildcard
  !                        # Delete key modifier
  !!                       # Delete branch modifier
  !!!                      # Delete all modifier

=head2 Deleting Path Elements

Single C<!> deletes matching keys:

  = section
      # Remove all keys in section, mostly for debug or temporary purpose
      !

Double C<!!> deletes matching branches:

  = section
      # Remove all branches
      !!

Triple C<!!!> deletes both:

  = section
      # Remove everything
      !!!

=head2 Auto-Indexing with *

Wildcard C<*> finds next available numeric index:

  = items  *
      name First

  = items  *
      name Second

Sections become:

  'items' => {
    1 => { name => 'First' },
    2 => { name => 'Second' }
  }

=head1 OPTIONS AND DEBUG TRACKING

=head2 Load Options

C<nini_load_file> OPTIONS hash:

=over

=item DIRS

Array ref of directories for C<@include> search

=item DL

Array ref to collect debug locations

=back

Example:

  my @locations;
  my $data = nini_load_file('app.nini', {
    DIRS => ['/etc', '/home/user'],
    DL   => \@locations
  });

  # @locations now contains file:line information for each line

=head2 Parse Options

C<nini_parse_data> OPTIONS hash:

=over

=item DEBUG

Enable debug collection (boolean)

=item DL

Array ref for debug location strings

=back

Example:

  my @locations;
  my $config = nini_parse_data($data, {
    DEBUG => 1,
    DL    => \@locations
  });

=head2 Debug Information

=over

=item :ord

Integer sequence number (regular sections only).
Reflects section order in file.

=item :origin

Array ref of location strings.
Each location: "filename line N" or "filename top/bottom"

Exists only when DEBUG is enabled.

=item :warn

Array ref of warning messages.
Includes unresolved inherits, self-reference attempts, etc.

Exists only when DEBUG is enabled.

=back

Accessing debug info:

  for my $origin (@{$config->{section}{':origin'}}) {
    print "Defined at: $origin\n";
  }

  if (exists $config->{':warn'}) {
    for my $warning (@{$config->{':warn'}}) {
      warn "Config warning: $warning\n";
    }
  }

=head2 Error Messages

Error messages include context:

  nini: error: file load: loop detected for file [FILE]
  nini: error: syntax error in data [LINE] at LOCATION
  nini: error: unrecognisable data [LINE] at LOCATION
  nini: error: cannot inherit parent branch into current at LOCATION

=head1 EXAMPLES

=head2 Simple Configuration

File: C<database.nini>

  = Database
  host        localhost
  port        5432
  user        dbuser
  password    secure_pass
  options[,] ssl,compression,timeout

Perl:

  my $cfg = nini_parse_data( nini_load_file( 'database.nini' ) );

  print $cfg->{Database}{host};      # localhost
  print $cfg->{Database}{port};      # 5432

  my @opts = @{$cfg->{Database}{options}};
  # @opts = ('ssl', 'compression', 'timeout')

=head2 Hierarchical Configuration

File: C<app.nini>

  = Application
      name    MyApp
      version 1.0

  = Application Database
      host    db.example.com
      port    5432

  = Application Cache
      enabled 1
      ttl     3600

Perl:

  my $cfg = nini_parse_data( nini_load_file('app.nini') );

  print $cfg->{Application}{name};
  print $cfg->{Application}{Database}{host};
  print $cfg->{Application}{Cache}{enabled};

=head2 Inheritance

File: C<servers.nini>

  = Default Server
      user          ubuntu
      ssh_key_file  /home/ubuntu/.ssh/id_rsa
      timeout       30

  = Production Web Server
    & Default Server
    hostname      prod-web-01
    ip_address    192.168.1.100
    cpu_count     8

  = Staging Web Server
    & Default Server
    hostname      staging-web-01
    ip_address    192.168.1.101
    cpu_count     4

Perl:

  my $cfg = nini_parse_data( nini_load_file('servers.nini') );

  my $prod = $cfg->{'Production Web Server'};
  print $prod->{user};        # Inherited: ubuntu
  print $prod->{hostname};    # Own: prod-web-01
  print $prod->{timeout};     # Inherited: 30

=head2 Arrays and Delimiters

File: C<services.nini>

  = Services
      tcp_ports[,] 22,80,443,8080
      http_methods[|] GET|POST|PUT|DELETE
      workers[] worker1 worker2 worker3

Perl:

  my $cfg = nini_parse_data( nini_load_file('services.nini') );

  my @tcp = @{ $cfg->{Services}{tcp_ports} };
  # @tcp = ('22', '80', '443', '8080')

  my @methods = @{$cfg->{Services}{http_methods}};
  # @methods = ('GET', 'POST', 'PUT', 'DELETE')

  my @w = @{ $cfg->{Services}{workers} };
  # @w = ('worker1', 'worker2', 'worker3')

=head2 File Inclusion

File: C<main.nini>

  = Application
      name MyApp

      @include database.nini
      @include services.nini

File: C<database.nini>

  = Application Database
      host localhost
      port 5432

File: C<services.nini>

  = Application Services
      api_port 8000

Perl:

  my $cfg = nini_parse_data(
    nini_load_file('main.nini', {
      DIRS => ['.']
    }),
    {}
  );

  print $cfg->{Application}{name};
  print $cfg->{Application}{Database}{host};
  print $cfg->{Application}{Services}{api_port};

=head2 Abstract Sections and Auto-Indexing

File: C<items.nini>

  inventory *
        name      Laptop
        quantity  5
        price     1200

  inventory *
        name      Mouse
        quantity  25
        price     50

  inventory *
        name      Monitor
        quantity  10
        price     350

Perl:

  my $cfg = nini_parse_data(
    nini_load_file('items.nini'),
    {}
  );

  # Access by numeric index
  for my $i (0..2) {
    my $key = "$i";
    my $item = $cfg->{inventory}{$key};
    print "$item->{name}: $item->{quantity}\n";
  }

Output:

  Laptop: 5
  Mouse: 25
  Monitor: 10

=head2 Debug Information

File: C<config.nini>

  = Section1
      key1 value1

  = Section2
      & NonExistent

Perl:

  my @locations;
  my $cfg = nini_parse_data(
    nini_load_file('config.nini', { DL => \@locations }),
    { DEBUG => 1, DL => \@locations }
  );

  # Check for warnings
  if (exists $cfg->{':warn'}) {
    for my $w (@{$cfg->{':warn'}}) {
      print "Warning: $w\n";
    }
  }

Output:

  Warning: cannot find path to inherit [NonExistent] at config.nini line 5

=head1 ERROR HANDLING

=head2 Fatal Errors

Parser dies on:

=over

=item * Syntax errors in key/value lines

=item * Unrecognizable data format

=item * File load loop detection

=item * Invalid inheritance (circular references)

=item * Self-inheritance attempts

=back

Use eval to catch:

  my $cfg;
  eval {
    $cfg = nini_parse_data(
      nini_load_file('config.nini'),
      {}
    );
  };

  if ($@) {
    die "Failed to load config: $@\n";
  }

=head2 Non-Fatal Issues

Warnings collected in C<:warn> key:

=over

=item * Cannot find path to inherit

=item * Self-inheritance attempted

=item * Invalid optional syntax

=back

Access warnings:

  if (exists $config->{':warn'}) {
    for my $warning (@{$config->{':warn'}}) {
      warn "Config issue: $warning\n";
    }
  }

=head2 Common Issues and Solutions

=head3 Value contains # character

Solution: Quote the value

  key1 "#important"       # Value is: #important
  key2 "URL: http://..."  # Value is: URL: http://...

=head3 Array parsing fails

Solution: Ensure separator is single character and matches usage

  correct:   items [,] a,b,c
  wrong:     items [,] a, b, c   # Spaces included in values
  solution:  items [,] a, b, c   # Use proper format

=head3 Include file not found

Solution: Verify DIRS paths or use absolute paths

  Relative:  @include config.nini
  Absolute:  @include /etc/app/config.nini

=head3 Inheritance path not found

Solution: Ensure section exists and is defined before use

  = Parent Section
  key1 value1

  = Child Section
  & Parent Section
  key2 value2

=head1 DEPENDENCIES

NINI uses dclone() from Storable module.

=head1 AUTHOR

Copyright: 2026 (c) Vladi Belperchinov-Shabanski "Cade" E<lt>cade@noxrun.comE<gt>

=head1 LICENSE

This module is distributed under the terms of the GNU General Public License,
version 2 (GPLv2). See http://www.gnu.org/licenses/gpl-2.0.html for details.

=cut
