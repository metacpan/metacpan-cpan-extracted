package DBIx::Foo;

use strict;

use DBI;
use DBIx::Foo::SearchQuery;
use DBIx::Foo::SimpleQuery;
use DBIx::Foo::UpdateQuery;

use Log::Any qw($log);

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(selectrow selectrow_array selectrow_hashref selectall selectall_arrayref selectall_hashref dbh_do do err last_insert_id);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $VERSION = '0.03';

sub new {
    my ($class) = shift;
    $class->connect(@_);
}

sub connect {
    my ($class, @arguments) = @_;

	my $self = {};

    if (defined $arguments[0] and UNIVERSAL::isa($arguments[0], 'DBI::db')) {
        $self->{dont_disconnect} = 1;
		$self->{dbh} = shift @arguments;
		Carp::carp("Additional arguments for $class->connect are ignored") if @arguments;
    } else {
		$arguments[3]->{PrintError} = 0
	    unless defined $arguments[3] and exists $arguments[3]{PrintError};
        $arguments[3]->{RaiseError} = 1
            unless defined $arguments[3] and exists $arguments[3]{RaiseError};
		$self->{dbh} = DBI->connect(@arguments);
    }

    return undef unless $self->{dbh};

    $self->{dbd} = $self->{dbh}->{Driver}->{Name};
    bless $self, $class;

    return $self;
}

sub disconnect {
	my $self = shift;
	$self->{dbh}->disconnect();
}

sub dbh {
	my $self = shift;
	return $self->{dbh};
}

sub do {
	return shift->dbh_do(@_); # just an alias
}

sub err {
	my $self = shift;
	return $self->{dbh}->err;
}

sub last_insert_id {
	my ($self, @args) = @_;
	return $self->{dbh}->last_insert_id(@args);
}

sub update_query {
	my ($self, $table) = @_;
	return DBIx::Foo::UpdateQuery->new($table, $self);
}

1;

__END__

=head1 NAME

DBIx::Foo - Simple Database Wrapper and Helper Functions.  Easy DB integration without the need for an ORM.

=head1 SYNOPSIS

=head2 DBIx::Foo::SimpleQuery

  my $dbh = DBIx::Foo->connect(...) # or ->new

  my $rows = $dbh->selectall("select * from test");

  my $row = $dbh->selectrow("select * from test where ID = ?", 1); # alias for selectrow_hashref

=head2 DBIx::Foo::UpdateQuery

This can be used to build a query for writing to the database.  First an insert statement:

  my $query = $dbh->update_query('test');

  $query->addField(Name => 'Foo');
  $query->addField(Desc => 'Bar');

  my $newid = $query->DoInsert;

And with very similar syntax, an update statement:

  my $query = $dbh->update_query('test');

  $query->addKey(ID => $newid);
  $query->addField(Name => 'Fu');
  $query->addField(Desc => 'Baz');

  $query->DoUpdate;

This works nicely with data in a hash, which can be interated and used to update or insert as appropriate, based the existence of a key field:

  my $data = {
   	Name => 'Foo',
   	Desc => 'Bar',
  };

  foreach my $field (key %$data) {

   	$query->addField($field => $data->{$field}) if $data->{$field};
  }

  if (my $id = $data->{ID}) {

    # updating
   	$query->addKey(ID => $id);

   	$query->DoUpdate;
  }
  else {

    # inserting
    my $newid = $query->DoInsert;
  }

=cut
