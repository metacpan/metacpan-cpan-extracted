package File::Process::Utils;

use strict;
use warnings;

use Carp;
use Text::CSV_XS;
use Data::Dumper;
use ReadonlyX;
use Scalar::Util qw(reftype);

Readonly our $SUCCESS => 1;
Readonly our $FAILURE => 0;
Readonly our $TRUE    => 1;
Readonly our $FALSE   => 0;

Readonly our $EMPTY => q{};
Readonly our $NL    => "\n";
Readonly our $TAB   => "\t";
Readonly our $PIPE  => q{|};
Readonly our $COMMA => q{,};

use parent qw(Exporter);

our @EXPORT_OK = qw(
  $COMMA
  $EMPTY
  $FAILURE
  $FALSE
  $NL
  $PIPE
  $SUCCESS
  $TAB
  $TRUE
  is_array
  is_hash
  process_csv
);

our %EXPORT_TAGS = (
  'booleans' => [qw($TRUE $FALSE $SUCCESS $FAILURE is_array is_hash)],
  'chars'    => [qw($NL $EMPTY $PIPE $TAB $COMMA)],
  'all'      => \@EXPORT_OK,
);

our $VERSION = '0.12';

########################################################################
sub _is_array { push @_, 'ARRAY'; goto &_is_type; }
sub _is_hash  { push @_, 'HASH';  goto &_is_type; }
sub is_code   { push @_, 'CODE';  goto &_is_type; }
########################################################################

########################################################################
sub is_hash {  ## no critic (RequireArgUnpacking)
########################################################################
  my $result = _is_hash( $_[0] );

  return
    if !$result;

  return wantarray ? %{ ref $_[0] ? $_[0] : {} } : $result;
}

########################################################################
sub is_array {  ## no critic (RequireArgUnpacking)
########################################################################
  my $result = _is_array( $_[0] );

  return
    if !$result;

  return wantarray ? @{ ref $_[0] ? $_[0] : [] } : $result;
}

########################################################################
sub _is_type { return ref $_[0] && reftype( $_[0] ) eq $_[1]; }
########################################################################

########################################################################
sub process_csv {
########################################################################
  my ( $file, %options ) = @_;

  require File::Process;

  my $csv_options = $options{csv_options} // {};

  my $csv = Text::CSV_XS->new($csv_options);

  $options{chomp} //= $TRUE;

  my ( $csv_lines, %info ) = File::Process::process_file(
    $file,
    csv => $csv,
    %options,
    pre => sub {
      my ( $file, $args ) = @_;

      my ( $fh, $all_lines ) = File::Process::pre( $file, $args );

      if ( $args->{'has_headers'} ) {
        my @column_names = $args->{csv}->getline($fh);
        $args->{csv}->column_names(@column_names);
      }

      return ( $fh, $all_lines );
    },
    next_line => sub {
      my ( $fh, $all_lines, $args ) = @_;

      return
           if defined $args->{max_rows}
        && @{$all_lines}
        && @{$all_lines} >= $args->{max_rows};

      my $ref;

      if ( $args->{has_headers} ) {
        $ref = $args->{csv}->getline_hr($fh);

        if ( my (%skips) = is_hash( $args->{skip_list} ) ) {
          for ( keys %skips ) {
            delete $ref->{$_};
          }
        }
      }
      else {
        $ref = $args->{csv}->getline($fh);

        return $ref
          if !$ref;

        if ( !$args->{keep_list} && is_array( $args->{skip_list} ) ) {

          my @keep_list = ( 0 .. $#{$ref} );

          for ( @{ $args->{skip_list} } ) {
            splice @keep_list, $_, 1;
          }

          $args->{keep_list} = \@keep_list;
        }

        if ( $args->{keep_list} ) {
          $ref = [ @{$ref}[ @{ $args->{keep_list} } ] ];
        }
      }

      my %row;

      my $column_keys = $args->{column_names};

      if ( is_array($column_keys) ) {

        if ( !@{$column_keys} ) {
          # generated extra column names as needed
          $column_keys = [ map {"col$_"} ( 0 .. $#{$ref} ) ];
          $args->{column_names} = $column_keys;
        }
      }

      if ($column_keys) {
        %row = map { $column_keys->[$_] => $ref->[$_] } ( 0 .. $#{$ref} );
        if ( my (%skips) = is_hash( $args->{skip_list} ) ) {
          for ( keys %skips ) {
            delete $row{$_};
          }
        }
      }

      # hooks?
      if ( my (@hooks) = is_array( $args->{hooks} ) ) {

        for my $col ( 0 .. $#{$ref} ) {
          is_code $hooks[$col];

          next if !is_code $hooks[$col];

          $ref->[$col] = $hooks[$col]->( $ref->[$col] );
        }
      }
      elsif ( my (%hooks) = is_hash( $args->{hooks} ) ) {

        croak "you just define column_names when 'hooks' is a hash\n"
          if !@{$column_keys};

        for my $column_name ( @{$column_keys} ) {
          next if !is_code $hooks{$column_name};

          $row{$column_name}
            = $hooks{$column_name}->( $row{$column_name} );
        }
      }

      return $column_keys ? \%row : $ref;
    }
  );

  return ( $csv_lines, %info );
}

1;

__END__

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

File::Process::Utils - commonly used recipes for File::Process

=head1 SYNOPSIS

 use File::Process::Utils qw(process_csv);

 my $obj = process_csv('foo.csv', has_headers => 1);

=head1 DESCRIPTION

Set of utilities that represent some common use cases for L<File::Process>.

=head1 METHODS AND SUBROUTINES

=head2 process_csv

 process_csv(file, options)

Reads a CSV files using L<Text::CSV_XS> and returns an array of hashes
or an array or arrays.

Example:

 my $obj = process_file(
   'foo.csv',
   has_header  => 1,
   csv_options => { sep_char "\t" },
   );

=over

=item file

Filename or file handle of an open CSV file.

=item options

List of options described below.

=over 5

=item column_names

A list of column names that should be used as the CSV header. These
names will be in the keys for the hashes returned.

I<Note: By setting C<column_names> to an empty array, you can force
the return of an array of hashes instead of an array of arrays. The
keys will be set the strings C<col0>..C<col{n-1}>>.

=item csv_options

Hash of options that will be passed through to L<Text::CSV_XS>

=back

=item has_header

Boolean that indicates whether or not the first line of the CSV file
should be considred the column titles.  These will be used as the hash
keys. If C<has_header> is not true, then the first line is considered
data and included in the returned array.

Set C<column_names> to an array of strings that will be used as the
keys instead in lieu of having a header line. If you do not set
C<column_names> and C<has_header> is not true, an array of arrays will
be returned instead of an array of hashes.

=item hooks

An array or hash of subroutines that will be passed each element of a
row and should return a transformed value for that element.

If you pass a hash, keys should represent one of the column names you
passed in the C<columns> argument or one of the generated keys
(C<col{n}>).

If you pass an array, the array should contain a code reference in the
index of the array tha that corresponds to the index in the input you
wish to process.

  my %hooks = ( col1 => sub { uc shift } );
              
  my $obj = process_csv(
    'foo.csv',
    column_names => [],
    keep_open    => 1,
    csv_options  => { sep_char => "\t" },
    hooks        => \%hooks,
  );

Instead of using hooks, which operate at the column level, you could
define your own custom C<process()> method and pass that as an option
to C<process_csv()> as all options are passed through to
C<process_file()>..

  my $obj = process_csv(
    'foo.csv',
    column_names => [],
    keep_open    => 1,
    csv_options  => { sep_char => "\t" },
    process      => sub {
      my ( $fh, $lines, $args, $row ) = @_;
      $row->{col1} = uc $row->{col1};
      return $row;
    }
  );

=item keep_open

Boolean that indicates that the file should not be closed after all
records are read.

=item max_rows

Maximum number of rows to process. If undefined, then all lines of the
file will be processed.

=item skip_list

If column names are being used this is hash of keys that will deleted
from the returned hash list;

If column names are not being used, C<skip_list> is an array of
indexes that will be removed from the returned arrays.

 process_csv(
   'foo.csv',
   has_headers => 1,
   skip_list   => { ssn => 1 }
 );

=back

=head1 SEE ALSO

L<File::Process>, L<Text::ASCIITable::EasyTable>

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut
