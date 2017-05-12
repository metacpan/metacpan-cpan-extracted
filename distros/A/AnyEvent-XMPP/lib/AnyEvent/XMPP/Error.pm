package AnyEvent::XMPP::Error;
use strict;
use AnyEvent::XMPP::Util qw/stringprep_jid prep_bare_jid/;
use AnyEvent::XMPP::Error;
use AnyEvent::XMPP::Error::SASL;
use AnyEvent::XMPP::Error::IQ;
use AnyEvent::XMPP::Error::Register;
use AnyEvent::XMPP::Error::Stanza;
use AnyEvent::XMPP::Error::Stream;
use AnyEvent::XMPP::Error::Presence;
use AnyEvent::XMPP::Error::Message;
use AnyEvent::XMPP::Error::Parser;
use AnyEvent::XMPP::Error::Exception;
use AnyEvent::XMPP::Error::IQAuth;

=head1 NAME

AnyEvent::XMPP::Error - Error class hierarchy for error reporting

=head1 SYNOPSIS

   die $error->string;

=head1 DESCRIPTION

This module is a helper class for abstracting any kind
of error that occurs in AnyEvent::XMPP.

You receive instances of these objects by various events.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self->init;
   $self
}

sub init { }

=head1 SUPER CLASS

AnyEvent::XMPP::Error - The super class of all errors

=head2 METHODS

These methods are implemented by all subclasses.

=over 4

=item B<string ()>

Returns a humand readable string for this error.

=cut

sub string {
   my ($self) = @_;
   $self->{text}
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
