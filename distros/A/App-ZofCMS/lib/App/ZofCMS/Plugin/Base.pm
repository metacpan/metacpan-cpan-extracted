package App::ZofCMS::Plugin::Base;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my $key = $self->_key;

    $template->{$key} = $template->{$key}->( $template, $query, $config )
        if ref $template->{$key} eq 'CODE';

    $config->conf->{$key} = $config->conf->{$key}->( $template, $query, $config )
        if ref $config->conf->{$key} eq 'CODE';

    return
        unless $template->{$key}
            or $config->conf->{$key};

    my %conf = (
        $self->_defaults,
        %{ delete $config->conf->{$key} || {} },
        %{ delete $template->{$key}     || {} },
    );

    $self->_do( \%conf, $template, $query, $config );
}

sub _key { 'base' }
sub _defaults { () }
sub _has_value {
    my $v = shift;

    return 1
        if defined $v and length $v;

    return 0;
}

sub _dbh {
    my $self = shift;

    return $self->{DBH}
        if $self->{DBH};

    $self->{DBH} = DBI->connect_cached(
        @{ $self->{CONF} }{ qw/dsn user pass opt/ },
    );

    return $self->{DBH};
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::Base - base class for App::ZofCMS plugins

=head1 SYNOPSIS

    package App::ZofCMS::Plugin::Example;

    use strict;
    use warnings;
    use base 'App::ZofCMS::Plugin::Base';

    sub _key { 'plug_example' }
    sub _defaults {
        return (
        qw/foo bar baz beer/
        );
    }
    sub _do {
        my ( $self, $conf, $t, $q, $config ) = @_;

        $self->_dbh->do('DELETE FROM `foo`')
            if _has_value( $q->{foo} );
    }

=head1 DESCRIPTION

The module is a base class for L<App::ZofCMS> plugins. I'll safely
assume that you've already read the docs for L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

The base class (currently) is only for plugins who take their "config"
as a single first-level key in either Main Config File or ZofCMS
Template. That key's value must be a hashref or a subref that returns
a hashref, empty list or C<undef>.

=head1 SUBS TO OVERRIDE

=head2 C<_key>

    sub _key { 'plug_example' }

The C<_key> needs to return a scalar containing the name of first level
key in ZofCMS template or Main Config file. Study the source code of
this module to find out what it's used for if it's still unclear. The
value of that key can be either a hashref or a subref that returns a
hashref or undef. If the value is a subref, its return value will be
assigned to the key and its C<@_> will contain (in that order):
C<$t, $q, $conf> where C<$t> is ZofCMS Template hashref, C<$q> is
hashref of query parameters and C<$conf> is L<App::ZofCMS::Config>
object.

=head2 C<_defaults>

    sub _defaults { qw/foo bar baz beer/ }

The C<_defaults> sub needs to return a list of default arguments in a
form of key/value pairs. By default it returns an empty list.

=head2 C<_do>

    sub _do {
        my ( $self, $conf, $template, $query, $config ) = @_;
    }

The C<_do> sub is where you'd do all of your processing. The C<@_> will
contain C<$self, $conf, $template, $query and $config> (in that order)
where C<$self> is your plugin's object, C<$conf> is the plugin's
configuration hashref (what the user would specify in ZofCMS Template
or Main Config File, the key of which is returned by C<_key()> sub), the
C<$template> is the hashref of ZofCMS template that is being processed,
the C<$query> is a query parameters hashref where keys are names of the
params and values are their values. Finally, the C<$config> is
L<App::ZofCMS::Config> object.

=head1 UTILITY SUBS

The module provides these utility subs that are meant to give you a
hand during coding:

=head2 C<_has_value>

    sub _has_value {
        my $v = shift;

        return 1
            if defined $v and length $v;

        return 0;
    }

This sub is shown above and is meant to provide a shorter way to
test whether a given variable has any meaningful content.

=head2 C<_dbh>

    sub _dbh {
        my $self = shift;

        return $self->{DBH}
            if $self->{DBH};

        $self->{DBH} = DBI->connect_cached(
            @{ $self->{CONF} }{ qw/dsn user pass opt/ },
        );

        return $self->{DBH};
    }

This sub (shown above) has marginally narrower spectrum of usability
as opposed to the rest of this module; nevertheless, I found needing
it way too often. The sub is an accessor to a connected C<DBI>'s
database handle that autoconnects if it hasn't already. Note that the
sub expects C<dns>, C<user>, C<pass> and C<opt> arguments located
in C<< $self->{CONF} >> hashref. For descriptionof these arguments,
see L<DBI>'s C<connect_cached()> method.

=head1 MOAR!

Feel free to email me the requests for extra functionality for this
base class.

=head1 DOCUMENTATION FOR PLUGINS

Below is a "template" documentation. If you're going to use it, make
sure to read through the entire thing as some things may not apply to
your plugin; I've added those bits as they are very common in the
plugins that I write, some of them (but not all) I marked with
word C<[EDIT]>.

    =head1 DESCRIPTION

    The module is a plugin for L<App::ZofCMS> that provides means to [EDIT].

    This documentation assumes you've read L<App::ZofCMS>,
    L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

    =head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

    =head2 C<plugins>

        plugins => [ qw/[EDIT]/ ],

    B<Mandatory>. You need to include the plugin in the list of
    plugins to execute.

    =head2 C<[EDIT]>

        [EDIT] => {
        },

        # or
        [EDIT] => sub {
            my ( $t, $q, $config ) = @_;
            return $hashref_to_assign_to_this_key_instead_of_subref;
        },

    B<Mandatory>. Takes either a hashref or a subref as a value.
    If subref is specified, its return value will be assigned to
    C<[EDIT]> as if it were already there. If sub returns an C<undef>
    or an empty list, then plugin will stop further processing. The
    C<@_> of the subref will contain C<$t>, C<$q>, and C<$config>
    (in that order), where C<$t> is ZofCMS Template hashref, C<$q> is
    query parameter hashref, and C<$config> is L<App::ZofCMS::Config>
    object. Possible keys/values for the hashref are as follows:

    =head3 C<cell>

        [EDIT] => {
            cell => 't',
        },

    B<Optional>. Specifies ZofCMS Template first-level key where to
    [EDIT]. Must be pointing to either a hashref or an C<undef>
    (see C<key> below). B<Defaults to:> C<t>

    =head3 C<key>

        [EDIT] => {
            key => '[EDIT]',
        },

    B<Optional>. Specifies ZofCMS Template second-level key where to
    [EDIT]. This key will be inside C<cell> (see above)>.
    B<Defaults to:> C<[EDIT]>

=head1 DBI BIT OF DOCUMENTATION FOR PLUGINS

The following is the documentation I use for the L<DBI> configuration
part of arguments that are used by L<DBI>-using modules:

    =head3 C<dsn>

        [EDIT] => {
            dsn => "DBI:mysql:database=test;host=localhost",
        ...

    B<Mandatory>. The C<dsn> key will be passed to L<DBI>'s
    C<connect_cached()> method, see documentation for L<DBI> and
    C<DBD::your_database> for the correct syntax for this one.
    The example above uses MySQL database called C<test> that is
    located on C<localhost>.

    =head3 C<user>

        [EDIT] => {
            user => '',
        ...

    B<Optional>. Specifies the user name (login) for the database.
    This can be an empty string if, for example, you are connecting
    using SQLite driver. B<Defaults to:> C<''> (empty string)

    =head3 C<pass>

        [EDIT] => {
            pass => undef,
        ...

    B<Optional>. Same as C<user> except specifies the password for the
    database. B<Defaults to:> C<undef> (no password)

    =head3 C<opt>

        [EDIT] => {
            opt => { RaiseError => 1, AutoCommit => 1 },
        ...

    B<Optional>. Will be passed directly to L<DBI>'s
    C<connect_cached()> method as "options". B<Defaults to:>
    C<< { RaiseError => 1, AutoCommit => 1 } >>

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