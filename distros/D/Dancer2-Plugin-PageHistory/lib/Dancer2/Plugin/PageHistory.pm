package Dancer2::Plugin::PageHistory;
use utf8;
use strict;
use warnings;

=encoding utf8

=head1 NAME

Dancer2::Plugin::PageHistory - store recent page history for user into session

=head1 VERSION

Version 0.210

=cut

our $VERSION = '0.210';

use Dancer2::Core::Types qw/Bool HashRef Str/;
use Dancer2::Plugin;
use Dancer2::Plugin::PageHistory::PageSet;
use Dancer2::Plugin::PageHistory::Page;
use Data::Structure::Util qw/unbless/;

my $history_name = 'page_history';

=head1 SYNOPSIS

    get '/product/:sku/:name' => sub {
        add_to_history(
            type       => 'product',
            title      => param('name'),
            attributes => { sku => param('sku') }
        );
    };

    hook 'before_template_render' => sub {
        my $tokens = shift;
        $tokens->{previous_page} = history->previous_page->uri;
    };

=head1 DESCRIPTION

The C<add_to_history> keyword which is exported by this plugin allows you to 
add interesting items to the history lists which are returned using the
C<history> keyword.

=head1 KEYWORDS

=head2 add_to_history

Adds a page via L<Dancer2::Plugin::PageHistory::PageSet/add>. Both of
L<path|Dancer2::Plugin::PageHistory::Page/path> and
L<query_string|Dancer2::Plugin::PageHistory::Page/query_string> are optional
arguments
which will be set automatically from the current request if they are not
supplied.

=head2 history

Returns the current L<Dancer2::Plugin::PageHistory::PageSet> object from the
user's session.

=head1 SUPPORTED SESSION ENGINES

L<CGISession|Dancer2::Session::CGISession>,
L<Cookie|Dancer2::Session::Cookie>, 
L<DBIC|Dancer2::Session::DBIC>,
L<JSON|Dancer2::Session::JSON>,
L<Memcached|Dancer2::Session::Memcached>,
L<MongoDB|Dancer2::Session::MongoDB>,
L<PSGI|Dancer2::Session::PSGI>,
L<Redis|Dancer2::Session::Redis>,
L<Sereal|Dancer2::Session::Sereal>,
L<Simple|Dancer2::Session::Simple>,
L<YAML|Dancer2::Session::YAML>

=head1 CONFIGURATION

No configuration is necessarily required.

If you wish to have arguments passed to
L<Dancer2::Plugin::PageHistory::PageSet/new> these can be added to your
configuration along with configuration for the plugin itself, e.g.:

    plugins:
      PageHistory:
        add_all_pages: 1
        ingore_ajax: 1 
        history_name: someothername
        PageSet:
          default_type: all
          fallback_page:
            path: "/"
          max_items: 20
          methods:
            - default
            - product
            - navigation
 
Configuration options for the plugin itself:

=over

=item * add_all_pages

Defaults to 0. Set to 1 to have all pages added to the list
L<Dancer2::Plugin::PageHistory::PageSet/default_type> in the L</before> hook.

=item * ignore_ajax

If L</add_all_pages> is true this controls whether ajax requests are added to
the list L<Dancer2::Plugin::PageHistory::PageSet/default_type> in the
L</before> hook.

Defaults to 0. Set to 1 to have ajax requests ignored.

=item * history_name

This setting can be used to change the name of the key used to store
the history object in the session from the default C<page_history> to
something else. This is also the key used for name of the token
containing the history object that is passed to templates.

=back

=head1 HOOKS

This plugin makes use of the following hooks:

=head2 before

Add current page to history. See L</add_all_pages> and L</ignore_ajax>.

=head2 before_template_render

Puts history into the token C<page_history>.

=cut

has add_all_pages => (
    is          => 'ro',
    isa         => Bool,
    from_config => sub { 0 },
);

has ignore_ajax => (
    is          => 'ro',
    isa         => Bool,
    from_config => sub { 0 },
);

has history_name => (
    is          => 'ro',
    isa         => Str,
    from_config => sub { 'page_history' },
);

has page_set_args => (
    is          => 'ro',
    isa         => HashRef,
    from_config => 'PageSet',
    default     => sub { +{} },
);

plugin_keywords 'add_to_history', 'history';

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {

                return
                  if ( !$plugin->add_all_pages
                    || (   $plugin->ignore_ajax
                        && $plugin->app->request->is_ajax ) );

                $plugin->add_to_history;
            },
        )
    );

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                my $tokens = shift;
                $tokens->{$plugin->history_name} = $plugin->history;
            },
        )
    );
};

sub add_to_history {
    my ( $plugin, @args ) = @_;

    my $history = $plugin->history;

    $history->add( request => $plugin->app->request, @args );

    $plugin->app->session->write(
        $plugin->history_name => unbless( $history->pages ) );
}

sub history {
    my $plugin = shift;

    return Dancer2::Plugin::PageHistory::PageSet->new(
        %{ $plugin->page_set_args },
        pages => $plugin->app->session->read( $plugin->history_name ) || {},
    );
}

=head1 TODO

=over

=item * Add more tests

=back

=head1 AUTHOR

Peter Mottram (SysPete), C<< <peter@sysnix.com> >>

=head1 CONTRIBUTORS

 Slaven Rezić (eserte) - GH issues #1, #2, #3
 Andreas J. König (andk) - GH issue #4

=head1 BUGS

Please report any bugs or feature requests via the project's GitHub
issue tracker:

L<https://github.com/SysPete/Dancer2-Plugin-PageHistory/issues>

I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes. PRs are always welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::PageHistory

You can also look for information at:

=over 4

=item * L<GitHub repository|https://github.com/SysPete/Dancer2-Plugin-PageHistory>

=item * L<meta::cpan|https://metacpan.org/pod/Dancer2::Plugin::PageHistory>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dancer2::Plugin::PageHistory
