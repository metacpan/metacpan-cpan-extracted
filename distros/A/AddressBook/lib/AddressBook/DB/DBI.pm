package AddressBook::DB::DBI;

=head1 NAME

AddressBook::DB::DBI - Backend for AddressBook to use in databases

=head1 SYNOPSIS

  use AddressBook;
  $a = AddressBook->new(source => "DBI:CSV:f_dir=/tmp/csv",
			table=>"a_csv",
			);

=head1 DESCRIPTION

The DBI perl library module is required in order to use this package.

AddressBook::DB::DBI supports both sequential and random access backend database 
methods.

The DBI backend has so far only been tested against the CSV database driver.

AddressBook::DB::DBI behavior can be modified using the following options:

=over 4

=item table

Required parameter

=item key_fields

A list of DBI field names (not cannonical names) which can be used to uniquely
identify a database record.

=item dsn

See constructor details below

=back

=cut

use strict;
use DBI;
use AddressBook;
use AddressBook::Entry;
use Carp;
use File::Basename;
use Date::Manip;
use vars qw($VERSION @ISA);

$VERSION = '0.13';

@ISA = qw(AddressBook);

=head2 new

The database driver and driver arguments may be specified in in the constructor
in one of two ways: 

=over 4

=item 1

As part of the "source" parameter, for example:

  $a = AddressBook->new(source => "DBI:CSV:f_dir=/tmp/csv",
			table=>"a_csv",
			);

=item 2

In a "dsn" parameter, for example:

  $a = AddressBook->new(source => "DBI",
			dsn=>"CSV:f_dir=/tmp/csv",
			table=>"a_csv",
			);

Like all AddressBook database constructor parameters, the "dsn" and "table" may 
also be specified in the configuration file.

=back

=cut

sub new {
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  my %args = @_;
  foreach (keys %args) {
    $self->{$_} = $args{$_};
  }
  if(defined $self->{dsn}) {
    ($self->{dbi_driver},$self->{dsn}) = split (':',$self->{dsn});
    my $dbh = DBI->connect("dbi:" . $self->{dbi_driver} . ":" . $self->{dsn}) 
	|| croak $self->{dbh}->errstr;
    $self->{dbh} = $dbh;
  }
  if (! defined $self->{intra_attr_sep_char}) {
    $self->{intra_attr_sep_char} = ';';
  }
  $self->_verify_table;
  return $self;
}

sub _verify_table {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  if ($self->{dbi_driver} eq "CSV") {
    my @tables = $self->{dbh}->func('list_tables');
    my $found = 0;
    foreach (@tables) {
      if ($_ eq $self->{table}) {
	$found=1;
	last;
      }
    }
    if (! $found) {croak "table \"$self->{table}\" does not exist"}
  } else {
    croak "Cannot verify table";
  }
}

sub DESTROY {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";

  $self->{dbh}->disconnect;
}

sub search {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my @ret;
  my %arg = @_;
  my ($filter,@filter,$count);
  my $op = "select * from " . $self->{table};
  if(defined $arg{filter}) {
    my $entry = AddressBook::Entry->new(attr=>{%{$arg{filter}}},
					config => $self->{config},
					);
    $entry = $entry->get(db=>$self->{db_name},values_only=>'1');
    foreach (keys %{$entry}) {
      push @filter,"$_ = ".$self->{dbh}->quote(join ($self->{intra_attr_sep_char},@{$entry->{$_}}));
    }
    $filter = join " AND ",@filter;
    $op .= " where $filter";
  }
  my $result = $self->{dbh}->selectall_arrayref($op) || croak $self->{dbh}->errstr;
  $count = $#{$result} + 1;
  $self->{so} = $self->{dbh}->prepare($op) || croak $self->{dbh}->errstr;
  $self->{so}->execute;
  return $count;
}

sub read {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  if (! defined ($self->{so})) {
    $self->reset;
  }
  if(defined ($_ = $self->{so}->fetchrow_hashref)) {
    my $entry = AddressBook::Entry->new(db => $self->{db_name},
					attr=>{%$_},
					config=>$self->{config});
    $entry->{timestamp} = $self->_get_timestamp;
    return $entry;
  }
  return undef;
}

sub _get_timestamp {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  if ($self->{dbi_driver} =~ /^CSV/) {
    my @stat = stat($self->{dbh}->{f_dir} . "/" . $self->{table});
    return ParseDateString("epoch $stat[9]");
  } else {
    croak "Error: Don't know how to determine timestamp for this database type";
  }
}

sub reset {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  $self->search;
}

sub update {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  my %args = @_;
  my $count = $self->search(filter=>$args{filter},strict=>1);
  if ($count == 0){
    croak "Update Error: filter did not match any entries";
  } elsif ($count > 1) {
    croak "Update Error: filter matched multiple entries";
  }
  my $filter_entry = AddressBook::Entry->new(attr=>{%{$args{filter}}},
					     config => $self->{config},
					     );
  my $filter_attrs = $filter_entry->get(db=>$self->{db_name},values_only=>'1');
  my @filter;
  foreach (keys %{$filter_attrs}) {
    push @filter,"$_ = ".$self->{dbh}->quote(join ($self->{intra_attr_sep_char},@{$filter_attrs->{$_}}));
  }
  my $filter = join " AND ",@filter;
  my $entry = $args{entry};
  $entry->calculate;
  my $attr = $entry->get(db=>$self->{db_name},values_only=>'1');
  my @updates;
  foreach (keys %{$attr}) {
    push @updates,"$_ = ".$self->{dbh}->quote(join ($self->{intra_attr_sep_char},@{$attr->{$_}}));
  }
  $self->{dbh}->do(
		 "update " . $self->{table} . " set "  
		 . join (",",@updates) 
		 . " where $filter"
		 ) || croak $self->{dbh}->errstr;
}

sub add {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  my ($entry) = @_;
  my ($attr);
  $entry->calculate;
  $attr = $entry->get(db=>$self->{db_name},values_only=>'1');
  foreach (keys %{$attr}) {
    $attr->{$_} = join $self->{intra_attr_sep_char},@{$attr->{$_}};
    $attr->{$_} = $self->{dbh}->quote($attr->{$_});
  }
  $self->{dbh}->do(
		 "insert into " . $self->{table} . " (" 
		 . join (",",keys (%{$attr})) . ") values " 
		 . "(" . join (",",values (%{$attr})) . ")") 
      || croak $self->{dbh}->errstr;
}

sub write {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  return $self->add(@_);
}

sub delete {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  carp "Method not implemented."
}

sub truncate {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  $self->{dbh}->do("delete from " . $self->{table}) || croak $self->{dbh}->errstr;
}

1;
__END__

=head2 Timestamps

For syncronization purposes, all records are timestamped depending on the database
driver type:

=over 4

=item CSV

All records are timestamped with the modification data of the CSV file.

=back

=head1 AUTHOR

Mark A. Hershberger, <mah@everybody.org>
David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>
L<AddressBook::Config>,
L<AddressBook::Entry>.

DBI
DBD::CSV

=cut
