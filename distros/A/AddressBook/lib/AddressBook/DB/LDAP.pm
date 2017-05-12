package AddressBook::DB::LDAP;

=head1 NAME

AddressBook::DB::LDAP - Backend for AddressBook to use LDAP.

=head1 SYNOPSIS

  use AddressBook;
  $a = AddressBook->new(source => "LDAP:hostname/ou=People,dc=example,dc=com",
                        username => "user", password => "pass");
  $a->add($entry) || die $a->code;

=head1 DESCRIPTION

The Net::LDAP library module is required in order to use this package.

AddressBook::DB::LDAP supports random access backend database methods.

Behavior can be modified using the following options:

=over 4

=item key_fields

A list of LDAP attribute names (not cannonical names) which can be used to
uniquely identify an entry.

=item hostname

The LDAP host to which to connect.

=item base

The base for LDAP queries.

=item objectclass

The objectclass for AddressBook entries.

=item username

An LDAP dn to use for accessing the server.

=item password

=item dn_calculate

A perl expression which, when eval'd returns a valid LDAP "dn" 
(omitting the "base" part of the dn).  Other attributes may be referenced as "$<attr>".  

For example, if LDAP entries have a dn like: "cn=John Doe,mail=jdoe@mail.com", then use
the following:

  dn_calculate="'cn=' . $cn . ',mail=' . $mail"

=back

Any of these options may be specified in the constructor, or in the configuration file.

=cut

use strict;
use Net::LDAP;
use Net::LDAP::Util qw(ldap_error_text);
use AddressBook;
use Date::Manip;
use Carp;
use vars qw(@ISA $VERSION);

$VERSION = '0.13';

@ISA = qw(AddressBook);

=head2 new

  $a = AddressBook->new(source => "LDAP");
  $a = AddressBook->new(source => "LDAP:localhost/ou=People,dc=example,dc=com");
  $a = AddressBook->new(source => "LDAP",
			hostname=>"localhost",
			base=>"o=test"
			);

Any or all options may be specified in the constructor, or in the configuration file.

=cut

sub new {
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  my %args = @_;
  foreach (keys %args) {
    $self->{$_} = $args{$_};
  }
  my ($hostname,$base,$mesg);
  if ($self->{dsn}) {
    ($hostname,$base) = split "/", $self->{dsn};
  }
  $self->{hostname} = $hostname || $self->{hostname};
  $self->{base} = $base || $self->{base};
  $self->{ldap} = Net::LDAP->new($self->{hostname}, async => 1 || croak $@);
  unless ($self->{anonymous}) {
    $mesg = $self->{ldap}->bind($self->{username}, password => $self->{password});
  } else {
    $mesg = $self->{ldap}->bind;
  }
  if ($mesg->is_error) {
    croak "could not bind to LDAP server: " . $mesg->error;
  }
  return $self;
}

sub search {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  my @ret;
  my %arg = @_;
  my $max_size = $arg{entries} || 0;
  my $max_time = $arg{time} || 0;
  my $fuzzy = $arg{fuzzy} || 0;
  if (exists $arg{strict}) {
    warn "The 'strict' parameter to LDAP backend searches has been removed";
  } 
  delete $arg{entries};
  delete $arg{time};

  if(defined $arg{filter}) {
    # We have stuff to look for;
    if (ref($arg{filter}) ne "ARRAY") {$arg{filter} = [$arg{filter}]}
    my $evalstring = "=";
    my ($entry,$filter,$filter_element,$subfilter,$value);
    foreach $filter_element (@{$arg{filter}}) {
      $entry = AddressBook::Entry->new(attr=>$filter_element,
				       config => $self->{config},
				       );
      #$entry->calculate;
      $entry = $entry->get(db=>$self->{db_name},values_only=>'1');
      $subfilter="";
      foreach (keys %{$entry}) { 
	$value = $entry->{$_}->[0];
	$value =~ s/\(/\\(/g;
	$value =~ s/\)/\\)/g;
        if ($fuzzy) {
	  $value = "*" . $value . "*";
	}
	$subfilter .= "(" . $_ . $evalstring . $value . ")";
      }
      $filter .= "(& $subfilter)";
    }
    $filter = "(| $filter)";
    $self->{so} = $self->{ldap}->search(base => $self->{base} || '',
				      async => 1,
				      sizelimit => $max_size,
				      timelimit => $max_time,
				      filter => "(&(objectclass=" .
				      $self->{objectclass} .')' .
				      $filter . ')');
    if ($self->{so}->code) {
      $self->{code} = ldap_error_text($self->{so}->code); 
      return 0;
    }
  } else {
    # We need to return everything;
    $self->{so} = $self->{ldap}->search(base => $self->{base} || '',
				      async => 1,
				      filter => "objectclass=" . $self->{objectclass});
    if ($self->{so}->code) {
      $self->{code} = ldap_error_text($self->{so}->code) ;
      return 0;
    }
  }
  undef $self->{code};
  return $self->{so}->count;
}

sub read {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  if (! defined $self->{so}) {
    $self->reset;  
  } 
  if (defined (my $entry = $self->{so}->shift_entry)) {
    my $attr;
    my $ret = AddressBook::Entry->new(config=>$self->{config});
    foreach $attr ($entry->attributes) {
      if (exists $self->{config}->{db2generic}->{$self->{db_name}}->{$attr}) {
	$ret->add(db=>$self->{db_name},attr=>{$attr=>[$entry->get_value($attr)]});
      }
    }
    $ret->{timestamp} = _get_timestamp($entry);
    undef $self->{code};
    return $ret;
  } else {
    $self->{code} = ldap_error_text($self->{so}->code) ;
    return undef;
  }
}

sub _get_timestamp {
  my $entry=shift;
  my $timestamp;
  if ($entry->exists("modifytimestamp")) {
    ($timestamp) = $entry->get_value("modifytimestamp");
  } elsif ($entry->exists("createtimestamp")) {
    ($timestamp) =  $entry->get_value("createtimestamp");
  } else {
    $timestamp="today";
  }
  return ParseDate($timestamp);
}

sub reset {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  $self->search;
}

sub update {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my %args = @_;
  my $count = $self->search(filter=>$args{filter});
  if ($count == 0){
    $self->{code} = "Update Error: filter did not match any entries";
    return 0;
  } elsif ($count > 1) {
    $self->{code} = "Update Error: filter matched multiple entries";
    return 0;
  }
  my $entry = $args{entry};
  $entry->calculate;
  my $old_entry=$self->read;
  my $rdn = $self->_rdn_from_entry($entry);
  my $old_rdn = $self->_rdn_from_entry($old_entry);
  my $result;
  if ($rdn ne $old_rdn) {
    $result=$self->{ldap}->moddn("$old_rdn," . $self->{base},deleteoldrdn=>1,newrdn=>$rdn);
    if ($result->code) {
      $self->{code} =  ldap_error_text($result->code) ;
      return 0;
    }
  }
  my %attr = %{$entry->get(db=>$self->{db_name},values_only=>'1')};
  $result=$self->{ldap}->modify("$rdn," . $self->{base},replace=>[%attr]);
  if ($result->code) {
    $self->{code} =  ldap_error_text($result->code) ;
    return 0;
  }
  undef $self->{code};
  return 1;
}

sub add {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $entry = shift;
  $entry->calculate;
  my $dn = $self->_rdn_from_entry($entry) . "," . $self->{base};
  my %attr = %{$entry->get(db=>$self->{db_name},values_only=>'1')};
  $attr{objectclass} = [$self->{objectclass}];
  my $result = $self->{ldap}->add($dn, attrs => [%attr]);
  if ($result->code) {
    $self->{code} =  ldap_error_text($result->code) ;
    return 0;
  }
  undef $self->{code};
  return 1;
}

sub write {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  return $self->add(@_);
}

sub delete {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  my $entry=shift;
  $entry->calculate;
  my $dn = $self->_rdn_from_entry($entry) . "," . $self->{base};
  my $result = $self->{ldap}->delete($dn);
  if ($result->code) {
    $self->{code} = ldap_error_text($result->code) ;
    return 0;
  }
  undef $self->{code};
  return 1;
}

sub code {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  return $self->{code};
}

sub _rdn_from_entry {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $entry = shift || croak "Need an entry";
  my ($dn,$dn_calculate);
  my %attr = %{$entry->get(db=>$self->{db_name},values_only=>'1')};
  ($dn_calculate=$self->{dn_calculate}) =~ s/\$(\w*)/\$attr{$1}->[0]/g;
  eval qq{\$dn = $dn_calculate}; warn "Syntax error in dn_calculate: $@" if $@;
  return $dn;
}

1;
__END__

=head2 Timestamps

For syncronization purposes, all records are timestamped using the "modifytimestamp"
LDAP attribute.  If the record has no "modifytimestamp", "createtimestamp" is used.
If there is no "createtimestamp", the current time is used.

=head1 AUTHOR

Mark A. Hershberger, <mah@everybody.org>
David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>,
L<AddressBook::Config>,
L<AddressBook::Entry>.

Net::LDAP

=cut
