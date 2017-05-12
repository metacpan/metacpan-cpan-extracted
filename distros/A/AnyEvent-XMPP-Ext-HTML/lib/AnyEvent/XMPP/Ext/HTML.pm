package AnyEvent::XMPP::Ext::HTML;
{
  $AnyEvent::XMPP::Ext::HTML::VERSION = '0.02';
}
# ABSTRACT: XEP-0071: XHTML-IM (Version 1.5) for AnyEvent::XMPP

use warnings;
use strict;

use AnyEvent::XMPP::Ext;
use AnyEvent::XMPP::Namespaces qw/set_xmpp_ns_alias xmpp_ns/;

our @ISA = qw/AnyEvent::XMPP::Ext/;


sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless { @_ }, $class;
    $self->init;
    $self;
}


sub init {
    my $self = shift;

    set_xmpp_ns_alias(xhtml_im => 'http://jabber.org/protocol/xhtml-im');
    set_xmpp_ns_alias(xhtml => 'http://www.w3.org/1999/xhtml');

    $self->{disco}->enable_feature($self->disco_feature) if defined $self->{disco};

    $self->{cb_id} = $self->reg_cb(
        send_message_hook => sub {
            my ($self, $con, $id, $to, $type, $attrs, $create_cb) = @_;

            return unless exists $attrs->{html};
            my $html = delete $attrs->{html};

            push @$create_cb, sub {
                my ($w) = @_;

                $w->addPrefix(xmpp_ns('xhtml_im'), '');
                $w->startTag([xmpp_ns('xhtml_im'), 'html']);
                if (ref($html) eq 'HASH') {
                    for (keys %$html) {
                        $w->addPrefix(xmpp_ns('xhtml'), '');
                        $w->startTag([xmpp_ns('xhtml'), 'body'], ($_ ne '' ? ([xmpp_ns('xml'), 'lang'] => $_) : ()));
                        $w->raw($html->{$_});
                        $w->endTag;
                    }
                } else {
                    $w->addPrefix(xmpp_ns('xhtml'), '');
                    $w->startTag([xmpp_ns('xhtml'), 'body']);
                    $w->raw($html);
                    $w->endTag;
                }
                $w->endTag;
            };
        },
    );
}

sub disco_feature {
    xmpp_ns('xhtml_im');
}

sub DESTROY {
    my $self = shift;
    $self->unreg_cb($self->{cb_id});
}

1;

__END__

=pod

=head1 NAME

AnyEvent::XMPP::Ext::HTML - XEP-0071: XHTML-IM (Version 1.5) for AnyEvent::XMPP

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $c = AnyEvent::XMPP::Connection->new(...);
    $c->add_extension(my $disco = AnyEvent::XMPP::Ext::Disco->new);
    $c->add_extension(AnyEvent::XMPP::Ext::HTML->new(disco => $disco));
    
    $c->send_message(
        body => "This is plain text; same as usual.",
        html => "This is <em>XHTML</em>!",
    );

=head1 DESCRIPTION

An implementation of XEP-0071: XHTML-IM for HTML-formatted messages.

=head1 METHODS

=head2 new

Creates a new extension handle.  It takes an optional C<disco> argument which
is a L<AnyEvent::XMPP::Ext::Disco> object for which this extension will be
enabled.

=head2 init

Initialize the extension.  This does not need to be called externally.

=head1 CAVEATS

HTML messages are not validated nor escaped, so it is your responsibility to
use valid XHTML-IM tags and to close them properly.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
