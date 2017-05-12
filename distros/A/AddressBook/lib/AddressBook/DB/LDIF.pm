package AddressBook::DB::LDIF;

=head1 NAME

AddressBook::DB::LDIF - Backend for AddressBook to use LDIF files.

=head1 SYNOPSIS

  use AddressBook;
  $a = AddressBook->new(source => "LDIF",
			filename => "/tmp/ldif")

=head1 DESCRIPTION

AddressBook::DB::LDIF supports sequential backend database methods.

AddressBook::DB::LDIF behavior can be modified using the following options:

=over 4

=item key_fields

A list of LDIF attribute names (not cannonical names) which can be used to
uniquely identify an entry.

=item base

The LDAP base for all entries

=item objectclass

The LDAP objectclass for entries

=item dn_calculate

A perl expression which, when eval'd returns a valid LDAP "dn" 
(omitting the "base" part of the dn).  Other attributes may be referenced as "$<attr>".  

For example, if LDIF entries have a dn like: "cn=John Doe,mail=jdoe@mail.com", then use
the following:

  dn_calculate="'cn=' . $cn . ',mail=' . $mail"

=back

Any of these options can be specified in the constructor, or in the configuration file.

=cut

use strict;
use AddressBook;
use Carp;
use Net::LDAP::LDIF;
use Net::LDAP::Entry;
use IO::File;
use Date::Manip;

use vars qw($VERSION @ISA);

$VERSION = '0.13';

@ISA = qw(AddressBook);

=head2 new

The LDIF file is specified using the "filename" parameter:

  $a = AddressBook->new(source => "LDIF",
			filename => "/tmp/ldif")

The filename may also be specified in the configuration file.

=cut

sub new {
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  my %args = @_;
  foreach (keys %args) {
    $self->{$_} = $args{$_};
  }
  $self->{mode} = "";
  if (defined $self->{filename}) {
    $self->{fh} = IO::File->new($self->{filename},O_RDWR | O_CREAT)
	|| croak "Couldn't open `" . $self->{filename} . "': $@";
    $self->{ldif} = Net::LDAP::LDIF->new($self->{fh});
  }
  return $self;
}

sub DESTROY {$_[0]->fh->close}

sub reset {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  $self->{fh}->seek(0,0);
  $self->{mode} = "";
}

sub truncate {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  $self->{fh}->truncate(0);
}

sub read {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  if ($self->{mode} eq "w") {
    croak "Error:  After writing, do a reset before reading";
  }
  $self->{mode} = "r";
  if (my $ldap_entry = $self->{ldif}->read) {
    my $ret = AddressBook::Entry->new(config=>$self->{config});
    foreach ($ldap_entry->attributes) {
      if (exists $self->{config}->{db2generic}->{$self->{db_name}}->{$_}) {
	$ret->add(db=>$self->{db_name},attr=>{$_=>[$ldap_entry->get_value($_)]});
      }
    }
    $ret->{timestamp} = $self->_get_timestamp;
    return $ret;
  } else {
    return undef;
  }
}

sub write {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  $self->{fh}->seek(0,2); # jump to the end of the file
  $self->{mode} = "w";
  my $entry = shift;
  $entry->calculate;
  my $dn = $self->_dn_from_entry($entry);
  my %attr = %{$entry->get(db=>$self->{db_name},values_only=>'1')};
  $attr{objectclass} = [$self->{objectclass}];
  my $ldap_entry = Net::LDAP::Entry->new();
  $ldap_entry->dn($dn);
  $ldap_entry->add(%attr);
  $self->{ldif}->write($ldap_entry);
}

sub _dn_from_entry {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $entry = shift || croak "Need an entry";
  my ($dn,$dn_calculate);
  my %attr = %{$entry->get(db=>$self->{db_name},values_only=>'1')};
  ($dn_calculate=$self->{dn_calculate}) =~ s/\$(\w*)/\$attr{$1}->[0]/g;
  eval qq{\$dn = $dn_calculate}; warn "Syntax error in dn_calculate: $@" if $@;
  $dn .= "," . $self->{base};
  return $dn;
}

sub _get_timestamp {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my @stat = stat($self->{filename});
  return ParseDateString("epoch $stat[9]");
}

1;

=head2 Timestamps

For syncronization purposes, all records are timestamped with the modification date
of the LDIF file.

=head1 AUTHOR

David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>,
L<AddressBook::Config>,
L<AddressBook::Entry>.

Net::LDAP

=cut
