package App::LDAP::Command::Init;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

use Authen::SASL;
use IO::String;
use Net::LDAP::LDIF;

our $schemas = {};

sub run {
    my ($self, ) = @_;

    my $ldap = Net::LDAP->new("ldapi://");
    my $sasl = Authen::SASL->new(mechanism => "EXTERNAL")
                           ->client_new("ldap", "localhost");

    $ldap->bind(undef, sasl => $sasl);

    for my $schema (keys %{$schemas}) {
        my $file = IO::String->new($schemas->{$schema});
        my $entry = Net::LDAP::LDIF->new($file, "r", onerror => "die")->read_entry();
        my $msg = $ldap->add($entry);
        die $msg->error if $msg->code;
    }

    ldap()->add($self->create_gidnext);
    ldap()->add($self->create_uidnext);

}

$schemas->{idnext} = <<'IDNEXT';
dn: cn=idnext,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: idnext
olcObjectClasses: {0}( 1.3.6.1.4.1.7165.1.2.2.3 
  NAME 'uidNext' SUP top STRUCTURAL
  DESC 'Next available UNIX uid'
  MUST ( uidNumber $ cn ) )
olcObjectClasses: {1}( 1.3.6.1.4.1.7165.1.2.2.4 
  NAME 'gidNext' SUP top STRUCTURAL
  DESC 'Next available UNIX gid'
  MUST ( gidNumber $ cn ) )
IDNEXT

$schemas->{sudo} = <<'SUDO';
dn: cn=sudo,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: sudo
olcAttributeTypes: {0}( 1.3.6.1.4.1.15953.9.1.1 NAME 'sudoUser' DESC 'User(s) 
 who may  run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMa
 tch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: {1}( 1.3.6.1.4.1.15953.9.1.2 NAME 'sudoHost' DESC 'Host(s) 
 who may run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMat
 ch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: {2}( 1.3.6.1.4.1.15953.9.1.3 NAME 'sudoCommand' DESC 'Comma
 nd(s) to be executed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1
 466.115.121.1.26 )
olcAttributeTypes: {3}( 1.3.6.1.4.1.15953.9.1.4 NAME 'sudoRunAs' DESC 'User(s)
  impersonated by sudo (deprecated)' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1
 .4.1.1466.115.121.1.26 )
olcAttributeTypes: {4}( 1.3.6.1.4.1.15953.9.1.5 NAME 'sudoOption' DESC 'Option
 s(s) followed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115
 .121.1.26 )
olcAttributeTypes: {5}( 1.3.6.1.4.1.15953.9.1.6 NAME 'sudoRunAsUser' DESC 'Use
 r(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466
 .115.121.1.26 )
olcAttributeTypes: {6}( 1.3.6.1.4.1.15953.9.1.7 NAME 'sudoRunAsGroup' DESC 'Gr
 oup(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.14
 66.115.121.1.26 )
olcObjectClasses: {0}( 1.3.6.1.4.1.15953.9.2.1 NAME 'sudoRole' DESC 'Sudoer En
 tries' SUP top STRUCTURAL MUST cn MAY ( sudoUser $ sudoHost $ sudoCommand $ s
 udoRunAs $ sudoRunAsUser $ sudoRunAsGroup $ sudoOption $ description ) )
SUDO

sub create_uidnext {
    my ($self, ) = @_;
    my $base = config()->{base};
    my $uidnext = Net::LDAP::Entry->new("cn=uidnext,$base");
    $uidnext->add(
        cn          => "uidnext",
        objectClass => "uidNext",
        uidNumber   => 1001,
    );
    return $uidnext;
}

sub create_gidnext {
    my ($self, ) = @_;
    my $base = config()->{base};
    my $gidnext = Net::LDAP::Entry->new("cn=gidnext,$base");
    $gidnext->add(
        cn          => "gidnext",
        objectClass => "gidNext",
        gidNumber   => 1001,
    );
    return $gidnext;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::Command::Init - setup the prerequisites needed by App::LDAP

=head1 SYNOPSIS

    $ sudo ldap init

=head1 DESCRIPTION

This command initailizes the environment of LDAP server for App::LDAP to function.

1. import the schema of idnext

2. import the schema of sudo

3. add a entry of uidnext, uidNumber 1001

4. add a entry of gidnext, gidNumber 1001

=cut

