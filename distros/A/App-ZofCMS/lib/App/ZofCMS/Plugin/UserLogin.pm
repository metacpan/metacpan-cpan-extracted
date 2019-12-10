package App::ZofCMS::Plugin::UserLogin;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use DBI;
use HTML::Template;
use Digest::MD5 (qw/md5_hex/);
use URI::Escape;

# create TABLE users (login TEXT, password VARCHAR(32), login_time VARCHAR(10), session_id VARCHAR(55), role VARCHAR(20));


sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query_ref, $config ) = @_;


    return
        unless $template->{plug_login}
            or $config->conf->{plug_login};

    my %opts = (
        login_page  => '/login',
        table       => 'users',
        user_ref    => sub {
            my ( $user_ref, $template ) = @_;
            $template->{d}{plug_login_user} = $user_ref;
        },
        opt         => { RaiseError => 1, AutoCommit => 0 },
        redirect_on_restricted => '/',

        login_button => '<input type="submit" class="input_submit" value="Login">',
        logout_button => '<input type="submit" class="input_submit" value="Logout">',

        %{ $config->conf->{plug_login}    || {} },
        %{ delete $template->{plug_login} || {} },
    );

    $self->opts( \%opts );

    $self->{COOKIE_LOGIN} = $config->cgi->cookie( $opts{preserve_login} )
        if defined $opts{preserve_login}
            and length $opts{preserve_login}
            and not $opts{no_cookies};

    my %query = %$query_ref;
    for ( values %query ) {
        $_ = ''
            unless defined;
    }
    $query{page} = $query{dir} . $query{page};

    if ( ( ref $opts{login_page} eq 'Regexp'
            and
          $query{page} =~ /$opts{login_page}/
        )
        or (
           not ref $opts{login_page}
           and $query{page} eq $opts{login_page}
        )
    ) {
        $self->process_login_page( $template, \%query, $config );
    }

    my ( $user_ref, $user_ref_raw ) = $self->is_logged_in( \%query, $config );

    if ( $opts{user_ref} ) {
        $opts{user_ref}->( $user_ref_raw, $template, $query_ref, $config->conf );
    }

    if ( $self->is_page_restricted( $query{page}, $user_ref ) ) {
        if ( $opts{redirect_on_restricted} ) {
            print $config->cgi->redirect(
                $opts{redirect_on_restricted}
                . process_smart_deny( \%opts )
            );
            exit;
        }
    }
    if ( $user_ref ) {
        if ( exists $query{zofcms_plugin_login}
            and $query{zofcms_plugin_login} eq 'logout_user' ) {
            $self->log_user_out( $user_ref );
            if ( $opts{redirect_on_logout} ) {
                print $config->cgi->redirect( $opts{redirect_on_logout} );
                exit;
            }
        }
        else {
            my $t = HTML::Template->new_scalar_ref(
                \ $self->logout_form_template()
            );
            $t->param(
                page            => $query{page},
                logout_button   => $opts{logout_button},
            );
            $template->{t}{plug_login_logout} = $t->output;
        }

        $template->{t}{plug_login_user} = $user_ref->{login};
    }

    return 1;
}

sub log_user_out {
    my ( $self, $user_ref ) = @_;
    my $opts = $self->opts;

    my $dbh = DBI->connect_cached(
        @$opts{ qw/dsn user pass opt/ },
    );

    $dbh->do(
        "UPDATE $opts->{table} SET session_id = ?, login_time = ? WHERE "
        . "login = ?; ",
        undef,
        0,
        0,
        $user_ref->{login},
    );
}

sub is_page_restricted {
    my ( $self, $page, $user_ref ) = @_;
    my $opts = $self->opts;

    if ( $page eq $opts->{login_page} ) {
        return;
    }

    for ( @{ $opts->{not_restricted} || [] } ) {
        if ( $self->page_matches( $page, $_ ) ) {
            if ( ref eq 'HASH' ) {
                if ( exists $_->{role} ) {
                    return if ref $_->{role} eq 'SCALAR';
                    return exists $user_ref->{role}{ $_->{role} } ? () : 1;
                }
                else {
                    return;
                }
            }
            else {
                return;
            }
        }
    }

    for ( @{ $opts->{restricted} || [] } ) {
        if ( $self->page_matches( $page, $_ ) ) {
            defined $user_ref
                or return 1;

            if ( ref eq 'HASH' ) {
                return 1 if ref $_->{role} eq 'SCALAR';
                return exists $user_ref->{role}{ $_->{role} } ? 1 : ();
            }
            else {
                return 0;
            }
        }
    }

    return;
}

sub page_matches {
    my ( $self, $page, $what ) = @_;

    if ( ref $what eq 'Regexp' ) {
        return $page =~ /$what/ ? 1 : ();
    }
    elsif ( ref $what eq 'HASH' ) {
        if ( ref $what->{page} eq 'Regexp' ) {
            return $page =~ /$what->{page}/ ? 1 : ();
        }
        elsif ( $what->{page} eq $page ) {
            return 1;
        }
        return 0;
    }
    elsif ( $what eq $page ) {
        return 1;
    }
    return;
}

sub is_logged_in {
    my ( $self, $query, $config) = @_;

    my $opts = $self->opts;
    my ( $cookie_l, $cookie_s ) = ( $self->cookie_l, $self->cookie_s );
    my $login_hash =
        defined $cookie_l ? $cookie_l : $config->cgi->cookie('zofcms_plug_login_l');

    my $session_id =
        defined $cookie_s ? $self->cookie_s : $config->cgi->cookie('zofcms_plug_login_s');

    my $dbh = DBI->connect_cached(
        @$opts{ qw/dsn user pass opt/ }
    );

    my $users = $dbh->selectall_arrayref(
        "SELECT * FROM $opts->{table} WHERE session_id = ?",
        undef,
        $session_id,
    );

    my $user_ref;
    for ( @$users ) {
        if ( md5_hex($_->[0]) eq $login_hash ) { # login
            $user_ref = $_;
            last;
        }
    }

    $user_ref
        or return;

    my $user_ref_raw = $user_ref;
    @{ $user_ref = {} }{ qw/login password login_time session_id role/ }
    = @$user_ref;
    $user_ref->{role} = { map { $_ => 1 } split /,/, $user_ref->{role} };

    if ( $opts->{limited_time}
        and $user_ref->{login_time} < time() - $opts->{limited_time}
    ) {
        $dbh->do(
            "UPDATE $opts->{table} SET login_time = ? WHERE login = ?;",
            undef,
            0,
            $user_ref->{login},
        );
        return;
    }

    $dbh->do(
        "UPDATE $opts->{table} SET login_time = ? WHERE login = ?;",
        undef,
        time(),
        $user_ref->{login},
    );

    return $user_ref, $user_ref_raw;
}

sub process_login_page {
    my ( $self, $template, $query, $config ) = @_;
    my $opts = $self->opts;

    $query->{login} = lc $query->{login};

    if ( $query->{zofcms_plugin_login} ne 'login_user' ) {
        $template->{t}{plug_login_form} = $self->make_login_form(
            login_button => $opts->{login_button},
            page => $query->{page},
            (
                $opts->{preserve_login}
                ? ( cookie_login => $self->{COOKIE_LOGIN} ) : ()
            ),
            smart_deny_name  => $opts->{smart_deny},
            smart_deny_value => $query->{ $opts->{smart_deny} },
        );
        return 1;
    }
    else {
        my $session_id = $self->login_user( @$query{ qw/login pass/ } );
        unless ( $session_id ) {
            $template->{t}{plug_login_form} = $self->make_login_form(
                login_button => $opts->{login_button},
                error => $self->login_error,
                page  => $query->{page},
                (
                    $opts->{preserve_login}
                    ? ( cookie_login => $self->{COOKIE_LOGIN} ) : ()
                ),
                smart_deny_name     => $opts->{smart_deny},
                smart_deny_value    => $query->{ $opts->{smart_deny} },
            );
            return;
        }

        if ( $opts->{no_cookies} ) {
            $template->{t}{plug_login_session_id} = $session_id;
        }
        else {
            print "Set-Cookie: $opts->{preserve_login}=$query->{login}; path=/; expires=Sat, 23 May 2037 23:38:25 GMT\n"
                if $opts->{preserve_login};

            print "Set-Cookie: zofcms_plug_login_s=$session_id; path=/;\n";
            printf "Set-Cookie: zofcms_plug_login_l=%s; path=/;\n",
                md5_hex($query->{login});
        }

        if ( $opts->{redirect_on_login} ) {
            print $config->cgi->redirect(
                process_smart_deny_logon( $opts, $query )
            );
            exit;
        }
        else {
            $self->cookie_l( md5_hex($query->{login}) );
            $self->cookie_s( $session_id );
        }

        return 1;
    }
}

sub login_user {
    my ( $self, $login, $pass ) = @_;
    my $opts = $self->opts;

    $login = lc $login;

    my $dbh = DBI->connect_cached(
        @$opts{ qw/dsn user pass opt/ }
    );

    my $users_ref = $dbh->selectall_arrayref(
        "SELECT * FROM $opts->{table} WHERE login = ? AND password = ?;",
        undef,
        $login,
        md5_hex($pass),
    );
# create TABLE users (login TEXT, password TEXT, login_time VARCHAR(10), session_id VARCHAR(55), role VARCHAR(20));
    unless ( @$users_ref ) {
        $self->login_error("Invalid login or password");
        return;
    }

    my $session_id = rand() . rand() . rand();
    $dbh->do(
        "UPDATE $opts->{table} SET login_time = ?, session_id = ?"
        . " WHERE login = ?;",
        undef,
        time(),
        $session_id,
        $login,
    );

    return $session_id;
}

sub make_login_form {
    my ( $self, %args ) = @_;

    my $t = HTML::Template->new_scalar_ref( \ login_form_template() );

    $t->param(
        %args,
        smart_deny => (
            (
                defined $args{smart_deny_name}
                and length $args{smart_deny_name}
            ) ? 1 : 0
        ),
    );

    return $t->output;
}

sub opts {
    my $self = shift;
    if ( @_ ) {
        $self->{OPTS} = shift;
    }
    return $self->{OPTS};
}

sub login_error {
    my $self = shift;
    if ( @_ ) {
        $self->{LOGIN_ERROR} = shift;
    }
    return $self->{LOGIN_ERROR};
}

sub process_smart_deny_logon {
    my ( $opts, $q ) = @_;

    return $opts->{redirect_on_login}
        unless defined $opts->{smart_deny}
            and length $opts->{smart_deny}
            and defined $q->{ $opts->{smart_deny} }
            and length $q->{ $opts->{smart_deny} };

    return $q->{ $opts->{smart_deny} };
}

sub process_smart_deny {
    my ( $opts ) = @_;

    return ''
        unless defined $opts->{smart_deny}
            and length $opts->{smart_deny};

    use Data::Dumper;


    my $appended_value = $opts->{redirect_on_restricted} =~ /\?/
    ? '' : '?';

    $appended_value .= $opts->{smart_deny} . '=' . uri_escape( $ENV{REQUEST_URI} );

    return $appended_value;
}

sub login_form_template {
    return <<'END_TEMPLATE';
<form action="" method="POST" id="zofcms_plugin_login">
<div><tmpl_if name="error"><p class="error"><tmpl_var escape="html" name="error"></p></tmpl_if>
    <input type="hidden" name="page" value="<tmpl_var escape="html" name="page">">
    <input type="hidden" name="zofcms_plugin_login" value="login_user">
    <tmpl_if name="smart_deny">
        <input type="hidden" name="<tmpl_var escape="html" name="smart_deny_name">" value="<tmpl_var escape="html" name="smart_deny_value">">
    </tmpl_if>
    <ul>
        <li>
            <label for="zofcms_plugin_login_login">Login: </label
            ><input type="text" class="input_text" name="login" id="zofcms_plugin_login_login" value="<tmpl_var escape='html' name='cookie_login'>">
        </li>
        <li>
            <label for="zofcms_plugin_login_pass">Password: </label
            ><input type="password" class="input_password" name="pass" id="zofcms_plugin_login_pass">
        </li>
    </ul>
    <tmpl_var name='login_button'>
</div>
</form>
END_TEMPLATE
}

sub logout_form_template {
    return <<'END_TEMPLATE';
<form action="" method="POST" id="zofcms_plugin_login_logout">
<div><tmpl_if name="error"><p class="error"><tmpl_var escape="html" name="error"></p></tmpl_if>
    <input type="hidden" name="page" value="<tmpl_var escape="html" name="page">">
    <input type="hidden" name="zofcms_plugin_login" value="logout_user">
    <tmpl_var name='logout_button'>
</div>
</form>
END_TEMPLATE
}

sub cookie_l {
    my $self = shift;
    @_ and $self->{COOKIE_L} = shift;
    $self->{COOKIE_L};
}

sub cookie_s {
    my $self = shift;
    @_ and $self->{COOKIE_S} = shift;
    $self->{COOKIE_S};
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::UserLogin - restrict access to pages based on user accounts

=head1 SYNOPSIS

In $your_database_of_choice that is supported by L<DBI> create a table.
You can have extra columns in it, but the first five must be named as appears
below. C<login_time> is the return of Perl's C<time()>. Password will be
C<md5_hex()>ed (with L<Digest::MD5>,
C<session_id> is C<rand() . rand() . rand()> and role depends
on what you set the roles to be:

    create TABLE users (
        login TEXT,
        password VARCHAR(32),
        login_time VARCHAR(10),
        session_id VARCHAR(55),
        role VARCHAR(20)
    );

Main config file:

    template_defaults => {
        plugins => [ { UserLogin => 10000 } ],
    },
    plug_login => {
        dsn                     => "DBI:mysql:database=test;host=localhost",
        user                    => 'test', # user,
        pass                    => 'test', # pass
        opt                     => { RaiseError => 1, AutoCommit => 0 },
        table                   => 'users',
        login_page              => '/login',
        redirect_on_restricted  => '/login',
        redirect_on_login       => '/',
        redirect_on_logout      => '/',
        not_restricted          => [ qw(/ /index) ],
        restricted              => [ qr/^/ ],
        smart_deny              => 'login_redirect_page',
        preserve_login          => 'my_site_login',
        login_button => '<input type="submit"
            class="input_submit" value="Login">',
        logout_button => '<input type="submit"
            class="input_submit" value="Logout">',
    },

In L<HTML::Template> template for C<'/login'> page:

    <tmpl_var name="plug_login_form">
    <tmpl_var name="plug_login_logout">


=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>; it provides functionality to
restrict access to some pages based on user accounts (which support "roles")

Plugin uses HTTP cookies to set user sessions.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 NOTE ON LOGINS

Plugin makes the logins B<lowercased> when doing its processing; thus C<FooBar> login
is the same as C<foobar>.

=head1 NOTE ON REDIRECTS

There are quite a few options that redirect the user upon a certain event.
The C<exit()> will be called upon a redirect so keep that
in mind when setting plugin's priority setting.

=head1 DATABASE

Plugin needs access to the database that is supported by L<DBI> module.
You'll need to create a table the format of which is described in the
first paragraph of L<SYNOPSIS> section above. B<Note>: plugin does not
support I<creation> of user accounts. That was left for other plugins
(e.g. L<App::ZofCMS::Plugin::FormToDatabase>)
considering that you are flexible in what the entry for each user in the
database can contain.

=head1 ROLES

The "role" of a user can be used to limit access only to certain users.
In the database the user can have several roles which are to be separated
by commas (C<,>). For example:

    foo,bar,baz

The user with that role is member of role "foo", "bar" and "baz".

=head1 TEMPLATE/CONFIG FILE SETTINGS

    plug_login => {
        dsn                     => "DBI:mysql:database=test;host=localhost",
        user                    => 'test',
        pass                    => 'test',
        opt                     => { RaiseError => 1, AutoCommit => 0 },
        table                   => 'users',
        user_ref    => sub {
            my ( $user_ref, $template ) = @_;
            $template->{d}{plug_login_user} = $user_ref;
        },
        login_page              => '/login',
        redirect_on_restricted  => '/login',
        redirect_on_login       => '/',
        redirect_on_logout      => '/',
        not_restricted          => [ qw(/ /index) ],
        restricted              => [ qr/^/ ],
        smart_deny              => 'login_redirect_page',
        preserve_login          => 'my_site_login',
        login_button => '<input type="submit"
            class="input_submit" value="Login">',
        logout_button => '<input type="submit"
            class="input_submit" value="Logout">',
    },

These settings can be set via C<plug_login> first-level key in ZofCMS
template, but you probably would want to set all this in main config file via
C<plug_login> first-level key.

=head2 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. The C<dsn> key will be passed to L<DBI>'s C<connect_cached()>
method, see documentation for L<DBI> and C<DBD::your_database> for the
correct syntax of this one. The example above uses MySQL database called
C<test> which is location on C<localhost>

=head2 C<user>

    user => 'test',

B<Mandatory>. Specifies the user name (login) for the database. This can
be an empty string if, for example, you are connecting using SQLite driver.

=head2 C<pass>

    pass => 'test',

B<Mandatory>. Same as C<user> except specifies the password for the database.

=head2 C<table>

    table => 'users',

B<Optional>. Specifies which table in the database stores user accounts.
For format of this table see L<SYNOPSIS> section. B<Defaults to:> C<users>

=head2 C<opt>

    opt => { RaiseError => 1, AutoCommit => 0 },

B<Optional>. Will be passed directly to C<DBI>'s C<connect_cached()> method
as "options". B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 0 } >>

=head2 C<user_ref>

    user_ref => sub {
        my ( $user_ref, $template ) = @_;
        $template->{d}{plug_login_user} = $user_ref;
    },

B<Optional>. Takes a subref as an argument. When specified the subref will be called and
its C<@_> will contain the following: C<$user_ref>, C<$template_ref>, C<$query_ref>,
C<$config_obj>, where C<$user_ref> will be either C<undef> (e.g. when user is not logged on)
or will contain an arrayref with user data pulled from the SQL table, i.e. an arrayref
with all the columns in a table that correspond to the currently logged in user.
The C<$template_ref> is
the reference to your ZofCMS template, C<$query_ref> is the reference to a query hashref as
is returned from L<CGI>'s C<Vars()> call. Finally, C<$config_obj> is the L<App::ZofCMS::Config>
object. Basically you'd use C<user_ref> to stick user's data into your ZofCMS template for
later processing, e.g. displaying parts of it or making it accessible to other plugins.
B<Defaults to:> (will stick user data into C<{d}{plug_login_user}> in ZofCMS template)

    user_ref    => sub {
        my ( $user_ref, $template ) = @_;
        $template->{d}{plug_login_user} = $user_ref;
    },

=head2 C<login_page>

    login_page => '/login',

    login_page => qr|^/log(?:in)?|i;

B<Optional>. Specifies what page is a page with a login form. The check will
be done against a "page" that is constructed by C<$query{dir} . $query{page}>
(the C<dir> and C<page> are discussed in ZofCMS's core documentation).
The value for the C<login_page> key can be either a string or a regex.
B<Note:> the access is B<NOT> restricted to pages matching C<login_page>.
B<Defaults to:> C</login>

=head2 C<redirect_on_restricted>

    redirect_on_restricted => '/uri',

B<Optional>. Specifies the URI to which to redirect if access to the page
is denied, e.g. if user does not have an appropriate role or is not logged
in. B<Defaults to:> C</>

=head2 C<redirect_on_login>

    redirect_on_login  => '/uri',

B<Optional>. Specifies the URI to which to redirect after user successfully
logged in. B<By default> is not specified.

=head2 C<smart_deny>

    smart_deny => 'login_redirect_page',

B<Optional>. Takes a scalar as a value that represents a query parameter
name into which to store the URI of the page that not-logged-in  user
attempted to access. This option works only when C<redirect_on_login> is
specified. When specified, plugin enables the magic to "remember" the page
that a not-logged-in user tried to access, and once the user enters correct
login credentials, he is redirected to said page automatically; thereby
making the login process transparent. B<By default> is not specified.

=head2 C<preserve_login>

    preserve_login => 'my_site_login',

B<Optional>. Takes a scalar that represents the name of a cookie
as a value. When specified, the plugin will automatically
(via the cookie, name of which you specify here) remember, and fill
out, the username from last successfull login. This option only works
when C<no_cookies> is set to a false value (that's the default).
B<By default> is not specified

=head2 C<login_button>

    login_button => '<input type="submit"
            class="input_submit" value="Login">',

B<Optional>. Takes HTML code for the login button, though, feel free to
use it as an insertion point for any extra code you might want in your
login form. B<Defaults to:>
C<< <input type="submit" class="input_submit" value="Login"> >>

=head2 C<logout_button>

    logout_button => '<input type="submit"
        class="input_submit" value="Logout">'

B<Optional>. Takes HTML code for the logout button, though, feel free to
use it as an insertion point for any extra code you might want in your
logout form. B<Defaults to:>
C<< <input type="submit" class="input_submit" value="Logout"> >>

=head2 C<redirect_on_logout>

    redirect_on_logout => '/uri',

B<Optional>. Specifies the URI to which to redirect the user after he or
she logged out.

=head2 C<restricted>

    restricted => [
        qw(/foo /bar /baz),
        qr|^/foo/|i,
        { page => '/admin', role => 'admin' },
        { page => qr|^/customers/|, role => 'customer' },
    ],

B<Optional> but doesn't make sense to not specify this one.
B<By default> is not specified. Takes an arrayref
as a value. Elements of this arrayref can be as follows:

=head3 a string

    restricted => [ qw(/foo /bar) ],

Elements that are plain strings represent direct pages ( page is made out of
$query{dir} . $query{page} ). The example above will restrict access
only to pages C<http://foo.com/index.pl?page=foo> and
C<http://foo.com/index.pl?page=bar> for users that are not logged in.

=head3 a regex

    restricted => [ qr|^/foo/| ],

Elements that are regexes (C<qr//>) will be matched against the page. If
the page matches the given regex access will be restricted to any user
who is not logged in.

=head3 a hashref

    restricted => [
        { page => '/secret', role => \1 },
        { page => '/admin', role => 'customer' },
        { page => '/admin', role => 'not_customer' },
        { page => qr|^/customers/|, role => 'not_customer' },
    ],

Using hashrefs you can set specific roles that are restricted from a given
page. The hashref must contain two keys: the C<page> key and C<role> key.
The value of the C<page> key can be either a string or a regex which will
be matched against the current page the same way as described above. The
C<role> key must contain a role of users that B<are restricted> from
accessing the page specified by C<page> key or a scalarref
(meaning "any role"). B<Note> you can specify only
B<one> role per hashref. If you want to have several roles you need to
specify several hashrefs or use C<not_restricted> option described below.

In the example above only logged in users who are B<NOT> members of role
C<customer> or C<not_customer> can access C</admin> page and
only logged in users who are B<NOT> members of role C<not_customer>
can access pages that begin with C</customers/>. The page C</secret> is
restricted for B<everyone> (see note on scalarref below).

B<IMPORTANT NOTE:> the restrictions will be checked until the first one
matching the page criteria found. Therefore, make sure to place
the most restrictive restrictions first. In other words:

    restricted => [
        qr/^/,
        { page => '/foo', role => \1 },
    ],

Will B<NOT> block logged in users from page C</foo> because C<qr/^/> matches
first. Proper way to write this restriction would be:

    restricted => [
        { page => '/foo', role => \1 },
        qr/^/,
    ],

B<Note:> the role can also be a I<scalarref>; if it is, it means "any role".
In other words:

    restricted => [ qr/^/ ],

Means "all the pages are restricted for users who are not logged in". While:

    restricted => [ { page => qr/^/, role \1 } ],

Means that "all pages are restricted for everyone" (in this case you'd use
C<not_restricted> option described below to ease the restrictions).


=head2 C<not_restricted>

    not_restricted => [
        qw(/foo /bar /baz),
        qr|^/foo/|i,
        { page => '/garbage', role => \1 },
        { page => '/admin', role => 'admin' },
        { page => qr|^/customers/|, role => 'customer' },
    ],

B<Optional>. The value is the exact same format as for C<restricted> option
described above. B<By default> is not specified.
The purpose of C<not_restricted> is the reverse of
C<restricted> option. Note that pages that match anything in
C<not_restricted> option will not be checked against C<restricted>. In other
words you can construct rules such as this:

    restricted => [
        qr/^/,
        { page => qr|^/admin|, role => \1 },
    ],
    not_restricted => [
        qw(/ /index),
        { page => qr|^/admin|, role => 'admin' },
    ],

The example above will restrict access to every page on the site that is
not C</> or C</index> to any user who is not logged in. In addition, pages
that begin with C</admin> will be accessible only to users who are members
of role C<admin>.

=head2 C<limited_time>

    limited_time => 600,

B<Optional>. Takes integer values greater than 0. Specifies the amount
of seconds after which user's session expires. In other words, if you
set C<limited_time> to 600 and user went to the crapper for 10 minutes, then
came back, he's session would expire and he would have to log in again.
B<By default> not specified and sessions expire when the cookies do so
(which is "by the end of browser's session", let me know if you wish to
control that).

=head2 C<no_cookies>

    no_cookies => 1,

B<Optional>. When set to a false value plugin will set two cookies:
C<md5_hex()>ed user login and session ID. When set to a true value plugin
will not set any cookies and instead will put session ID into
C<plug_login_session_id> key under ZofCMS template's C<{t}> special key.
B<By default> is not specified (false).

=head1 HTML::Template TEMPLATE

There are two (or three, depending if you set C<no_cookies> to a true value)
keys created in ZofCMS template C<{t}> special key, thus are available in
your L<HTML::Template> templates:

=head2 C<plug_login_form>

    <tmpl_var name="plug_login_form">

The C<plug_login_form> key will contain the HTML code for the "login form".
You'd use C<< <tmpl_var name="plug_login_form"> >> on your "login page".
Note that login errors, i.e. "wrong login or password" will be automagically
display inside that form in a C<< <p class="error"> >>.

=head2 C<plug_login_logout>

    <tmpl_var name="plug_login_logout">

This one is again an HTML form except for the "logout" button. Drop it
anywhere you want.

=head2 C<plug_login_user>

    <tmpl_if name="plug_login_user">
        Logged in as <tmpl_var name="plug_login_user">.
    </tmpl_if>

The C<plug_login_user> will contain the login name of the currently logged in
user.

=head2 C<plug_login_session_id>

If you set C<no_cookies> argument to a true value, this key will contain
session ID.

=head1 GENERATED HTML CODE

Below are the snippets of HTML code generated by the plugin; here for the
reference when styling your login/logout forms.

=head2 login form

    <form action="" method="POST" id="zofcms_plugin_login">
    <div>
        <input type="hidden" name="page" value="/login">
        <input type="hidden" name="zofcms_plugin_login" value="login_user">
        <ul>
            <li>
                <label for="zofcms_plugin_login_login">Login: </label
                ><input type="text" name="login" id="zofcms_plugin_login_login">
            </li>
            <li>
                <label for="zofcms_plugin_login_pass">Password: </label
                ><input type="password" name="pass" id="zofcms_plugin_login_pass">
            </li>
        </ul>
        <input type="submit" value="Login">
    </div>
    </form>

=head2 login form with a login error

    <form action="" method="POST" id="zofcms_plugin_login">
    <div><p class="error">Invalid login or password</p>
        <input type="hidden" name="page" value="/login">
        <input type="hidden" name="zofcms_plugin_login" value="login_user">
        <ul>
            <li>
                <label for="zofcms_plugin_login_login">Login: </label
                ><input type="text" class="input_text" name="login" id="zofcms_plugin_login_login">
            </li>
            <li>
                <label for="zofcms_plugin_login_pass">Password: </label
                ><input type="password" class="input_password" name="pass" id="zofcms_plugin_login_pass">
            </li>
        </ul>
        <input type="submit" class="input_submit" value="Login">
    </div>
    </form>

=head2 logout form

    <form action="" method="POST" id="zofcms_plugin_login_logout">
    <div>
        <input type="hidden" name="page" value="/login">
        <input type="hidden" name="zofcms_plugin_login" value="logout_user">
        <input type="submit" class="input_submit" value="Logout">
    </div>
    </form>

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