package App::ZofCMS::Plugin::DBI;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use strict;
use warnings;
use DBI;
use Carp;

sub new { bless {}, shift; }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my $dbi_conf = {
        do_dbi_set_first    => 1,
        %{ $config->conf->{dbi} || {} },
        %{ delete $template->{dbi} || {} },
    };

    $dbi_conf or return;

    ( $dbi_conf->{dbi_set} or $dbi_conf->{dbi_get} )
        or return;
    my $dbh = DBI->connect_cached(
        @$dbi_conf{ qw/dsn user pass opt/ }
    );

    if ( $dbi_conf->{do_dbi_set_first} ) {
        if ( $dbi_conf->{dbi_set} ) {
            $self->_do_dbi_set( $dbi_conf, $query, $template, $config, $dbh );
        }
        if ( $dbi_conf->{dbi_get} ) {
            $self->_do_dbi_get( $dbi_conf, $query, $template, $config, $dbh );
        }
    }
    else {
        if ( $dbi_conf->{dbi_get} ) {
            $self->_do_dbi_get( $dbi_conf, $query, $template, $config, $dbh );
        }
        if ( $dbi_conf->{dbi_set} ) {
            $self->_do_dbi_set( $dbi_conf, $query, $template, $config, $dbh );
        }
    }
}

sub _do_dbi_set {
    my ( $self, $dbi_conf, $query, $template, $config, $dbh ) = @_;

    if ( ref $dbi_conf->{dbi_set} eq 'CODE'
        or not ref $dbi_conf->{dbi_set}[0]
    ) {
        $dbi_conf->{dbi_set} = [ $dbi_conf->{dbi_set} ];
    }

    for my $set ( @{ $dbi_conf->{dbi_set} } ) {
        if ( ref $set eq 'CODE' ) {
            my $sub_set_ref = $set->($query, $template, $config, $dbh );

            $sub_set_ref = [ $sub_set_ref ]
                unless not $sub_set_ref
                    or ( ref $sub_set_ref eq 'ARRAY'
                        and ref $sub_set_ref->[0] eq 'ARRAY'
                    );
            $dbh->do( @$_ ) for @{ $sub_set_ref || [] };
        }
        else {
            $dbh->do( @$set );
        }
    }
    if ( defined $dbi_conf->{last_insert_id} ) {
        $dbi_conf->{last_insert_id} = [
            undef,
            undef,
            undef,
            undef,
        ] unless ref $dbi_conf->{last_insert_id};

        $template->{d}{last_insert_id} = $dbh->last_insert_id(
            @{ $dbi_conf->{last_insert_id} }
        );
    }
}

sub _do_dbi_get {
    my ( $self, $dbi_conf, $query, $template, $config, $dbh ) = @_;

    if ( ref $dbi_conf->{dbi_get} eq 'CODE' ) {
        $dbi_conf->{dbi_get} = $dbi_conf->{dbi_get}->(
            $query, $template, $config, $dbh
        );
    }

    if ( ref $dbi_conf->{dbi_get} eq 'HASH' ) {
        $dbi_conf->{dbi_get} = [ $dbi_conf->{dbi_get} ];
    }

    for my $get ( @{ $dbi_conf->{dbi_get} } ) {
        $get->{type}   ||= 'loop';
        $get->{name}   ||= 'dbi_var';
        $get->{method} ||= 'selectall';
        $get->{cell}   ||= 't';

        if ( $get->{type} eq 'loop' ) {
            my $data_ref;
            if ( $get->{method} eq 'selectall' ) {
                $data_ref = $dbh->selectall_arrayref(
                    @{ $get->{sql} },
                );

                if ( $get->{process} ) {
                    $get->{process}->( $data_ref, $template, $query, $config );
                }

                my $is_hash = ${ $get->{sql} || []}[1];
                $is_hash = ref $is_hash->{Slice} eq 'HASH' ? 1 : 0;

                if ( $get->{single} ) {

                    my $loop_ref = $self->_prepare_loop_arrayref(
                        $data_ref, $get->{layout}, $is_hash
                    )->[0] || {};

                    if ( defined $get->{single_prefix} ) {
                        my $pre = $get->{single_prefix};

                        $loop_ref->{"$pre$_"}
                        = delete $loop_ref->{$_}
                        for keys %$loop_ref;
                    }

                    $template->{ $get->{cell} }
                    = {
                        %{ $template->{ $get->{cell} } || {} },
                        %$loop_ref,
                    };
                }
                else {
                    $template->{ $get->{cell} }{ $get->{name} }
                    = $self->_prepare_loop_arrayref(
                        $data_ref,
                        $get->{layout},
                        $is_hash,
                    );
                }

                if ( $get->{on_data} ) {
                    $template->{t}{ $get->{on_data} } = 1
                        if @$data_ref;
                }
            }
        }
    }
}

sub _prepare_loop_arrayref {
    my ( $self, $data_ref, $layout_ref, $is_hash ) = @_;

    my @loop;
    for my $entry_ref ( @$data_ref ) {
        if ( $is_hash ) {
            if ( defined $layout_ref ) {
                @{ $entry_ref = {} }{ @$layout_ref } = @$entry_ref{ @$layout_ref };
            }
            push @loop, $entry_ref;
        }
        else {
            push @loop, {
                map +(
                    $layout_ref->[$_] => $entry_ref->[$_]
                ), 0 .. $#$entry_ref
            };
        }
    }

    return \@loop;
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::DBI - DBI access from ZofCMS templates

=head1 SYNOPSIS

In your main config file or ZofCMS template:

    dbi => {
        dsn     => "DBI:mysql:database=test;host=localhost",
        user    => 'test', # user,
        pass    => 'test', # pass
        opt     => { RaiseError => 1, AutoCommit => 0 },
    },

In your ZofCMS template:

    dbi => {
        dbi_get => {
            layout  => [ qw/name pass/ ],
            sql     => [ 'SELECT * FROM test' ],
        },
        dbi_set => sub {
            my $query = shift;
            if ( defined $query->{user} and defined $query->{pass} ) {
                return [
                    [ 'DELETE FROM test WHERE name = ?;', undef, $query->{user}      ],
                    [ 'INSERT INTO test VALUES(?,?);', undef, @$query{qw/user pass/} ],
                ];
            }
            elsif ( defined $query->{delete} and defined $query->{user_to_delete} ) {
                return [ 'DELETE FROM test WHERE name =?;', undef, $query->{user_to_delete} ];
            }
            return;
        },
    },

In your L<HTML::Template> template:

    <form action="" method="POST">
        <div>
            <label for="name">Name: </label>
            <input id="name" type="text" name="user" value="<tmpl_var name="query_user">"><br>
            <label for="pass">Pass: </label>
            <input id="pass" type="text" name="pass" value="<tmpl_var name="query_pass">"><br>
            <input type="submit" value="Add">
        </div>
    </form>

    <table>
        <tmpl_loop name="dbi_var">
            <tr>
                <td><tmpl_var name="name"></td>
                <td><tmpl_var name="pass"></td>
                <td>
                    <form action="" method="POST">
                        <div>
                            <input type="hidden" name="user_to_delete" value="<tmpl_var name="name">">
                            <input type="submit" name="delete" value="Delete">
                        </div>
                    </form>
                </td>
            </tr>
        </tmpl_loop>
    </table>

=head1 DESCRIPTION

Module is a L<App::ZofCMS> plugin which provides means to retrieve
and push data to/from SQL databases using L<DBI> module.

Current functionality is limited. More will be added as the need arrises,
let me know if you need something extra.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 DSN AND CREDENTIALS

    dbi => {
        dsn     => "DBI:mysql:database=test;host=localhost",
        user    => 'test', # user,
        pass    => 'test', # pass
        opt     => { RaiseError => 1, AutoCommit => 0 },
        last_insert_id => 1,
        do_dbi_set_first => 1,
    },

You can set these either in your ZofCMS template's C<dbi> key or in your
main config file's C<dbi> key. The key takes a hashref as a value.
The keys/values of that hashref are as follows:

=head2 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

Specifies the DSN for DBI, see C<DBI> for more information on what to use
here.

=head2 C<user> and C<pass>

        user    => 'test', # user,
        pass    => 'test', # pass

The C<user> and C<pass> key should contain username and password for
the database you will be accessing with your plugin.

=head2 C<opt>

    opt => { RaiseError => 1, AutoCommit => 0 },

The C<opt> key takes a hashref of any additional options you want to
pass to C<connect_cached> L<DBI>'s method.

=head2 C<last_insert_id>

    last_insert_id => 1,
    last_insert_id => [
        $catalog,
        $schema,
        $table,
        $field,
        \%attr,
    ],

B<Optional>. When set to a true value, the plugin will attempt to figure out the
C<LAST_INSERT_ID()> after processing C<dbi_set> (see below). The result will be placed
into C<d> ZofCMS Template special key under key C<last_insert_id> (currently there is no
way to place it anywhere else). The value of C<last_insert_id> argument can be either a true
value or an arrayref. Having any true value but an arrayref is the same as having an
arrayref with three C<undef>s. That arrayref will be directly dereferenced into L<DBI>'s
C<last_insert_id()> method. See documentation for L<DBI> for more information.
B<By default is not specified> (false)

=head2 C<do_dbi_set_first>

    do_dbi_set_first => 1,

B<Optional>. Takes either true or false values. If set to a true value, the plugin
will first execute C<dbi_set> and then C<dbi_get>; if set to a false value, the order will
be reversed (i.e. C<dbi_get> first and then C<dbi_set> will be executed. B<Defaults to:> C<1>

=head1 RETRIEVING FROM AND SETTING DATA IN THE DATABASE

In your ZofCMS template the first-level C<dbi> key accepts a hashref two
possible keys: C<dbi_get> for retreiving data from database and C<dbi_set>
for setting data into the database. Note: you can also have your C<dsn>,
C<user>, C<pass> and C<opt> keys here if you wish.

=head2 C<dbi_get>

    dbi => {
        dbi_get => {
            layout  => [ qw/name pass/ ],
            single  => 1,
            sql     => [ 'SELECT * FROM test' ],
            on_data => 'has_data',
            process => sub {
                my ( $data_ref, $template, $query, $config ) = @_;
            }
        },
    }

    dbi => {
        dbi_get => sub {
            my ( $query, $template, $config, $dbh ) = @_;
            return {
                sql     => [
                    'SELECT * FROM test WHERE id = ?',
                    { Slice => {} },
                    $query->{id},
                ],
                on_data => 'has_data',
            }
        },
    },

    dbi => {
        dbi_get => [
            {
                layout  => [ qw/name pass/ ],
                sql     => [ 'SELECT * FROM test' ],
            },
            {
                layout  => [ qw/name pass time info/ ],
                sql     => [ 'SELECT * FROM bar' ],
            },
        ],
    }

The C<dbi_get> key takes either a hashref, a subref or an arrayref as a value.
If the value is a subref, the subref will be evaluated and its value will be assigned to C<dbi_get>; the C<@_> of that subref will contain the following (in that order):
C<$query, $template, $config, $dbh> where C<$query> is query string hashref, C<$template> is
ZofCMS Template hashref, $config is the L<App::ZofCMS::Config> object and C<$dbh> is a
L<DBI> database handle (already connected).

If the value is a hashref it is the same as having just that hashref
inside the arrayref. Each element of the arrayref must be a hashref with
instructions on how to retrieve the data. The possible keys/values of
that hashref are as follows:

=head3 C<layout>

    layout  => [ qw/name pass time info/ ],

B<Optional>. Takes an arrayref as an argument.
Specifies the name of C<< <tmpl_var name=""> >>s in your
C<< <tmpl_loop> >> (see C<type> argument below) to which map the columns
retrieved from the database, see C<SYNOPSIS> section above. If the second element in your
C<sql> arrayref is a hashref with a key C<Slice> whose value is a hashref, then C<layout>
specifies which keys to keep, since C<selectall_arrayref()> (the only currently supported
method) will return an arrayref of hashrefs where keys are column names and values are
the values. Not specifying C<layout> is only allowed when C<Slice> is a hashref and in that
case all column names will be kept. B<By default> is not specified.

=head3 C<sql>

    sql => [ 'SELECT * FROM bar' ],

B<Mandatory>. Takes an arrayref as an argument which will be directly
dereferenced into the L<DBI>'s method call specified by C<method> argument
(see below). See L<App::ZofCMS::Plugin::Tagged> for possible expansion
of possibilities you have here.

=head3 C<single>

    single => 1,

B<Optional>. Takes either true or false values. Normally, the plugin will make
a datastructure suitable for a C<< <tmpl_loop name=""> >>; however, if you expecting
only one row from the table to be returned you can set C<single> parameter B<to a true value>
and then the plugin will stuff appropriate values into C<{t}> special hashref where keys will
be the names you specified in the C<layout> argument and values will be the values of the
first row that was fetched from the database. B<By default is not specified> (false)

=head3 C<single_prefix>

    single_prefix => 'dbi_',

B<Optional>. Takes a scalar as a value. Applies only when
C<single> (see above) is set to a true value. The value you specify here
will be prepended to any key names your C<dbi_get> generates. This is
useful when you're grabbing a single record from the database and
dumping it directly into C<t> special key; using the prefix helps
prevent any name clashes. B<By default is not specified>

=head3 C<type>

    dbi_get => {
        type    => 'loop'
    ...

B<Optional>. Specifies what kind of a L<HTML::Template> variable to
generate from database data. Currently the only supported value is C<loop>
which generates C<< <tmpl_loop> >> for yor L<HTML::Template> template.
B<Defaults to:> C<loop>

=head3 C<name>

    dbi_get => {
        name    => 'the_var_name',
    ...

B<Optional>. Specifies the name of the key in the C<cell> (see below) into
which to stuff your data. With the default C<cell> argument this will
be the name of a L<HTML::Template> var to set. B<Defaults to:> C<dbi_var>

=head3 C<method>

    dbi_get => {
        method => 'selectall',
    ...

B<Optional>. Specifies with which L<DBI> method to retrieve the data.
Currently the only supported value for this key is C<selectall> which
uses C<selectall_arrayref>. B<Defaults to:> C<selectall>

=head3 C<cell>

    dbi_get => {
        cell => 't'
    ...

B<Optional>. Specifies the ZofCMS template's first-level key in which to
create the C<name> key with data from the database. C<cell> must point
to a key with a hashref in it (though, keep autovivification in mind).
Possibly the sane values for this are either C<t> or C<d>. B<Defaults to:>
C<t> (the data will be available in your L<HTML::Template> templates)

=head3 C<on_data>

    dbi_get => {
        on_data => 'has_data',
    ...

B<Optional>. Takes a string as an argument. When specified will set the key in C<{t}> name of
which is specified C<on_data> to C<1> when there are any rows that were selected. Typical
usage for this would be to display some message if no data is available; e.g.:

    dbi_get => {
        layout => [ qw/name last_name/ ],
        sql => [ 'SELECT * FROM users' ],
        on_data => 'has_users',
    },

    <tmpl_if name="has_users">
        <p>Here are the users:</p>
        <!-- display data here -->
    <tmpl_else>
        <p>I have no users for you</p>
    </tmpl_if>

=head3 C<process>

    dbi_get => {
        process => sub {
            my ( $data_ref, $template, $query, $config ) = @_;
            # do stuff
        }
    ...

B<Optional>. Takes a subref as a value. When specified the sub will be executed right after
the data is fetched. The C<@_> will contain the following (in that order):
C<$data_ref> - the return of L<DBI>'s C<selectall_arrayref> call, this may have other
options later on when more methods are supported, the ZofCMS Template hashref, query
hashref and L<App::ZofCMS::Config> object.

=head2 C<dbi_set>

    dbi_set => sub {
        my $query = shift;
        if ( defined $query->{user} and defined $query->{pass} ) {
            return [
                [ 'DELETE FROM test WHERE name = ?;', undef, $query->{user}      ],
                [ 'INSERT INTO test VALUES(?,?);', undef, @$query{qw/user pass/} ],
            ];
        }
        elsif ( defined $query->{delete} and defined $query->{user_to_delete} ) {
            return [ 'DELETE FROM test WHERE name =?;', undef, $query->{user_to_delete} ];
        }
        return;
    },

    dbi_set => [
        'DELETE FROM test WHERE name = ?;', undef, 'foos'
    ],

    dbi_set => [
        [ 'DELETE FROM test WHERE name = ?;', undef, 'foos' ],
        [ 'INSERT INTO test VALUES(?, ?);', undef, 'foos', 'bars' ],
    ]

B<Note:> the C<dbi_set> will be processed B<before> C<dbi_get>. Takes
either a subref or an arrayref as an argument. Multiple instructions
can be put inside an arrayref as the last example above demonstrates. Each
arrayref will be directly dereferenced into L<DBI>'s C<do()> method. Each
subref must return either a single scalar, an arrayref or an arrayref
of arrayrefs. Returning a scalar is the same as returning an arrayref
with just that scalar in it. Returning just an arrayref is the same as
returning an arrayref with just that arrayref in it. Each arrayref of
the resulting arrayref will be directly dereferenced into L<DBI>'s C<do()>
method. The subrefs will have the following in their C<@_> when called:
C<< $query, $template, $config, $dbh >>. Where C<$query> is a hashref
of query parameters in which keys are the name of the parameters and
values are values. C<$template> is a hashref of your ZofCMS template.
C<$config> is the L<App::ZofCMS::Config> object and C<$dbh> is L<DBI>'s
database handle object.

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