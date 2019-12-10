package App::ZofCMS::Plugin::Session;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use Storable (qw/freeze thaw/);
use DBI;

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my %conf = (
        #dsn     => "DBI:mysql:database=test;host=localhost",
        user            => 'root',
        pass            => undef,
        opt             => { RaiseError => 1, AutoCommit => 1 },
        table           => 'session',
        create_table    => 0,
        cookie_name     => 'plug_session_id',
        cookie_expiry   => '+24h',
        auto            => 1,
        cell            => 'd',
        key             => 'session',
        no_op           => 0,
        no_load         => 0,
        no_save         => 0,
        session_expiry  => 86400, # 24 hours
        %{ $config->conf->{plug_session} || {} },
        %{ $template->{plug_session} || {} },
    );

    return
        if $conf{no_op};

    my $dbh = DBI->connect_cached(
        @conf{ qw/dsn user pass opt/ }
    );

    if ( $conf{create_table} ) {
        $dbh->do(
            "CREATE TABLE `$conf{table}` (
                `id`      TEXT,
                `time`    VARCHAR(10),
                `data`    TEXT
            );",
        );
    }

    my $session_id = $config->cgi->cookie( $conf{cookie_name} );

    if ( $conf{auto} ) {
        $template->{plug_session} = \%conf;
        if ( defined $template->{d}{session} ) {

            if ( defined $session_id ) {
                $dbh->do(
                    "UPDATE $conf{table} SET data = ?, time = ? WHERE id = ?",
                    undef,
                    freeze( $template->{d}{session} ),
                    time(),
                    $session_id,
                );
            }
            else {
                $session_id = rand() . time() . rand();
                $session_id =~ tr/.//d;
                my $cookie = $config->cgi->cookie(
                    -name       => $conf{cookie_name},
                    -path       => '/',
                    -value      => $session_id,
                    -expires    => $conf{cookie_expiry},
                );
                print "Set-Cookie: $cookie\n";

                $dbh->do(
                    "INSERT INTO $conf{table} VALUES( ?, ?, ? );",
                    undef,
                    $session_id,
                    time(),
                    freeze( $template->{ $conf{cell} }{ $conf{key} } ),
                );
            }

            $dbh->do(
                "DELETE FROM $conf{table} WHERE time < ?",
                undef,
                time() - $conf{session_expiry},
            );
        }
        elsif ( defined $session_id ) {
            my $session = $dbh->selectall_arrayref(
                "SELECT * FROM $conf{table} WHERE id = ?",
                { Slice => {} },
                $session_id,
            ) || [];

            @$session
                and $template->{ $conf{cell} }{ $conf{key} } = thaw $session->[0]{data};
        }
    }
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::Session - plugin for storing data across requests

=head1 SYNOPSIS

    plugins => [
        { Session => 2000 },
        { Sub     => 3000 },
    ],

    plugins2 => [
        qw/Session/,
    ],

    plug_session => {
        dsn     => "DBI:mysql:database=test;host=localhost",
        user    => 'test',
        pass    => 'test',
    },

    plug_sub => sub {
        my $t = shift;
        $t->{d}{session}{time} = localtime;
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to store data across HTTP
requests.

B<The docs for this plugin are incomplete>

B<This plugin requires ZofCMS version of at least 0.0211 where multi-level plugin sets are implemented>

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        qw/Session/,
    ],

    plugins2 => [
        qw/Session/,
    ],

B<Important>. This plugin requires to be executed twice. On first execution [currently]
it will load the session data into C<< $t->{d}{session} >> where C<$t> is ZofCMS Template
hashref. On second execution, it will save that data into an SQL table.

=head2 C<plug_session>

    plug_session => {
        dsn     => "DBI:mysql:database=test;host=localhost",
        user    => 'test',
        pass    => 'test',
        opt     => { RaiseError => 1, AutoCommit => 1 },
        create_table => 1,
    },

B<Mandatory>. The C<plug_session> key takes a hashref as a value. The possible keys/values of that hashref are described below. B<There are quite a few more options to come - see source
code - but those are untested and may be changed, thus use them at your own risk.>

=head2 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. Specifies the DSN for database, see L<DBI> for more information on what to use
here.

=head2 C<user> and C<pass>

        user    => 'test',
        pass    => 'test',

B<Semi-optional>. The C<user> and C<pass> key should contain username and password for
the SQL database that plugin will use. B<Defaults are:> C<user> is C<root> and C<pass> is set
to C<undef>.

=head2 C<opt>

    opt => { RaiseError => 1, AutoCommit => 0 },

The C<opt> key takes a hashref of any additional options you want to
pass to C<connect_cached> L<DBI>'s method.

B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 0 }, >>

=head2 C<table>

    table   => 'session',

B<Optional>. Takes a string as a value. Specifies the name of the SQL table that plugin
will use to store data. B<Defaults to:> C<session>

=head2 C<create_table>

    create_table => 1,

B<Optional>. Takes either true or false values. When set to a true value, the plugin will
automatically create the database table that it nees for operation. B<Defaults to:> C<0>.
Here is the table that it creates (C<$conf{table}> is the C<table> plugin's argument):

    CREATE TABLE `$conf{table}` (
        `id`      TEXT,
        `time`    VARCHAR(10),
        `data`    TEXT
    );

=head1 USAGE

Currently just store your data in C<< $t->{d}{session} >>. I suggest you use it as a hashref.

More options to come soon!

=head1 MORE INFO

See source code, much of it is understandable (e.g. that session cookies last for 24 hours).
I'll write better documentation once I get more time.

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