package AddressBook::Entry;

=head1 NAME

AddressBook::Entry - An entry in the AddressBook

=head1 SYNOPSIS

An AddressBook::Entry object contains an addressbook entry's attributes, 
attribute metadata, and information about how to translate the attributes between 
different backend databases.  An Entry's attributes can be accessed  using
either cannonical attribute names, or database-specific names.

=head1 DESCRIPTION

The following examples assume  a configuration file which maps the cannonical 
attribute named "lastname" to the ldap attribute named "sn" and the cannonical 
attribute named "firstname" to the ldap attribute named "givenname".  For example,

  <field name="lastname">        
    <db type="LDAP" name="sn">
  </field>
  <field name="firstname">
    <db type="LDAP" name="givenname">
  </field>

Each of the following pairs of commands will give the same result:
  
  $entry=AddressBook::Entry->new(attr=> {
                                   lastname=>Doe,
                                   firstname => John
                                        });
  $entry=AddressBook::Entry->new(db=>LDAP,
				 attr=>{
                                   sn=>Doe,
                                   givenname => John
                                        });

  $entry->add(attr=>{lastname=>Doe,firstname=>John})
  $entry->add(attr=>{sn=Doe,givenname=John},db=>LDAP)

  $entry->replace(attr=>{firstname=>Jane})
  $entry->replace(attr=>{givenname=>Jane},db=>LDAP)

  $entry->delete(attrs=>[firstname,lastname])
  $entry->delete(attrs=>[givenname,sn],db=>LDAP)

Reading and writing an entry from a backend database:

  $db = AddressBook->new(source=>LDAP);
  $entry = $db->read;
  $db->write($entry);

Generating values in calculated fields:
  
  $entry->calculate;

Comparing entries:

  AddressBook::Entry::Compare($entry1,$entry2);

Dumping an entry:

  $entry->dump;

Note: Each attribute contains a reference to an array of values.

=cut

use strict;
use Carp;

use vars qw($VERSION);

$VERSION = '0.12';

=head2 new

    $entry=AddressBook->new();
    $entry=AddressBook::Entry->new(attr=>\%attr);
    $entry=AddressBook::Entry->new(attr=>\%attr,db=>$db)

Create and optionally load an entry object.
  
All of the following parameters are optional:

=over 4

=item %attr

An optional hash containing the attributes to add to the entry.  The attribute 
values may be scalars or array references.

=item $config

An AddressBook::Config reference.  If supplied, this configuration will be used
and any  $config_file paramater is ignored.

=item $config_file

The configuration file to use instead of the default (/etc/AddressBook.conf).

=item $db

Can be used to specify that the keys of %attr are those for a specific backend.

=back

=cut

sub new {
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  my %args = @_;
  if ($args{config}) {
    $self->{config} = $args{config};
  } else {
    $self->{config} = AddressBook::Config->new(config_file=>$args{config_file});
  }
  if ($args{attr}) {
    $self->add(attr=>$args{attr},db=>$args{db});
  }
  return $self;
}

=head2 add

    $entry->add(attr=>\%attr);
    $entry->add(attr=>\%attr,db=>$db);

Adds attributes to the entry object.  New data is added to attributes which already 
exist

=over 4

=item %attr

Required hash containing the attributes to add to the entry.  The attribute values
may be specified as scalars or array references.

=item $db

Can be used to specify that the keys of %attr are those for a specific backend.

=back

=cut

sub add {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my (%args) = @_;
  my $attr=$args{attr};
  foreach (keys %{$attr}) {
    if (ref $attr->{$_} ne "ARRAY") {
      $attr->{$_} = [$attr->{$_}];
    }
    next unless (@{$attr->{$_}});
    if (defined $args{db}) {
      if (defined $self->{config}->{db2generic}->{$args{db}}->{$_}) {
	push @{$self->{attr}->{$self->{config}->{db2generic}->{$args{db}}->{$_}}}, @{$attr->{$_}};
      } else {
	croak "Error:  \"$_\" is not a defined attribute for $args{db}";
      }
    } else {
      if (defined $self->{config}->{meta}->{$_}) {
	push @{$self->{attr}->{$_}}, @{$attr->{$_}}
      } else {
	croak "Error: \"$_\" is not a defined attribute";
      }
    }
  }
}

=head2 replace

    $entry->replace(attr=>\%attr);
    $entry->replace(attr=>\%attr,db=>$db);

Adds attributes to the entry object.  New data is added to attributes which already 
exist

=over 4

=item %attr

Required hash containing the attributes to add to the entry.  The attribute values
may be specified as scalars or array references.

=item $db

Can be used to specify that the keys of %attr are those for a specific backend.

=back

=cut

sub replace {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my (%args) = @_;
  my $attr=$args{attr};
  foreach (keys %{$attr}) {
    if (ref $attr->{$_} ne "ARRAY") {
      $attr->{$_} = [$attr->{$_}];
    }
    next unless (@{$attr->{$_}});
    if (defined $args{db}) {
      $self->{attr}->{$self->{config}->{db2generic}->{$args{db}}->{$_}} = 
		  $attr->{$_} 
	  if defined $self->{config}->{db2generic}->{$args{db}}->{$_};
    } else {
      $self->{attr}->{$_} = $attr->{$_} 
	  if defined $self->{config}->{meta}->{$_};
    }
  }
}

=head2 delete

  $entry->delete(attrs=>\@attrs)
  $entry->delete(attrs=>\@attrs,db=>$db)

Remove attributes from the Entry.

=over 4

=item @attrs

Required array containing the attributes to delete from the entry.

=item $db

Can be used to specify that the keys of %attr are those for a specific backend.

=back

=cut

sub delete {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  my (%args) = @_;
  my $attr = $self->{attr};
  foreach (@{$args{attrs}}) {
    if (defined $args{db}) {
      delete $attr->{$self->{config}->{db2generic}->{$args{db}}->{$_}};
    } else {
      delete $attr->{$_};
    }
  }
  $self->{attr} = $attr;
}

=head2 get

    $attr_ref = $entry->get();
    $attr_ref = $entry->get(db=>$db);
    $attr_ref = $entry->get(db=>$db,values_only=>1);

Get attributes from the Entry.  Returns a hash with cannonical attribute names as keys.

=over 4

=item $values_only

Unless "values_only" is specified, each value in the result is a hash with a "value"
key pointing to the attribute value array, and a "meta" key pointing to the 
attribute metadata hash.  If "values_only" is specified, each value in the result
points to the attribute value array.

=item $db

Can be used to specify that the keys of %attr are those for a specific backend.

=back

=cut

sub get {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my %args = @_;
  my ($ret,$key,$meta);
  $ret={};
  foreach (keys %{$self->{attr}}) {
    if ($args{db}) {
      next unless (defined $self->{config}->{generic2db}->{$_}->{$args{db}});
      $key=$self->{config}->{generic2db}->{$_}->{$args{db}};
    } else {
      $key=$_;
    }
    if ($args{values_only}) {
      $ret->{$key}=$self->{attr}->{$_};
    } else {
      $ret->{$key}->{value}=$self->{attr}->{$_};
      %{$ret->{$key}->{meta}} = %{$self->{config}->getMeta(attr=>$_,db=>$args{db})};
    }
  }
  return $ret->{$args{attr}} if defined $args{attr};
  return $ret;
}

=head2 calculate

    $entry->calculate

Computes all calculated attributes.  Does so in the order specified
by the calc_order attribute metadata value.

=cut

sub calculate {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my ($calculate,$result,$attr,$i);
  foreach (sort {$self->{config}->{meta}->{$a}->{calc_order} <=> 
		     $self->{config}->{meta}->{$b}->{calc_order}}
	   grep {defined $self->{config}->{meta}->{$_}->{calculate}} 
	   keys %{$self->{config}->{meta}}) {
    $calculate=$self->{config}->{meta}->{$_}->{calculate};
    foreach $attr (keys %{$self->{config}->{generic2db}}) {
      $calculate =~ s/\$$attr/\$self->{attr}->{$attr}/g;
    }
    eval qq{(\$result) = $calculate}; croak "Error in attribute calculation for \"$_\": $@" if $@;
    if (! ref $result) {
      $self->{attr}->{$_}->[0] = $result;
    } elsif (ref $result eq "ARRAY") {
      @{$self->{attr}->{$_}} = @{$result};
    } else {
      croak "Error in attribute calculation for \"$_\": result must be a scalar or arrayref\n";
    }
  }
  foreach (keys %{$self->{attr}}) {
    delete $self->{attr}->{$_} unless (defined $self->{attr}->{$_}->[0]);
  }
}

=head2 compare

  AddressBook::Entry::compare($entry1,$entry2)

Returns true if all attributes in both entries match, false otherwise.

=cut

sub compare {
  my ($entry1,$entry2) = @_;
  _compare_oneway($entry1,$entry2) || return undef;
  _compare_oneway($entry2,$entry1) || return undef;
  return 1;
}

sub _compare_oneway {
  my ($entry1,$entry2) = @_;
  my ($key,$i);
  foreach $key (keys %{$entry1->{attr}}) {
    if (defined $entry2->{attr}->{$key}) {
      for ($i=0;$i<=$#{$entry1->{attr}->{$key}};$i++) {
	if ($entry1->{attr}->{$key}->[$i] ne $entry2->{attr}->{$key}->[$i]) {
	  return undef;
	}
      }
      return undef if ($#{$entry1->{attr}->{$key}} != $#{$entry2->{attr}->{$key}});
    } else {
      return undef;
    }
  }
  return 1;
}

=head2 fill

  $entry->fill(db=>$db);
  $entry->fill(db=>$db,defaults=>1);

Ensures that the Entry includes all attributes for a specific backend database.
New attributes are added with null values.  If the "defaults" parameter is specified,
new attributes are added with values as specified by the attribute "default" metadata
specified in the config file.

=cut

sub fill {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my %args = @_;
  unless ($args{db}) {croak "database type not specified in AddressBook::Entry::fill"}
  my (%add_hash,$value,$meta);
  foreach (values %{$self->{config}->{db2generic}->{$args{db}}}) {
    unless (exists $self->{attr}->{$_}) {
      if ($args{defaults}) {
	$meta = $self->{config}->getMeta(attr=>$_,db=>$args{db});
	$value = $meta->{default} || '';
      } else {
	$value = "";
      }
      $add_hash{$_} = $value;
    }
  }
  $self->add(attr=>\%add_hash);
}

=head2 chop

  $entry->chop

Removes null valued attributes from an Entry.

=cut

sub chop {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my (@delete_list,@list,$key,$found,$i);
  foreach $key (keys %{$self->{attr}}) {
    $found = 0;
    @list=();
    for ($i=0;$i<=$#{$self->{attr}->{$key}};$i++) {
      if ($self->{attr}->{$key}->[$i] ne "") {
	$found=1;
	push @list,$self->{attr}->{$key}->[$i];
      }
    }
    @{$self->{attr}->{$key}} = @list;
    if (! $found) {
      push @delete_list, $key;
    }
  }
  $self->delete(attrs=>\@delete_list);
}

=head2 dump

    print $entry->dump

Returns the (cannonical) attribute names and values.  Primarily used for 
debugging purposes.

=cut

sub dump {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  return map {"$_ -> ". join(", ", @{$self->{attr}->{$_}}). "\n"}
    keys %{$self->{attr}}
}
1;
__END__

=head1 AUTHOR

Mark A. Hershberger, <mah@everybody.org>
David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>
L<AddressBook::Config>

=cut
