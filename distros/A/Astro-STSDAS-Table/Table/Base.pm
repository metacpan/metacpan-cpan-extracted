package Astro::STSDAS::Table::Base;

our $VERSION = '0.12';

use strict;
use Config;
use POSIX;


use IO::File;
use Carp qw( carp croak );

use Astro::STSDAS::Table::HeaderPars;
use Astro::STSDAS::Table::Columns;

sub new
{ 
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = {
	     # the filehandle to the table
	     fh	=> undef,
	     
	     pars => Astro::STSDAS::Table::HeaderPars->new(),
	     
	     cols => Astro::STSDAS::Table::Columns->new(),

	     nrows => undef,

	     file => undef,

	     mode => undef,

	     fh => undef

	    };


  bless $self, $class;
}

sub open
{
  @_ >=2 or croak 'usage : $self->open( $file [, $mode] )';
  my ( $self, $file, $mode ) = @_;

  $mode = '<' if ! defined $mode;
  $self->{mode} = $mode;
  my $fh = new IO::File;

  if ( ref($file) )
  {
    $fh->fdopen( $file, $mode ) || return undef;
  }
  else
  {
    $fh->open( $file, $mode ) || return undef;
  }

  $self->{file} = $file;
  $self->{fh} = $fh;

  # if this is open for reading, suck in the header
  if ( $mode =~ /[<+]/ )
  {
    $self->_read_hdr;
  }

  1;
}

sub METHOD::ABSTRACT
{
  my ($self) = @_;
  my $object_class = ref($self);
  my ($file, $line, $method) = (caller(1))[1..3];
  my $loc = "at $file, line $line\n";
  die "call to abstract method ${method} $loc";
}


sub _read_hdr { ABSTRACT METHOD @_ }
sub read_cols { ABSTRACT METHOD }
sub read_rows { ABSTRACT METHOD }

sub close
{
  my $self = shift;

  if ( defined $self->{fh} )
  {
    close $self->{fh};
    $self->{fh} = undef;
  }
}


1;

__END__

=pod

=head1 NAME

Astro::STSDAS::Table::Base - Base class for STSDAS Tables

=head1 SYNOPSIS

  use Astro::STSDAS::Table::Base;

  @isa = qw( Astro::STSDAS::Table::Base );

  sub new
  { 
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = $class->SUPER::new();

    ...

    bless $self, $class;
  }

=head1 DESCRIPTION

B<Astro::STSDAS::Table::Base> is a base class and should be sub-classed
to derive any functionality.  B<Astro::STSDAS::Table::Binary> is a
fully derived class which reads binary STSDAS tables.

B<Astro::STSDAS::Table::Base> provides several methods and requires
that the derived class provide the rest.

The base class constructor (which must be called by the derived class)
creates a hash object.  The following keys are reserved, and shouldn't
be changed unless explicitly allowed.

=over 8

=item fh

An B<IO::File> object attached to the file.

=item pars

An B<Astro::STSDAS::Table::HeaderPars> object, which must be
initialized by the derived class.  It is created by the base class.

=item cols

An B<Astro::STSDAS::Table::Columns> object, which must be
initialized by the derived class.  It is created by the base class.

=item nrows

The number of rows in the table, if determinable.  This is filled in
by the derived class.

=item file

The table's filename.  This is filled in by the base class.

=item mode

The mode in which the table was opened.  This is filled in by the base
class.

=back


=head1 METHODS

=head2 Methods provided by the base class

=over 8

=item new

The B<new> method is the class constructor, and must be called before
any other methods are invoked.  It is usually invoked from the derived
class as

        @ISA = ( Astro::STSDAS::Table::Base );
        ...
	$self = $class->SUPER->new();


=item open

  $table->open( file or filehandle [, mode] );

B<open> connects to a file (if it is passed a scalar) or to an
existing file handle (if it is passed a reference to a glob).  If mode
is not specified, it is opened as read only, otherwise that specified.
Modes are the standard Perl-ish ones (see the Perl open command).  If
the mode is read only or read/write, it calls the C<_read_hdr> method
to read in the table header.  This method must be provided by the
derived class.

It returns true upon success, false otherwise.

=item close

explicitly close the table.  This usually need not be called, as the
file will be closed when the object is destroyed.

=back

=head2 Methods provided by the derived class

These methods are I<not> provided by the base class.

=over 8

=item _read_hdr

  $table->_read_hdr;

This method is called by the B<open> method.  It should read the table
header from C<$table-E<gt>{fh}>, parse it, and initialize the C<<
$table->{cols} >> and C<< $table->{pars} >> objects.  It should
leave the file pointer at the beginning of the data.

=item read_rows_hash

  $rows = $tbl->read_rows_hash;

This method should read the table data from C<$table-E<gt>{fh}> (which
will be positioned so that the table data is the next data available
from it), digest the whole enchilada and return a reference to an
array of hashes, one per row. The hash keys are the (lower cased)
column names.  Vector elements are stored as references to arrays
containing the data.

For example, to access the value of column C<time> in row 3,

	$rows->[2]{time}

=item read_rows_array

  $rows = $tbl->read_rows_array;

This method should read the table data from C<$table-E<gt>{fh}> (which
will be positioned so that the table data is the next data available
from it), digest the whole enchilada and return a reference to an
array of arrays, one per row.  Vector elements are stored as
references to arrays containing the data.

For example, to access the value of column 9 in row 3,

	$rows->[3][9]

=item read_cols_hash

  $cols = $tbl->read_cols;

This method should read the table data from C<$table-E<gt>{fh}> (which
will be positioned so that the table data is the next data available
from it), digest the whole enchilada and return a reference to a hash,
each element of which is a reference to an array containing data for a
column.  The hash keys are the (lower cased) column names.  Vector
elements are stored as references to arrays containing the data.

For example, to access the value of column C<time> in row 3,

	$cols->{time}[2]

=item read_cols_array

  $cols = $tbl->read_cols_array

This method should read the table data from C<$table-E<gt>{fh}> (which
will be positioned so that the table data is the next data available
from it), digest the whole enchilada and return a reference to an
array, each element of which is a reference to an array containing
data for a column.  Vector elements are stored as references to arrays
containing the data.

For example, to access the value of column 9 in row 3,

	$cols->[9][3]

=back

=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius (djerius@cpan.org)

=cut

