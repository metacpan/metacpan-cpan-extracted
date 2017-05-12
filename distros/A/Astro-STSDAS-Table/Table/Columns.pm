package Astro::STSDAS::Table::Columns;

require 5.005_62;
use strict;
use warnings;

use Carp;

use Astro::STSDAS::Table::Column;

our $VERSION = '0.01';

sub new
{
  my $class = shift;
  $class = ref($class) || $class;


  my $self = {
	       cols  => {},
	       idxs  => {},
	       idxs_s => undef, # sorted indices
	     };

  bless $self, $class;
}

sub ncols
{
  scalar keys %{$_[0]->{cols}};
}

sub add
{
  my $self = shift;

  $self->_add( Astro::STSDAS::Table::Column->new( @_ ) );
}

sub _add
{
  my ( $self, $col ) = @_;

  croak( __PACKAGE__, "->add: duplicate column index `", $col->idx, "'\n" )
    if exists $self->{idxs}{$col->idx};

  croak( __PACKAGE__, "->add: duplicate column name `", $col->name, "'\n" )
    if exists $self->{cols}{lc $col->name};

  $self->{cols}{lc $col->name} = $col;
  $self->{idxs}{$col->idx} = $col;
  $_[0]->{idxs_s} = undef;
  $col;
}

sub del
{
  my $self = shift;
  my $col = shift;

  # first make sure its one of ours.
  return 0 unless grep { $col == $_ } values %{$self->{cols}};

  $self->delbyname( $col->name );
}

sub delbyname
{
  my $self = shift;
  my $name = lc shift;
  return 0 unless exists $self->{cols}{$name};

  delete $self->{idxs}{$self->{cols}{$name}->idx};
  delete $self->{cols}{$name};
  $_[0]->{idxs_s} = undef;
  1;
}

sub byidx
{
  exists $_[0]->{idxs}{$_[1]} ? $_[0]->{idxs}{$_[1]} : undef;
}


sub byname
{
  my $name = lc $_[1];
  return undef unless exists $_[0]->{cols}{$name};
  $_[0]->{cols}{$name};
}

sub cols
{
  $_[0]->_mkidxs_s unless defined $_[0]->{idxs_s};
  @{$_[0]->{idxs_s}};
}

sub _mkidxs_s
{
  $_[0]->{idxs_s} = [ sort { $a->idx <=> $b->idx} values %{$_[0]->{cols}} ];
}

sub names
{
  map { $_->name } $_[0]->cols;
}

sub rename
{
  my ( $self, $name, $newname ) = @_;

  my $col = $self->byname($name);
  return undef unless defined $col;

  $self->delbyname( $name );

  $col->name($newname);
  $self->_add( $col );
}

sub _access
{
  my $what = shift;
  
  sub { 
    
    my $self = shift;
    my $name = lc shift;
    return undef unless exists $self->{cols}{$name};
    $self->{cols}{$name}->$what(@_);
  }
}

{ 
  no strict 'refs';
  *$_ = _access( $_ ) 
    foreach qw( units format idx offset type nelem fmt is_string is_undef );
}



sub copy
{
  my $self = shift;

  my $new = $self->new;

  $new->_add( $_->copy ) foreach values %{$self->{cols}};

  $new;
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Astro::STSDAS::Table::Columns - Container for table columns

=head1 SYNOPSIS

  use Astro::STSDAS::Table::Columns;

=head1 DESCRIPTION

B<Astro::STSDAS::Table::Columns> is a container for a set of
B<Astro::STSDAS::Table::Column> objects.

Column names are stored as mixed case, but case is ignored
when searching by name.  All methods which return
column names return them as stored (i.e. in mixed case).

=head2 Methods

=over 8

=item new

  $cols = Astro::STSDAS::Table::Columns->new;

The constructor.  It takes no arguments.

=item ncols

  $ncols = $cols->ncols

The number of columns in the container

=item add

  $newcol = $cols->add( ... )

Add a column to the container.  It takes the same arguments as the
B<Astro::STSDAS::Table::Column> constructor.  It returns a reference
to the new column object.

=item del

  $cols->del( $col )

Delete the passed B<Astro::STSDAS::Table::Column> object from the container.
It returns C<1> if successful, C<0> if not.

=item delbyname

Delete the named column from the container.  It returns C<1> if
successful, C<0> if not.

=item byidx

  $col = $cols->byidx( $idx );

return the column with the specified zero-based index in the list of
columns.

=item byname

  $col = $cols->byname( $name );

return the column with the specified name.

=item cols

  @cols = $cols->cols;

returns a list of the columns (as B<Astro::STSDAS::Table::Column> objects)
sorted on column index.

=item names

  @names = $cols->names;

returns a list of column names, sorted on column index.

=item rename

  $cols->rename( $oldname, $newname );

Rename the named column.  It is important to use this method rather
than a column's B<name> method, to ensure the integrity of the
container.


=item copy

  $new_cols = $cols->copy;

This returns a new B<Astro::STSDAS::Table::Columns> object which is a
copy of the current object.  The contained
B<Astro::STSDAS::Table::Column> objects are copies of the originals.

=back


=head2 EXPORT

None by default.


=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius (djerius@cpan.org)

=head1 SEE ALSO

Astro::STSDAS::Table, Astro::STSDAS::Table::Column, perl(1).

=cut
