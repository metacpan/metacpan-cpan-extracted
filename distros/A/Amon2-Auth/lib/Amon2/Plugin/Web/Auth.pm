package Amon2::Plugin::Web::Auth;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.07';
use Plack::Util;
use URI::WithBase;

sub init {
    my ($class, $c, $code_conf) = @_;

    my $module = $code_conf->{module} or die "Missing mandatory parameter: module";
    my $klass = Plack::Util::load_class($code_conf->{module}, 'Amon2::Auth::Site');

    my $moniker = $klass->moniker;
    my $authenticate_path = $code_conf->{authenticate_path} || "/auth/${moniker}/authenticate";
    my $callback_path = $code_conf->{callback_path} || "/auth/${moniker}/callback";

    # handlers
    my $on_finished = $code_conf->{on_finished} or die "Missing mandatory parameter: on_finished";
    my $on_error = $code_conf->{on_error} || sub {
        my ($c, $err) = @_;
        die "Authentication error in $module: $err";
    };

    # auth object
    my $conf = $c->config->{'Auth'}->{$module} || die "Missing configuration for Auth.${module}";
    my $auth = $klass->new($conf);
    if (exists $code_conf->{user_info}) {
        $auth->user_info($code_conf->{user_info});
    }

    $c->add_trigger(BEFORE_DISPATCH => sub {
        my $c = shift;
        my $path_info = $c->req->path_info;

        if ($path_info eq $authenticate_path) {
            my $callback = URI::WithBase->new($c->uri_for($callback_path), $c->req->base);
            return $c->redirect($auth->auth_uri($c, $callback->abs->as_string));
        } elsif ($path_info eq $callback_path) {
            return $auth->callback($c, {
                on_finished => sub {
                    $on_finished->($c, @_);
                },
                on_error => sub {
                    $on_error->($c, @_);
                },
            });
        } else {
            return undef; # DECLINED
        }
    });
}

1;
__END__

=encoding utf8

=for stopwords auth

=head1 NAME

Amon2::Plugin::Web::Auth - auth with SNS

=head1 SYNOPSIS

    package MyApp::Web;

    # simple usage
    # more configurable...
    __PACKAGE__->load_plugin(
        'Web::Auth' => {
            module => 'Facebook',
            on_finished => sub {
                my ($c, $token, $user) = @_;
                ...
            }
        }
    );

=head1 DESCRIPTION

Amon2::Plugin::Web::Auth is authentication engine for Amon2.

B<THIS MODULE IS EXPERIMENTAL STATE. SOME API CHANGES WITHOUT NOTICE>.

=head1 CONFIGURATION IN CODE

=over 4

=item module

This is a module name for authentication plugins. You can write 'Amon2::Auth::Site::Facebook' as 'Facebook' in this part. If you want to use your own authentication module, you can write it as '+My::Own::Auth::Module' like DBIx::Class.

    __PACKAGE__->load_plugin(
        'Web::Auth' => {
            module => 'Twitter',
            ...
        }
    );
    # or
    __PACKAGE__->load_plugin(
        'Web::Auth' => {
            module => '+My::Own::Auth::Module',
            ...
        }
    );

=item on_finished

This is a callback when authentication flow was finished. You MUST return a response object in this callback function. You MAY return the response of C<< $c->redirect() >>.

    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'Github',
        on_finished => sub {
            my ($c, $token, $user) = @_;
            my $gihtub_id = $user->{id} || die;
            my $github_name = $user->{name} || die;
            $c->session->set('name' => $github_name);
            $c->session->set('site' => 'github');
            return $c->redirect('/');
        }
    });

The arguments of this callback function is a auth module specific.

=item user_info

In auth module that uses OAuth2, is not required to fetch user information, just get a access_token. If you don't need a user information, you can set false value on this attribute.

This attribute is true by default on most modules for your laziness.

=item on_error

Auth module calls this callback function when error occurred.

Arguments are following format.

    my ($c, $err) = @_;

The default value is following.

    sub {
        my ($c, $err) = @_;
        die "Authentication error in $module: $err";
    }

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
