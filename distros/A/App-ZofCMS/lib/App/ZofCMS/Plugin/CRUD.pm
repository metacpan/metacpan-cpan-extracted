package App::ZofCMS::Plugin::CRUD;

use strict;
use warnings;

our $VERSION = '1.001007'; # VERSION

use DBI;
use Carp;
use HTML::Template;
use File::Spec;
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_crud' }
sub _defaults {
    return (
        table       => 'products',
        file_dir    => 'files',
        can         => 'CRUDL',
        no_time_sort => 0,
        opt         => {
            RaiseError => 1,
            AutoCommit => 1,
            mysql_enable_utf8 => 1,
        },

        # These are plug's parameters, but with no defaults
        #   dsn     => 'DBI:mysql:database=zofdb;host=localhost',
        #   user    => db_login
        #   pass    => db_pass
        #   opt     => db_opt
        #   items   => CRUD items
        #  list_sub => # sub for processing the list of output items

    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    return
        unless $conf->{items} and @{ $conf->{items} || [] };

    if ( ref $conf->{can} eq 'CODE' ) {
        $conf->{can} = $conf->{can}->( $t, $q, $config );
    }

    $conf->{can} = {
        map +( $_ => 1 ),
            grep /^[crudl]$/, map lc, split //, $conf->{can}
    };

    for ( keys %{ $conf->{can} } ) {
        $t->{t}{"crud_can_$_"} = 1;
    }

    @$self{ qw/CONF  T  Q  CONFIG/ } = ( $conf, $t, $q, $config );

    croak "Cannot have backticK(`) character in `table` parameter"
        if $conf->{table} =~ /`/;

    croak "Cannot have backticK(`) character in `order_by` parameter"
        if $conf->{order_by} =~ /`/;

    $self->_prepare_items;

    if ( $q->{crud_update_save} and $conf->{can}{u} ) {
        $self->_process_UPDATE_SAVE;
    }
    elsif ( $q->{crud_update} and $conf->{can}{u} ) {
        $self->_process_UPDATE_LOAD;
    }
    elsif ( $q->{crud_delete} and $conf->{can}{d} ) {
        $self->_process_DELETE;
    }
    elsif ( $q->{crud_create} and $conf->{can}{c} ) {
        $self->_process_CREATE;
    }

    if ( $conf->{can}{c}
        and not $q->{crud_update}
        and not $q->{crud_update_save}
    ) {
        $t->{t}{crud_form} = $self->_create_CU_form('yes_is_create_form');
    }
    elsif ( $conf->{can}{u} ) {
        $t->{t}{crud_form} = $self->_create_CU_form;
    }

    $t->{t}{crud_list} = $self->_create_list
        if $conf->{can}{l};
}

sub _process_UPDATE_SAVE {
    my $self = shift;

    my @errors;
    for ( grep !$_->{el_auto_set} && !$_->{el_file},
        @{ $self->{ITEMS} || [] }
    ) {
        next if $_->{optional};

        push @errors, +{ error => "Parameter '$_->{text}' must be specified" }
            unless defined $_->{value} and length $_->{value};
    }

    if ( @errors ) {
        $self->{FORM_ERRORS} = \@errors;
        return;
    }

    $self->_update_UPDATE_in_the_db;
}

sub _update_UPDATE_in_the_db {
    my $self = shift;

    my %items = map +( @$_{qw/name value/} ),
        grep !$_->{el_auto_set} && !$_->{el_file}, @{ $self->{ITEMS} };

    $self->_dbh->do(
        "UPDATE `$self->{CONF}{table}` SET " .
            join(',', map "`$_` = ?", keys %items )
            . ' WHERE `crud_id` = ?',
        undef,
        values %items,
        $self->{Q}{crud_id},
    );

    $self->{UPDATE_SUCCESS} = 1;
}

sub _process_UPDATE_LOAD {
    my $self = shift;

    my $item = ($self->_dbh->selectall_arrayref(
        'SELECT * FROM `' . $self->{CONF}{table}. '` WHERE `crud_id` = ?',
        { Slice => {} },
        $self->{Q}{crud_id},
    ) || [])->[0]
        or return $self->_set_error(q|Couldn't find the item to update|);

    for ( @{ $self->{ITEMS} || [] } ) {
        $_->{value} = $item->{ $_->{name} };
    }
}

sub _create_list {
    my $self = shift;

    my $is_do_sort_by_time = grep $_->{name} eq 'time', @{ $self->{ITEMS} };
    $is_do_sort_by_time = 0
        if $self->{CONF}{no_time_sort};

    my $db_items = $self->_dbh->selectall_arrayref(
        'SELECT * FROM `' . $self->{CONF}{table} . '`'
            . ( $is_do_sort_by_time ? ' ORDER BY `time`+0 DESC' : '' ),
        { Slice => {} },
    ) || [] ;

    my $Dt = HTML::Template->new_scalar_ref(
        \(_get_D_form_template()),
        die_on_bad_params => 0,
    );
    $Dt->param( page => $self->{Q}{page}, );
    $Dt = $Dt->output;

    my $Ut = HTML::Template->new_scalar_ref(
        \(_get_U_form_template()),
        die_on_bad_params => 0,
    );
    $Ut->param( page => $self->{Q}{page}, );
    $Ut = $Ut->output;

    my $conf = $self->{CONF};

    for ( @$db_items ) {
        $_->{crud_can_u} = $conf->{can}{u};
        $_->{crud_can_d} = $conf->{can}{d};
        $_->{crud_can_ud} = $_->{crud_can_u} || $_->{crud_can_d};
        ( $_->{crud_d_form} = $Dt )
            =~ s/\[<<ITEM:ID>>]/$_->{crud_id}/;
        ( $_->{crud_u_form} = $Ut )
            =~ s/\[<<ITEM:ID>>]/$_->{crud_id}/;
    }

    if ( ref $self->{CONF}{list_sub} ) {
        $self->{CONF}{list_sub}->( $db_items, $self->{T}, $self->{Q} );
    }

    if ( @$db_items ) {
        $self->{T}{t}{crud_has_items} = 1;
        $self->{T}{t}{crud_items} = $db_items;
    }
}

sub _process_DELETE {
    my $self = shift;

    ### Delete all the files, if we have any
    my @file_items = grep $_->{el_file}, @{ $self->{ITEMS} || [] };
    if ( @file_items ) {
        my $item = ($self->_dbh->selectall_arrayref(
            'SELECT * FROM `' . $self->{CONF}{table}. '` WHERE `crud_id` = ?',
            { Slice => {} },
            $self->{Q}{crud_id},
        ) || [])->[0]
            or return $self->_set_error(q|Couldn't find the item to delete|);

        for ( map $_->{name}, @file_items ) {
            unlink $item->{ $_ };
        }
    }

    $self->_dbh->do(
        'DELETE FROM `' . $self->{CONF}{table} . '` WHERE `crud_id` = ?',
        undef,
        $self->{Q}{crud_id},
    );

    $self->{T}{t}{crud_success_message}
    = '<p class="success-message">Item was successfully deleted.</p>';
}

sub _set_error {
    my $self = shift;
    my $error = shift;
    $self->{T}{t}{crud_error} = qq|<p class="error">$error</p>|;
    return;
}

sub _process_CREATE {
    my $self = shift;

    my @errors;
    for ( grep !$_->{el_auto_set}, @{ $self->{ITEMS} || [] } ) {
        next if $_->{optional};

        push @errors, +{ error => "Parameter '$_->{text}' must be specified" }
            unless defined $_->{value} and length $_->{value};
    }

    if ( @errors ) {
        $self->{FORM_ERRORS} = \@errors;
        return;
    }

    for my $item (
        grep $_->{el_file}
            && defined $self->{Q}{ $_->{name} }
            && length $self->{Q}{ $_->{name} }, @{ $self->{ITEMS} || [] }
    ) {
        push @errors, grep defined, $self->_process_file_upload( $item );
    }

    if ( @errors ) {
        $self->{FORM_ERRORS} = \@errors;
        return;
    }

    $self->_insert_CREATE_into_db;
}

sub _process_file_upload {
    my $self = shift;
    my $item = shift;

    my $cgi = $self->{CONFIG}{cgi};

    my $fh = $cgi->upload( $item->{name} );

    if ( not $fh and $cgi->cgi_error ) {
        return +{ error => 'File upload error: ' . $cgi->cgi_error };
    }

    return +{ error => q|File upload error (no error message available)| }
        unless $fh;

    ( my $filename = $item->{value} ) =~ s/[^\w.-]/_/g;
    while ( -e File::Spec->catdir( $self->{CONF}{file_dir}, $filename ) ) {
        $filename = "_$filename";
    }

    $filename = File::Spec->catdir( $self->{CONF}{file_dir}, $filename );

    return +{ error => "Failed to open local file $filename [$!]" }
        unless open my $fh_out, '>', $filename;

    seek $fh, 0, 0;
    binmode $fh;
    binmode $fh_out;

    {
        local $/ = \1024;
        while ( <$fh> ) {
            print $fh_out $_;
        }
    }

    close $fh;
    close $fh_out;

    $item->{value} = $filename;

    return;
}

sub _insert_CREATE_into_db {
    my $self = shift;

    my %items = map +( @$_{qw/name value/} ), @{ $self->{ITEMS} };

    $self->_dbh->do(
        "INSERT INTO `$self->{CONF}{table}` (" .
            join(',', map "`$_`", keys %items )
        . ') VALUES (' .
            join(', ', ('?') x (keys %items) )
        . ')',
        undef,
        values %items,
    );

    $self->{CREATE_SUCCESS} = 1
}

sub _create_CU_form {
    my $self = shift;
    my $is_create = shift;

    my $ht = HTML::Template->new_scalar_ref( \(_get_CU_form_template()),
        die_on_bad_params => 0,
    );

    my @items = @{ $self->{ITEMS} || [] };

    $ht->param(
        is_create   => $is_create,
        id          => $self->{Q}{crud_id},
        page        => $self->{Q}{dir} . $self->{Q}{page},
        has_files   => scalar( grep $_->{el_file}, @items ),
        elements    => [ grep !$_->{el_auto_set}, @items ],
        create_success  => $self->{CREATE_SUCCESS},
        update_success  => $self->{UPDATE_SUCCESS},
        hide_form       => ($self->{CREATE_SUCCESS} || $self->{UPDATE_SUCCESS}),
        (
            @{ $self->{FORM_ERRORS} || [] }
            ? ( errors      => $self->{FORM_ERRORS}, )
            : (),
        ),
    );

    return $ht->output;
}

sub _prepare_items {
    my $self = shift;

    $self->{ITEMS} = $self->{CONF}{items};

    for ( @{ $self->{ITEMS} || [] } ) {
        unless ( ref ) {
            $_ = +{ $_ => 'text' },
        }

        my ( $text, $type ) = %$_;
        ( my $name = lc $text ) =~ s/\W/_/g;

        my %opts;
        if ( ref $type eq 'ARRAY' ) {
            ( $type, %opts ) = ( @$type );
        }
        elsif ( ref $type eq 'CODE' ) {
            $self->{Q}{ $name } = $type->( @{ $self }{ qw/T  Q/ } );
            $type = 'auto_set';
        }
        my $id = "crud_$name";
        $_ = +{
            text        => $text,
            "el_$type"  => 1,
            name        => $name,
            id          => $id,
            value       => $self->{Q}{ $name },
            is_create   => !$self->{Q}{crud_update}
                            && !$self->{Q}{crud_update_save},
            %opts,
        };
    }

    return;
}

sub _get_D_form_template {
    return <<'END_HTML';
<form class="delete_button_form delete_form" method="POST" action=""
><div
    ><input type="hidden"
        name="page"
        value="<tmpl_var escape='html' name='page'>"
    ><input type="hidden"
        name="crud_delete"
        value="1"
    ><input type="hidden"
        name="crud_id"
        value="[<<ITEM:ID>>]"
    ><input type="image"
        alt="Delete"
        class="delete_button_no_style"
        src="/pics/delete-button.png"
></div></form>
END_HTML
}

sub _get_U_form_template {
    return <<'END_HTML';
<form class="update_button_form update_form" method="POST" action=""
><div
    ><input type="hidden"
        name="page"
        value="<tmpl_var escape='html' name='page'>"
    ><input type="hidden"
        name="crud_update"
        value="1"
    ><input type="hidden"
        name="crud_id"
        value="[<<ITEM:ID>>]"
    ><input type="image"
        alt="Update"
        class="update_button"
        src="/pics/update-button.png"
></div></form>
END_HTML
}

sub _get_CU_form_template {
    return <<'END_HTML';
<tmpl_if name='create_success'>
    <p class="success-message">Item has been successfully added. <a href="<tmpl_var escape='html' name='page'>">Add another one</a></p>
</tmpl_if>
<tmpl_if name='update_success'>
    <p class="success-message">Item has been successfully updated. <a href="<tmpl_var escape='html' name='page'>">Back to the form</a></p>
</tmpl_if>
<tmpl_unless name='hide_form'>
    <form action="" method="POST" id="crud_<tmpl_if name='is_create'>c<tmpl_else>u</tmpl_if>form"<tmpl_if name='has_files'> enctype="multipart/form-data"</tmpl_if>>
    <div>
        <input type="hidden" name="page"
            value="<tmpl_var escape='html' name='page'>">
        <input type="hidden" name="crud_<tmpl_if name='is_create'>create<tmpl_else>update_save</tmpl_if>" value="1">

        <tmpl_unless name='is_create'>
            <input type="hidden" name="crud_id"
                value="<tmpl_var escape='html' name='id'>">
        </tmpl_unless>

        <tmpl_loop name='errors'>
            <p class="error"><tmpl_var escape='html' name='error'></p>
        </tmpl_loop>

        <p class="crud_form_note">Fields marked with
            an asterisk(*) are mandatory.</p>
        <ul>
            <tmpl_loop name='elements'>
            <li>
                <tmpl_if name='el_text'>
                    <label for="<tmpl_var escape='html' name='id'>">
                        <tmpl_unless name='optional'>
                        *</tmpl_unless><tmpl_var
                            escape='html' name='text'>:</label>
                    <input type="text"
                        class="input_text"
                        name="<tmpl_var escape='html' name='name'>"
                        value="<tmpl_var escape='html' name='value'>"
                        id="<tmpl_var escape='html' name='id'>">
                </tmpl_if>
                <tmpl_if name='el_textarea'>
                    <label for="<tmpl_var escape='html' name='id'>"
                        class="textarea_label"
                        ><tmpl_unless name='optional'>
                        *</tmpl_unless><tmpl_var
                            escape='html' name='text'>:</label>
                    <textarea cols="60" rows="5"
                        name="<tmpl_var escape='html' name='name'>"
                        id="<tmpl_var escape='html' name='id'>"
                        ><tmpl_var escape='html' name='value'></textarea>
                </tmpl_if>
                <tmpl_if name='el_file'>
                    <tmpl_if name='is_create'>
                        <label for="<tmpl_var escape='html' name='id'>"
                            ><tmpl_unless name='optional'>
                        *</tmpl_unless><tmpl_var
                            escape='html' name='text'>:</label>
                        <input type="file"
                            class="input_file"
                            name="<tmpl_var escape='html' name='name'>"
                            id="<tmpl_var escape='html' name='id'>">
                    <tmpl_else>
                        Can't change files.
                    </tmpl_if>
                </tmpl_if>
            </li>
            </tmpl_loop>
        </ul>

        <input type="submit" value="Submit">
    </div>
    </form>
</tmpl_unless>
END_HTML
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::CRUD - Generic "Create Read Update Delete List" functionality

=head1 SYNOPSIS

In your ZofCMS Template:

    plugins => [
        qw/CRUD/,
    ],

    plug_crud => {
        table       => 'information_packages',
        file_dir    => 'files/information-packages/',
        items       => [
            'Item',
            { Description => [ 'textarea', optional => 1 ] },
            { File        => 'file'                        },
            { Time        => sub { time(); }               },
        ],
    },

Create a SQL table for the plugin to use:

    CREATE TABLE `information_packages` (
        `crud_id` INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
        `item` TEXT,
        `description` TEXT,
        `file` TEXT,
        `time` INT(10) UNSIGNED
    );

In your HTML::Template Template:

    <h2>Information Packages Admin</h2>

    <tmpl_var name='crud_success_message'>
    <tmpl_var name='crud_error'>

    <h3>Add New Item</h3>

    <tmpl_var name='crud_form'>

    <h3>Items In The Database</h3>

    <tmpl_if name='crud_has_items'>
        <table>
        <thead>
            <tr>
                <td>File</td>
                <td>Description</td>
                <td>Add Time</td>
            </tr>
        </thead>
        <tbody>
            <tmpl_loop name='crud_items'>
                <tr>
                    <td>
                    <tmpl_var name='crud_d_form'>
                    <tmpl_var name='crud_u_form'>
                    <a href="<tmpl_var escape='html' name='file'>"
                        target="_blank"><tmpl_var
                        escape='html' name='item'></a></td>
                    <td><tmpl_var name='description'></td>
                    <td><tmpl_var name='foo1'></td>
                    <td><tmpl_var name='foo2'></td>
                    <td><tmpl_var escape='html' name='time'></td>
                </tr>
            </tmpl_loop>
        </tbody>
        </table>
    <tmpl_else>
        <p>Currently there are no items in the database.</p>
    </tmpl_if>

=head1 DESCRIPTION

The plugin provides a generic "Create Read Update Delete List" functionality.
(Currently, READ is not implemented). In conjunction with this plugin,
you might find these plugins useful L<App::ZofCMS::Plugin::DBIPPT>
and L<App::ZofCMS::Plugin::FormChecker>.

=head1 ZofCMS TEMPLATE/MAIN CONFIG FILE FIRST LEVEL KEYS

The keys can be set either in ZofCMS template or in Main Config file,
if same keys are set in both, then the one in ZofCMS
template takes precedence.

=head2 C<plugins>

    plugins => [ qw/CRUD/ ],

You obviously would want to include the plugin in the
list of plugins to execute.

=head2 C<plug_crud>

    ### Mandatory fields without defaults: dsn, user, items

    plug_crud => {
        dsn             => 'DBI:mysql:database=zofdb;host=localhost',
        user            => 'db_login',
        pass            => 'db_pass',
        opt             => {
            RaiseError        => 1,
            AutoCommit        => 1,
            mysql_enable_utf8 => 1,
        },
        items       => [
            'Item',
            { Description => [ 'textarea', optional => 1 ] },
            { File        => 'file'                        },
            { Time        => sub { time(); }               },
        ],
        list_sub        => # sub for processing the list of output items
        table           => 'products',
        file_dir        => 'files/',
        can             => 'CRUDL',
        no_time_sort    => 0,
    }

B<Mandatory>. Takes either a hashref or a subref as a value. If a subref is
specified, its return value will be assigned to C<plug_crud> as if
it were already there. If the sub returns an C<undef>, then the plugin
will stop
further processing. The C<@_> of the subref will contain (in that order):
ZofCMS Template hashref, query parameters hashref, and
L<App::ZofCMS::Config> object. Possible keys/values for the hashref
are as follows:

=head3 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. Specifies the "DSN" for L<DBI> module. See L<DBI>'s docs for C<connect_cached()> method for more info on this one.

=head3 C<user>

    user => 'test',

B<Mandatory>. Specifies your username for the SQL database.

=head3 C<pass>

    pass => 'test',

B<Optional>. Specifies your password for the SQL database. If not specified,
behaviour will be akin to not having a set password.

=head3 C<opt>

    opt => {
        RaiseError => 1,
        AutoCommit => 1,
        mysql_enable_utf8 => 1,
    }

B<Optional>. Takes a hashref as a value. Specifies the
additional options for L<DBI>'s C<connect_cached()> method.
See L<DBI>'s docs for C<connect_cached()> method for more info on this
one. B<Defaults to:>
C<< { RaiseError => 1, AutoCommit => 1, mysql_enable_utf8 => 1, } >>

=head3 C<table>

    table => 'products',

B<Optional>. Takes a string as a value that represents the name of the
table in which to store the data. B<Defaults to:> C<products>

=head3 C<items>

    items => [
        'Item',
        { Description => [ 'textarea', optional => 1 ] },
        { File        => 'file'                        },
        { Time        => sub { time(); }               },
    ],

B<Mandatory>. B<Takes >an arrayref as a value that must contain at least
one item in it. Specifies the list of items
that comprise a single record that the plugin will create/read/update/delete.
B<Important note:> if you're not using C<time> item
to store time, see C<no_time_sort> option below; you'll likely want it set
to a true value, to avoid the plugin from erroring out.
The items in a list can be of these types:

=head4 String

    items => [
        'Item',
        q|Employee's Performance Record #|,
    ],

A simple string will be represented as a C<< <input type="text"> >>
in the Create/Update HTML form. The string will become the
C<< <label> >> text for the form element. Then everything in it that doesn't
match C<\w> will be converted into underscores, and C<lc()> will be run,
and that new string will be used for:

=over 10

=item * SQL column name for that field

=item * HTML C<< <input> >>'s C<name=""> attribute in the Create/Update form

=item * HTML C<id=""> attribute in the Create/Update form (prefix
C<crud_> will be added)

=item * C<< <tmpl_var> >> name for the List function of the plugin.

=back

=head4 B<An example:>

We have two items in our record that we'll manipulate with this plugin:

    items => [
        'Item',
        q|Employee's Performance Record #|,
    ],

We'll create a table, where field C<< `crud_id` >> is mandatory
and must contain the unique ID of the record (this example shows
MySQL taking care of that automatically):

    CREATE TABLE `example` (
        `crud_id` INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
        `item` TEXT,
        `employee_s_performance_record__` TEXT,
    );

Let's say we have L<App::ZofCMS::Plugin::FormChecker> checking the
input given to the Create form. The trigger will be
C<crud_create> and the fields it will be checking are
C<item> and C<employee_s_performance_record__>:

    plug_form_checker => {
        trigger     => 'crud_create',
        fail_code   => sub { my $t = shift; delete $t->{plug_crud} },
        rules       => {
            item                            => { max => 200 },
            employee_s_performance_record__ => 'num',
        },
    },

Lastly, when displaying the list of records, we'll use this code
in the HTML::Template template:

    <tmpl_if name='crud_has_items'>
        <table>
        <thead>
            <tr>
                <td>Item</td>
                <td>Employee's Performance Record #</td>
            </tr>
        </thead>
        <tbody>
            <tmpl_loop name='crud_items'>
                <tr>
                    <td><tmpl_var escape='html' name='item'></td>
                    <td><tmpl_var escape='html'
                        name='employee_s_performance_record__'></td>
                </tr>
            </tmpl_loop>
        </tbody>
        </table>
    <tmpl_else>
        <p>Currently there are no items in the database.</p>
    </tmpl_if>

=head4 hashref

    items => [
        { File        => 'file'                        },
        { Description => [ 'textarea', optional => 1 ] },
        { Time        => sub { time(); }               },
    ]

B<The key> of the hashref functions the same as described above for
C<String> (i.e. it'll be the C<< <label> >> and the base for the
C<name="">, etc.).
B<The value> of the hashref can be a string, an arrayref, or a subref:

=head4 A string

    items => [
        { File => 'file' },
    ],

When the value is a string, it will specify the type of HTML element to
use for this record item in the Create/Update form. B<Currently supported
values> are C<text> for C<< <input type="text"> >>, C<textarea> for
C<< <textarea> >>, and C<file> for C<< <input type="file"> >>.
File inputs are currently not editable in the Update form.

=head4 An arrayref

    items => [
        { Description => [ 'textarea', optional => 1 ] },
    ]

The first item in the arrayref will be the type of HTML element to
use for this record item (see C<A string> section right above). The
rest of the items are in key/value pairs and specify options for this
record. The currently available option is C<optional> that, when set to
a true value, will cause the item to be optional: an asterisk will not
be prepended to its label and an error will not show if the user leaves
this item blank in the Create/Update form.

=head4 A subref

    items => [
        { Time => sub { time(); } },
    ]

The key will function the same as described for C<A string> above. The
only difference is that this item will not be shown in the Create/Update
form. The sub will be executed and its value will be assigned to the item
as if it were specified by the user. On Update, this item will not be
editable and the sub B<will NOT be executed>. The C<@_> of the sub will
contain (in that order): ZofCMS Template hashref and query parameters
hashref where keys are params' names and values are their values.

=head3 C<list_sub>

    list_sub => sub {
        my ( $d, $t, $q ) = @_;

        for ( @$d ) {
            $_->{time} = localtime $_->{time};
            $_->{is_good_employee}
            = $t->{d}{records}{ $_->{employee_s_performance_record__} }
                ? 1 : 0;

            $_->{sort} = $q->{sort};
        }
    },

B<Optional.> B<By default> is not specified.
B<Takes >a subref as a value. Allows you to make modifications
to the list of records in the List output. The C<@_> of the sub will
contain (in that order): the arrayref of hashrefs where each hashref
is a record in the database, ZofCMS Template hashref, and query parameters
hashref where keys are params' names and values are their values. The
hashref for each record will contain all the columns from the database
for that specific record, as well as:

=over 10

=item * C<< crud_can_ud => 1 >> if the user
can either update or delete records (see C<can> parameter below),

=item * C<< crud_can_u => 1 >> if the user can update records

=item * C<< crud_can_d => 1 >> if the user can delete records

=item * C<< crud_d_form >> containing HTML of the form used for deleting
this record

=item * C<< crud_u_form >> containing HTML of the form used for
updating this record

=back

=head3 C<file_dir>

    file_dir => 'files',

B<Optional.> B<Defaults to> C<files>. B<Takes> a string as a value that
specifies the directory (relative to C<index.pl>) where the plugin
will store files uploaded by the user (that is for any records for which
C<< <input type="file"> >> was used in the Create form).

=head3 C<can>

    can => 'CRUDL',

    can => 'RL',

    can => 'CUL',

B<Optional.> B<Defaults to> C<CRUDL>. Takes a string of letters
(in any order) as the value. Each letter specifies what the current
user is allowed to do: C<< C => Create >>, C<< R => Read >>,
C<< U => Update >>, C<< D => Delete >>, C<< L => List >>. B<Note:>
if C<L> is specified, plugin will automatically load B<all> records into
C<< {t}{crud_list} >>.

=head3 C<no_time_sort>

    no_time_sort => 0,

B<Optional. Takes> true or false value. B<Defaults to> false. In 99%
of my CRUD pages, I've had a C<time> item in the record that stored
the time of
when the record was added, and when the records were listed they were
sorted by "most recent first." This is exactly what this plugin does
automatically
and it expects C<time> item to be present and set to a value of Unix time
(output of C<time()>). If you don't have such a column or don't want your
records sorted by time, set C<no_time_sort> to a true value.

=head1 HTML::Template TEMPLATE VARIABLES

    <tmpl_var name='crud_success_message'>
    <tmpl_var name='crud_error'>

    <h3>Add New Item</h3>

    <tmpl_var name='crud_form'>

    <h3>Items In The Database</h3>

    <tmpl_if name='crud_has_items'>
        <table>
        <thead>
            <tr>
                <td>File</td>
                <td>Description</td>
                <td>Add Time</td>
            </tr>
        </thead>
        <tbody>
            <tmpl_loop name='crud_items'>
                <tr>
                    <td>
                    <tmpl_var name='crud_d_form'>
                    <tmpl_var name='crud_u_form'>
                    <a href="<tmpl_var escape='html' name='file'>"
                        ><tmpl_var escape='html' name='item'></a></td>
                    <td><tmpl_var name='description'></td>
                    <td><tmpl_var name='foo1'></td>
                    <td><tmpl_var name='foo2'></td>
                    <td><tmpl_var escape='html' name='time'></td>
                </tr>
            </tmpl_loop>
        </tbody>
        </table>
    <tmpl_else>
        <p>Currently there are no items in the database.</p>
    </tmpl_if>

=head2 C<crud_success_message>

    <tmpl_var name='crud_success_message'>

This variable will contain
C<< <p class="success-message">Item was successfully deleted.</p> >>
when Delete action succeeds.

=head2 C<crud_error>

    <tmpl_var name='crud_error'>

This variable will contain an error message, if any, B<except for>
messages generated during submission of the Create/Update forms, as those
will be stuffed inside the form, but same HTML code will be wrapping
the error message.
The code will be C<< <p class="error">$error</p> >> where C<$error> is
the text of the error, which currently will be either
C<Couldn't find the item to update> or C<Couldn't find the item to delete>.

=head2 C<crud_form>

    <tmpl_var name='crud_form'>

This variable will contain either Create or Update form, depending on
whether is the user is trying to update a record.
See the source code of this module or
the output of C<crud_form> to find HTML code for the form.
This variable will be empty if the user doesn't have Create or Update
permissions (see C<can> configuration variable).

=head2 C<crud_has_items>

    <tmpl_if name='crud_has_items'>
        ... output the record list here
    <tmpl_else>
        <p>Currently there are no items in the database.</p>
    </tmpl_if>

Contains true or false values. If true, it means the plugin retrieved
at least one record with the List operation. This variable will always be
false if the user isn't allowed to I<List> (see C<can> configuration
argument).

=head2 C<crud_items>

   <tmpl_loop name='crud_items'>
        <tr>
            <td>
            <tmpl_var name='crud_d_form'>
            <tmpl_var name='crud_u_form'>
            <a href="<tmpl_var escape='html' name='file'>"
                ><tmpl_var escape='html' name='item'></a></td>
            <td><tmpl_var name='description'></td>
            <td><tmpl_var name='foo1'></td>
            <td><tmpl_var name='foo2'></td>
            <td><tmpl_var escape='html' name='time'></td>
        </tr>
    </tmpl_loop>

A loop containing records returned by the List operation. This variable
will be empty if the user isn't allowed to I<List> (see C<can> configuration
argument). The variables in the loop are as follows:

=head3 All items from C<items> configuration argument

    <a href="<tmpl_var escape='html' name='file'>"
        ><tmpl_var escape='html' name='item'></a></td>
    <td><tmpl_var name='description'></td>
    <td><tmpl_var name='foo1'></td>
    <td><tmpl_var name='foo2'></td>
    <td><tmpl_var escape='html' name='time'></td>

All the items you specified in the C<items> configuration argument will be
present here, even if that item was set as a subref in the C<items>.
You can also add extra keys here through C<list_sub> sub specified in the
configuration. B<Note:> any C<file> items will contain filename
I<and> directory specified in the C<file_dir> argument. You can modify that
using C<list_sub> sub.

=head3 C<crud_can_d>

    <tmpl_if name="crud_can_d">
        Can delete!
    </tmpl_if>

True or false value. If true, then the user is allowed to delete
records (see C<can> configuration argument).

=head3 C<crud_can_u>

    <tmpl_if name="crud_can_u">
        Can update!
    </tmpl_if>

True or false value. If true, then the user is allowed to update
records (see C<can> configuration argument).

=head3 C<crud_can_ud>

    <tmpl_if name="crud_can_ud">
        Can update or delete!
    </tmpl_if>

True or false value. If true, then the user is allowed to delete
B<or> update records (see C<can> configuration argument).

=head3 C<crud_u_form>

    <tmpl_var name='crud_u_form'>

Contains HTML code for the "Update Record" form. This HTML might change
in the future or be configurable, as currently it's highly specific
to what I use in a specific Web app. You can easily use your own form
by including C<crud_update> parameter set to a true value and
C<crud_id> paramater set to the ID of the record (that will be in the
C<< <tmpl_var name='crud_id> >>).

=head3 C<crud_d_form>

    <tmpl_var name='crud_d_form'>

Contains HTML code for the "Delete Record" form. This HTML might change
in the future or be configurable, as currently it's highly specific
to what I use in a specific Web app. You can easily use your own form
by including C<crud_delete> parameter set to a true value and
C<crud_id> paramater set to the ID of the record (that will be in the
C<< <tmpl_var name='crud_id> >>).

=head1 TODO AND LIMITATIONS

Currently, the module doesn't actually implement the "READ" functionality.
Instead, it only does "LIST" (i.e. list all records instead of a chosen
one) and it doesn't support pagination. If you expect a whole ton of
records in the database, heed the "L" flag in the C<can> option; if it's
present, the plugin will always load B<all> records into C<{t}>

Along with the "READ" optional and pagination, this plugin could make use
of absorbing some of the HTML for the LIST feature; so you'd have to
just type C<< <tmpl_var name="crud_list"> >> instead of doing HTML
by hand, but so far I haven't found a flexible solution that doesn't
drown the user of the plugin in settings options.

In addition, the plugin needs an option to add a variable amount of files,
all stored in a single database field, which in turn would allow updating
the file field during record editing.

Lastly, the plugin currently doesn't support
selects, checkboxes, or radio boxes in the Create/Update form.

=head1 A NOTE ON FORM INPUT ERROR CHECKING

This plugin only checks for whether or not a mandatory field is
present when creating/updating records. If you need more advanced error
checking, see L<App::ZofCMS::Plugin::FormChecker> that can (read "should")
work together with this plugin (run C<FormChecker> first).

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