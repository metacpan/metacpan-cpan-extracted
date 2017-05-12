package App::ZofCMS::Plugin::StyleSwitcher;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use DBI;

sub _key { 'plug_style_switcher' }
sub _defaults {
    return (
        q_name                  => 'style',
        q_ajax_name             => 'plug_style_switcher_ajax',
        t_prefix                => 'style_switcher_',
        table                   => 'style_switcher',
        max_time                => 2678400, # one month
        default_style           => 'main',
        xhtml                   => 0,
        # styles => {}
        dsn                     => "DBI:mysql:database=test;host=localhost",
        #user                    => 'test',
        #pass                    => 'test',
        create_table            => 0,
        opt                     => { RaiseError => 1, AutoCommit => 1 },
    );
}
sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;

    my $dbh = DBI->connect_cached(
        @$conf{ qw/dsn user pass opt/ },
    );
    $self->dbh( $dbh );

    if ( $conf->{create_table} ) {
        $dbh->do(
            "CREATE TABLE $conf->{table} ( host VARCHAR(200), style TEXT, time VARCHAR(10) );",
        );
    }

    if ( defined $query->{ $conf->{q_name} }
        and length $query->{ $conf->{q_name} }
    ) {
        $self->_set_style( $conf, $config->cgi, $query->{ $conf->{q_name} } );
    }

    my $style = $self->_get_current_style( $conf, $config->cgi );

    my $tp = $conf->{t_prefix};
    $template->{t}{ $tp . 'style'  } = $self->_make_style_html( $conf, $style );
    $template->{t}{ $tp . 'toggle' } = $self->_make_toggle_html(
        $conf,
        map +(defined() ? $_ : ''), @$query{qw/page dir/},
        $style,
    );
    $dbh->disconnect;

    print "Set-Cookie: plug_style_switcher=$style\n";

    if ( $query->{ $conf->{q_ajax_name} } ) {
        print "Content-type: text/plain\n\n";
        exit;
    }
}

sub _make_toggle_html {
    my ( $self, $conf, $page, $dir, $style ) = @_;
    my $styles_ref = $conf->{styles};

    my $next;
    my $last;
    for ( sort keys %$styles_ref ) {
        $next = $_
            unless defined $next;
        if ( defined $last and $last eq $style ) {
            $next = $_;
            last;
        }
        $last = $_;
    }

    return qq|<a id="plug_style_switcher" |
            . qq|href="/index.pl?page=$page&dir=$dir&$conf->{q_name}=$next">|
            . qq|toggle style</a>\n|;
}

sub _make_style_html {
    my ( $self, $conf, $style ) = @_;
    my $styles_ref = $conf->{styles};
    my $ending = $conf->{xhtml} ? '/' : '';

    my @out;
    for my $key ( sort keys %$styles_ref ) {
        my $rel = $key eq $style ? 'stylesheet' : 'alternate stylesheet';

        my $styles = $styles_ref->{ $key };
        $styles = [ $styles ]
        unless ref $styles eq 'ARRAY';
        for my $style ( @$styles ) {
            if ( '[IE]' eq substr $style, 0, 4 ) {
                $style = substr $style, 0, 4;
                push @out,
                    qq|<!--[if IE]><link rel="$rel" type="text/css" href="$style" media="screen,tv,projection"$ending><![endif]-->|;
            }
            else {
                push @out,
                    qq|<link rel="$rel" type="text/css" href="$style" media="screen,tv,projection"$ending>|;
            }
        }
    }

    return join "\n", @out;
}

sub _set_style {
    my ( $self, $conf, $cgi, $style ) = @_;
    my $host = $self->_make_host( $cgi );

    $style = $conf->{default_style}
         unless exists $conf->{styles}{ $style };

    my $dbh = $self->dbh;
    $dbh->do(
        "DELETE FROM $conf->{table} WHERE host = ? OR time < ?;",
        undef,
        $host,
        time() - $conf->{max_time},
    );

    $dbh->do(
        "INSERT INTO $conf->{table} VALUES (?, ?, ?);",
        undef,
        $host,
        $style,
        time(),
    );
}


sub _get_current_style {
    my ( $self, $conf, $cgi ) = @_;

    my $host = $self->_make_host( $cgi );
    my $user_style = $self->dbh->selectall_arrayref(
        "SELECT * FROM $conf->{table} WHERE host = ?;",
        { Slice => {} },
        $host,
    );

    $self->dbh->do(
        "UPDATE $conf->{table} SET time = ? WHERE host = ?;",
        undef,
        time(),
        $host,
    );

    return $conf->{default_style}
        unless @$user_style;

    return $user_style->[0]{style};
}

sub _make_host {
    my ( $self, $cgi ) = @_;
    my $host = $cgi->remote_host . $ENV{HTTP_USER_AGENT};
    $host =~ s/[^\w.]+//g;
    $host = substr $host, 0, 200;
    return $host;
}

sub dbh {
    my $self = shift;
    @_ and $self->{DBH} = shift;
    return $self->{DBH};
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::StyleSwitcher - CSS Style switcher plugin

=head1 SYNOPSIS

In your ZofCMS template but most likely in your Main Config File:

    plugins => [ qw/StyleSwitcher/ ],
    plug_style_switcher => {
        dsn                     => "DBI:mysql:database=test;host=localhost",
        user                    => 'test',
        pass                    => 'test',
        opt                     => { RaiseError => 1, AutoCommit => 1 },
        styles => {
            main => 'main.css',
            alt  => [ 'alt.css', '[IE]alt_ie.css' ],
        },
    },

In your L<HTML::Template> template:

    <head>
        <tmpl_var name="style_switcher_style">
    ...

    <body>
        <tmpl_var name="style_switcher_toggle">
    ....

=head1 DESCRIPTION

The module provides means to have what is known as "Style Switcher" thingie on your webpages.
In other words, having several CSS stylesheets per website.

The L<http://alistapart.com/stories/alternate/> describes the concept in more detail. It
also provides JavaScript based realization of the idea; this plugin does not rely on
javascript at all.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/StyleSwitcher/ ],

You need to include the plugin in the list of plugins to execute.

=head2 C<plug_style_switcher>

    plug_style_switcher => {
        dsn                     => "DBI:mysql:database=test;host=localhost",
        user                    => 'test',
        pass                    => 'test',
        opt                     => { RaiseError => 1, AutoCommit => 1 },
        create_table            => 0,
        q_name                  => 'style',
        q_ajax_name             => 'plug_style_switcher_ajax',
        t_prefix                => 'style_switcher_',
        table                   => 'style_switcher',
        max_time                => 2678400, # one month
        default_style           => 'main',
        xhtml                   => 0,
        # styles => {}
        styles => {
            main => 'main.css',
            alt  => [ 'alt.css', '[IE]alt_ie.css' ],
        },
    },

    plug_style_switcher => sub {
        my ( $t, $q, $config ) = @_;
        return {
            dsn                     => "DBI:mysql:database=test;host=localhost",
            user                    => 'test',
            pass                    => 'test',
        }
    },

The plugin reads it's configuration from L<plug_style_switcher> first-level ZofCMS Template
or Main Config file template. Takes a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_style_switcher>
as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Keys that are set in ZofCMS Template will override same
ones that are set in Main Config file. Considering that you'd want the CSS style settings
to be set on an entire site, it only makes sense to set this plugin up in your Main Config
file.

=head3 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>.
The plugin needs access to an SQL database supported by L<DBI> module. The C<dsn> key takes
a scalar as a value that contains the DSN for your database. See L<DBI> for details.

=head3 C<user> and C<pass>

    user => 'test',
    pass => 'test',

B<Mandatory>. The C<user> and C<pass> arguments specify the user name (login) and password
for your database.

=head3 C<opt>

    opt => { RaiseError => 1, AutoCommit => 1 },

B<Optional>. The C<opt> key takes a hashref as a value. This hashref will be directly
passed as "additional arguments" to L<DBI>'s C<connect_cached()> method. See L<DBI> for
details. B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 1 }, >>

=head3 C<table>

    table => 'style_switcher',

B<Optional>. Specifies the name of the table in which to store the style-user data.
B<Defaults to:> C<style_switcher>

=head3 C<create_table>

    create_table => 0,

B<Optional>. Takes either true or false values. B<Defaults to:> C<0> (false). When set to
a true value plugin will automatically create the SQL tables that is needed for the plugin.
Just set it to a true value, load any page that calls the plugin, and remove this setting.
Alternatively you can create the table yourself:
C<< CREATE TABLE style_switcher ( host VARCHAR(200), style TEXT, time VARCHAR(10) ); >>

=head3 C<q_name>

    q_name => 'style',

B<Optional>. Takes a string as a value that must contain the name of the query parameter
that will contain the name of the style to "activate". B<Defaults to:> C<style>

=head3 C<q_ajax_name>

    q_ajax_name => 'plug_style_switcher_ajax',

B<Optional>. Some of you may want to change styles with JS along with keeping style information
server-side. For this plugin supports the C<q_ajax_name>, it must contain the name of
a query parameter which you'd pass with your Ajax call (sorry to those who really dislike
calling it Ajax). The value of this parameter needs to be a true value. When plugin will see
this query parameter set to a true value, it will set the style (based on the value of
the query parameter referenced by C<q_name> plugin setting; see above) and will simply exit.
B<Defaults to:> C<plug_style_switcher_ajax>

=head3 C<t_prefix>

    t_prefix => 'style_switcher_',

B<Optional>. The plugin sets two keys in ZofCMS Template C<{t}> special key. The C<t_prefix>
takes a string as a value; that string will be prefixed to those two keys that are set.
See C<HTML::Template VARIABLES> section below for imformation on those two keys.
B<Defaults to:> C<style_switcher_> (note the underscore (C<_>) at the end).

=head3 C<max_time>

    max_time => 2678400, # one month

B<Optional>. Takes a positive integer as a value that indicates how long (in seconds) to
keep the style information for the user. The time is updated every time the user accesses
the plugin. The plugin identifies the "user" by contatenating user's C<User-Agent> HTTP
header and his/her/its host name. Note that old entries are deleted only when someone sets the
style; in other words, if you set C<max_time> to one month and no one ever changes their style
and that user comes back after two month the setting will be preserved.
B<Defaults to:> C<2678400> (one month)

=head3 C<default_style>

    default_style => 'main',

B<Optional>. Takes a string as a value that must be one of the keys in C<styles> hashref
(see below). This will be the "default" style. In other words, if the plugin does not
find the particular user in the database it will make the C<default_style> style active.

=head3 C<xhtml>

    xhtml => 0,

B<Optional>. Takes either true or false values. When set to a true value will close
C<< <link> >> elements with an extra C</> to keep it XHTML friendly. B<Defaults to>: C<0>

=head3 C<styles>

    styles => {
        main => 'main.css',
        alt  => [ 'alt.css', '[IE]alt_ie.css' ],
    },

B<Mandatory>. Takes a hashref as a value. The keys of a that hashref are the names of your
styles. The name of the key is what you'd pass as a value of a query parameter indicated by
plugin's C<q_name> parameter. The value can be either a string or an arrayref. If the value
is a string then it will be converted into an arrayref with just that element in it. Each
element of that arrayref will be converted into a C<< <link> >> element where the C<href="">
attribute will be set to that element of the arrayref. Each element can contain string
C<[IE]> (including the square brackets) as the first four characters, in that case
the C<href=""> will be wrapped in C<< <!--[if IE]> >> conditional comments (if you don't
know what those are, see: L<http://haslayout.net/condcom>).

=head1 HTML::Template VARIABLES

Note: examples include the default C<t_prefix> in names of C<< <tmpl_var> >>s.

=head2 C<style>


    <tmpl_var name="style_switcher_style">

The C<style> variable will contain appropriate C<< <link> >> elements. You'd want to put
this variable somewhere in HTML C<< <head> >>

=head2 C<toggle>

    <tmpl_var name="style_switcher_toggle">

The C<toggle> variable will contain a style toggle link. By clicking this link user can load
the next style (sorted alphabetically by its name). You don't have to use this one and
write your own instead.

=head1 SEE ALSO

L<http://alistapart.com/stories/alternate/>

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