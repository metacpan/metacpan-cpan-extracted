package AddressBook::Config;

=head1 NAME

AddressBook::Config - AddressBook configuration object

=head1 SYNOPSIS

The AddressBook::Config object contains the list of cannonical attribute names,
their respective backend database equivalents, attribute metadata, and backend
database attributes.

  $config = AddressBook::Config->new(config_file=>$filename);

AddressBook::Config looks for a configuration file in /etc/AddressBook.conf if 
no config_file parameter is present.

=head1 DESCRIPTION

Configuration is read from an XML configuration file which follows this DTD:

  <?xml version="1.0"?>
  <!DOCTYPE AddressBook_config [
    <!ELEMENT fields (field)>
    <!ELEMENT field  (db)>
    <!ELEMENT db (EMPTY)>
    <!ELEMENT databases (LDAP,LDIF,DBI,PDB,Text,HTML)>
    <!ELEMENT LDAP (EMPTY)>
    <!ELEMENT LDIF (EMPTY)>
    <!ELEMENT DBI (EMPTY)>
    <!ELEMENT PDB (EMPTY)>
    <!ELEMENT Text (EMPTY)>
    <!ELEMENT HTML (EMPTY)>

    <!ATTLIST field 	name 		CDATA 	#REQUIRED
                  	order 		CDATA 	#IMPLIED
                  	type 		(text|textblock|phone|email|url|lurl|boolean) #IMPLIED
                  	values 		CDATA 	#IMPLIED
                  	non_multiple 	CDATA 	#IMPLIED
                  	read_only 	CDATA 	#IMPLIED
                  	calculate 	CDATA 	#IMPLIED
                  	calc_order 	CDATA 	#IMPLIED>

    <!ATTLIST db 	name 		CDATA 	#REQUIRED
                	type 		CDATA 	#REQUIRED
                	order 		CDATA 	#IMPLIED
                	calculate 	CDATA 	#IMPLIED
                	calc_order 	CDATA 	#IMPLIED>

    <!ATTLIST LDAP      key_fields 	CDATA 	#IMPLIED
			hostname        CDATA   #IMPLIED
                     	objectclass 	CDATA 	#IMPLIED
                     	base 		CDATA 	#IMPLIED
                     	dn_calculate 	CDATA 	#IMPLIED
                     	username 	CDATA 	#IMPLIED
                     	password 	CDATA 	#IMPLIED>

    <!ATTLIST LDIF      key_fields 	CDATA 	#IMPLIED
			filename        CDATA   #IMPLIED
                     	objectclass 	CDATA 	#IMPLIED
                     	base 		CDATA 	#IMPLIED
                     	dn_calculate 	CDATA 	#IMPLIED>

    <!ATTLIST DBI       key_fields 	CDATA 	#IMPLIED
                     	table 		CDATA 	#IMPLIED
			dsn             CDATA   #IMPLIED>

    <!ATTLIST PDB       write_format 	CDATA 	#IMPLIED
			intra_attr_sep  CDATA   #IMPLIED
                     	form_format 	CDATA 	#IMPLIED>

    <!ATTLIST HTML      key_fields 	CDATA 	#IMPLIED
			filename        CDATA   #IMPLIED
                     	phone_display 	CDATA 	#IMPLIED>
  ]>

For example,

  <AddressBook_config>
    <fields>
      <field name="firstname" type="text" order="1">
        <db type="LDAP" name="givenname" />
        <db type="HTML" name="First Name" order="2" />
      </field>
      <field name="lastname" type="text" order="2">
        <db type="LDAP" name="sn" />
        <db type="HTML" name="Last Name" order="1" />
      </field>
      <field name="fullname" type="text" order="3" 
             calculate="$firstname . ' ' . $lastname">
        <db type="LDAP" name="cn" />
        <db type="HTML" name="Full Name" />
      </field>
    </fields>
    <databases>
      <LDAP objectclass="inetOrgPerson"
            base="o=abook"
            dn_calculate="'cn='.$cn"
            username="cn=Manager,o=abook"
            password="secret"
            key_fields="cn"
      />
    </databases>
  </AddressBook_config>

This defines three attributes with cannonical names "firstname", "lastname", and 
"fullname".  These are accessed in the LDAP backend context as "givenname", "sn" and 
"cn", and in the HTML backend context as "First Name", "Last Name" and "Full Name" 
respectively.

The default attribute ordering  is "firstname", "lastname", "fullname", however
the HTML backend overrides this and in that context attributes are ordered: "lastname",
"firstname", "fullname".   All other meta-attributes may be similarily overriden by 
specific backends

"fullname" is a calculated attribute.  Calculation strings may reference the 
names of other attributes by "$<attr_name>".

Backend databases may also be named and then tied to a source type by using the 'driver'
attribute.  This technique is useful for defining multiple backends of the same type.  
For example,

  <AddressBook_config>
    <fields>
      <field name="firstname" >
        <db type="ldap_server_1" name="givenname" />
        <db type="ldap_server_2" name="givenname" />
      </field>
      <field name="lastname" >
        <db type="ldap_server_1" name="sn" />
        <db type="ldap_server_2" name="sn" />
      </field>
    </fields>
    <databases>
      <ldap_server_1 driver="LDAP"
                     hostname="server_1"
                     objectclass="inetOrgPerson"
                     base="o=abook"
                     dn_calculate="'cn='.$cn"
                     username="cn=Manager,o=abook"
                     password="secret"
                     key_fields="cn"
      />
      <ldap_server_2 driver="LDAP"
                     hostname="server_2"
                     objectclass="inetOrgPerson"
                     base="o=abook"
                     dn_calculate="'cn='.$cn"
                     username="cn=Manager,o=abook"
                     password="secret"
                     key_fields="cn"
      />
    </databases>
  </AddressBook_config>

See the various backend man pages for information on the <database> configuration
attributes.  See also the sample configuration files in the 'examples' directory.

=cut

use AddressBook;
use strict;
use Carp;
use XML::DOM;

use vars qw($VERSION);

$VERSION = '0.13';

$AddressBook::Config::config_file = "/etc/AddressBook.conf";

#----------------------------------------------------------------
sub new {
  my $class=shift;
  my %args = @_;
  my $self = {};
  bless ($self,$class);
  my ($parser,$config,$field,$field_name,$attr,$db_type,$db_field_name,$db,$select,$option,$value);
  $self->{config_file} = $args{config_file} || $AddressBook::Config::config_file;
  eval {
    $parser = XML::DOM::Parser->new(ErrorContext=>1,
				    ParseParamEnt=>1,
				    ProtocolEncoding=>'UTF-8');
    $config = $parser->parsefile($self->{config_file});
  };
  if ($@ || ! $config) {
    $self->configError("Error reading config file: $@");
  }
  foreach $field ($config->getElementsByTagName("field")){
    $field_name=$field->getAttribute("name");
    foreach $attr ($field->getAttributes->getValues) {
      $self->{meta}->{$field_name}->{$attr->getName} = $attr->getValue;
    }
    foreach $db ($field->getElementsByTagName("db")) {
      $db_type=$db->getAttribute("type");
      $db_field_name=$db->getAttribute("name");
      $self->{generic2db}->{$field_name}->{$db_type} = $db_field_name;
      $self->{db2generic}->{$db_type}->{$db_field_name} = $field_name;
      foreach $attr ($db->getAttributes->getValues) {
	if ($attr->getName !~ /^type|name$/) {
	  $self->{dbmeta}->{$db_type}->{$field_name}->{$attr->getName} = $attr->getValue;
	}
      }
    }
  }
  my ($n) = $config->getElementsByTagName("databases");
  my ($db_name);
  if ($n) {
    foreach $db ($n->getElementsByTagName("*")) {
      $db_name=$db->getTagName;
      foreach $attr ($db->getAttributes->getValues) {
	$self->{db}->{$db_name}->{$attr->getName} = $attr->getValue;
      }
    }
  }
  foreach (keys %{$self->{db2generic}}) {
    if (! exists $self->{db}->{$_}->{driver}) {
      $self->{db}->{$_}->{driver} = $_;
    }
  }
  $self->validate();
  return $self;
}
#----------------------------------------------------------------
sub validate {
  my $self=shift;
  my $class = ref $self || croak "Not a method call.";
  my ($db);
  foreach $db (keys %{$self->{db}}) {
    next unless ($self->{db}->{$db}->{key_fields});
    foreach  (split ",", $self->{db}->{$db}->{key_fields}) {
      if (! exists $self->{db2generic}->{$db}->{$_}) {
	$self->configError("key field \"$_\" is not a valid attribute for backend $db");
      }
    }
  }
}
#----------------------------------------------------------------
sub configError {
  my $self=shift;
  my $class = ref $self || croak "Not a method call.";
  my $msg = shift; 
  croak "Configuration File Error (".$self->{config_file}."):\n$msg\n";
}
#----------------------------------------------------------------

=head2 getMeta
  
  %meta = %{$config->getMeta(attr=>$attr)}
  %meta = %{$config->getMeta(attr=>$attr,db=>$db)}

Returns an attribute metadata hash

=cut

sub getMeta {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  my %args = @_;
  my %ret;
  if (exists $args{attr} && exists $self->{meta}->{$args{attr}}) {
    %ret = %{$self->{meta}->{$args{attr}}};
  }
  if ($args{db}) {
    foreach (keys %{$self->{dbmeta}->{$args{db}}->{$args{attr}}}) {
      $ret{$_} = $self->{dbmeta}->{$args{db}}->{$args{attr}}->{$_};
    }
  }
  return \%ret;
}

1;
__END__

=head1 AUTHOR

David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>
L<AddressBook::Entry>

=cut
