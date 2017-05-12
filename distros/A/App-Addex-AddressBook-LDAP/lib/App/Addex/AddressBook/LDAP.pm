use Modern::Perl;

package App::Addex::AddressBook::LDAP;
BEGIN {
  $App::Addex::AddressBook::LDAP::VERSION = '0.001';
}

# ABSTRACT: LDAP address book for App::Addex

use parent 'App::Addex::AddressBook';

use App::Addex::Entry;
use App::Addex::Entry::EmailAddress;
use Carp;
use Net::LDAP;
use URI;

sub new {
    my ($class, $arg) = @_;

    my $uri = URI->new($arg->{uri});

    my $self = bless {
        uri => $uri,
    } => $class;

    my $ldap = Net::LDAP->new(
        "$uri",
        raw     => qr/(?i:^jpegPhoto|;binary)/,
        onerror => 'die'
    ) or confess $@;
    $ldap->bind();
    $self->{ldap} = $ldap;

    return $self;
}

sub _entrify {
    my ($self, $entry) = @_;

    my @emails = map { App::Addex::Entry::EmailAddress->new($_) }
      $entry->get_value('mail');
    return unless @emails;

    return App::Addex::Entry->new(
        {
            name   => $entry->get_value('cn'),
            nick   => $entry->get_value('uid'),
            emails => \@emails,
        }
    );
}

sub entries {
    my ($self) = @_;

    my $mesg = $self->{ldap}->search(
        base   => $self->{uri}->dn,
        filter => $self->{uri}->filter,
        scope  => $self->{uri}->scope,
    );

    return map { $self->_entrify($_) } $mesg->entries;
}

1;


__END__
=pod

=head1 NAME

App::Addex::AddressBook::LDAP - LDAP address book for App::Addex

=head1 VERSION

version 0.001

=head1 SYNOPSIS

This module implements the App::Addex::AddressBook interface by querying an
LDAP server for mail attributes. To use it, your App::Addex configuration might look like this:

    addressbook = App::Addex::AddressBook::LDAP
    output = App::Addex::Output::Mutt

    [App::Addex::AddressBook::LDAP]
    uri = ldap://yourldaphost/ou=People,dc=example,dc=org??sub

    [App::Addex::Output::Mutt]
    filename = /home/mxey/.mutt_aliases

The cn attribute is used as the name, the uid attribute is used as the nick and
mail attributes are used as e-mail addresses.

=head1 BUGS

Attributes in the LDAP URI are ignored. It might be nice to specify attributes
to use as mail addresses in the URI.

Only anonymous binding is supported. If you need to specify a binddn, please
open a bugreport and/or send a patch :-)

=head1 AUTHOR

Maximilian Gass <mxey@ghosthacking.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

