package CGI::Application::Plugin::RequireSSL;
use warnings;
use strict;
use Carp;
use base 'Exporter';
use Attribute::Handlers;
our @EXPORT = qw/config_requiressl mode_redirect/;
our %SSL_RUN_MODES;
use Data::Dumper;

=head1 NAME

CGI::Application::Plugin::RequireSSL - Force SSL in specified pages or modules

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use CGI::Application::Plugin::RequireSSL;

    sub login_form :RequireSSL {
        my $self = shift;
        # etc
    }
    
=head1 DESCRIPTION

CGI::Application::Plugin::RequireSSL allows individual run modes or
whole modules to be protected by SSL. If a standard HTTP request is
received, you can specify whether an error is raised or if the request
should be redirected to the HTTPS equivalent URL.

=head1 EXPORT

Exported methods:
    config_requiressl, mode_redirect


=head1 USAGE

=head2 run mode-level protection

run mode protection is specified by the RequireSSL attribute after the
method name:

    sub process_login :RequireSSL {
        my $self = shift;
    }

=head2 Module-level protection

You can protect a complete module by setting the 'require_ssl'
parameter in your instance script:

    use MyApp;
    my $webapp = MyApp->new(
        PARAMS => {require_ssl => 1}
    );
    $webapp->run();
    
=head2 Redirecting to a protected URL.

By default, an error is raised if a request is made to a protected
run mode or module using HTTP. However, you can specify that the request
is redirected to the HTTPS url by setting the rewrite_to_ssl parameter
as long as the requested method is not POST:

    my $webapp = MyApp->new(
        PARAMS => {rewrite_to_ssl => 1}
    );
    
=head2 Turning off checks.

If you need to turn off checks, simply set the ignore_check parameter
when configuring the plugin (see L</"config_requiressl"> below).


=head2 Reverting to HTTP

Once a successful request is made to a protected run mode or module, subsequent
requests to a non-protected run mode or module will revert to using HTTP.
To prevent this from happening, set the parameter keep_in_ssl in the
configuration
(see L</"config_requiressl"> below)

=cut

sub import {
    my $caller = scalar(caller);
    $caller->add_callback(init   => \&_add_runmodes);
    $caller->add_callback(prerun => \&_check_ssl);
    goto &Exporter::import;
}

sub CGI::Application::RequireSSL : ATTR(CODE, BEGIN, CHECK) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    if ($phase eq 'CHECK') {
        $SSL_RUN_MODES{*{$symbol}{NAME}}++;
    }
}

=head1 METHODS

=head2 config_requiressl

Optionally configure the plugin in your cgiapp_init method

    $self->config_requiressl(
        keep_in_ssl => 0,
        ignore_check => 0,
    )
    
Valid parameters are:

=over 4

=item * keep_in_ssl - if set, all subsequent requests following one to a
protected run mode or module will be via HTTPS.

=item * ignore_check - ignore SSL schecking. This is useful if your
application is deployed in an environment that doesn't support SSL.

=back

=cut

sub config_requiressl {
    my ($self, %args) = @_;

    foreach my $param (qw/ keep_in_ssl ignore_check/) {
        $self->{__PACKAGE__ . $param} = $args{$param} if $args{$param};
    }
}

=head2 mode_redirect

This is a run mode that will be automatically called if the request should
be redirected to the equivalent HTTP or HTTPS URL. You should not call it
directly.

=cut

sub mode_redirect {
    my $self     = shift;
    my $new_mode = $self->{__PACKAGE__ . 'new_mode'};
    croak "Cannot redirect from POST" if $self->query->request_method eq 'POST';
    my $new_url = $self->query->url(-base => 1);
    # Can't rely on -query option in case the query has been played with
    # prior to the redirect being invoked. Use the REQUEST_URI instead
    $new_url .= $ENV{REQUEST_URI} if $ENV{REQUEST_URI};
    if ($new_mode eq 'https') {
        $new_url =~ s/^http:/https:/;
    } else {
        $new_url =~ s/^https:/http:/;
    }
    $self->header_type('redirect');
    $self->header_add(-uri => $new_url);

    return ' ';
}

sub _add_runmodes {
    my $self = shift;
    $self->run_modes([qw/config_requiressl mode_redirect/]);
}

sub _check_ssl {
    my $self = shift;
    my $rm   = $self->get_current_runmode;

    unless ($self->{__PACKAGE__ . 'ignore_check'}) {

        # Process protection is either the module or the requested run mode
        # is protected
        if (($self->param('require_ssl') || $SSL_RUN_MODES{$rm})
            && !$self->query->https)
        {
            if ($self->param('rewrite_to_ssl')) {
                $self->{__PACKAGE__ . 'new_mode'} = 'https';
                return $self->prerun_mode('mode_redirect');
            } else {
                croak "https request required";
            }
        }

        # If a request is made using SSL, but we don't need it to be, then
        # redirect to the non-SSL page
        if (
            $self->query->https
            && !(
                   $self->{__PACKAGE__ . 'keep_in_ssl'}
                || $self->param('require_ssl')
                || $SSL_RUN_MODES{$rm}
            )
            )
        {
            $self->{__PACKAGE__ . 'new_mode'} = 'http';
            return $self->prerun_mode('mode_redirect');
        }
    }
}

=head1 AUTHOR

Dan Horne, C<< <dhorne at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-requiressl at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-RequireSSL>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 CAVEAT

This module been tested under the FastCGI persistent environment, but not under
mod_perl. The author would apprecaute feedback from anyone who is able to
test with that environment.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::RequireSSL

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-RequireSSL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-RequireSSL>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-RequireSSL>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-RequireSSL>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Users of the CGI::Application wiki (http://www.cgi-app.org) who requested
this module.

=item * Andy Grundman - I stole the idea of the keep_in_ssl parameter from his
L<Catalyst::Plugin::RequireSSL> module

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dan Horne, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of CGI::Application::Plugin::RequireSSL
