package App::ZofCMS::Plugin::UserLogin::ChangePassword;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use DBI;
use Digest::MD5 (qw/md5_hex/);
use HTML::Template;

sub _key { 'plug_user_login_change_password' }
sub _defaults {
    dsn     => "DBI:mysql:database=test;host=localhost",
    user    => 'test',
    pass    => 'test',
    opt     => { RaiseError => 1, AutoCommit => 1 },
    table   => 'users',
    login   => sub { $_[0]{d}{user}{login} },
    key     => 'change_pass_form',
    min     => 4,
    submit_button => q|<input type="submit" class="input_submit"|
        . q| name="plug_user_login_change_password_submit"|
        . q| value="Change password">|,
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    unless ( $q->{plug_user_login_change_password_submit} ) {
        $t->{t}{ $conf->{key} } = _make_form($q, undef, $conf);
        return;
    }

    my $dbh = DBI->connect_cached(
        @$conf{ qw/dsn user pass opt/ },
    );

    $conf->{login} = $conf->{login}->( $t, $q, $config )
        if ref $conf->{login} eq 'CODE';

    my $pass = ( ( $dbh->selectall_arrayref(
        "SELECT `password` FROM `$conf->{table}` WHERE `login` = ?",
        { Slice => {} },
        $conf->{login},
    ) || [] )->[0] || {} )->{password};

    unless ( defined $pass ) {
        $t->{t}{ $conf->{key} } = _make_form($q, $t, $conf, 'Your login was not found');
        return;
    }

    unless ( $pass eq md5_hex( $q->{plug_user_login_change_password_pass} ) ) {
        $t->{t}{ $conf->{key} } = _make_form($q, $t, $conf, 'Invalid current password');
        return;
    }

    if ( $q->{plug_user_login_change_password_newpass}
            ne $q->{plug_user_login_change_password_repass}
    ) {
        $t->{t}{ $conf->{key} } = _make_form($q, $t, $conf, 'You did not retype your new password correctly');
        return;
    }

    if ( $conf->{min} > length $q->{plug_user_login_change_password_newpass} ) {
        $t->{t}{ $conf->{key} } = _make_form($q, $t, $conf, "New password must be at least $conf->{min} characters in length");
        return;
    }

    $dbh->do(
        "UPDATE `$conf->{table}` SET `password` = ? WHERE `login` = ?",
        undef,
        md5_hex( $q->{plug_user_login_change_password_newpass} ),
        $conf->{login},
    );

    $t->{t}{ $conf->{key} } = _make_form($q, $t, $conf);
}


sub _make_form {
    my ( $q, $t, $conf, $error ) = @_;

    my $temp = HTML::Template->new_scalar_ref( \ _form_template() );

    $temp->param(
        dir => $q->{dir},
        page => $q->{page},
        submit_button => $conf->{submit_button},
    );

    unless ( defined $t ) {
        return $temp->output;
    }

    if ( defined $error and length $error ) {
        $t->{t}{plug_user_login_change_password_error} = 1;
        $temp->param( error => $error );
        return $temp->output;
    }

    $t->{t}{plug_user_login_change_password_ok} = 1;
    $temp->param( change_ok => 1 );
    return $temp->output;
}

sub _form_template {
    return <<'END';
<tmpl_if name='change_ok'>
    <p id="plug_user_login_change_password_ok" class="success-message">Your password has been successfully changed</p>
<tmpl_else>
    <form action="" method="POST" id="plug_user_login_change_password_form">
    <div>
        <tmpl_if name='error'>
            <p class="error"><tmpl_var escape='html' name='error'></p>
        </tmpl_if>
        <input type="hidden" name="page" value="<tmpl_var escape='html' name='page'>">
        <input type="hidden" name="dir" value="<tmpl_var escape='html' name='dir'>">
        <ul>
            <li>
                <label for="plug_user_login_change_password_pass">Current password: </label
                ><input type="password" class="input_password" name="plug_user_login_change_password_pass" id="plug_user_login_change_password_pass">
            </li>
            <li>
                <label for="plug_user_login_change_password_newpass">New password: </label
                ><input type="password" class="input_password" name="plug_user_login_change_password_newpass" id="plug_user_login_change_password_newpass">
            </li>
            <li>
                <label for="plug_user_login_change_password_repass">Retype new password: </label
                ><input type="password" class="input_password" name="plug_user_login_change_password_repass" id="plug_user_login_change_password_repass">
            </li>
        </ul>
        <tmpl_var name='submit_button'>
    </div>
    </form>
</tmpl_if>
END
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::UserLogin::ChangePassword - UserLogin plugin suppliment for changing user passwords

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template:

    plugins => [
        { UserLogin                   => 200  },
        { 'UserLogin::ChangePassword' => 1000 },
    ],

    plug_user_login_change_password => {
        dsn     => "DBI:mysql:database=hl;host=localhost",
        login   => 'test',
        pass    => 'test',
    },

    # UserLogin plugin's configuration skipped for brevity

In your HTML::Template template:

    <tmpl_var name='change_pass_form'>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to display and process the
"change password" form. This plugin was designed with an assumption that you are using
L<App::ZofCMS::Plugin::UserLogin>, but that's not a requirement.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        { 'UserLogin::ChangePassword' => 2000 },
    ],

B<Mandatory>. You need to include the plugin in the list of plugins to execute. By default
this plugin is configured to interface with
L<App::ZofCMS::Plugin::UserLogin> plugin, thus you'd
include UserLogin plugin with lower priority sequence to execute earlier.

=head2 C<plug_user_login_change_password>

    plug_user_login_change_password => {
        dsn     => "DBI:mysql:database=test;host=localhost",
        user    => 'test',
        pass    => 'test',
        opt     => { RaiseError => 1, AutoCommit => 1 },
        table   => 'users',
        login   => sub { $_[0]{d}{user}{login} },
        key     => 'change_pass_form',
        min     => 4,
        submit_button => q|<input type="submit" class="input_submit"|
            . q| name="plug_user_login_change_password_submit"|
            . q| value="Change password">|,
    },

    # or set arguments via a subref
    plug_user_login_change_password => sub {
        my ( $t, $q, $config ) = @_;
        return {
            dsn => "DBI:mysql:database=test;host=localhost",
        },
    },

B<Mandatory>. Takes either a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_user_login_change_password> as if it was already
there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. To run with all the defaults (which won't be the case for
nearly everything but testing environment) set to empty hashref.
Possible keys/values for the hashref are as follows:

=head3 C<dsn>

    plug_user_login_change_password => sub {
        dsn => "DBI:mysql:database=test;host=localhost",
    },

B<Optional>. Specifies L<DBI>'s "dsn" (driver, database and host) for the plugin to use.
See L<App::ZofCMS::Plugin::UserLogin> for more details; this one needs
to point to the
same database that UserLogin plugin uses so the right password could be changed.
B<Defaults to:> C<DBI:mysql:database=test;host=localhost>  (as I've said, useful only for
testing enviroment)

=head3 C<user>

    plug_user_login_change_password => sub {
        user    => 'test',
    },

B<Optional>. Specifies the username for database access. B<Defaults to:> C<test>

=head3 C<pass>

    plug_user_login_change_password => sub {
        pass    => 'test',
    },

B<Optional>. Specifies the password for database access. B<Defaults to:> C<test>

=head3 C<opt>

    plug_user_login_change_password => sub {
        opt => { RaiseError => 1, AutoCommit => 1 },
    },

B<Optional>. Specifies additional L<DBI> options. See L<App::ZofCMS::Plugin::UserLogin>'s
C<opt> argument for more details. B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<table>

    plug_user_login_change_password => sub {
        table   => 'users',
    },

B<Optional>. Specifies the SQL table used in L<App::ZofCMS::Plugin::UserLogin>. Actually,
you do not have to use UserLogin plugin, but the passwords must be stored in a column
named C<password>. B<Defaults to:> C<users>

=head3 C<login>

    plug_user_login_change_password => sub {
        login   => 'admin',
    },

    plug_user_login_change_password => sub {
        login   => sub { $_[0]{d}{user}{login} },
    },

B<Optional>. Specifies the login of the user whose password to chagne.
Takes either a string or a subref as a value. If subref is specified, its
return value will be assigned to C<login> as if it was already there.
The C<@_> of the subref will contain (in that order): ZofCMS Template hashref, query
parameters hashref and L<App::ZofCMS::Config> object.
B<Defaults to:> C<sub { $_[0]{d}{user}{login} }> (my common way of storing C<$user_ref> from
UserLogin plugin)

=head3 C<key>

    plug_user_login_change_password => sub {
        key     => 'change_pass_form',
    },

B<Optional>. Specifies the name of the key inside C<{t}> special key into which
the plugin will put the password change form (see PLUGIN'S HTML AND OUTPUT section for
details).
B<Defaults to:> C<change_pass_form>

=head3 C<min>

    plug_user_login_change_password => sub {
        min     => 4,
    },

B<Optional>. Takes a positive intereger or zero as a value. Specifies
the minimum C<length()> of the new password. B<Defaults to:> C<4>

=head3 C<submit_button>

    plug_user_login_change_password => sub {
        submit_button => q|<input type="submit" class="input_submit"|
            . q| name="plug_user_login_change_password_submit"|
            . q| value="Change password">|,
    },

B<Optional>. Takes a string of HTML code as a value. Specifies the
code for the submit button of the form; feel free to add any extra
code you might require as well. B<Defaults to:>
C<< <input type="submit" class="input_submit"  name="plug_user_login_change_password_submit" value="Change password"> >>

=head1 PLUGIN'S HTML AND OUTPUT

The plugin uses key in C<{t}> special key that is specified via C<key> plugin's configuration
argument (defaults to C<change_pass_form>). That key will contain either the HTML
form for password changing or the message that password was successfully changed.

If an error occured (such as mismatching passwords), plugin will set
C<< $t->{t}{plug_user_login_change_password_error} >> to a true value (where C<$t> is
ZofCMS Template hashref). If password was successfully changed, plugin will set
C<< $t->{t}{plug_user_login_change_password_ok} >> to a true value (where C<$t> is
ZofCMS Template hashref). You do not have to use these, as they are set only if you have
a large page and want to hide/show different bits depending on what is going on.

Below is the HTML::Template template that plugin uses for the form as well as successfully
password changes. It is shown here for you to know how to style your password changing
form/success message properly:

    <tmpl_if name='change_ok'>
        <p id="plug_user_login_change_password_ok" class="success-message">Your password has been successfully changed</p>
    <tmpl_else>
        <form action="" method="POST" id="plug_user_login_change_password_form">
        <div>
            <tmpl_if name='error'>
                <p class="error"><tmpl_var escape='html' name='error'></p>
            </tmpl_if>
            <input type="hidden" name="page" value="<tmpl_var escape='html' name='page'>">
            <input type="hidden" name="dir" value="<tmpl_var escape='html' name='dir'>">
            <ul>
                <li>
                    <label for="plug_user_login_change_password_pass">Current password: </label
                    ><input type="password" class="input_password" name="plug_user_login_change_password_pass" id="plug_user_login_change_password_pass">
                </li>
                <li>
                    <label for="plug_user_login_change_password_newpass">New password: </label
                    ><input type="password" class="input_password" name="plug_user_login_change_password_newpass" id="plug_user_login_change_password_newpass">
                </li>
                <li>
                    <label for="plug_user_login_change_password_repass">Retype new password: </label
                    ><input type="password" class="input_password" name="plug_user_login_change_password_repass" id="plug_user_login_change_password_repass">
                </li>
            </ul>
            <input type="submit" class="input_submit" name="plug_user_login_change_password_submit" value="Change password">
        </div>
        </form>
    </tmpl_if>

=head1 SEE ALSO

L<DBI>, L<App::ZofCMS::Plugin::UserLogin>

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