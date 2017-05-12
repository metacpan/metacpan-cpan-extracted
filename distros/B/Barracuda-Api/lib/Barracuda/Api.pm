package Barracuda::Api ;

use strict;
use warnings;
use Data::Dumper;
use XML::RPC;
use Carp qw(croak);

our $VERSION = '0.03';

sub new {
    my ( $classe, $ref_args ) = @_;

    $classe = ref($classe) || $classe;

    my $self = {};
    bless( $self, $classe );

    foreach my $attribut ( qw/domain password/ ) {
        croak("Must set $attribut") unless $ref_args->{$attribut}
    }

    # Default value if some attributes are not set
    $ref_args->{port} = 8000 unless defined $ref_args->{port};
    $ref_args->{verbose} = 0 unless defined $ref_args->{verbose};
    $ref_args->{proto} = 'http' unless defined $ref_args->{proto};

    $self->{_DOMAIN}       = $ref_args->{domain};
    $self->{PORT}          = $ref_args->{port};
    $self->{_PASSWORD}     = $ref_args->{password};
    $self->{VERBOSE}       = $ref_args->{verbose};
    $self->{_PROTO}        = $ref_args->{proto};
    $self->{XMLRPC}        = XML::RPC->new("$self->{_PROTO}://$self->{_DOMAIN}:$self->{PORT}/cgi-mod/api.cgi?password=$self->{_PASSWORD}");

    return $self;
}

sub listAllDomain {
    my $self = shift;

    $self->{XMLRPC}->call('config.list', { type => 'global',
                                child_type => 'domain' });

    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub getDestinationAddress {
    my ( $self, $domain ) = @_;

        $self->{XMLRPC}->call('config.get', { 
                                type => 'domain',
                                path => "$domain",
				variable => 'mta_relay_advanced_host'});
    
    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub createDomain {
    my ( $self, $domain, $destination ) = @_;

    croak('You must define domain and destination')
                        unless ( $domain && $destination);

    $self->{XMLRPC}->call('config.create', { parent_type => 'global',
                                parent_path => '',
                                type => 'domain',
                                name => "$domain",
                                mta_relay_advanced_host => "$destination" } );

    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub deleteDomain {
    my ( $self, $domain ) = @_;

    croak('You must define domain')
                        unless ( $domain );

    $self->{XMLRPC}->call('config.delete', { parent_type => 'global',
                                parent_path => '',
                                type => 'domain',
                                path => "$domain" });

    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub createUser {
    my ( $self, $user ) = @_;

    croak('You must define a user')
                        unless ( $user );

    $self->{XMLRPC}->call('user.create', { 
				user => "$user" });

    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub deleteUser {
    my ( $self, $user ) = @_;

    croak('You must define a user')
                        unless ( $user );

    $self->{XMLRPC}->call('user.remove', { 
                                user => "$user" });

    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub whitelistSenderForDomain {
    my ( $self, $domain, $whitelist, $comment ) = @_;

    croak('You must define domain and whitelist')
                        unless ( $domain && $whitelist);

    # Do not print anything in comment if not set
    $comment = '' unless defined $comment;

    $self->{XMLRPC}->call('config.create', { parent_type => 'domain',
                                parent_path => "$domain",
                                type => 'mta_sender_allow_address',
                                name => "$whitelist",
                                mta_sender_allow_comment => "$comment" });

    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub blacklistSenderForDomain {
    my ( $self, $domain, $blacklist, $comment ) = @_;

    croak('You must define domain and blacklist')
                        unless ( $domain && $blacklist);

    # Print anything in comment if not set
    $comment = '' unless defined $comment;

    $self->{XMLRPC}->call('config.create', { parent_type => 'domain',
                                parent_path => "$domain",
                                type => 'mta_sender_block_address',
                                name => "$blacklist",
                                mta_sender_allow_comment => "$comment" });

    $self->_parseOutput($self->{XMLRPC}->xml_in());
}

sub _parseOutput {
    my ( $self, $output ) = @_;
    my $result = '';

    if ( $self->{VERBOSE} == 0 ) {
        while ( $output =~ m/CDATA\[(.*)\]\]/g ) {
            $result .= "$1\n";
        }
    } else {
        $result = $output;
    }

    $result
}

1;
__END__


=head1 NAME

Barracuda::Api - Easy way to communicate with Barracuda API version 4.x and above

=head1 SYNOPSIS

    use Barracuda::Api

    my $bar = Barracuda::Api->new(
        {
            domain => 'mydomain.com',
            password => 'myp@ssword'
        }
    );

=head1 DESCRIPTION

This module gives few method to play with Barracuda API version 4.x and above.

A better documentation of Barracuda API can be found at https://techlib.barracuda.com/BSF/APIGuide

=head1 ATTRIBUTES

=over 12

=item B<domain>     - domain to your Barracuda API

=item B<password>   - password API

=item B<port>       - optional port to your Barracuda API (Default : 8000)

=item B<proto>      - optional protocol to your Barracuda API (default : http)

=item B<verbose>    - optional verbose level : 0, 1 (default : 0)

=back

=head1 METHODS

=over 4

=item new( $ref )

The constructor take a reference to hash. See the ATTRIBUTES section to get all parameters.

=item listAllDomain()

Method to list all domain.

It return a scalar with XMLRPC answer (formatted or not).

=item getDestinationAddress( $domain )

Method to get the destination host for $domain.

It return a scalar with XMLRPC answer (formatted or not).

=item createDomain( $domain, $destination )

Method to create domain $domain with destination $destination.

It return a scalar with XMLRPC answer (formatted or not).

=item deleteDomain( $domain )

Method to delete domain $domain.

It return a scalar with XMLRPC answer (formatted or not).

=item createUser( $user )

Method to create user $user.

It return a scalar with XMLRPC answer (formatted or not).

=item deleteUser( $user )

Method to delete user $user.

It return a scalar with XMLRPC answer (formatted or not).

=item whitelistSenderForDomain( $domain, $whitelist, $comment )

Method to whitelist $whitelist for specific domain $domain and optionally add a comment $comment.

It return a scalar with XMLRPC answer (formatted or not).

=item blacklistSenderForDomain( $domain, $blacklist, $comment )

Same as whitelist method, but blacklist $blacklist.

It return a scalar with XMLRPC answer (formatted or not).

=back

=head1 AUTHOR

Mael Regnery <mael@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, <Mael Regnery>.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.

=cut
