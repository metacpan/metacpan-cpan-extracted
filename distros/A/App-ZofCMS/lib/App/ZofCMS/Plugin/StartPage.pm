package App::ZofCMS::Plugin::StartPage;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use HTML::Template;
use DBI;

sub _key { 'plug_start_page' }
sub _defaults {
    return (
    dsn         => "DBI:mysql:database=test;host=localhost",
    user        => '',
    pass        => undef,
    opt         => { RaiseError => 1, AutoCommit => 1 },
    table       => 'users',
    login_col   => 'login',
    page_col    => 'start_page',
    login       => sub { $_[0]->{d}{user}{login} },
    # pages       => [],
    label_text    => 'Start page:',
    default_page  => undef,
    no_redirect   => undef,
    submit_button => q|<input type="submit" class="input_submit"|
                        . q| value="Save">|,
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    for ( qw/pages  login/ ) {
        $conf->{$_} = $conf->{$_}->( $t, $q, $config )
            if ref $conf->{$_} eq 'CODE';
    }

    return
        unless defined $conf->{pages}
            and @{ $conf->{pages} }
            and defined $conf->{login};

    @{ $conf->{pages} } % 2
        and die '`pages` must contain even number of elements';

    $self->{CONF}   = $conf;
    $self->{Q}      = $q;
    $self->{Q_PAGE} = ( $q->{dir} || '' ) . ( $q->{page} || '' );

    my $page = $self->get_redirect_page;

    unless ( $conf->{no_redirect} ) {
        if ( has_value( $page ) ) {
            print $config->cgi->redirect( $page );
            exit;
        }
        else {
            return;
        }
    }

    $self->prepare_pages;
    $self->save_settings
        if $q->{plugsp_save_settings};

    $t->{t}{plug_start_page_form} = $self->make_form;
}

sub get_redirect_page {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};
    my $dbh  = $self->dbh;

    my $page = ($dbh->selectall_arrayref(
        'SELECT `' . $conf->{page_col} . '` FROM `' .
            $conf->{table} . '` WHERE `' .
            $conf->{login_col} . '` = ?',
        { Slice => {} },
        $conf->{login},
    ) || [])->[0] || {};

    if ( has_value( $page->{ $conf->{page_col} } ) ) {
        $page = $page->{ $conf->{page_col} };
    }
    elsif ( has_value( $conf->{default_page} ) ) {
        $page = $conf->{default_page};
    }
    else {
        undef $page;
    }

    $conf->{redirect_page} = $page;
    return $page;
}

sub save_settings {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};

    return
        unless has_value( $q->{plugsp_page} )
            and $conf->{valid_pages}{ $q->{plugsp_page} };

    for ( @{ $conf->{pages} || [] } ) {
        $_->{is_selected} = $_->{page} eq $q->{plugsp_page} ? 1 : 0;
    }

    my $dbh = $self->dbh;
    $dbh->do(
        'UPDATE `' . $conf->{table} . '` SET `' . $conf->{page_col}
            . '` = ? WHERE `' . $conf->{login_col} . '` = ?',
        undef,
        $q->{plugsp_page},
        $conf->{login},
    );

    $conf->{save_settings_ok} = 1;
}

sub prepare_pages {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};

    my %valid_pages;
    my @proper_pages;
    my $key;
    my $is_redirect_page = 0;
    my $redir_page = has_value( $conf->{redirect_page} )
        ? $conf->{redirect_page} : $conf->{pages}[0];

    for ( 0 .. $#{ $conf->{pages} } ) {
        if ( $_ % 2 == 0 ) {
            $key                 = $conf->{pages}[ $_ ];
            $valid_pages{ $key } = 1;
            $is_redirect_page    = $redir_page eq $key ? 1 : 0;
        }
        else {
            push @proper_pages, {
                page        => $key,
                name        => $conf->{pages}[ $_ ],
                is_selected => $is_redirect_page,
            };
        }
    }

    $conf->{pages}       = \@proper_pages;
    $conf->{valid_pages} = \%valid_pages;
}

sub make_form {
    my $self = shift;
    my $conf = $self->{CONF};

    my $template = HTML::Template->new_scalar_ref(
        \ form_html_template(),
        die_on_bad_params => 0,
    );

    $template->param(
        ( $conf->{save_settings_ok} ? ( save_success => 1 ) : () ),
        page          => $self->{Q_PAGE},
        pages         => $conf->{pages},
        submit_button => $conf->{submit_button},
        label_text    => $conf->{label_text},
    );

    return $template->output;
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
<form action="" method="POST" id="plug_start_page_form">
<div>
    <input type="hidden" name="page"
        value="<tmpl_var escape='html' name='page'>">
    <input type="hidden" name="plugsp_save_settings" value="1">

    <label for="plugsp_page"><tmpl_var escape='html'
        name='label_text'></label
    ><select id="plugsp_page" name="plugsp_page"
    ><tmpl_loop name='pages'>
        <option value="<tmpl_var escape='html' name='page'>"
            <tmpl_if name='is_selected'>selected</tmpl_if>
        ><tmpl_var escape='html' name='name'></option>
    </tmpl_loop>

    <tmpl_var name="submit_button">
</div>
</form>
END_HTML
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::StartPage - ZofCMS plugin that redirects the user to a page choosen by the user

=head1 SYNOPSIS

In L<HTML::Template> template:

    <tmpl_var name='plug_start_page_form'>

In ZofCMS Template:

    plugins => [ qw/StartPage/ ],

    plug_start_page => {
        pages => [
            'http://google.ca/'             => 'Google',
            'http://zoffix.com/'            => 'Zoffix Znet Portal',
            'http://mind-power-book.com/'   => 'Mind Power Book',
        ],

        # everthing below is optional; default values are shown
        dsn           => "DBI:mysql:database=test;host=localhost",
        user          => '',
        pass          => undef,
        opts          => { RaiseError => 1, AutoCommit => 1 },
        no_redirect   => undef,
        table         => 'users',
        login_col     => 'login',
        page_col      => 'start_page',
        login         => sub { $_[0]->{d}{user}{login} },
        label_text    => 'Start page:',
        default_page  => undef,
        submit_button => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to present
a user a form where they can select one of several pages to which to
redirect (selection is stored in a SQL database). The module was
designed to provide means to let the users select their landing pages
upon logon, which is how the name of the module originated.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/StartPage/ ],

B<Mandatory>. You need to include the plugin in the list of plugins
to execute.

=head2 C<plug_start_page>

    plug_start_page => {
        pages => [
            'http://google.ca/'             => 'Google',
            'http://zoffix.com/'            => 'Zoffix Znet Portal',
            'http://mind-power-book.com/'   => 'Mind Power Book',
        ],

        # everthing below is optional; default values are shown
        dsn           => "DBI:mysql:database=test;host=localhost",
        user          => '',
        pass          => undef,
        opts          => { RaiseError => 1, AutoCommit => 1 },
        no_redirect   => undef,
        table         => 'users',
        login_col     => 'login',
        page_col      => 'start_page',
        login         => sub { $_[0]->{d}{user}{login} },
        label_text    => 'Start page:',
        default_page  => undef,
        submit_button => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    },

B<Mandatory>. Takes either a hashref or a subref as a value.
If subref is specified, its return value will be assigned to
C<plug_start_page> key as if it was already there.
If sub returns an C<undef>, then plugin will stop further processing.
The C<@_> of the subref will contain C<$t>, C<$q>, and C<$config>
(in that order), where C<$t> is ZofCMS Template hashref,
C<$q> is query parameters hashref, and C<$config> is the
L<App::ZofCMS::Config> object. Possible keys/values for the hashref
are as follows:

=head3 C<pages>

    plug_start_page => {
        pages => [
            'http://google.ca/'             => 'Google',
            'http://zoffix.com/'            => 'Zoffix Znet Portal',
            'http://mind-power-book.com/'   => 'Mind Power Book',
        ],
    ...

    plug_start_page => {
        pages => sub {
            my ( $t, $q, $config ) = @_;
            return $t->{plug_start_page__pages_arrayref};
        }
    ...

B<Mandatory>. Takes an arrayref or a subref as a value. If subref is
specified, its return value must be either an arrayref or
C<undef> (or empty list). The return value will be assigned to
C<pages> as if it was already there. The C<@_> of the subref will
contain C<$t>, C<$q>, and C<$config> (in that order), where C<$t> is
ZofCMS Template hashref, C<$q> is query parameters hashref,
and C<$config> is the L<App::ZofCMS::Config> object.

If C<pages> is not specified, or its arrayref is empty, or if the subref
returns C<undef>, empty arrayref or empty list, plugin will stop further
execution.

The arrayref must have an even number of elements that are to be thought
of as keys and values (the arrayref is used to preserve order). The "keys"
of the arrayref represent URIs to which to redirect the user and
the "values" must be strings that represent the human readable description
of their corresponding "keys". These will be shown as text in the C<<
<option> >>s in the start page selection form; the order being the same
as what you specify here, in C<pages>.

=head3 C<dsn>

    plug_start_page => {
        dsn => "DBI:mysql:database=test;host=localhost",
    ...

B<Optional, but with a useless default>. The C<dsn> key will be passed
to L<DBI>'s C<connect_cached()> method, see documentation for L<DBI> and
C<DBD::your_database> for the correct syntax for this one. The example
above uses MySQL database called C<test> which is located
on C<localhost>. B<Defaults to:>
C<DBI:mysql:database=test;host=localhost>

=head3 C<user>

    plug_start_page => {
        user => '',
    ...

B<Optional>. Specifies the user name (login) for the database. This
can be an empty string if, for example, you are connecting using SQLite
driver. B<Defaults to:> C<''> (empty string)

=head3 C<pass>

    plug_start_page => {
        pass => undef,
    ...

B<Optional>. Same as C<user> except specifies the password for the
database. B<Defaults to:> C<undef> (no password)

=head3 C<opts>

    plug_start_page => {
        opts => { RaiseError => 1, AutoCommit => 1 },
    ...

B<Optional>. Will be passed directly to L<DBI>'s C<connect_cached()>
method as "options". B<Defaults to:>
C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<no_redirect>

    plug_start_page => {
        no_redirect => undef,
    ...

B<Optional>. Takes either true or false values. If set to a true value,
plugin will B<not> redirect the user and will present them with
a start page selection form (see HTML::Template VARIABLES and
GENERATED HTML CODE sections below). If set to a false value,
plugin will look up which start page the user chose and redirect
to it B<and will call> C<exit()> B<right after that>. If user has
not chosen any start pages, plugin will redirect the user to the URI
specified by C<default_page> (see below) and will B<also call>
C<exit()>. If C<default_page> is not specified, plugin will B<NOT>
redirect the user anywhere, and will simply stop processing (without
calling C<exit()>).
B<Defaults to:> C<undef> (process redirections)

=head3 C<table>

    plug_start_page => {
        table => 'users',
    ...

    # Minimal needed table:
    CREATE TABLE `users` (
        `login`      TEXT,
        `start_page` TEXT
    );

B<Optional>. Specifies the name of the SQL table into which to store
start page choices the user selects. Configuration of the table
can be anything you like, but must at least contain two columns
(as shown in the example above): the C<login_col> (see below)
that can be of any type; and C<page_col> that needs to be of type
suitable for storing the URIs of your start pages. B<NOTE:> the
table B<must already contain a row with the user's login>, as plugin
only calls SQL C<UPDATE>, which won't save user's start page unless
their row is already in the database. B<Defaults to:> C<users>

=head3 C<login_col>

    plug_start_page => {
        login_col => 'login',
    ...

B<Optional>. Takes a string as value that specifies the name of
a column in C<table> table that contains usernames of users. The
plugin will look for C<login> (see below) value in this column in order
to find saved start page. B<Defaults to:> C<login>

=head3 C<page_col>

    plug_start_page => {
        page_col => 'start_page',
    ...

B<Optional>. Takes a string as value that specifies the name of
a column in C<table> table that contains users' start page settings. The
plugin will read/write into this column, so make sure that data type
is suitable for storing your start page URIs.
B<Defaults to:> C<start_page>

=head3 C<login>

    plug_start_page => {
        login => sub { $_[0]->{d}{user}{login} }, # @_ = ( $t, $q, $config );
    ...

    plug_start_page => {
        login => 'zoffix',
    ...

B<Optional>. Takes a subref, C<undef>, or a string as a value.
Specifies the login of the current user that plugin will use to look
up saved start page setting. If C<undef> is specified or the
subref returns an C<undef> or an empty list, plugin will stop further
processing. If subref is specified, its return value will be assigned to
C<login> as if it was already there. The C<@_> of the subref will
contain C<$t>, C<$q>, and C<$config> (in that order), where C<$t> is
ZofCMS Template hashref, C<$q> is query parameters hashref,
and C<$config> is the L<App::ZofCMS::Config> object.
B<Defaults to:> C<< sub { $_[0]->{d}{user}{login} } >>

=head3 C<label_text>

    plug_start_page => {
        label_text => 'Start page:',
    ...

B<Optional>. Takes a string as a value. Specifies the text for the
C<< <label> >> element in the start page selection form.
B<Defaults to:> C<Start page:>

=head3 C<default_page>

    plug_start_page => {
        default_page => undef,
    ...

    plug_start_page => {
        default_page => 'http://mind-power-book.com/',
    ...

B<Optional>. Takes either C<undef> or a string as a value.
If set to a string and the user does not have saved start page
setting, then the user will be redirected to C<default_page> URI.
If C<default_page> is not specified (C<undef>), then user will not
be redirected anywhere (that is, when their start page was never
chosen). B<Defaults to:> C<undef>

=head3 C<submit_button>

    plug_start_page => {
        submit_button => q|<input type="submit" class="input_submit"|
                            . q| value="Save">|,
    ...

B<Optional>. Takes HTML code as a value. Specifies the HTML
code for the submit button of the start page selecting form.
Feel free to insert here any extra HTML code you might require.
B<Defaults to:>
C<< <input type="submit" class="input_submit" value="Save"> >>

=head1 HTML::Template VARIABLES

If C<no_redirect> argument (see above) is set to a true value, the
plugin will stick C<plug_start_page_form> variable into C<{t}>
ZofCMS Template special key. It will contain the start page selecting
form in it.

    <tmpl_var name='plug_start_page_form'>

=head1 GENERATED HTML CODE

Here's what plugin generated start page selecting form looks like:

    <p class="success-message">Successfully saved</p>

    <form action="" method="POST" id="plug_start_page_form">
    <div>
        <input type="hidden" name="page" value="/index">
        <input type="hidden" name="plugsp_save_settings" value="1">

        <label for="plugsp_page">Start page:</label
        ><select id="plugsp_page" name="plugsp_page"
        >
            <option value="http://google.ca/">Google</option>
            <option value="http://zoffix.com/"
                selected
            >Zoffix Znet Portal</option>
            <option value="http://mind-power-book.com/">Mind Power Book</option>
        <input type="submit" class="input_submit" value="Save">
    </div>
    </form>

The value for C<page> hidden C<< <input> >> is derived by the plugin
automagically. The C<< <p class="success-message">Successfully saved</p>
>> element is shown only when the user saves their settings. The text
for the C<< <label> >> is controlled by the C<label_text> argument,
and the HTML code of the submit button is controlled by
C<submit_button>.

=head1 REQUIRED MODULES

Plugin likes to play with these modules:

    App::ZofCMS::Plugin::Base => 0.0106,
    HTML::Template            => 2.9,
    DBI                       => 1.609,

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