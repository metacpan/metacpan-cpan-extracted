package App::ZofCMS::Plugin::BoolSettingsManager;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use HTML::Template;
use DBI;

sub _key { 'plug_bool_settings_manager' }
sub _defaults {
    return (
    dsn         => "DBI:mysql:database=test;host=localhost",
    user        => '',
    pass        => undef,
    opt         => { RaiseError => 1, AutoCommit => 1 },
    table       => 'users',
    login_col   => 'login',
    login       => sub { $_[0]->{d}{user}{login} },
#     settings    =>
    submit_button => q|<input type="submit" class="input_submit"|
                        . q| value="Save">|,
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    for ( qw/settings  login/ ) {
        $conf->{$_} = $conf->{$_}->( $t, $q, $config )
            if ref $conf->{$_} eq 'CODE';
    }

    return
        unless defined $conf->{settings}
            and @{ $conf->{settings} }
            and defined $conf->{login};

    $self->{CONF}   = $conf;
    $self->{Q}      = $q;
    $self->{Q_PAGE} = ( $q->{dir} || '' ) . ( $q->{page} || '' );

    $self->save_settings
        if $q->{pbsm_save_settings};

    $t->{t}{plug_bool_settings_manager_form} = $self->make_form;
}

sub save_settings {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};
    my $dbh  = $self->dbh;

    my %settings = @{ $conf->{settings} || [] };
    my @q_names = keys %settings;

    $dbh->do(
        'UPDATE `' . $conf->{table} .'` SET'
        . ( join ',', map "`$_` = ?", @q_names )
        . 'WHERE `' . $conf->{login_col} .'` = ?',
        undef,
        ( map +( $q->{$_} ? 1 : 0 ), @q_names ),
        $conf->{login},
    );
}

sub make_form {
    my $self = shift;
    my $q = $self->{Q};

    my $template = HTML::Template->new_scalar_ref(
        \ form_html_template(),
        die_on_bad_params => 0,
    );

    $template->param(
        ( $q->{pbsm_save_settings} ? ( save_success => 1 ) : () ),
        page        => $self->{Q_PAGE},
        settings    => $self->get_settings,
        submit_button => $self->{CONF}{submit_button},
    );

    return $template->output;
}

sub get_settings {
    my $self = shift;
    my $conf = $self->{CONF};
    my $dbh  = $self->dbh;

    my $user = ($dbh->selectall_arrayref(
        'SELECT * FROM `' . $conf->{table}
            . '` WHERE `' . $conf->{login_col} . '` = ?',
        { Slice => {} },
        $conf->{login},
    ) || [])->[0] || {};

    my @settings;
    my $key;
    for ( 0 .. $#{ $conf->{settings} } ) {
        if ( $_ % 2 == 0 ) {
            $key = $conf->{settings}[$_];
        }
        else {
            push @settings, {
                id         => $key,
                value      => $conf->{settings}[$_],
                is_checked => ( $user->{$key} ? 1 : 0 ),
            };
        }
    }

    return \@settings;
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

sub has_value {
    my $v = shift;

    return 1
        if defined $v and length $v;

    return 0;
}

sub form_html_template {
    return <<'END_HTML';
<tmpl_if name='save_success'>
    <p class="success-message">Successfully saved</p>
</tmpl_if>
<form action="" method="POST" id="plug_bool_settings_manager_form">
<div>
    <input type="hidden" name="page"
        value="<tmpl_var escape='html' name='page'>">
    <input type="hidden" name="pbsm_save_settings" value="1">
    <ul>
    <tmpl_loop name='settings'>
        <li id="pbsm_container_<tmpl_var escape='html' name='id'>">
            <input type="checkbox"
                id="pbsm_<tmpl_var escape='html' name='id'>"
                name="<tmpl_var escape='html' name='id'>"
                <tmpl_if name='is_checked'>checked</tmpl_if>
                ><label for="pbsm_<tmpl_var escape='html' name='id'>"
                    class="checkbox_label"> <tmpl_var escape='html' name='value'></label>
        </li>
    </tmpl_loop>
    </ul>

    <tmpl_var name="submit_button">
</div>
</form>
END_HTML
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::BoolSettingsManager - Plugin to let individual users manage boolean settings

=head1 SYNOPSIS

In L<HTML::Template> template:

    <tmpl_var name='plug_bool_settings_manager_form'>

In ZofCMS Template:

    plugins => [
        qw/BoolSettingsManager/,
    ],

    plug_bool_settings_manager => {
        settings => [
            notice_forum         => q|new forum posts|,
            notice_flyers        => q|new flyer uploads|,
            notice_photo_library => q|new images added to Photo Library|,
        ],

        # everything below is optional; default values are shown
        dsn           => "DBI:mysql:database=test;host=localhost",
        user          => '',
        pass          => undef,
        opt           => { RaiseError => 1, AutoCommit => 1 },
        table         => 'users',
        login_col     => 'login',
        login         => sub { $_[0]->{d}{user}{login} },
        submit_button => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to present
a user a form with a number of checkboxes that control boolean settings,
which are stored in a SQL database.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/BoolSettingsManager/ ],

B<Mandatory>. You need to include the plugin in the list of plugins
to execute.

=head2 C<plug_bool_settings_manager>

    plug_bool_settings_manager => {
        settings => [
            notice_forum         => q|new forum posts|,
            notice_flyers        => q|new flyer uploads|,
            notice_photo_library => q|new images added to Photo Library|,
        ],

        # everything below is optional; default values are shown
        dsn           => "DBI:mysql:database=test;host=localhost",
        user          => '',
        pass          => undef,
        opt           => { RaiseError => 1, AutoCommit => 1 },
        table         => 'users',
        login_col     => 'login',
        login         => sub { $_[0]->{d}{user}{login} },
        submit_button => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    },

B<Mandatory>. Takes either a hashref or a subref as a value.
If subref is specified, its return value will be assigned to
C<plug_bool_settings_manager> key as if it was already there.
If sub returns an C<undef>, then plugin will stop further processing.
The C<@_> of the subref will contain C<$t>, C<$q>, and C<$config>
(in that order), where C<$t> is ZofCMS Template hashref,
C<$q> is query parameters hashref, and C<$config> is the
L<App::ZofCMS::Config> object. Possible keys/values for the hashref
are as follows:

=head3 C<settings>

    plug_bool_settings_manager => {
        settings => [
            notice_forum         => q|new forum posts|,
            notice_flyers        => q|new flyer uploads|,
            notice_photo_library => q|new images added to Photo Library|,
        ],
    ...

    plug_bool_settings_manager => {
        settings => sub {
            my ( $t, $q, $config ) = @_;
            return $arrayref_to_assing_to_settings;
        },
    ...

B<Mandatory>. Takes an arrayref or a subref as a value. If subref is
specified, its return value must be either an arrayref or
C<undef> (or empty list). The C<@_> of the subref will contain C<$t>,
C<$q>, and C<$config> (in that order), where C<$t> is ZofCMS Template
hashref, C<$q> is query parameters hashref, and C<$config> is the
L<App::ZofCMS::Config> object.

If C<settings> is not specified, or its arrayref is empty, or if the subref
returns C<undef>, empty arrayref or empty list, plugin will stop further
execution.

The arrayref must have an even number of elements that are to be thought
of as keys and values (the arrayref is used to preserve order). The "keys"
of the arrayref represent boolean column names in C<table> (see below)
SQL table in which users' settings are stored (one setting per column).
The keys will also be used as parts of C<id=""> attributes in the form, thus
they need to also conform to HTML spec (L<http://xrl.us/bicips>)
(or whatever your markup language of choice is).

The "values" must be strings that represent the human readable description
of their corresponding "keys". These will be shown as text in the C<<
<label> >>s for corresponding checkboxes.

=head3 C<dsn>

    plug_bool_settings_manager => {
        dsn => "DBI:mysql:database=test;host=localhost",
    ...

B<Optional, but the default is pretty useless>.
The C<dsn> key will be passed to L<DBI>'s
C<connect_cached()> method, see documentation for L<DBI> and
C<DBD::your_database> for the correct syntax for this one.
The example above uses MySQL database called C<test> which is
located on C<localhost>.
B<Defaults to:> C<"DBI:mysql:database=test;host=localhost">

=head3 C<user>

    plug_bool_settings_manager => {
        user => '',
    ...

B<Optional>. Specifies the user name (login) for the database. This can be
an empty string if, for example, you are connecting using SQLite
driver. B<Defaults to:> C<''> (empty string)

=head3 C<pass>

    plug_bool_settings_manager => {
        pass => undef,
    ...

B<Optional>. Same as C<user> except specifies the password for the
database. B<Defaults to:> C<undef> (no password)

=head3 C<opt>

    plug_bool_settings_manager => {
        opt => { RaiseError => 1, AutoCommit => 1 },
    ...

B<Optional>. Will be passed directly to L<DBI>'s C<connect_cached()> method
as "options". B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<table>

    plug_bool_settings_manager => {
        table => 'users',
    ...

B<Optional>. Takes a string as a value that specifies the name of the
table in which users' logins and their settings are stored.
B<Defaults to:> C<users>

=head3 C<login_col>

    plug_bool_settings_manager => {
        login_col => 'login',
    ...

B<Optional>. Takes a string as a value that specifies the name of the
column in C<table> table that contains users' logins.
B<Defaults to:> C<login>

=head3 C<login>

    plug_bool_settings_manager => {
        login => sub {
            my ( $t, $q, $config ) = @_;
            return $t->{d}{user}{login};
        },
    ...

    plug_bool_settings_manager => {
        login => 'zoffix',
    ...

B<Optional>. Takes an C<undef>, a subref or a scalar as a value.
Specifies the login of a current user. This is the value located in the
C<login_col> (see above) column. This will be used to look up/store the
settings. If a subref is specified, its return value must be either an
C<undef> or a scalar, which will be assigned to C<login> as if it was
already there. If C<login> is set to C<undef> (or the sub returns an
C<undef>/empty list), then plugin will stop further execution. The C<@_> of
the subref will contain C<$t>, C<$q>, and C<$config> (in that order), where
C<$t> is ZofCMS Template hashref, C<$q> is query parameters hashref, and
C<$config> is the L<App::ZofCMS::Config> object. B<Defaults to:>
C<< sub { $_[0]->{d}{user}{login} } >>

=head3 C<submit_button>

    plug_bool_settings_manager => {
        submit_button => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    ...

B<Optional>. Takes HTML code as a value, which represents the submit
button to be used on the settings-changing form. Feel free to throw in
any extra code into this argument. B<Defaults to:>
C<< <input type="submit" class="input_submit" value="Save"> >>

=head1 HTML::Template TEMPLATE VARIABLE

All of plugin's output is spit out into a single variable in your
L<HTML::Template> template:

    <tmpl_var name='plug_bool_settings_manager_form'>

=head1 HTML CODE GENERATED BY THE PLUGIN

The HTML code below was generated after saving settings in the form
generated using this plugin's C<settings> argument:

    settings => [
        notice_forum         => q|new forum posts|,
        notice_flyers        => q|new flyer uploads|,
        notice_photo_library => q|new images added to Photo Library|,
    ],

Notice the "keys" in the C<settings> arrayref are used to generate
C<id=""> attributes on the C<< <li> >> and C<< <input> >> elements
(and C<for=""> attribute on C<< <label> >>s). The value for C<page>
hidden C<< <input> >> is derived by the plugin automagically.

    <p class="success-message">Successfully saved</p>

    <form action="" method="POST" id="plug_bool_settings_manager_form">
    <div>
        <input type="hidden" name="page" value="/index">
        <input type="hidden" name="pbsm_save_settings" value="1">

        <ul>
            <li id="pbsm_container_notice_forum">
                <input type="checkbox"
                    id="pbsm_notice_forum"
                    name="notice_forum"
                ><label for="pbsm_notice_forum"
                    class="checkbox_label"> new forum posts</label>
            </li>
            <li id="pbsm_container_notice_flyers">
                <input type="checkbox"
                    id="pbsm_notice_flyers"
                    name="notice_flyers"
                ><label for="pbsm_notice_flyers"
                    class="checkbox_label"> new flyer uploads</label>
            </li>
            <li id="pbsm_container_notice_photo_library">
                <input type="checkbox"
                    id="pbsm_notice_photo_library"
                    name="notice_photo_library"
                    checked
                ><label for="pbsm_notice_photo_library"
                    class="checkbox_label"> new images added to Photo Library</label>
            </li>
        </ul>
        <input type="submit" class="input_submit" value="Save">
    </div>
    </form>

The C<< <p class="success-message">Successfully saved</p> >> paragraph
is only shown when user saves their settings.

=head1 REQUIRED MODULES

Plugin requires the following modules to survive:

    App::ZofCMS::Plugin::Base => 0.0106,
    HTML::Template            => 2.9,
    DBI                       => 1.607,

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