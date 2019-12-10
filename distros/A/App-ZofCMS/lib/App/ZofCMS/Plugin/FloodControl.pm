package App::ZofCMS::Plugin::FloodControl;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use DBI;
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_flood_control' }
sub _defaults {
    return (
#        dsn     => "DBI:mysql:database=test;host=localhost",
#        user    => 'test',
#        pass    => 'test',
        create_table    => 0,
        opt             => { RaiseError => 1, AutoCommit => 1 },
        limit           => 2,
        run             => 1,
        timeout         => 600,
        table           => 'flood_control',
        trigger         => 'plug_flood',
        t_key           => 'plug_flood',
        cell            => 'q',
        flood_id        => 'flood',
    );
}
sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;

    unless ( $conf->{run} ) {
        my ( $cell, $trigger ) = @$conf{ qw/cell trigger/ };
        if ( $cell eq 'q' ) {
            return
                unless defined $query->{ $trigger }
                    and length $query->{ $trigger };
        }
        elsif ( $cell eq 't' or $cell eq 'd' ) {
            return unless $template->{ $cell }{ $trigger };
        }
        elsif ( $cell eq '' ) {
            return unless $template->{ $trigger };
        }
    }

    my $host = $config->cgi->remote_host;
    $host = substr $host, 0, 250;

    my $dbh = DBI->connect_cached(
        @$conf{ qw/dsn user pass opt/ }
    );

    if ( $conf->{create_table} ) {
        $dbh->do(
            "CREATE TABLE $conf->{table} (host TEXT, time VARCHAR(10), id VARCHAR(5));",
        );
    }

    $dbh->do(
        "DELETE FROM $conf->{table} WHERE time < ? AND id = ?;",
        undef,
        time() - $conf->{timeout},
        $conf->{flood_id},
    );

    my $entries = $dbh->selectall_arrayref(
        "SELECT * FROM $conf->{table} WHERE host = ? AND id = ?;",
        { Slice => {} },
        $host,
        $conf->{flood_id},
    );

    if ( @{ $entries || [] } >= $conf->{limit} ) {
        $template->{t}{ $conf->{t_key} } = 1;
        if ( $conf->{flood_code} ) {
            $conf->{flood_code}( $template, $query, $config );
        }
    }
    else {
        $dbh->do(
            "INSERT INTO $conf->{table} VALUES(?, ?, ?);",
            undef,
            $host,
            time(),
            $conf->{flood_id},
        );
        if ( $conf->{no_flood_code} ) {
            $conf->{no_flood_code}( $template, $query, $config );
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FloodControl - plugin for protecting forms and anything else from floods (abuse)

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template file:

    plug_flood_control => {
        dsn             => "DBI:mysql:database=test;host=localhost",
        user            => 'test',
        pass            => 'test',
        # everything below is optional
        opt             => { RaiseError => 1, AutoCommit => 1 },
        create_table    => 0,
        limit           => 2,
        timeout         => 600,
        table           => 'flood_control',
        run             => 0,
        trigger         => 'plug_flood',
        cell            => 'q',
        t_key           => 'plug_flood',
        flood_id        => 'flood',
        flood_code      => sub {
            my ( $template, $query, $config ) = @_;
            kill_damn_flooders();
        },
        no_flood_code   => sub {
            my ( $template, $query, $config ) = @_;
            hug_the_user();
        },
    }

In your L<HTML::Template> Template:

    <tmpl_if name='plug_flood'>
        STOP FLOODING, ASSHOLE!
    <tmpl_else>
        <form ....
        .../form>
    </tmpl_if>

Plugin needs an SQL table to operate. You can either create it by hand or set the
C<create_table> option to a true value once so plugin could create the table automatically.
The needed table needs to have these three columns:

    CREATE TABLE flood_table (host VARCHAR(250), time VARCHAR(10), id VARCHAR(5));

The value type of the C<id> column can be different depending on what C<flood_id> arguments
you'd use (see docs below for more).

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to detect flood (abuse) and
react accordingly depending on whether or not flood was detected.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/FloodControl/ ],

You obviously need to the add the plugin in the list of plugins to execute. Along with this
plugin you would probably want to use something like L<App::ZofCMS::Plugin::FormChecker>
and L<App::ZofCMS::Plugin::DBI>

=head2 C<plug_flood_control>

    plug_flood_control => {
        dsn             => "DBI:mysql:database=test;host=localhost",
        user            => 'test',
        pass            => 'test',
        # everything below is optional
        opt             => { RaiseError => 1, AutoCommit => 1 },
        create_table    => 0,
        limit           => 2,
        timeout         => 600,
        table           => 'flood_control',
        run             => 0,
        trigger         => 'plug_flood',
        cell            => 'q',
        t_key           => 'plug_flood',
        flood_id        => 'flood',
        flood_code      => sub {
            my ( $template, $query, $config ) = @_;
            kill_damn_flooders();
        },
        no_flood_code   => sub {
            my ( $template, $query, $config ) = @_;
            hug_the_user();
        },
    }

    plug_flood_control => sub {
        my ( $t, $q, $config ) = @_;
        return {
            dsn             => "DBI:mysql:database=test;host=localhost",
            user            => 'test',
            pass            => 'test',
        };
    }

Plugin uses C<plug_flood_control> first-level key that can be specified in either (or both)
Main Config File or ZofCMS Template file. The key takes a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_flood_control> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. If the keys of
that hashref are specified in both files will take their values from ZofCMS Template.
Most of these keys are optional with sensible defaults. Possible keys/values are as follows:

=head3 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. Specifies the "DSN" for L<DBI> module. See L<DBI>'s docs for C<connect_cached()>
method for more info on this one.

=head3 C<user>

    user => 'test',

B<Mandatory>. Specifies your username for the SQL database.

=head3 C<pass>

    pass => 'test',

B<Mandatory>. Specifies your password for the SQL database.

=head3 C<opt>

    opt => { RaiseError => 1, AutoCommit => 1 },

B<Optional>. Takes a hashref as a value. Specifies the additional options for L<DBI>'s
C<connect_cached()> method. See L<DBI>'s docs for C<connect_cached()>
method for more info on this one. B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<table>

    table => 'flood_control',

B<Optional>. Takes a string as a value that represents the name of the table in which to
store flood data. B<Defaults to:> C<flood_control>

=head3 C<create_table>

    create_table => 0,

B<Optional>. Takes either true or false values. When set to a true value will automatically
create the table that is needed for the plugin. You can create the table manually, its
format is described in the C<SYNOPSIS> section above. B<Defaults to:> C<0>

=head3 C<limit>

    limit => 2,

B<Optional>. Specifies the "flood limit". Takes a positive integer value that
is the number of times the plugin will be
triggered in C<timeout> (see below) seconds before it will think we are being abused.
B<Defaults to:> C<2>

=head3 C<timeout>

    timeout => 600,

B<Optional>. Takes a positive integer value. Specifies timeout in seconds after which
the plugin will forget that a certain user triggered it. In other words, if the plugin is
triggered when someone submits the form and C<timeout> is set to C<600> and C<limit> is set
to C<2> then the user would be able to submit the form only twice every 10 minutes.
B<Defaults to:> C<600>

=head3 C<trigger>

    trigger => 'plug_flood',

B<Optional>. Takes a string as a value that names the key in a C<cell> (see below).
Except for when the C<cell> is set to C<q>, the value referenced by the key must contain
a true value in order for the plugin to trigger (to run). B<Defaults to:> C<plug_flood>

=head3 C<cell>

    cell => 'q',

B<Optional>. The plugin can be triggered either from query, C<{t}> special key, C<{d}>
ZofCMS Template special key, or any first-level ZofCMS Template key (also, see C<run>
option below). The value of the C<cell> key specifies where the plugin will look for the
C<trigger> (see above). Possible values for C<cell> key are: C<q> (query), C<d> (C<{d}> key),
C<t> (C<{t}> key) or empty string (first-level ZofCMS Template key). For every C<cell> value
but the C<q>, the trigger (i.e. the key referenced by the C<trigger> argument) must be set
to a true value in order for the plugin to trigger. When C<cell> is set to value C<q>, then
the query parameter referenced by C<trigger> must have C<length()> in order for the plugin
to trigger. B<Defaults to:> C<q>

=head3 C<run>

    run => 0,

B<Optional>. An alternative to using C<cell> and C<trigger> arguments you can set
(e.g. dynamically with some other plugin) the C<run> argument to a true value. Takes
either true or false values. When set to a true value plugin will "trigger" (check for floods)
without any consideration to C<cell> and C<trigger> values. B<Defaults to:> C<0>

=head3 C<t_key>

    t_key => 'plug_flood',

B<Optional>. If plugin sees that the user is flooding, it will set C<t_key> in ZofCMS Template
C<{t}> special key. Thus you can display appropriate messages using C<< <tmpl_if name=""> >>.
B<Defaults to:> C<plug_flood>

=head3 C<flood_id>

    flood_id => 'flood',

B<Optional>. You can use the same table to control various pages or forms from flood
independently by setting C<flood_id> to different values for each of them. B<Defaults to:>
C<flood>

=head3 C<flood_code>

    flood_code => sub {
        my ( $template, $query, $config ) = @_;
        kill_damn_flooders();
    },

B<Optional>. Takes a subref as a value. This sub will be run if plugin thinks that the user
is flooding. The C<@_> will contain (in that order) ZofCMS Template hashref, query parameters
hashref where keys are params' names and values are their values and L<App::ZofCMS::Config>
object. B<By default> is not specified.

=head3 C<no_flood_code>

    no_flood_code   => sub {
        my ( $template, $query, $config ) = @_;
        hug_the_user();
    },

B<Optional>. Takes a subref as a value. This is the opposite of C<flood_code>.
This sub will be run if plugin thinks that the user
is B<NOT> flooding.
The C<@_> will contain (in that order) ZofCMS Template hashref, query parameters
hashref where keys are params' names and values are their values and L<App::ZofCMS::Config>
object. B<By default> is not specified.

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