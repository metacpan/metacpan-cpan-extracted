package AddressBook;

=head1 NAME

AddressBook - Abstract class for using AddressBooks

=head1 SYNOPSIS

  use AddressBook;
  $a = AddressBook->new(source => "LDAP:localhost");
  $b = AddressBook->new(source => "DBI:CSV:f_dir=/tmp/data");
  $c = AddressBook->new(source => "PDB");

  $a->search(name => "hersh");
  $entry = $a->read;
  $b->add($entry);

  $entry = AddressBook::Entry->new(attr=>{name => "dleigh"});
  $c->write($entry);

  AddressBook::sync(master=>$a,slave=>$c);

=head1 DESCRIPTION

AddressBook provides a unified interface to access various databases
for keeping track of contacts.  Included with this module are several
backends:

  AddressBook::DB::LDAP
  AddressBook::DB::LDIF
  AddressBook::DB::DBI
  AddressBook::DB::PDB
  AddressBook::DB::Text
  AddressBook::DB::HTML

More will be added in the future.  

=cut

use strict;
use Carp;
use Date::Manip;
use AddressBook::Entry;
use AddressBook::Config;

use vars qw($VERSION @ISA);

$VERSION = '0.16';

=head2 new
	   
Create a new AddressBook object.

  AddressBook->new(source=$source,\%args)

See the appropriate backend documentation for constructor details.

=cut

sub new {
  my $class = shift;
  my $self;
  my %args = @_; 
  if ($args{config}) {
    $self->{config} = $args{config};
  } else {
    $self->{config} = AddressBook::Config->new(config_file=>$args{config_file});
  }
  if(defined $args{source}) {
    my ($type, $dsn) = split(':', $args{source}, 2);
    $dsn = '' unless $dsn; 
    delete $args{source};
    my (%bedb_args,$k,$v);
    foreach ($self->{config}->{db}->{$type}, \%args) {
      next if (ref($_) ne "HASH" || ! %{$_} );
      while (($k,$v) = each %{$_}) {
	$bedb_args{$k} = $v;
      }
    }
    my $driverName = $self->{config}->{db}->{$type}->{driver} || croak "Uknown driver type for source = \"$type\"";
    eval qq{
      require AddressBook::DB::$driverName;
      \$self = AddressBook::DB::$driverName->new(dsn => "$dsn",
						 config => \$self->{config},
						 \%bedb_args,
						 );
    };
    croak "Couldn't load backend `$driverName': $@" if $@;
    $self->{db_name}=$type;
  } else {
    bless ($self,$class);
  }
  return $self;
}

=head2 sync

  AddressBook::sync(master=>$master_db, slave=>$slave_db)
  AddressBook::sync(master=>$master_db, slave=>$slave_db,debug=>1)

Synchronizes the "master" and "slave" databases.  The "master" database type must be
one that supports random-access methods.  The "slave" database type must
be one that supports sequential-access methods.

When the 'debug' option is true, debug messages will be printed to stdout.  The 
msg_function paramater, if included, should be a subroutine reference which will
be called with a status message is the argument.

=over 4

=item 1

For each record in the slave, look for a corresponding record in the master, using
the key_fields of each.

=over 6

=item Z<>

If no match is found, the entry is added to the master.

=item Z<>

If multiple matches are found, an error occurrs.

=item Z<>

If one match is found, then:

=over 8

=item Z<>

If the records match, nothing is done.

=item Z<>

If the records do not match, then:

=over 10

=item Z<>

If the slave record's timestamp is newer, the master's entry is merged (see below) 
with the slave entry's data.

=item Z<>

If the master record's timestamp is newer, nothing is done.

=back

=back

=back

=item 2

The slave database is truncated.

=item 3

Each record of the master is added to the slave

=back

The 'merging' of the master and slave entries involves taking each attribute in the
slave's entry and replacing the corresponding attribute in the master's entry.  
Note that attributes that are deleted only on the slave are therefore effectively ignored 
during synchronization.

Similarly, deletions made on the slave database are effectively ignored during
synchronization.

=cut

sub sync {
  my %args = @_;
  my $master = $args{master};
  my $slave = $args{slave};
  unless ($master->{key_fields} && $slave->{key_fields}) {
    croak "Key fields must be defined for both master and slave backends";
  }
  $slave->reset;
  my ($entry,$filter,$key,$count,@non_keys, $slave_entry_attrs,
      %slave_keys,$master_entry,$flag,$master_tmp,$slave_tmp,$msg);
  foreach $key (split ',', $slave->{key_fields}) {
    $slave_keys{$key} = "";
  }
  foreach (grep {! exists $slave_keys{$_}} $slave->get_attribute_names) {
    push @non_keys, $_;
  }
  my (%seen, @master_only, @slave_only);
  @seen{$slave->get_cannonical_attribute_names} = ();
  foreach ($master->get_cannonical_attribute_names) {
    push (@master_only,$_) unless exists $seen{$_};
  }
  @seen{$master->get_cannonical_attribute_names} = ();
  foreach ($slave->get_cannonical_attribute_names) {
    push (@slave_only,$_) unless exists $seen{$_};
  }
  while ($entry = $slave->read) {
    $filter = AddressBook::Entry->new(config=>$slave->{config},
                                      attr=>$entry->{attr});
    $filter->delete(attrs=>\@non_keys,db=>$slave->{db_name});
    $count = $master->search(filter=>$filter->{attr});
    $msg = join "\n", $filter->dump;
    $msg .= "matched: $count\n";
    if ($args{debug}) {print $msg}
    if ($args{msg_function}) {&{$args{msg_function}}($msg)}
    if ($count == 1) {
      $master_entry = $master->read;
      $master_tmp = $master_entry;
      $master_tmp->delete(attrs=>\@master_only);
      $slave_tmp = $entry;
      $slave_tmp->delete(attrs=>\@slave_only);
      if (AddressBook::Entry::compare($slave_tmp,$master_tmp)) {
	$msg = "**entries match**\n";
	if ($args{debug}) {print $msg}
	if ($args{msg_function}) {&{$args{msg_function}}($msg)}
      } else {
	$msg = "slave entry timestamp: " . $entry->{timestamp} . "\n";
	$msg .= "master entry timestamp: " . $master_entry->{timestamp} . "\n";
	if ($args{debug}) {print $msg}
	if ($args{msg_function}) {&{$args{msg_function}}($msg)}
	$flag = Date_Cmp($entry->{timestamp},$master_entry->{timestamp});
	if ($flag < 0) {
	  $msg = "**master is newer**\n";
	  if ($args{debug}) {print $msg}
	  if ($args{msg_function}) {&{$args{msg_function}}($msg)}
	} else {
	  $msg = "**slave is newer - updating master**\n";
	  if ($args{debug}) {print $msg}
	  if ($args{msg_function}) {&{$args{msg_function}}($msg)}
	  $slave_entry_attrs = $entry->get(values_only=>1);
	  $master_entry->replace(attr=>$slave_entry_attrs);
	  $master->update(entry=>$master_entry,filter=>$filter->{attr}) || croak $master->code;
	}
      }
    } elsif ($count == 0) {
      $msg = "**Entry not found in master - adding**:\n".$entry->dump."\n";
      if ($args{debug}) {print $msg}
      if ($args{msg_function}) {&{$args{msg_function}}($msg)}
      $master->add($entry) || croak $master->code;;
    } else {croak "Error: entry matched multiple entries in master!\n"}
  }
  $msg = "Truncating slave\n";
  if ($args{debug}) {print $msg}
  if ($args{msg_function}) {&{$args{msg_function}}($msg)}
  $slave->truncate;
  $master->reset;
  $msg = "Adding master's records to slave\n";
  if ($args{debug}) {print $msg}
  if ($args{msg_function}) {&{$args{msg_function}}($msg)}
  while ($entry = $master->read) {
    $slave->write($entry);
  }
}

=head2 search

  $abook->search(attr=>\%filter);
  while ($entry=$abook->read) {
    print $entry->dump;
  }

\%filter is a list of cannonical attribute/value pairs. 

=cut

sub search {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";

  carp "Method not implemented."
}

=head2 read

  $entry=$abook->read;

Returns an AddressBook::Entry object

=cut

sub read {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";

  carp "Method not implemented"
}

=head2 update

  $abook->update(filter=>\%filter,entry=>$entry)

\%filter is a list of cannonical attriute/value pairs used to identify the entry to
be updated.

$entry is an AddressBook::Entry object

=cut

sub update {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";

  carp "Method not implemented"
}

=head2 add

  $abook->add($entry)

$entry is an AddressBook::Entry object

=cut

sub add {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";

  carp "Method not implemented"
}

=head2 delete

  $abook->delete($entry)

$entry is an AddressBook::Entry object

=cut

sub delete {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";

  carp "Method not implemented"
}

=head2 truncate

  $abook->truncate

Removes all records from the database.

=cut

sub truncate {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";

  carp "Method not implemented"
}

=head2 get_attribute_names 

  @names = $abook->get_attribute_names;

Returns a list of valid backend-specific attribute names

=cut

sub get_attribute_names {
  my $self=shift;
  my $class = ref $self || croak "Not a method call.";
  my %fields = %{$self->{config}->{db2generic}->{$self->{db_name}}};
  my @names = sort {$self->{config}->getMeta(attr=>$fields{$a})->{order} <=> $self->{config}->getMeta(attr=>$fields{$b})->{order}} keys %fields;
  return @names;
}

1;

=head2 get_cannonical_attribute_names 

  @names = $abook->get_cannonical_attribute_names;

Returns a list of valid cannonical attribute names

=cut

sub get_cannonical_attribute_names {
  my $self=shift;
  my $class = ref $self || croak "Not a method call.";
  my @fields = $self->get_attribute_names;
  my @names = map {$self->{config}->{db2generic}->{$self->{db_name}}->{$_}} @fields;
  return @names;
}

1;
__END__

=head1 AUTHOR

Mark A. Hershberger, <mah@everybody.org>
David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

  The perl-abook home page at http://perl-abook.sourceforge.net

L<AddressBook::Config>
L<AddressBook::Entry>
    
L<AddressBook::DB::LDAP>
L<AddressBook::DB::LDIF>
L<AddressBook::DB::DBI>
L<AddressBook::DB::PDB>
L<AddressBook::DB::Text>
L<AddressBook::DB::HTML>

=cut
