=head1 NAME

Class::Entity - Object interface for relational databases

=head1 DESCRIPTION

B<Class::Entity> allows a developer to create an object interface for
a relational database by writing a minimal amount of code in a set of
sub-classes which correspond to database tables.

Right now this module only implements a read only interface. Writes
will probably come later.

=head1 SYNOPSIS

  package Table;
  use base qw(Class::Entity);

  package main;
  use DBI;
  my $dbh = DBI->connect(...);
  my $table = Table->fetch(dbh => $dbh, key => 1234);
  print $table->Column;

  for (Table->find(dbh => $dbh, where => "Name like 'foo%'")) {
    printf "% %\n", $table->Name, $table->Date;
  }

=head1 METHODS

=over 4

=cut

use strict;
use warnings;

our $VERSION = "0.5";

package Class::Entity;
our $AUTOLOAD;

=item new(dbh => $dbh, data => $data)

The constructor creates a new instance of the current class. If you
pass in values via B<data> they will be stored in the object for
later use.

=cut

sub new {
  my ($class, %args) = @_;
  bless {
    _dbh  => $args{dbh} || undef,
    _data => $args{data} || undef
  }, $class || ref $class;
}

=item _primary_key()

Return the primary key for the table the current sub-class of
B<Class::Entity> represents. You will normally want to overide this
in the sub-class but for convenience it returns B<id> by default.

The value of this method is used to create the query that is run
when a call to B<fetch> is made.

=cut

sub _primary_key { "id" }

=item _table()

Return the name of the table the current sub-class of B<Class::Entity>
represents. You will normally want to overide this in the sub-class
but for convenience it returns the final part of the sub-class name;
that is: the sub-class name minus the leading /.*:/.

=cut

sub _table {
  my $self = shift;
  my ($table) = (ref($self)||$self) =~ /:?([^:]+)$/;
  $table;
}

=item _relation()

This method provides the sub-class author a means of joing accross
multiple tables when a call to B<fetch> or B<find> is made. All
database fields returned via these methods are stored in an instance
of the current sub-class and exposed via the autoloader. By default
it returns all fields in the current table represented by the
sub-class.

=cut

sub _relation {
  my $self = shift;
  sprintf "* from %s", $self->_table;
}

=item _object_map()

The object map works in conjuction with the autoloader. If you have
sub-classes of B<Class::Entity>, which represent tables linked to
in the current sub-class, you can overload this method to return a
hash where the keys are the table columns and the values are the
names of the associated B<Class::Entity> sub-classes.

The object map will only be used for method calls of the form
B<get_Value>.

Here's an example:

  package Users;
  use base qw(Class::Entity);

  package Departments;
  use base qw(Class::Entity);
  sub _object_map({
    UserID => "Users"
  })

  package main;
  use DBI;
  my $dbh DBI->connect(...);
  my @support = Departments->find(dbh => $dbh, where => "Name = 'Support'");
  for (@support) {
    printf "%s %s\n", $_->UserID, $_->get_UserID->name;
  }

=cut

sub _object_map { }

=item fetch(dbh => $dbh, key => $key)

Return an instance of the current sub-class. You must provide a
database value via B<dbh> and a primary key value via B<key>. The
database handle is stored in the returned object for later use and
all table fields are exposed via the auoloader.

=cut

sub fetch {
  my ($class, %args) = @_;
  my $dbh = $args{dbh} || die "no database handle";
  my $key = $args{key} || die "no key argument";
  my $query = sprintf "select %s where %s = $key",
    $class->_relation, $class->_primary_key;
  my $sth = $dbh->prepare($query) or return undef;
  $sth->execute or return undef;
  $class->new(dbh => $dbh, data => $sth->fetchrow_hashref);
}

=item find(dbh => $dbh, where => $where)

Return an array in array context, or the first item of the array
in scalar context, of instances of the current sub-class based on
the query modifier passed in via B<where>. You must pass in a
database handle via B<dbh> which will be stored in the returned
instances for later use.

=cut

sub find {
  my ($class, %args) = @_;
  my $dbh = $args{dbh} || die "no database handle";
  my $where = $args{where} || die "no where argument";
  my $query = sprintf "select %s where %s",
    $class->_relation, $where;
  my $sth = $dbh->prepare($query) or return undef;
  $sth->execute or return undef;
  wantarray or return # just the first row in scalar context
    $class->new(dbh => $dbh, data => $sth->fetchrow_hashref);
  my @rows;
  while (my $r = $sth->fetchrow_hashref) {
    push @rows, $class->new(dbh => $dbh, data => $r);
  }
  @rows;
}

=item AUTOLOAD([$value])

The autoloader provides get and set methods for the table values
represented in an instance of the current sub-class. For example,
if you have a table with the fields: Name, Date, Subject, you would
access them like this:

  package Table;
  use base qw(Class::Entity);

  package main;
  use DBI;
  my $dbh = DBI->connect(...);
  my $table = Table->fetch(dbh => $dbh, key => 10);
  print $table->Name . "\n";
  print $table->Date . "\n";
  print $table->Subject . "\n";

If you call an anonymous method of the form B<get_Value>, where
B<Value> is a column represented by the current object, the autoloader
will attempt to dispatch the call to the fetch method of the
corresponding sub-class of B<Class::Entity>, if it's listed in the
B<_bject_map>.

=cut

sub AUTOLOAD {
  my ($self, $arg) = @_;
  return if $AUTOLOAD =~ /DESTROY$/;
  (my $symbol = $AUTOLOAD) =~ s/.*://;
  if (my ($method) = $symbol =~ /get_(.*)/) {
    my %h = $self->_object_map;
    if (my $class = $h{$method}) {
      return $class->fetch(dbh => $self->{_dbh}, key => $self->$method);
    }
    warn sprintf qq(annonymous method "%s" cannot be mapped), $symbol;
    return undef;
  } elsif (exists $self->{_data}->{$symbol}) {
    $arg ? $self->{_data}->{$symbol} = $arg : $self->{_data}->{$symbol};
  } else {
    warn qq(annonymous method "$symbol" cannot be mapped);
    return undef;
  }
}

1;

=back

=head1 SEE ALSO

DBI

=head1 AUTHORS

Paddy Newman, <pnewman@cpan.com>

=head1 ACKNOWLEDGEMENTS

This is basically a cut-down, slightly modified version of something
an ex-colegue of mine wrote and introduced me to. His name is Dan
Barlow and he's a much better programmer than me and he deserves
all the credit.

=cut

