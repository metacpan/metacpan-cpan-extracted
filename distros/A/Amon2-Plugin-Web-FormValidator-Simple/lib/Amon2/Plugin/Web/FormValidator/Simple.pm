package Amon2::Plugin::Web::FormValidator::Simple;
use utf8;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.04';

use FormValidator::Simple;

sub init { my ($class, $c, $conf) = @_; #{{{
    my $s = $c->config->{validator};

    my $plugins = $s && exists $s->{plugins} ? $s->{plugins} : [];
    FormValidator::Simple->import(@$plugins);

    FormValidator::Simple->set_messages($s->{messages})
        if $s && exists $s->{messages};
    FormValidator::Simple->set_option(%{$s->{options}})
        if $s && exists $s->{options};
    FormValidator::Simple->set_message_format($s->{message_format})
        if $s && exists $s->{message_format};
    FormValidator::Simple->set_message_decode_from($s->{message_decode_from})
            if $s && exists $s->{message_decode_from};

    Amon2::Util::add_method($c, 'form', \&form);
    Amon2::Util::add_method($c, 'set_invalid_form', \&set_invalid_form);

    $c->add_trigger(BEFORE_DISPATCH => sub { my $c = shift;
        $c->{validator} = FormValidator::Simple->new;

        return;
    });
} #}}}

sub form { my $c = shift; #{{{
    if ($_[0]) {
        my $form = $_[1] ? [@_] : $_[0];
        $c->{validator}->check($c->req, $form);
    }

    return $c->{validator}->results;
} #}}}

sub set_invalid_form { my $c = shift; #{{{
    $c->{validator}->set_invalid(@_);

    return $c->{validator}->results;
} #}}}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::FormValidator::Simple - Amon2 plugin

=head1 SYNOPSIS

    # MyApp.pm

    __PACKAGE__->load_plugins('Web::FormValidator::Simple');

    # MyApp/Web/Dispatcher.pm

    get '/user/{team}/{name}/' => sub {
        my ($c) = @_;

        # do validation
        $c->form(
            team => [qw!NOT_BLANK!, [qw!LENGTH 1 10!]],
            name => [qw!NOT_BLANK!, [qw!LENGTH 1 10!]],
        );

        # if detect errors, return with a error page.
        if ($c->form->has_error) {
            return $c->render('error.tt');
        }

        ...
    };

    # same as C::P::FV::S, you can use messages/messages.yml

    # development.pl
    ...

    +{
        ...

        validator => +{
            message_format => '<p>%s</p>',
            message_decode_from => 'UTF-8',
            # messages => 'messages.yml',
            messages => +{
                account => +{
                    team => +{
                        NOT_BLANK => 'TEAM cannot be blank!',
                        LENGTH => 'TEAM length must be [1, 10]',
                    },
                    name => +{
                        NOT_BLANK => 'NAME cannnot be blank!',
                        LENGTH => 'NAME length must be [1, 10]',
                    },
                },
            },
        },
    };

    # messages.yml

    account:
        team:
            NOT_BLANK: TEAM cannot be blank!
            LENGTH: TEAM length must be [1, 10]
        name:
            NOT_BLANK: NAME cannot be blank!
            LENGTH: NAME length must be [1, 10]

=head1 DESCRIPTION

Amon2::Plugin::Web::FormValidator::Simple is a port of
L<Catalyst::Plugin::FormValidator::Simple>.
This module has the same methods and options, so see her documents.

=head1 METHODS

=over 4

=item C<< $c->init() >>

initial setup.

=item C<< $c->form() >>

validate form/query parameters.

=item C<< $c->set_invalid_form() >>

set error from manual validation.

=back

=head1 AUTHOR

JINNOUCHI Yasushi E<lt>delphinus@remora.cxE<gt>

=head1 SEE ALSO

L<Amon2::Web>
L<FormValidator::Simple>
L<Catalyst::Plugin::FormValidator::Simple>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
