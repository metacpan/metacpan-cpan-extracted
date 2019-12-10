package App::ZofCMS::Plugin::BasicLWP;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use LWP::UserAgent;
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_basic_lwp' }

sub _defaults {
    return (
        t_name  => 'plug_basic_lwp',
        t_key   => 'd',
        decoded => 0,
        uri_fix => 0,
        ua_args => [
            agent   => 'Opera 9.2',
            timeout => 30,
        ],
        # uri     => 'http://google.com/',
    );
}

sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;

    if ( ref $conf->{uri} eq 'CODE' ) {
        $conf->{uri} = $conf->{uri}->( $template, $query, $config );
    }

    return
        unless defined $conf->{uri};

    if ( $conf->{uri_fix} ) {
        $conf->{uri} = "http://$conf->{uri}"
            unless $conf->{uri} =~ m{^(ht|f)tp://}i;
    }

    my ( $t_name, $t_key ) = @$conf{ qw/t_name t_key/ };

    my $ua = LWP::UserAgent->new( @{ $conf->{ua_args} || [] } );
    my $response = $ua->get( $conf->{uri} );
    unless ( $response->is_success ) {
        $template->{ $t_key }{ $t_name . '_error' } = $response->status_line;
        return;
    }

    $template->{ $t_key }{ $t_name } = $conf->{decoded}
                                     ? $response->decoded_content
                                     : $response->content;

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::BasicLWP - very basic "uri-to-content" style LWP plugin for ZofCMS.

=head1 SYNOPSIS

In your ZofCMS Template or Main Config File:

    plugins => [ qw/BasicLWP/ ],
    plug_basic_lwp => {
        t_key   => 't',
        uri     => 'http://zofdesign.com/'
    },

In your L<HTML::Template> template:

    <div id="funky_iframe">
        <tmpl_if name='plug_basic_lwp_error'>
            <p>Error fetching content: <tmpl_var name='plug_basic_lwp_error'></p>
        <tmpl_else>
            <tmpl_var name='plug_basic_lwp'>
        </tmpl_if>
    </div>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides basic functionality to fetch a random
URI with L<LWP::UserAgent> and stick the content into ZofCMS Template hashref.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/BasicLWP/ ],

You need to add the plugin to the list of plugins to execute. Since you are likely to work
on the fetched data, make sure to set correct priorities.

=head2 C<plug_basic_lwp>

    plug_basic_lwp => {
        uri     => 'http://zofdesign.com/', # everything but 'uri' is optional
        t_name  => 'plug_basic_lwp',
        t_key   => 'd',
        decoded => 0,
        fix_uri => 0,
        ua_args => [
            agent   => 'Opera 9.2',
            timeout => 30,
        ],
    }

The plugin won't run unless C<plug_basic_lwp> first-level key is present either in Main
Config File or ZofCMS Template. Takes a hashref or a subref as a value. If subref is
specified,
its return value will be assigned to C<plug_basic_lwp> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. If the same keys are specified
in both Main Config File and ZofCMS Template, then the value set in ZofCMS template will
take precedence. The possible keys/values of that hashref are as follows:

=head3 C<uri>

    uri => 'http://zofdesign.com/',

    uri => sub {
        my ( $template, $query, $config ) = @_;
        return $query->{uri_to_fetch};
    }

    uri => URI->new('http://zofdesign.com/');

B<Mandatory>. Takes a string, subref or L<URI> object as a value. Specifies the URI to fetch.
When value is a subref that subref will be executed and its return value will be given to
C<uri> argument. Subref's C<@_> will contain the following (in that order): ZofCMS Template hashref, hashref of query parameters and L<App::ZofCMS::Config> object. B<Plugin will stop>
if the C<uri> is undefined; that also means that you can return an C<undef> from your subref
to stop processing.

=head3 C<t_name>

    t_name => 'plug_basic_lwp',

B<Optional>. See also C<t_key> parameter below.
Takes a string as a value. This string represents the name of the key in
ZofCMS Template where to put the fetched content (or error). B<Note:> the errors will
be indicated by C<$t_name . '_error'> L<HTML::Template> variable, where C<$t_name> is the value
of C<t_name> argument.
See SYNOPSIS for examples. B<Defaults to:> C<plug_basic_lwp> (and
the errors will be in C<plug_basic_lwp_error>

=head3 C<t_key>

    t_key => 'd',

B<Optional>. Takes a string as a value. Specifies the name of B<first-level> key in ZofCMS
Template hashref in which to create the C<t_name> key (see above). B<Defaults to:> C<d>

=head3 C<decoded>

    decoded => 0,

B<Optional>. Takes either true or false values as a value. When set to a I<true> value,
the content will be given us with C<decoded_content()>. When set to a I<false> value, the
content will be given us with C<content()> method. See L<HTTP::Response> for description
of those two methods. B<Defaults to:> C<0> (use C<content()>)

=head3 C<fix_uri>

    fix_uri => 0,

B<Optional>. Takes either true or false values as a value. When set to a true value, the
plugin will try to "fix" URIs that would cause LWP to crap out with "URI must be absolute"
errors. When set to a false value, will attempt to fetch the URI as it is. B<Defaults to:>
C<0> (fixing is disabled)

B<Note:> the "fixer" is not that smart, here's the code; feel free not to use it :)

    $uri = "http://$uri"
        unless $uri =~ m{^(ht|f)tp://}i;

=head3 C<ua_args>

    ua_args => [
        agent   => 'Opera 9.2',
        timeout => 30,
    ],

B<Optional>. Takes an arrayref as a value. This arrayref will be directly dereference into
L<LWP::UserAgent> contructor. See L<LWP::UserAgent>'s documentation for possible values.
B<Defaults to:>

    [
        agent   => 'Opera 9.2',
        timeout => 30,
    ],

=head1 HTML::Template VARIABLES

The code below assumes default values for C<t_name> and C<t_key> arguments (see C<plug_basic_lwp> hashref keys' description).

    <tmpl_if name='plug_basic_lwp_error'>
        <p>Error fetching content: <tmpl_var name='plug_basic_lwp_error'></p>
    <tmpl_else>
        <tmpl_var name='plug_basic_lwp'>
    </tmpl_if>

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