package App::Brl2Brl;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;
use Exporter qw(import);
use Carp;
use File::ShareDir qw(dist_dir);

our @EXPORT_OK = qw(parse_dis Conv switch_brl_char_map new);

=encoding utf8

=head1 NAME

App::Brl2Brl - Convert between braille display tables defined in Liblouis.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

This module is useful if you have a text coded for one braille character set and need to convert it to another, e.g. you have a text in North American ASCII or Eurobraille and you need it in Unicode braille.

    use App::Brl2Brl;

    my $brl_obj = App::Brl2Brl->new({ # to read in the specified files and store the characters/dots in hashes
      from_table_file => 'en-us-brf.dis', # or another display table
      to_table_file => 'unicode.dis', # or another display table
      warn => 1, # if you want to be warned if a char isn't defined in table
    });
    my $out = $brl_obj->switch_brl_char_map('ABC123'); # switch from BRF to Unicode braille
    print "$out\n";

Or you may do:

    use App::Brl2Brl;

    my $from_table_file = 'en-us-brf.dis';
    my $to_table_file = 'unicode.dis';

    my %from_table = parse_dis( "$from_table_file" );
    my %to_table = parse_dis( "$to_table_file" );
    while( <> ){
      my $out = Conv( \%from_table, \%to_table, $_);
      print "$out\n";
    };


=head1 EXPORT

parse_dis - Parses a given display table

Conv - Convert from one display table to another.

=head1 SUBROUTINES/METHODS

=head2 new

Takes the following parameters:

      path => '/usr/share/liblouis/tables', # path to liblouis tables
      from_table_file => 'en-us-brf.dis', # or another display table
      to_table_file => 'unicode.dis', # or another display table
      warn => 1, # if you want to be warned if a char isn't defined in table

The path is optional. App::Brl2Brl comes with a copy of the data files
and knows where to find them. Only provide this if you want to use a
different set of data files, perhaps a more recent one. As with most
liblouis software you can also set C<LOUIS_TABLEPATH> in your environment.

The order of precedence is that the value in a C<path> argument will be used,
falling back to C<LOUIS_TABLEPATH>, falling back to using the data bundled with
the module.

=cut

sub new {
  my ($class,$args) = @_;

  # figure out which path to use
  if(!exists($args->{path})) {
      if(exists($ENV{LOUIS_TABLEPATH})) {
          $args->{path} = $ENV{LOUIS_TABLEPATH};
      } else {
          $args->{path} = dist_dir('App-Brl2Brl');
      }
  }

  my $self = {
    path => $args->{path},
    from_table_file => $args->{from_table_file},
    to_table_file => $args->{to_table_file},
    warn => $args->{warn},
  }; # $self
  my $complete_from_filename = "$self->{path}/"."$self->{from_table_file}";
  my $complete_to_filename = "$self->{path}/"."$self->{to_table_file}";
  $self->{from_table} = { parse_dis( $complete_from_filename ) };
  $self->{to_table} = { parse_dis( $complete_to_filename ) };
  
  bless( $self, $class );
  return $self;
} # new

=head2 switch_brl_char_map

Switch a character or string of characters from one character set
to another, defined by from_table and to_table set in the new function.

=cut

sub switch_brl_char_map {
  my $self = shift; 
  my $inputstr = shift;
  my $warn = $self->{warn};
  my $outputstr = Conv( $self->{from_table}, $self->{to_table}, $warn, $inputstr );
  return $outputstr;
} # switch_brl_char_map

=head2 parse_dis

Parses a liblouis display table file (.dis) and return a hash with the
characters and dots respectively.

=cut

sub parse_dis {
  my $fileName = shift;
  my ($char, $dots, %table);
  open( DIS, "<", $fileName) || croak "Error opening file $fileName;";
  while( my $line = <DIS>) {
    $char = '';
    $dots = 0;
    next unless( $line =~ /^display/i);
    ($char, $dots) = $line =~ /display\s+(\S+)\s+(\S+)/i;
    if( $char =~ /\\s/ ){
	$char = " ";
    }
    if( length($char) >=4 ){ # $char is a hex value, not a char.
      #$charhex = "u";
      #$charhex = sprintf '%2.2x', unpack('U0U*', $char);
      #$charhex .= sprintf "%04x", ord Encode::decode("UTF-8", $char);
      $char =~ s/\\x//i;
      $char =~ s/(....)/ pack( 'U*', hex($1))/ie;
    }
    if( !defined($table{$char})) {
      if( $dots =~ /^$/ ){
	$dots = 0;
      }
      $char =~ s/^\\\\$/\\/;
      $table{$char} = $dots;
    }
  }
  close( DIS );

  my( $chr, $dts );
  while( ($chr, $dts) = each (%table) ){
      $dts = $table{$chr};
      next unless( $dts == 1 );
      last;
  } # while
  if( $chr =~ /⠁/ ){ # if dot 1 is x2801
    $table{"⠀"} = 0; # inject unicode brl space
  } else {
    $table{" "} = "0";
  } # if

  return( %table );
} # parse_dis

=head2 Conv

Converts a string, character by character, from %from_table to %to_table.

=cut

sub Conv {
  my %from_tab = %{shift()};
  my %to_tab = %{shift()};
  my $warn = shift unless $#_ == 0;
  my $inputstr = shift;

  my( $dots, $outC, $outstr);
  foreach my $inC (split( //, $inputstr )){
    if( $inC =~ /([\r\n\f])/ ){
      $outstr .= $inC;
      next;
    } # if
    if( !exists $from_tab{$inC} ) {
      $outstr .= $inC;
      carp "Warning: Character $inC isn't defined in input table!\n" if( defined $warn && $warn != 0);
      next;
    }
    $dots = 0;
    $outC = '';
    $dots = $from_tab{$inC};
    for my $outkey (keys %to_tab) {
      if( $to_tab{$outkey} =~ /^$dots$/ ){
	$outC = $outkey;
	$outstr .= $outC;
      }
    }
    if( $outC =~ /^$/ ){
      $outstr .= $inC;
      carp "Warning: Dots $dots isn't defined in output table!\n" if( defined $warn && $warn != 0);
    }
  }
  return $outstr;
} # Conv

=head1 AUTHOR

Lars Bjørndal, C<< <lars at lamasti.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-brl2brl at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Brl2Brl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Brl2Brl

and

    perldoc brl2brl

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Brl2Brl>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-Brl2Brl>

=item * Search CPAN

L<https://metacpan.org/release/App-Brl2Brl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Lars Bjørndal.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

It includes data files in the C<share> directory copied from
v3.26.0 of
L<liblouis|https://github.com/liblouis/liblouis/tree/v3.26.0/tables>.
Liblouis is free software licensed under the
L<GNU LGPLv2.1+|https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>
(see the file COPYING.LESSER).

=cut

1; # End of App::Brl2Brl
