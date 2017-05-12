package App::ZofCMS::Plugin::GetRemotePageTitle;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use WWW::GetPageTitle;

sub _key {
    'plug_get_remote_page_title'
}
sub _defaults {
    ua => LWP::UserAgent->new(
        agent    => "Opera 9.5",
        timeout  => 30,
        max_size => 2000,
    ),
    uri => undef,
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    $conf->{uri} = $conf->{uri}->( $t, $q, $config )
        if ref $conf->{uri} eq 'CODE';

    return
        unless defined $conf->{uri}
            and length $conf->{uri};


    my $title = WWW::GetPageTitle->new( ua => $conf->{ua} );

    if ( ref $conf->{uri} eq 'ARRAY' ) {
        my @results;

        for ( @{ $conf->{uri} } ) {
            my $page_title = $title->get_title( $_ );

            if ( defined $page_title ) {
                push @results, { title => $page_title };
            }
            else {
                push @results, { error => $title->error };
            }

            $t->{t}{plug_remote_page_title} = \@results;
        }
    }
    else {
        my $page_title = $title->get_title( $conf->{uri} );
        if ( defined $page_title ) {
            $t->{t}{plug_remote_page_title} = $page_title;
        }
        else {
            $t->{t}{plug_remote_page_title_error} = $title->error;
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::GetRemotePageTitle - plugin to obtain page titles from remote URIs

=head1 SYNOPSIS

In ZofCMS Template or Main Config File:

    plugins => [
        qw/GetRemotePageTitle/
    ],

    plug_get_remote_page_title => {
        uri => 'http://zoffix.com',
    },

In HTML::Template file:

    <tmpl_if name='plug_remote_page_title_error'>
        <p class="error">Got error: <tmpl_var escape='html' name='plug_remote_page_title_error'></p>
    <tmpl_else>
        <p>Title: <tmpl_var escape='html' name='plug_remote_page_title'></p>
    </tmpl_if>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to get page titles from
remote URIs which can be utilized when automatically parsing URIs posted in coments, etc.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        qw/GetRemotePageTitle/
    ],

B<Mandatory>. You must specify the plugin in the list of plugins to execute.

=head2 C<plug_get_remote_page_title>

    plug_get_remote_page_title => {
        uri => 'http://zoffix.com',
        ua => LWP::UserAgent->new(
            agent    => "Opera 9.5",
            timeout  => 30,
            max_size => 2000,
        ),
    },

    plug_get_remote_page_title => sub {
        my ( $t, $q, $config ) = @_;
        return {
            uri => 'http://zoffix.com',
        };
    },

B<Mandatory>. Takes either a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_get_remote_page_title>
as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Possible keys/values for the hashref
are as follows:

=head3 C<uri>

    plug_get_remote_page_title => {
        uri => 'http://zoffix.com',
    }

    plug_get_remote_page_title => {
        uri => [
            'http://zoffix.com',
            'http://haslayout.net',
        ],
    }

    plug_get_remote_page_title => {
        uri => sub {
            my ( $t, $q, $config ) = @_;
            return 'http://zoffix.com';
        },
    }

B<Mandatory>. Specifies URI(s) titles of which you wish to obtain. The value can be either
a direct string, an arrayref or a subref. When value is a subref, its C<@_> will contain
(in that order): ZofCMS Template hashref, query parameters hashref and L<App::ZofCMS::Config>
object. The return value of the sub will be assigned to C<uri> argument as if it was already
there.

The single string vs. arrayref values affect the output format (see section below).

=head3 C<ua>

    plug_get_remote_page_title => {
        ua => LWP::UserAgent->new(
            agent    => "Opera 9.5",
            timeout  => 30,
            max_size => 2000,
        ),
    },

B<Optional>. Takes an L<LWP::UserAgent> object as a value; this object will be used for
fetching titles from the remote pages. B<Defaults to:>

    LWP::UserAgent->new(
        agent    => "Opera 9.5",
        timeout  => 30,
        max_size => 2000,
    ),

=head1 PLUGIN'S OUTPUT

    # uri argument set to a string
    <tmpl_if name='plug_remote_page_title_error'>
        <p class="error">Got error: <tmpl_var escape='html' name='plug_remote_page_title_error'></p>
    <tmpl_else>
        <p>Title: <tmpl_var escape='html' name='plug_remote_page_title'></p>
    </tmpl_if>


    # uri argument set to an arrayref
    <ul>
        <tmpl_loop name='plug_remote_page_title'>
        <li>
            <tmpl_if name='error'>
                Got error: <tmpl_var escape='html' name='error'>
            <tmpl_else>
                Title: <tmpl_var escape='html' name='title'>
            </tmpl_if>
        </li>
        </tmpl_loop>
    </ul>

Plugin will set C<< $t->{t}{plug_remote_page_title} >> (where C<$t> is ZofCMS Template
hashref) to either a string or an
arrayref when C<uri> plugin's argument is set to a string or arrayref respectively. Thus,
for arrayref values you'd use a C<< <tmpl_loop> >> plugins will use two variables
inside that loop: C<error> and C<title>; the C<error> variable will be present when
an error occured during title fetching. The C<title> will be the title of the URI. Order
for arrayrefs will be the same as the order in C<uri> argument.

If C<uri> argument was set to a single string, then C<{plug_remote_page_title}> will contain
the actual title of the page and C<{plug_remote_page_title_error}> will be set if an error
occured.

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