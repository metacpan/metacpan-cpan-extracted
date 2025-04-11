package Apache::Session::Browseable::LDAP;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Browseable::Store::LDAP;
use Apache::Session::Generate::SHA256;
use Apache::Session::Serialize::JSON;
use Apache::Session::Browseable::_common;
use Net::LDAP::Util qw(escape_filter_value);

our $VERSION = '1.3.6';
our @ISA     = qw(Apache::Session Apache::Session::Browseable::_common);

sub populate {
    my $self = shift;

    $self->{object_store} = new Apache::Session::Browseable::Store::LDAP $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Apache::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::JSON::unserialize;

    return $self;
}

sub unserialize {
    my $session = shift;
    my $tmp = { serialized => $session };
    Apache::Session::Serialize::JSON::unserialize($tmp);
    return $tmp->{data};
}

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = @_;

    my $index =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    if ( grep { $_ eq $selectField } @$index ) {
        ( $selectField, $value ) = escape_filter_value( $selectField, $value );
        return $class->_query( $args, $selectField, $value, @fields );
    }
    else {
        return $class->SUPER::searchOn( $args, $selectField, $value, @fields );
    }
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = @_;

    my $index =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    if ( grep { $_ eq $selectField } @$index ) {
        ( $selectField, $value ) = escape_filter_value( $selectField, $value );
        $value =~ s/\\2a/\*/gi;
        return $class->_query( $args, $selectField, $value, @fields );
    }
    else {
        return $class->SUPER::searchOn( $args, $selectField, $value, @fields );
    }
}

sub _query {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    $args->{ldapObjectClass}      ||= 'applicationProcess';
    $args->{ldapAttributeId}      ||= 'cn';
    $args->{ldapAttributeContent} ||= 'description';
    $args->{ldapAttributeIndex}   ||= 'ou';

    my %res = ();
    my $ldap =
      Apache::Session::Browseable::Store::LDAP::ldap( { args => $args } );
    my $msg = $ldap->search(
        base   => $args->{ldapConfBase},
        filter => "(&(objectClass="
          . $args->{ldapObjectClass} . ")("
          . $args->{ldapAttributeIndex}
          . "=${selectField}_$value))",

        #scope => 'base',
        attrs => [ $args->{ldapAttributeContent}, $args->{ldapAttributeId} ],
    );

    $ldap->unbind();
    $ldap->disconnect();

    if ( $msg->code ) {
        Apache::Session::Browseable::Store::LDAP->logError($msg);
    }
    else {
        foreach my $entry ( $msg->entries ) {
            my $id = $entry->get_value( $args->{ldapAttributeId} ) or die;
            my $tmp = $entry->get_value( $args->{ldapAttributeContent} );
            next unless ($tmp);
            eval { $tmp = unserialize($tmp); };
            next if ($@);
            if (@fields) {
                $res{$id}->{$_} = $tmp->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $tmp;
            }
        }
    }
    return \%res;
}

sub get_key_from_all_sessions {
    my $class = shift;
    my $args  = shift;
    my $data  = shift;
    $args->{ldapObjectClass}      ||= 'applicationProcess';
    $args->{ldapAttributeId}      ||= 'cn';
    $args->{ldapAttributeContent} ||= 'description';
    $args->{ldapAttributeIndex}   ||= 'ou';

    my %res;

    my $ldap =
      Apache::Session::Browseable::Store::LDAP::ldap( { args => $args } );
    my $msg = $ldap->search(
        base => $args->{ldapConfBase},

     # VERY STRANGE BUG ! With this filter, description isn't base64 encoded !!!
     #filter => '(objectClass=applicationProcess)',

        filter => '(&(objectClass='
          . $args->{ldapObjectClass} . ')('
          . $args->{ldapAttributeIndex} . '=*))',
        attrs => [ $args->{ldapAttributeId}, $args->{ldapAttributeContent} ],
    );

    $ldap->unbind();

    if ( $msg->code ) {
        Apache::Session::Browseable::Store::LDAP->logError($msg);
    }
    else {
        foreach my $entry ( $msg->entries ) {
            my $id = $entry->get_value( $args->{ldapAttributeId} ) or die;
            my $tmp = $entry->get_value( $args->{ldapAttributeContent} );
            next unless ($tmp);
            eval { $tmp = unserialize($tmp); };
            next if ($@);
            if ( ref($data) eq 'CODE' ) {
                $res{$id} = &$data( $tmp, $id );
            }
            elsif ($data) {
                $data = [$data] unless ( ref($data) );
                $res{$id}->{$_} = $tmp->{$_} foreach (@$data);
            }
            else {
                $res{$id} = $tmp;
            }
        }
    }

    return \%res;
}

1;

=pod

=head1 NAME

Apache::Session::Browseable::LDAP - An implementation of Apache::Session::LDAP

=head1 SYNOPSIS

  use Apache::Session::Browseable::LDAP;
  tie %hash, 'Apache::Session::Browseable::LDAP', $id, {
    ldapServer           => 'ldap://localhost:389',
    ldapConfBase         => 'dmdName=applications,dc=example,dc=com',
    ldapBindDN           => 'cn=admin,dc=example,dc=com',
    ldapBindPassword     => 'pass',
    Index                => 'uid ipAddr',
    ldapObjectClass      => 'applicationProcess',
    ldapAttributeId      => 'cn',
    ldapAttributeContent => 'description',
    ldapAttributeIndex   => 'ou',
    ldapVerify           => 'require',
    ldapCAFile           => '/etc/ssl/certs/ca-certificates.crt',
  };

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses an LDAP directory
to store datas.

=head1 COPYRIGHT AND LICENSE

=encoding utf8

=over

=item 2009-2025 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2025 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Apache::Session>

=cut
