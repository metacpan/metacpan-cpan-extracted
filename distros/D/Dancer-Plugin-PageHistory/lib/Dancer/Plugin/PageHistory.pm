package Dancer::Plugin::PageHistory;

=head1 NAME

Dancer::Plugin::PageHistory - store recent page history for user into session

=head1 VERSION

Version 0.102

=cut

our $VERSION = '0.102';

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::PageHistory::PageSet;
use Dancer::Plugin::PageHistory::Page;
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

Adds a page via L<Dancer::Plugin::PageHistory::PageSet/add>. Both of
L<path|Dancer::Plugin::PageHistory::Page/path> and
L<query|Dancer::Plugin::PageHistory::Page/query> are optional arguments
which will be set automatically from the current request if they are not
supplied.

=head2 history

Returns the current L<Dancer::Plugin::PageHistory::PageSet> object from the
user's session.

=head1 SUPPORTED SESSION ENGINES

L<CHI|Dancer::Session::CHI>,
L<Cookie|Dancer::Session::Cookie>, 
L<DBIC|Dancer::Session::DBIC>,
L<JSON|Dancer::Session::JSON>,
L<Memcached|Dancer::Session::Memcached>,
L<Memcached::Fast|Dancer::Session::Memcached::Fast>,
L<MongoDB|Dancer::Session::MongoDB>,
L<PSGI|Dancer::Session::PSGI>,
L<Simple|Dancer::Session::Simple>,
L<Storable|Dancer::Session::Storable>,
L<YAML|Dancer::Session::YAML>

=head1 CAVEATS

L<Dancer::Session::Cookie> and L<Dancer::Session::PSGI> either don't handle
destroy at all or else do it wrong so I suggest you avoid those modules if
you want things like logout to work.

See L</TODO>.

=head1 CONFIGURATION

No configuration is necessarily required.

If you wish to have arguments passed to
L<Dancer::Plugin::PageHistory::PageSet/new> these can be added to your
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
L<Dancer::Plugin::PageHistory::PageSet/default_type> in the L</before> hook.

=item * ignore_ajax

If L</add_all_pages> is true this controls whether ajax requests are added to
the list L<Dancer::Plugin::PageHistory::PageSet/default_type> in the
L</before> hook.

Defaults to 0. Set to 1 to have ajax requests ignored.

=item * history_name

This setting can be used to change the name of the key used to store
the history object in the session from the default C<page_history> to
something else. This is also the key used for name of the token
containing the history object that is passed to templates and also the var
used to cache the history object during the request lifetime.

=back

=head1 HOOKS

This plugin makes use of the following hooks:

=head2 before

Add current page to history. See L</add_all_pages> and L</ignore_ajax>.

=cut

hook before => sub {
    my $conf = plugin_setting;
    return
      if ( !$conf->{add_all_pages}
        || ( $conf->{ignore_ajax} && request->is_ajax ) );
    add_to_history();
};

=head2 before_template_render

Puts history into the token C<page_history>.

=cut

hook before_template_render => sub {
    my $tokens = shift;
    my $name = plugin_setting->{history_name} || $history_name;
    $tokens->{$name} = history();
};

sub add_to_history {
    my $name = plugin_setting->{history_name} || $history_name;
    my ( $self, @args ) = plugin_args(@_);

    my $path  = request->path;
    my $query = params('query');

    my %args = (
        path  => $path,
        query => $query,
        @args,
    );

    debug "adding page to history: ", \%args;

    my $history = history();

    # add the page and save back to session with pages all unblessed
    $history->add( %args );
    session $name => unbless( $history->pages );
}

sub history {
    my $conf = plugin_setting;
    my $name = $conf->{history_name} || $history_name;
    my $history;

    if ( defined var($name) ) {
        $history = var($name);
    }
    else {

        my $session_history = session($name);
        $session_history = {} unless ref($session_history) eq 'HASH';

        my %args = $conf->{PageSet} ? %{ $conf->{PageSet} } : ();
        $args{pages} = $session_history;

        $history = Dancer::Plugin::PageHistory::PageSet->new(%args);
        var $name => $history;
    }

    return $history;
}

register add_to_history => \&add_to_history;

register history => \&history;

register_plugin;

=head1 TODO

=over

=item * Add more tests

=item * Add support for more session engines

=item * Create Dancer2 plugin

=item * investigate C<destroy> problems with L<Dancer::Session::Cookie>
and L<Dancer::Session::PSGI>

=back

=head1 AUTHOR

Peter Mottram (SysPete), "peter@sysnix.com"

=head1 BUGS

Please report any bugs or feature requests via the project's GitHub
issue tracker:

L<https://github.com/SysPete/Dancer-Plugin-PageHistory/issues>

I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes. PRs are always welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::PageHistory

You can also look for information at:

=over 4

=item * L<GitHub repository|https://github.com/SysPete/Dancer-Plugin-PageHistory>

=item * L<meta::cpan|https://metacpan.org/pod/Dancer::Plugin::PageHistory>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dancer::Plugin::PageHistory
