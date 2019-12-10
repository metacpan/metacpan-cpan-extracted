package App::ZofCMS::Plugin::ConditionalRedirect;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;
    return
        unless $template->{plug_redirect}
            or $config->conf->{plug_redirect};

    my $sub = delete $template->{plug_redirect} || delete $config->conf->{plug_redirect};

    my $uri = $sub->( $template, $query, $config );

    defined $uri
        or return;

    print $config->cgi->redirect($uri);
    exit;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::ConditionalRedirect - redirect users based on conditions

=head1 SYNOPSIS

In Main Config file or ZofCMS template:

    plugins => [ qw/ConditionalRedirect/ ],
    plug_redirect => sub { time() % 2 ? 'http://google.com/' : undef },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to redirect user to pages
depending on certain conditions, e.g. some key having a value in ZofCMS Template hashref or
anything else, really.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config>
and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    plugins => [ qw/ConditionalRedirect/ ],

    plugins => [ { UserLogin => 1000 }, { ConditionalRedirect => 2000 } ],

The obvious is that you'd want to stick this plugin into the list of plugins to be
executed. However, since functionality of this plugin can be easily implemented using
C<exec> and C<exec_before> special keys in ZofCMS Template, being able to set the
I<priority> to when the plugin should be run would probably one of the reasons for you
to use this plugin (it was for me at least).

=head2 C<plug_redirect>

    plug_redirect => sub {
        my ( $template_ref, $query_ref, $config_obj ) = @_;
        return $template_ref->{foo} ? 'http://google.com/' : undef;
    }

The C<plug_redirect> first-level key in Main Config file or ZofCMS Template takes a subref
as a value. The sub will be executed and its return value will determine where to redirect
(if at all). Returning C<undef> from this sub will B<NOT> cause any redirects at all. Returning
anything else will be taken as a URL to which to redirect and the plugin will call C<exit()>
after printing the redirect headers.

The C<@_> of the sub will receive the following: ZofCMS Template hashref, query parameters
hashref and L<App::ZofCMS::Config> object (in that order).

If you set C<plug_redirect> in both Main Config File and ZofCMS Template, the one in
ZofCMS Template will take precedence.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut