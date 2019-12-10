package App::ZofCMS::Plugin::PreferentialOrder;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use DBI;
use HTML::Template;

sub _key { 'plug_preferential_order' }
sub _defaults {
    return (
    dsn           => "DBI:mysql:database=test;host=localhost",
    user          => '',
    pass          => undef,
    opt           => { RaiseError => 1, AutoCommit => 1 },
    users_table   => 'users',
    order_col     => 'plug_pref_order',
    login_col     => 'login',
    order_login   => sub { $_[0]->{d}{user}{login} },
    separator     => ',',
    has_disabled  => 1,
    enabled_label => '<p class="ppof_label">Enabled items</p>',
    disabled_label => '<p class="ppof_label">Disabled items</p>',
    submit_button => q|<input type="submit" class="input_submit"|
                        . q| value="Save">|,
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    for ( qw/items  order_login/ ) {
        $conf->{$_} = $conf->{$_}->( $t, $q, $config )
            if ref $conf->{$_} eq 'CODE';
    }

    return
        unless $conf->{items}
            and $conf->{order_login};

    $self->{CONFIG} = $config;
    $self->{CONF}   = $conf;
    $self->{T}      = $t;
    $self->{Q}      = $q;
    $self->{Q_PAGE} = ( $q->{dir} || '' ) . ( $q->{page} || '' );

    $self->prepare_items;

    if ( $q->{ppof_save_order}
        and (
            has_value( $q->{ppof_order} )
            or has_value( $q->{ppof_order_disabled} )
        )
    ) {
        $self->save_order;
        $t->{t}{plug_pref_order_form} = $self->generate_form('saved');
    }
    else {
        $t->{t}{plug_pref_order_form} = $self->generate_form;
    }

    @{ $t->{t} }{ qw/plug_pref_order_list  plug_pref_order_disabled_list/ }
    = $self->generate_order;
}

sub generate_order {
    my $self  = shift;
    my $conf  = $self->{CONF};

    my $items = $conf->{items};
    my $template = HTML::Template->new_scalar_ref(
        \ list_html_template(),
        die_on_bad_params => 0,
    );
    $template->param(
        items => $items,
        has_enabled_items => (
            scalar(@{ $items || [] }) ? 1 : 0
        ),
    );

    my $items_disabled = $conf->{items_disabled};
    my $template_disabled = HTML::Template->new_scalar_ref(
        \ list_html_template(),
        die_on_bad_params => 0,
    );
    $template_disabled->param(
        items       => $items_disabled,
        is_disabled => 1,
        has_disabled_items => (
            scalar(@{ $items_disabled || [] }) ? 1 : 0
        ),
    );

    return ( $template->output, $template_disabled->output );
}

sub save_order {
    my $self  = shift;
    my $conf  = $self->{CONF};
    my $items = $conf->{items};
    my $items_disabled = $conf->{items_disabled};

    my %items = map +(
        $_->{name} => {
            value     => $_->{value},
            form_name => $_->{form_name},
        },
    ), @$items, @$items_disabled;

    my @order = grep exists $items{$_},
        split /$conf->{separator}/, $self->{Q}{ppof_order} || '';

    my @disabled_order = grep exists $items{$_},
        split /$conf->{separator}/,
            $self->{Q}{ppof_order_disabled} || '';

    @$items = ();
    my %items_already_present;
    for ( @order ) {
        push @$items, {
            name      => $_,
            value     => $items{$_}{value},
            form_name => $items{$_}{form_name},
        }  unless exists $items_already_present{$_};
        $items_already_present{$_} = 1;
    }

    @$items_disabled = ();
    for ( @disabled_order ) {
        push @$items_disabled, {
            name      => $_,
            value     => $items{$_}{value},
            form_name => $items{$_}{form_name},
        } unless exists $items_already_present{$_};
        $items_already_present{$_} = 1;
    }

    my $new_disabled_order_string
    = join $conf->{separator}, map "[:[$_->{name}]:]", @$items_disabled;

    my $new_order_string = join $conf->{separator}, map $_->{name}, @$items;
    my $dbh = $self->dbh;
    $dbh->do(
        'UPDATE `' . $conf->{users_table}
            . '` SET `' . $conf->{order_col}
            . '` = ? WHERE `' . $conf->{login_col} . '` = ?',
        undef,
        (
            join $conf->{separator},
            $new_order_string, $new_disabled_order_string
        ),
        $conf->{order_login},
    );
}

sub generate_form {
    my $self = shift;
    my $is_saved = shift;

    my $template = HTML::Template->new_scalar_ref(
        \ form_html_template(),
        die_on_bad_params => 0,
    );

    $template->param(
        is_saved    => $is_saved,
        q_page      => $self->{Q_PAGE},
        map +( $_ => $self->{CONF}{$_} ),
            qw/items          submit_button  has_disabled  items_disabled
               enabled_label  disabled_label/,
    );

    return $template->output;
}

sub prepare_items {
    my $self = shift;
    my $conf = $self->{CONF};
    my ( $items, $disabled_items ) = $self->prepare_items_list;

    for ( @$items, @$disabled_items ) {
        if ( ref $_->{value} eq 'ARRAY' ) {
            @$_{qw/form_name value/} = @{ $_->{value} };
        }
        else {
            $_->{form_name} = $_->{name};
        }

        if ( ref $_->{value} eq 'CODE' ) {
            $_->{value} = $_->{value}->( @$self{ qw/T  Q  CONFIG/ } );
        }

        if ( ref $_->{value} eq 'SCALAR' ) {
            $_->{value} = HTML::Template->new_file(
                ${ $_->{value} },
                die_on_bad_params => 0,
            );
        }
        else {
            $_->{value} = HTML::Template->new_scalar_ref(
                \ $_->{value},
                die_on_bad_params => 0,
            );
        }

        $_->{value}->param( $self->{T}{t} );
        $_->{value} = $_->{value}->output;
    }

    $conf->{items}          = $items;
    $conf->{items_disabled} = $disabled_items;
}

sub prepare_items_list {
    my $self = shift;
    my $conf = $self->{CONF};

    my @items;
    my $key;
    for ( 0 .. $#{ $conf->{items} } ) {
        if ( $_ % 2 == 0) { # even index
            $key = $conf->{items}[$_];
        }
        else { # odd index
            push @items, {
                name  => $key,
                value => $conf->{items}[$_],
            };
        }
    }

    my $dbh = $self->dbh;
    my $saved_value = ($dbh->selectall_arrayref(
        'SELECT `' . $conf->{order_col}
            . '` FROM `' . $conf->{users_table}
            . '` WHERE `' . $conf->{login_col} .'` = ?',
        { Slice => {} },
        $conf->{order_login},
    ) || [])->[0];

    return \@items
        unless $saved_value
            and has_value($saved_value->{ $conf->{order_col} });

    my @saved_order_names =
        split /$conf->{separator}/, $saved_value->{ $conf->{order_col} };

    my %available_items = map +( $_->{name} => $_->{value} ), @items;
    my @saved_items = map +{
            name    => $_,
            value   => $available_items{ $_ },
        },
        grep exists $available_items{ $_ }, @saved_order_names;

    my %disabled_items =
        map +(  (/^\[:\[(.+)]:]$/)[0] => 1 ),
            grep /^\[:\[.+]:]$/, @saved_order_names;

    %disabled_items = ()
        unless $conf->{has_disabled};

    my %saved_items = map +( $_->{name} => 1 ), @saved_items;

    my @disabled_items;
    for ( sort keys %available_items ) {
        if ( exists $disabled_items{$_} ) {
            push @disabled_items, {
                name  => $_,
                value => $available_items{$_},
            };
        }
        else {
            push @saved_items, {
                name  => $_,
                value => $available_items{$_},
            } unless exists $saved_items{$_};
        }
    }

    return ( \@saved_items, \@disabled_items );
}

sub has_value {
    my $v = shift;

    return 1
        if defined $v
            and length $v;

    return 0;
}

sub dbh {
    my $self = shift;

    return $self->{DBH}
        if $self->{DBH};

    $self->{DBH} = DBI->connect_cached(
        @{ $self->{CONF} }{ qw/dsn user pass opt/ },
    );

    return $self->{DBH};
}

sub list_html_template {
    return <<'END_HTML';
<tmpl_if name='is_disabled'>
    <tmpl_if name='has_disabled_items'>
        <ul class="plug_list_html_template_disabled">
            <tmpl_loop name='items'>
                <li id="ppof_order_list_disabled_item_<tmpl_var escape='html'
                    name='name'>"><tmpl_var name='value'></li>
            </tmpl_loop>
        </ul>
    </tmpl_if>
<tmpl_else>
    <tmpl_if name='has_enabled_items'>
        <ul class="plug_list_html_template">
            <tmpl_loop name='items'>
                <li id="ppof_order_list_item_<tmpl_var escape='html'
                    name='name'>"><tmpl_var name='value'></li>
            </tmpl_loop>
        </ul>
    </tmpl_if>
</tmpl_if>
END_HTML
}

sub form_html_template {
    return <<'END_HTML';
<form action="" method="POST" id="plug_preferential_order_form">
<div>
    <input type="hidden" name="page" value="<tmpl_var escape='html' name='q_page'>">
    <input type="hidden" name="ppof_save_order" value="1">

    <tmpl_if name='is_saved'>
        <p class="success-message">Successfully saved</p>
    </tmpl_if>

    <div id="ppof_enabled_container">
        <tmpl_if name='has_disabled'>
            <tmpl_var name='enabled_label'>
        </tmpl_if>
        <ul id="ppof_order" class="ppof_list">
            <tmpl_loop name='items'>
                <li id="ppof_order_item_<tmpl_var escape='html' name='name'>"><tmpl_var name='form_name'></li>
            </tmpl_loop>
        </ul>
    </div>

    <tmpl_if name='has_disabled'>
        <div id="ppof_enabled_container">
            <tmpl_var name='disabled_label'>
            <ul id="ppof_order_disabled" class="ppof_list">
                <tmpl_loop name='items_disabled'>
                    <li id="ppof_order_item_<tmpl_var escape='html' name='name'>"><tmpl_var name='form_name'></li>
                </tmpl_loop>
            </ul>
        </div>
    </tmpl_if>

    <tmpl_var name='submit_button'>
</div>
</form>
END_HTML
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::PreferentialOrder - Display HTML snippets in user-controllable, savable order

=head1 EXTRA RESOURCES (BEYOND PERL)

This plugin was designed to be used in conjunction with JavaScript (JS)
code that controls the order of items on the page and submits that
information to the server.

If you wish to use a different, your own front-end, please study JS code
provided at the end of this documentation to understand what is required.

=head1 SYNOPSIS

In your L<HTML::Template> template:

    <tmpl_var name='plug_pref_order_form'>
    <tmpl_var name='plug_pref_order_list'>
    <tmpl_var name='plug_pref_order_disabled_list'>

In your ZofCMS template:

    plugins => [ qw/PreferentialOrder/, ],

    # except for the mandatory argument `items`, the default values are shown
    plug_preferential_order => {
        items => [ # four value type variations shown here
            forum3  => '<a href="#">Forum3</a>',
            forum4  => [ 'Last forum ":)"',   \'forum-template.tmpl', ],
            forum   => [ 'First forum ":)"',  '<a href="#">Forum</a>',  ],
            forum2  => [
                'Second forum ":)"',
                sub {
                    my ( $t, $q, $config ) = @_;
                    return '$value_for_the_second_element_in_the_arrayref';
                },
            ],
        ],
        dsn            => "DBI:mysql:database=test;host=localhost",
        user           => '',
        pass           => undef,
        opt            => { RaiseError => 1, AutoCommit => 1 },
        users_table    => 'users',
        order_col      => 'plug_pref_order',
        login_col      => 'login',
        order_login    => sub { $_[0]->{d}{user}{login} },
        separator      => ',',
        has_disabled   => 1,
        enabled_label  => q|<p class="ppof_label">Enabled items</p>|,
        disabled_label => q|<p class="ppof_label">Disabled items</p>|,
        submit_button  => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to have a
sortable list of custom HTML snippets. The order can be defined by each
individual user to suit their needs. The order is defined using a form
provided by the plugin, the actual sorting is done by
I<MooTools> (L<http://mootools.net>) JS framework. Use of this framework
is not a necessity; it's up to you what you'll use as a front-end. An
example of MooTools front-end is provided at the end of this documentation.

The plugin provides two modes: single sortable list, and double lists,
where the second list represents "disabled" items, although that can
well be used for having two lists with items being sorted between each of
them (e.g. primary and secondary navigations).

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/PreferentialOrder/ ],

B<Mandatory>. You need to include the plugin in the list of plugins to
execute.

=head2 C<plug_preferential_order>

    # except for the mandatory argument `items`, the default values are shown
    plug_preferential_order => {
        items => [ # four value type variations shown here
            forum3  => '<a href="#">Forum3</a>',
            forum4  => [ 'Last forum ":)"',   \'forum-template.tmpl', ],
            forum   => [ 'First forum ":)"',  '<a href="#">Forum</a>',  ],
            forum2  => [
                'Second forum ":)"',
                sub {
                    my ( $t, $q, $config ) = @_;
                    return '$value_for_the_second_element_in_the_arrayref';
                },
            ],
        ],
        dsn            => "DBI:mysql:database=test;host=localhost",
        user           => '',
        pass           => undef,
        opt            => { RaiseError => 1, AutoCommit => 1 },
        users_table    => 'users',
        order_col      => 'plug_pref_order',
        login_col      => 'login',
        order_login    => sub { $_[0]->{d}{user}{login} },
        separator      => ',',
        has_disabled   => 1,
        enabled_label  => q|<p class="ppof_label">Enabled items</p>|,
        disabled_label => q|<p class="ppof_label">Disabled items</p>|,
        submit_button  => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    },

    # or
    plug_preferential_order => sub {
        my ( $t, $q, $config ) = @_;
        return $hashref_to_assign_to_the_plug_key;
    },

B<Mandatory>. Takes either an C<undef>, a hashref or a subref as a value.
If subref is
specified, its return value will be assigned to C<plug_preferential_order>
as if it was already there. If C<undef> is specified or the sub returns
one, then plugin will
stop further processing. The C<@_> of the subref will contain C<$t>,
C<$q>, and C<$config> (in that
order), where C<$t> is ZofCMS Tempalate hashref, C<$q> is query parameter
hashref and C<$config> is L<App::ZofCMS::Config> object. Possible
keys/values for the hashref are as follows:

=head3 C<items>

    plug_preferential_order => {
        items => [ # four value type variations shown here
            forum3  => '<a href="#">Forum3</a>',
            forum4  => [ 'Last forum ":)"',   \'forum-template.tmpl', ],
            forum   => [ 'First forum ":)"',  '<a href="#">Forum</a>',  ],
            forum2  => [
                'Second forum ":)"',
                sub {
                    my ( $t, $q, $config ) = @_;
                    return '$value_for_the_second_element_in_the_arrayref';
                },
            ],
        ],
    ...

    plug_preferential_order => {
        items => sub {
            my ( $t, $q, $config ) = @_;
            return $items_arrayref;
        },
    ...

B<Mandatory>. Takes an arrayref, a subref or C<undef> as a value. If set to
C<undef> (i.e. not specified), plugin will not execute. If a subref is
specified, its return value will be assigned to C<items> as if it was
already there. The C<@_> of the subref will contain C<$t>,
C<$q>, and C<$config> (in that order), where C<$t> is ZofCMS Tempalate
hashref, C<$q> is query parameter hashref and C<$config> is
L<App::ZofCMS::Config> object. This argument tells the plugin the items on
the list you want the user to sort and use.

The insides of the arrayref are best to be thought as keys/values of a
hashref; the reason for the arrayref is to preserve the original order. The
"keys" of the arrayref must B<NOT> contain C<separator> (see below) and
need to conform to HTML/Your-markup-language C<id> attribute
(L<http://xrl.us/bicips>). These keys are used by the plugin
to label the items in the form that the user uses to sort their lists, the
labels for the actual list items when they are displayed, as
well as labels stored in the SQL table for each user.

The "value" of the "key" in the arrayref can be a scalar, a scalarref,
a subref, as well as an arrayref with two items, first being a scalar and
the second one being either a scalar, a scalarref, or a subref.

When the value is a scalar, scalarref or subref, it will be internally
converted to an arrayref with the value being the second item, and the first
item being the "key" of this "value" in the arrayref. In other words, these
two codes are equivalent:

    items => [ foo => 'bar', ],

    items => [ foo => [ 'foo', 'bar', ], ],

The first item in the inner arrayref specifies the human readable name of
the HTML snippet. This will be presented to the user in the sorting form.
The second item represents the actual snippet and it can be specified
using one of the following three ways:

=head4 a subref

    items => [
        foo => [
            bar => sub {
                my ( $t, $q, $config ) = @_;
                return 'scalar or scalarref to represent the actual snippet';
            },
        ],
    ],

If the second item is a subref, its C<@_> will contain C<$t>, C<$q>, and
C<$config> (in that order) where C<$t> is ZofCMS Template hashref,
C<$q> is query parameter hashref, and C<$config> is L<App::ZofCMS::Config>
object. The sub must return either a scalar or a scalarref that will be
assigned to the "key" instead of this subref.

=head4 a scalar

    items => [
        foo => [
            bar => [ bez => '<a href="#"><tmpl_var name="meow"></a>', ],
        ],
    ],

If the second item is a scalar, it will be interpreted as a snippet of
L<HTML::Template> template. The parameters will be set into this snippet
from C<{t}> ZofCMS Template special key.

=head4 a scalarref

    items => [
        foo => [
            bar => [ bez => \'template.tmpl', ],
        ],
    ],

If the second item is a scalaref, its meaning and function is the same as
for the scalar value, except the L<HTML::Template> template snippet will be
read from the filename specified by the scalarref. Relative paths here
will be relative to C<index.pl> file.

=head3 C<dsn>

    plug_preferential_order => {
        dsn => "DBI:mysql:database=test;host=localhost",
    ...

B<Optional, but with useless default value>. The dsn key will be passed to
L<DBI>'s C<connect_cached()> method, see documentation for L<DBI> and
C<DBD::your_database> for the correct syntax for this one. The example
above uses MySQL database called C<test> that is located on C<localhost>.
B<Defaults to:> C<DBI:mysql:database=test;host=localhost>

=head3 C<user>

    plug_preferential_order => {
        user => '',
    ...

B<Optional>. Specifies the user name (login) for the database. This can be
an empty string if, for example, you are connecting using SQLite driver.
B<Defaults to:> empty string

=head3 C<pass>

    plug_preferential_order => {
        pass => undef,
    ...

B<Optional>. Same as C<user> except specifies the password for the
database. B<Defaults to:> C<undef> (no password)

=head3 C<opt>

    plug_preferential_order => {
        opt => { RaiseError => 1, AutoCommit => 1 },
    ...

B<Optional>. Will be passed directly to L<DBI>'s C<connect_cached()>
method as "options". B<Defaults to:>
C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<users_table>

    plug_preferential_order => {
        users_table => 'users',
    ...

    # This is the minimal SQL table needed by the plugin:
    CREATE TABLE `users` (
        `login`           TEXT,
        `plug_pref_order` TEXT
    );

B<Optional>. Takes a scalar as a value that represents the table into which
to store users' sort orders. The table can be anything you want, but must
at least contain two columns (see C<order_col> and C<login_col> below).
B<Defaults to:> C<users>

=head3 C<order_col>

    plug_preferential_order => {
        order_col => 'plug_pref_order',
    ...

B<Optional>. Takes a scalar as a value. Specifies the name of the column in
the C<users_table> table into which to store users' sort orders. The
orders will be stored as strings, so the column must have appropriate type.
B<Defaults to:> C<plug_pref_order>

=head3 C<login_col>

    plug_preferential_order => {
        login_col => 'login',
    ...

B<Optional>. Takes a scalar as a value. Specifies the name of the column
in the C<users_table> table in which users' logins are stored. The
plugin will use the values in this column only to look up appropriate
C<order_col> columns, thus the data type can be anything you want.
B<Defaults to:> C<login>

=head3 C<order_login>

    plug_preferential_order => {
        order_login => sub {
            my ( $t, $q, $config ) = @_;
            return $t->{d}{user}{login};
        },
    ...

    plug_preferential_order => {
        order_login => 'zoffix',
    ...

B<Optional>. Takes a scalar, C<undef>, or a subref as a value. If
set to C<undef> (not specified) the plugin will not run.
If subref is specified, its return value will be assigned to
C<order_login> as it was already there. The C<@_> will contain C<$t>,
C<$q>, and C<$config> (in that order) where C<$t> is ZofCMS Template
hashref, C<$q> is query parameter hashref, and C<$config> is
L<App::ZofCMS::Config> object. The scalar value specifies the
"login" of the current user; this will be used to get and
store the C<order_col> value based on the C<order_login> present in the
C<login_col> column in the C<users_table> table.
B<Defaults to:> C<< sub { $_[0]->{d}{user}{login} } >>

=head3 C<separator>

    plug_preferential_order => {
        separator => ',',
    ...

B<Optional>. Specifies the separator that will be used to join together
sort order before sticking it into the database. B<IMPORTANT:> your JS
code must use the same separator to join together the sort order items
when user submits the sorting form. B<Defaults to:> C<,> (a comma)

=head3 C<has_disabled>

    plug_preferential_order => {
        has_disabled => 1,
    ...

B<Optional>. Takes either true or false values as a value. When set to a
true value, the plugin will present the user with two lists, with the
items movable between the two. When set to a false value, the plugin
will show the user only one sortable list.

If the order was stored between the I<two> lists, but then the second list
becomes disabled, the previously disabled items will be appended to the end
of the first list (both in the display list, and in the sorting form). If
the second list becomes enabled B<before the user saves the single-list
order>, the divisions between the two lists will be preserved.

Originally, this was designed to have "enabled" and "disabled" groups of
items, hence the naming of this and few other options; the "enabled"
represents the list that is always shown, and the "disabled" represents
the list that is toggleable with C<has_disabled> argument. B<Defaults to:>
C<1> (second list is enabled)

=head3 C<enabled_label>

    plug_preferential_order => {
        enabled_label => q|<p class="ppof_label">Enabled items</p>|,
    ...

B<Optional>. Applies only when C<has_disabled> is set to a true value.
Takes HTML code as a value that will be shown above the "enabled" list
of items inside the sorting form.
B<Defaults to:> C<< <p class="ppof_label">Enabled items</p> >>

=head3 C<disabled_label>

    plug_preferential_order => {
        disabled_label => q|<p class="ppof_label">Disabled items</p>|,
    ...

B<Optional>. Applies only when C<has_disabled> is set to a true value.
Takes HTML code as a value that will be shown above the "disabled" list
of items inside the sorting form.
B<Defaults to:> C<< <p class="ppof_label">Disabled items</p> >>

=head3 C<submit_button>

    plug_preferential_order => {
        submit_button => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    ...

B<Optional>. Takes HTML code as a value that represents the submit
button on the sorting form. This was designed with the idea to allow
image button use; however, feel free to insert here any extra HTML code you
require in your form. B<Defaults to:>
C<< <input type="submit" class="input_submit" value="Save"> >>

=head1 HTML::Template TEMPLATE VARIABLES

    <tmpl_var name='plug_pref_order_form'>
    <tmpl_var name='plug_pref_order_list'>
    <tmpl_var name='plug_pref_order_disabled_list'>

The plugin operates through three L<HTML::Template> variables that you
can use in any combination. These are as follows:

=head2 C<plug_pref_order_form>

    <tmpl_var name='plug_pref_order_form'>

This variable contains the sorting form.

=head2 C<plug_pref_order_list>

    <tmpl_var name='plug_pref_order_list'>

This variable contains the "enabled" list. If C<has_disabled> is turned
off while the user has some items in their "disabled" list; all of them
will be appended to the "enabled" list.

=head2 C<plug_pref_order_disabled_list>

    <tmpl_var name='plug_pref_order_disabled_list'>

This variable contains the "disabled" list. If C<has_disabled> is turned
off while the user has some items in their "disabled" list; all of them
will be appended to the "enabled" list, and this ("disabled") list will be
empty.

=head1 SAMPLE JavaScript CODE TO USED WITH THE PLUGIN

This code relies on I<MooTools> (L<http://mootools.net>) JS framework to
operate. (I<Note:> this code also includes non-essential bit to make the
enabled and disabled lists of constant size)

    window.onload = function() {
        setup_sortables();
    }

    function setup_sortables() {
        var els_list = $$('.ppof_list li');
        var total_height = 0;
        for ( var i = 0, l = els_list.length; i < l; i++ ) {
            total_height += els_list[i].getSize().y;
        }
        $$('.ppof_list').set({'styles': {'min-height': total_height}});

        var mySortables = new Sortables('#ppof_order, #ppof_order_disabled', {
            'constraint': true,
            'clone': true,
            'opacity': 0.3
        });

        mySortables.attach();
        $('ppof_order').zof_sortables = mySortables;
        $('plug_preferential_order_form').onsubmit = add_sorted_list_input;
    }

    function add_sorted_list_input() {
        var result = $('ppof_order').zof_sortables.serialize(
            0,
            function(element, index){
                return element.getProperty('id').replace('ppof_order_item_','');
            }
        ).join(',');

        var result_el = new Element ('input', {
            'type': 'hidden',
            'name': 'ppof_order',
            'value': result
        });
        result_el.inject(this);

        var result_disabled = $('ppof_order').zof_sortables.serialize(
            1,
            function(element, index){
                return element.getProperty('id').replace('ppof_order_item_','');
            }
        ).join(',');

        var result_el_disabled = new Element ('input', {
            'type': 'hidden',
            'name': 'ppof_order_disabled',
            'value': result_disabled
        });
        result_el_disabled.inject(this);
        return true;
    }

=head1 SAMPLE CSS CODE USED BY THE PLUGIN

This is just a quick and ugly sample CSS code to give your lists some
structure for you to quickly play with the plugin to decide if you need it:

    #ppof_enabled_container,
    #ppof_disabled_container {
        width: 400px;
        float: left;
    }

    .ppof_label {
        text-align: center;
        font-size: 90%;
        font-weight: bold;
        letter-spacing: -1px;
        padding: 0;
        margin: 0;
    }

    .success-message {
        color: #aa0;
        font-weight: bold;
        font-size: 90%;
    }

    .ppof_list {
        list-style: none;
        border: 1px solid #ccc;
        min-height: 20px;
        padding: 0;
        margin: 0 0 7px;
        background: #ffd;
    }

    .ppof_list li {
        padding: 10px;
        background: #ddd;
        border: 1px solid #aaa;
        position: relative;
    }

    #plug_preferential_order_form .input_submit {
        clear: both;
        display: block;
    }

=head1 HTML CODE GENERATED BY THE PLUGIN

=head2 Sorting Form

    <!-- Double list (has_disabled is set to a true value) -->
    <form action="" method="POST" id="plug_preferential_order_form">
    <div>
        <input type="hidden" name="page" value="/index">
        <input type="hidden" name="ppof_save_order" value="1">

        <div id="ppof_enabled_container">
            <p class="ppof_label">Enabled items</p>
            <ul id="ppof_order" class="ppof_list">
                <li id="ppof_order_item_forum4">Last forum ":)"</li>
                <li id="ppof_order_item_forum">First forum ":)"</li>
            </ul>
        </div>

        <div id="ppof_enabled_container">
            <p class="ppof_label">Disabled items</p>
            <ul id="ppof_order_disabled" class="ppof_list">
                <li id="ppof_order_item_forum2">Second forum ":)"</li>
                <li id="ppof_order_item_forum3">forum3</li>
            </ul>
        </div>

        <input type="submit" class="input_submit" value="Save">
    </div>
    </form>

    <!-- Single list (has_disabled is set to a false value) -->
    <form action="" method="POST" id="plug_preferential_order_form">
    <div>
        <input type="hidden" name="page" value="/index">
        <input type="hidden" name="ppof_save_order" value="1">

        <div id="ppof_enabled_container">
            <ul id="ppof_order" class="ppof_list">
                <li id="ppof_order_item_forum4">Last forum ":)"</li>
                <li id="ppof_order_item_forum">First forum ":)"</li>
                <li id="ppof_order_item_forum2">Second forum ":)"</li>
                <li id="ppof_order_item_forum3">forum3</li>
            </ul>
        </div>

        <input type="submit" class="input_submit" value="Save">
    </div>
    </form>

This form shows the default arguments for C<enabled_label>,
C<disabled_label> and C<submit_button>. Note that C<id=""> attributes on
the list items are partially made out of the "keys" set in C<items>
argument. The value for C<page> hidden C<input> is derived by the
plugin automagically.

=head2 "Enabled" Sorted List

    <ul class="plug_list_html_template">
        <li id="ppof_order_list_item_forum4">Foo:</li>
        <li id="ppof_order_list_item_forum"><a href="#">Forum</a></li>
    </ul>

The end parts of C<id=""> attributes on the list items are derived from
the "keys" in C<items> arrayref. Note that HTML in the values are
not escaped.

=head2 "Disabled" Sorted List

    <ul class="plug_list_html_template_disabled">
        <li id="ppof_order_list_disabled_item_forum2">Bar</li>
        <li id="ppof_order_list_disabled_item_forum3">Meow</li>
    </ul>

The end parts of C<id=""> attributes on the list items are derived from
the "keys" in C<items> arrayref. HTML in the values (innards of
C<< <li> >>s) are not escaped.

=head1 REQUIRED MODULES

This plugins lives on these modules:

    App::ZofCMS::Plugin::Base => 0.0106,
    DBI                       => 1.607,
    HTML::Template            => 2.9,

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