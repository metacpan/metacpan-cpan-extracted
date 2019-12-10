package App::ZofCMS::Plugin::GooglePageRank;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use WWW::Google::PageRank;
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_google_page_rank' }
sub _defaults {
    return (
        timeout => 20,
        agent   => 'Opera 9.6',
        host    => 'suggestqueries.google.com',
        cell    => 't',
        key     => 'plug_google_page_rank',
        # uri   => 'obtain from query',
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    if ( ref $conf->{uri} eq 'CODE' ) {
        $conf->{uri} = $conf->{uri}->( $t, $q, $config );
    }

    $conf->{uri} = 'http://' . $ENV{HTTP_HOST} . $ENV{REQUEST_URI}
        unless defined $conf->{uri}
            and length $conf->{uri};

    my $pr = WWW::Google::PageRank->new(
        timeout => $conf->{timeout},
        agent   => $conf->{agent},
        host    => $conf->{host},
    );

    if ( ref $conf->{uri} eq 'ARRAY' ) {
        for ( @{ $conf->{uri} } ) {
            unless ( m|https?://| ) {
                $_ = "http://$_";
            }

            my $rank = $pr->get($_);
            push @{ $t->{ $conf->{cell} }{ $conf->{key} } }, +{
                rank    => defined $rank ? $rank : 'N/A',
                uri     => $_,
            };
        }
    }
    else {
        unless ( $conf->{uri} =~ m|https?://| ) {
            $conf->{uri} = "http://$conf->{uri}";
        }
        my $rank = $pr->get( $conf->{uri} );
        $t->{ $conf->{cell} }{ $conf->{key} } = defined $rank ? $rank : 'N/A';
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::GooglePageRank - Plugin to show Google Page Ranks

=head1 SYNOPSIS

    plugins => [
        { GooglePageRank => 200 },
    ],

    # all defaults and URI is set to the current page
    plug_google_page_rank => {},

    # all options set
    plug_google_page_rank => {
        uri => 'zoffix.com',
        timeout => 20,
        agent   => 'Opera 9.6',
        host    => 'suggestqueries.google.com',
        cell    => 't',
        key     => 'plug_google_page_rank',
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to obtain Google Page Rank.
This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        qw/GooglePageRank/
    ],

B<Mangatory>. You need to add the plugin to list of plugins to execute.

=head2 C<plug_google_page_rank>

    plug_google_page_rank => {
        uri     => 'zoffix.com',
        timeout => 20,
        agent   => 'Opera 9.6',
        host    => 'suggestqueries.google.com',
        cell    => 't',
        key     => 'plug_google_page_rank',
    },

    plug_google_page_rank => {
        my ( $t, $q, $config ) = @_;
        return {
            uri     => 'zoffix.com',
            timeout => 20,
            agent   => 'Opera 9.6',
            host    => 'suggestqueries.google.com',
            cell    => 't',
            key     => 'plug_google_page_rank',
        };
    },

B<Mandatory>. Takes a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_google_page_rank> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object.
The C<plug_google_page_rank> first-level key can be set in either (or both)
ZofCMS Template and Main Config File files. If set in both, the values of keys that are set in
ZofCMS Template take precedence. Possible keys/values are as follows:

=head3 C<uri>

    uri => 'zoffix.com',

    uri => [
        'zoffix.com',
        'haslayout.net',
        'http://zofdesign.com',
    ],

    uri => sub {
        my ( $t, $q, $config ) = @_;
    },

B<Optional>. Takes a string, a coderef or an arrayref of strings each of which would specify
the page(s) for which to obtain Google Page Rank. If the value is a coderef, then it will
be exectued and its value will be assigned to C<uri>. The C<@_> will contain (in that order):
ZofCMS Template hashref, query parameters hashref, L<App::ZofCMS::Config> object.
B<Defaults to:> if not specified, then the URI of the current page will be calculated. Note
that this may depend on the server and is made up as:
C<< 'http://' . $ENV{HTTP_HOST} . $ENV{REQUEST_URI} >>

=head3 C<timeout>

    timeout => 20,

B<Optional>. Takes a positive integer as a value. Specifies a Page Rank request
timeout in seconds. B<Defaults to:> C<20>

=head3 C<agent>

    agent => 'Opera 9.6',

B<Optional>. Takes a string as a value that specifies the User-Agent string to use when
making the requests. B<Defaults to:> C<'Opera 9.6'>

=head3 C<host>

    host => 'suggestqueries.google.com',

B<Optional>. Specifies which google host to use for making requests.
B<Defaults to:> C<suggestqueries.google.com> (B<Note:> if all your queries failing try to set
this on to C<toolbarqueries.google.com>)

=head3 C<cell>

    cell => 't',

B<Optional>. Specifies the first-level key in ZofCMS Template hashref into which to store
the result. Must point to an C<undef> or a hashref. B<Defaults to:> C<t>

=head3 C<key>

    key => 'plug_google_page_rank',

B<Optional>. Specifies the second-level key inside C<cell> first-level key into which
to put the results. B<Defaults to:> C<plug_google_page_rank>

=head1 OUTPUT

Depending on whether the C<uri> argument was set to a string (or not set at all) or an
arrayref the output will be either a string indicating page's rank or an arrayref of
hashrefs - enabling you to use a simple C<< <tmpl_loop> >>, each of the hashrefs will contain two keys: C<rank> and C<uri> - the rank of
the page referenced by that URI.

If there was an error while obtaining the rank (i.e. request timeout) the rank will
be shown as string C<'N/A'>.

=head2 EXAMPLE DUMP 1

    plug_google_page_rank => {
        uri => [
            'zoffix.com',
            'haslayout.net',
            'http://zofdesign.com',
            'yahoo.com',
        ],
    },

    't' => {
        'plug_google_page_rank' => [
            {
                'rank' => '3',
                'uri' => 'http://zoffix.com'
            },
            {
                'rank' => '3',
                'uri' => 'http://haslayout.net'
            },
            {
                'rank' => '3',
                'uri' => 'http://zofdesign.com'
            },
            {
                'rank' => '9',
                'uri' => 'http://yahoo.com'
            }
        ]

=head2 EXAMPLE DUMP 2

    plug_google_page_rank => {
        uri => 'zoffix.com',
    },


    't' => {
        'plug_google_page_rank' => '3'
    }

=head2 EXAMPLE DUMP 3

    # URI became http://zcms/ which is a local address and not pageranked
    plug_google_page_rank => {},


    't' => {
        'plug_google_page_rank' => 'N/A'
    }

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