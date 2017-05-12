package App::ZofCMS::Plugin::FormToDatabase;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use DBI;

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{plug_form_to_database}
            or $config->conf->{plug_form_to_database};

    my %conf = (
        opt         => { RaiseError => 1, AutoCommit => 0 },
        go_field    => 'd|form_to_database',
        %{ delete $config->conf->{plug_form_to_database} || {} },
        %{ delete $template->{plug_form_to_database}     || {} },
    );

#         dsn     => "DBI:mysql:database=test;host=localhost",
#         user    => 'test', # user,
#         pass    => 'test', # pass
#         opt     => { RaiseError => 1, AutoCommit => 0 },

    my ( $source, $go_name ) = split /\|/, $conf{go_field}, 2;

    return
        unless ( $source eq 'q' and $query->{$go_name} )
            or
            $template->{$source}{$go_name};

    my @values = @{ $conf{values} };

    my $dbh = DBI->connect_cached(
        @conf{ qw/dsn user pass opt/ },
    );

    $dbh->do(
        "INSERT INTO $conf{table} VALUES(" . join(q|, |, ('?')x@values) . ');',
        undef,
        @$query{ @values },
    );
    $dbh->disconnect;

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FormToDatabase - simple insertion of query into database

=head1 SYNOPSIS

In your Main Config file or ZofCMS template:

    plugins => [ qw/FormToDatabase/ ],
    plug_form_to_database => {
        go_field   => 'd|foo',
        values   => [ qw/one two/ ],
        table   => 'form',
        dsn     => "DBI:mysql:database=test;host=localhost",
        user    => 'test',
        pass    => 'test',
        opt     => { RaiseError => 1, AutoCommit => 0 },
    },

=head1 DESCRIPTION

The module is a simple drop in to stick query into database. The module does not provide any
parameter checking and is very basic. For anything more advanced check out
L<App::ZofCMS::Plugin::DBI>

This documentation assumes you have read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE OR ZofCMS TEMPLATE FIRST LEVEL KEYS

    plug_form_to_database => {
        go_field   => 'd|foo',
        values   => [ qw/one two/ ],
        table   => 'form',
        dsn     => "DBI:mysql:database=test;host=localhost",
        user    => 'test',
        pass    => 'test',
        opt     => { RaiseError => 1, AutoCommit => 0 },
    },

Plugin uses the C<plug_form_to_database> first-level key in ZofCMS template or your
main config file. The key takes a hashref as a value. Values set under this key
in ZofCMS template will override values set in main config file. Possible keys/values
are as follows.

=head2 C<go_field>

    go_field => 'd|foo',

B<Optional>. B<Defaults to: > C<d|form_to_database>.
The C<go_field> key specifies the "go" to the plugin; in other words, if value referenced
by the string set under C<go_field> key the plugin will proceed with stuffing your database,
otherwise it will not do anything. Generally, you'd do some query checking with a plugin
(e.g. L<App::ZofCMS::Plugin::FormChecker>) with lower priority number (so it would be run
first) and then set the value referenced by the C<go_field>.

The C<go_field> key takes a string as a value. The string is in format C<s|key_name> - where
C<s> is the name of the "source". What follows the "source" letter is a pipe (C<|>)
and then they name of the key. The special value of source C<q> (note that it is lowercase)
means "query". That is C<q|foo> means, "query parameter 'foo'". Other values of the "source"
will be looked for inside ZofCMS template hash, e.g. C<d|foo> means key C<foo> in ZofCMS
template special first-level key C<{d}> - this is probably where you'd want to check that for.

Example:

    # ZofCMS template:
    plugins => [ qw/FormToDatabase/ ],
    d       => { foo => 1 },
    plug_form_to_database => {
        go_field => 'd|foo',
        ..... # omited for brevity
    },

The example above will always stuff the query data into the database because key C<foo> under
key C<d> is set to a true value and C<go_field> references that value with C<d|foo>.

=head2 C<values>

        values => [ qw/one two/ ],

B<Mandatory>. The C<values> key takes an arrayref as a value. The elements of that arrayref
represent the names of query parameters that you wish to stick into the database.
Under the hood of the module the following is being called:

    $dbh->do(
        "INSERT INTO $conf{table} VALUES(" . join(q|, |, ('?')x@values) . ');',
        undef,
        @$query{ @values },
    );

Where C<@values> contains values you passed via C<values> key and C<$dbh> is the database
handle created by C<DBI>. If you want something more
advanced consider using C<App::ZofCMS::Plugin::DBI> instead.

=head2 C<table>

    table => 'form',

B<Mandatory>. Specifies the name of the table into which you wish to store the data.

=head2 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. Specifies the I<dsn> to use in DBI connect call. See documentation for
L<DBI> and C<DBD::your_database> for proper syntax for this string.

=head2 C<user>

    user => 'test',

B<Mandatory>. Specifies the user name (login) to use when connecting to the database.

=head2 C<pass>

    pass => 'test',

B<Mandatory>. Specifies the password to use when connecting to the database.

=head2 C<opt>

B<Optional>. Specifies extra options to use in L<DBI>'s C<connect_cached()> call.
B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 0 } >>

=head1 SEE ALSO

L<DBI>, L<App::ZofCMS::Plugin::DBI>

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