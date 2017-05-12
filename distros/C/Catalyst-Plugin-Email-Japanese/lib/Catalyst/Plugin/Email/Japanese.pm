package Catalyst::Plugin::Email::Japanese;
use strict;

use strict;
use Catalyst::Exception;
use UNIVERSAL::require

our $VERSION = '0.07';

=head1 NAME

Catalyst::Plugin::Email::Japanese - Send Japanese emails with Catalyst

=head1 SYNOPSIS

    use Catalyst qw/Email::Japanese/;
    
    # config base parameters
    __PACKAGE__->config(
        email => {
            Template => 'email.tt',
            From => 'typester@cpan.org',
        }
    );
    
    # and later in your controller
    $c->email(
        To => 'example@example.com',
        Subject => 'Hi!',
    );

=head1 DESCRIPTION

Send emails with Catalyst and L<MIME::Lite::TT::Japanese>.

=head1 ForceUTF8 MODE

If $c->config->{ForceUTF8} or $c->config->{email}->{ForceUTF8} is true value,
this module use L<Template::Provider::Encoding> and L<Template::Stash::ForceUTF8> for correct utf-8 handling.

Please see these module's docs for detail.

=head1 HTML MAIL SUPPORT

If Template parameter is hash ref like below:

    $c->config->{email} = {
        Template => {
            html => 'html.tt',
            text => 'text.tt',
        },
    };

then this module use L<MIME::Lite::TT::HTML::Japanese> instead of L<MIME::Lite::TT::Japanese>.

This is useful for sending html mails.

=head1 METHODS

=head2 email( %args )

Send email with MIME::Lite::TT::(HTML::)Japanese.

%args and $c->config->{emal} is MIME::Lite::TT::(HTML::)Japanese's parameters, and %args override latter.

=cut

sub email {
    my $c = shift;
    my $args = $_[1] ? {@_} : $_[0];

    my $template = $args->{Template} || $c->stash->{email}->{template} || $c->config->{email}->{Template};

    my $module =
        ref $template eq 'HASH'
        ? 'MIME::Lite::TT::HTML::Japanese'
        : 'MIME::Lite::TT::Japanese';
    $module->require
        or Catalyst::Exception->throw(
            message => qq/Couldn't load $module, "$!"/ );

    my $options = {
        EVAL_PERL => 0,
        %{ $c->config->{email}->{TmplOptions} || {} },
        %{ $args->{TmplOptions} || {} },
    };

    my $include_path
        = delete $options->{INCLUDE_PATH}
        || $c->view->config->{INCLUDE_PATH}
        || [ $c->config->{root}, $c->config->{root} . '/base' ];

    if ( $c->config->{ForceUTF8} or $c->config->{email}{ForceUTF8} || $args->{ForceUTF8} ) {
        $_->require
            || Catalyst::Exception->throw( message => $! )
            for qw/Template::Provider::Encoding Template::Stash::ForceUTF8/;
        $options->{LOAD_TEMPLATES} = [ Template::Provider::Encoding->new( INCLUDE_PATH => $include_path ) ];
        $options->{STASH} = Template::Stash::ForceUTF8->new;
    }
    else {
        $options->{INCLUDE_PATH} = $include_path;
    }

    my $params = {
        base => $c->req->base,
        c => $c,
        name => $c->config->{name},
        %{ $c->stash },
        %{ $args->{TmplParams} || {} },
    };

    my $msg = $module->new(
        %{$c->config->{email} || {} },
        %{$args || {} },
        Template => $template,
        TmplParams => $params,
        TmplOptions => $options,
        Icode => $args->{Icode} || $c->config->{email}->{Icode} || 'utf8',
        LineWidth => $args->{LineWidth} || $c->config->{email}->{LineWidth} || 0,
    );

    my $route = $c->config->{email}->{mailroute} || { via => 'smtp', host => 'localhost' };
    $route->{via} ||= 'smtp';

    eval {
        if ( $route->{via} eq 'smtp_tls' ) {
            $msg->send_by_smtp_tls(
                $route->{host},
                User     => $route->{username},
                Password => $route->{password},
                Port     => $route->{port} || 587,
            );
        }
        elsif ( $route->{via} eq 'sendmail' ) {
            my %param;
            $param{FromSender} = '<' . $c->config->{email}->{mailfrom} . '>' if $c->config->{email}->{mailfrom};
            $param{Sendmail} = $route->{command} if defined $route->{command};
            $msg->send( 'sendmail', %param );
        }
        else {
            my @args = $route->{host} ? ( $route->{host} ) : ();
            $msg->send( $route->{via}, @args );
        }
    };

    if ($@) {
        Catalyst::Exception->throw( message => "Error while sending emails: $@" )
    }

    1;
}

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Email>, L<MIME::Lite::TT::Japanese>, L<MIME::Lite::TT::HTML::Japanese>.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
