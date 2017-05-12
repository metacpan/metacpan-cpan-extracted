package App::ZofCMS::Plugin::UserLogin::ForgotPassword;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use DBI;
use Digest::MD5 (qw/md5_hex/);
use HTML::Template;
use MIME::Lite;

sub _key { 'plug_user_login_forgot_password' }
sub _defaults {
    return (
    dsn         => "DBI:mysql:database=test;host=localhost",
    user        => '',
    pass        => undef,
    opt         => { RaiseError => 1, AutoCommit => 1 },
    users_table => 'users',
    code_table  => 'users_forgot_password',
    q_code      => 'pulfp_code',
    max_abuse   => '5:10:60', # 5 min intervals, max 10 attempts per 60 min.
    min_pass    => 6,
    code_expiry => 24*60*60, # 1 day
    code_length => 6,
    use_stage_indicators => 1,
    subject     => 'Password Reset',
    login_page  => '/',
    button_send_link => q|<input type="submit" class="input_submit"|
        . q| value="Send password">|,
    button_change_pass => q|<input type="submit" class="input_submit"|
        . q| value="Change password">|,

#     email_link  => undef, # this will be guessed
#     from        => undef,
#     email_template  => undef, # use plugin's default template
#     no_run          => undef
#     create_table    => undef,
#     mime_lite_params  => undef,
#     email           => undef,
    );
}

sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    return
        if $conf->{no_run};

    $self->{Q_PAGE} = ( $q->{dir} || '' ) . ( $q->{page} || '' );
    $self->{CONF} = $conf;
    $self->{Q}    = $q;
    $self->{T}    = $t;

    create_code_table( $conf )
        if $conf->{create_table};

    if ( has_value($q->{$conf->{q_code}}) ) {
        $self->process_q_code;
    }
    elsif ( has_value($q->{pulfp_ask_link}) ) {
        $self->process_ask_link;
    }
    else {
        $self->process_initial;
    }

    $t->{t}{plug_forgot_password} = $self->{OUTPUT};
}

sub process_q_code {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};

    my $code = $q->{ $conf->{q_code} };
    my $dbh  = $self->dbh;

    my $entry = ($dbh->selectall_arrayref(
        'SELECT * FROM `' . $conf->{code_table}
            . '` WHERE `code` = ?',
        { Slice => {} },
        $code,
    ) || [])->[0];

    unless ( $entry ) {
        $self->set_stage('code_invalid');
        $self->{OUTPUT} = '<p class="reset_code_expired">Your reset'
         . ' code has expired. Please try'
            . ' resetting your password again.</p>';
        return;
    }

    if ( has_value( $q->{pulfp_has_change_pass} ) ) {
        $self->check_change_pass
            or return;

        $self->set_new_pass( $entry );
        $self->set_stage('change_pass_done');
        $self->{OUTPUT} = '<p class="reset_pass_success">Your password'
            . ' has been successfully'
            . ' changed. You can now use it to '
            . (
                has_value( $conf->{login_page} )
                ? qq| <a href="$conf->{login_page}">log in</a>|
                : ' log in'
            )
            .'.</p>';
        return;
    }
    else {
        $self->set_stage('change_pass_ask');
        $self->{OUTPUT} = $self->make_change_pass_form;
    }
}

sub set_new_pass {
    my $self  = shift;
    my $entry = shift;
    my $q     = $self->{Q};
    my $conf  = $self->{CONF};
    my $dbh   = $self->dbh;

    my $new_pass = md5_hex( $q->{pulfp_pass} );
    $dbh->do(
        'UPDATE `' . $conf->{users_table}
            . '` SET `password` = ? WHERE `login` = ?',
        undef,
        $new_pass,
        $entry->{login},
    );
    $dbh->do(
        'DELETE FROM `' . $conf->{code_table} . '` WHERE `login` = ?',
        undef,
        $entry->{login},
    );
}

sub check_change_pass {
    my $self = shift;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};

    my ( $pass, $repass ) = @$q{ qw/pulfp_pass   pulfp_repass/ };
    unless ( has_value( $pass ) and length $pass >= $conf->{min_pass} ) {
        $self->set_stage('code_bad_pass_length');
        $self->{OUTPUT} = $self->make_change_pass_form(
            'Your new password must be at least '
            . $conf->{min_pass} . ' characters long.'
        );
        return;
    }

    unless ( has_value( $repass ) and $pass eq $repass ) {
        $self->set_stage('code_bad_pass_copy');
        $self->{OUTPUT} = $self->make_change_pass_form(
            'You did not retype your password correctly.'
        );
        return;
    }

    return 1;
}

sub make_change_pass_form {
    my ( $self, $error ) = @_;
    my $q    = $self->{Q};
    my $conf = $self->{CONF};

    my $template = HTML::Template->new_scalar_ref(
        \ change_pass_form_template(),
        die_on_bad_params => 0,
    );

    $template->param(
        submit_button => $conf->{button_change_pass},
        page       => $self->{Q_PAGE},
        error      => $error,
        code_name  => $conf->{q_code},
        code_value => $q->{ $conf->{q_code} },
    );

    return $template->output;
}

sub process_initial {
    my $self            = shift;
    my $show_form_error = shift;

    my $template = HTML::Template->new_scalar_ref(
        \ask_login_form_template(),
        die_on_bad_params => 0,
    );

    $template->param(
        submit_button => $self->{CONF}{button_send_link},
        page => $self->{Q}{page},
        $show_form_error ? ( error => $show_form_error ) : (),
    );

    $self->{OUTPUT} = $template->output;
    $self->set_stage('initial');
}

sub process_ask_link {
    my $self = shift;

    my $q = $self->{Q};

    unless ( has_value( $q->{pulfp_login} ) ) {
        $self->set_stage('ask_error_login');
        $self->process_initial( 'Please specify your login' );
        return;
    }

    my $dbh = $self->dbh;
    my $user = (@{
        $dbh->selectall_arrayref(
            'SELECT * FROM `users` WHERE `login` = ?',
            { Slice => {} },
            $q->{pulfp_login},
        )
    || [] })[0];

    unless ( $user ) {
        $self->set_stage('ask_error_no_user');
        $self->process_initial(
            'The login you provided was not found in the database.'
        );
        return;
    }

    if ( $self->check_abuse( $user ) ) {
        $self->set_stage('ask_error_abuse');
        $self->process_initial(
            'Sorry, but due to abuse we have to limit the amount of'
            . ' requests. Please wait a short while and try again.'
        );
        return;
    }

    my $code = $self->create_access_code( $user );
    $self->email_code( $user, $code );

    $self->set_stage('emailed');
    $self->{OUTPUT} = '<p class="reset_link_send_success">Please check'
        . ' your email for further'
        . ' instructions on how to reset your password.</p>';
}

sub email_code {
    my $self = shift;
    my $user = shift;
    my $code = shift;
    my $conf = $self->{CONF};

    my $template = HTML::Template->new(
        die_on_bad_params => 0,
        ref $conf->{email_template}
            ? ( filename => ${ $conf->{email_template} } )
            : has_value( $conf->{email_template} )
                ? ( scalarref => \ $conf->{email_template} )
                : ( scalarref => \ email_template()        )
    );

    my $link = $conf->{email_link};
    unless ( has_value( $link ) ) {
        $link = join '', 'http://', @ENV{ qw/SERVER_NAME  REQUEST_URI/ };
        $link .= $link =~ /\?/ ? '&' : '?';
        $link .= $conf->{q_code} . '='
    }

    $template->param(
        'link' => $link . $code,
    );

    my $msg = MIME::Lite->new (
        Subject => $conf->{subject},
        ( defined $conf->{from} ? ( From => $conf->{from} ) : (), ),
        To      => (
            has_value( $conf->{email} )
            ? $conf->{email}
            : $user->{email}
        ),
        Type    => 'text/html',
        Data    => $template->output,
    );

    MIME::Lite->send( @{ $conf->{mime_lite_params} } )
        if $conf->{mime_lite_params};

    $msg->send;
}

sub create_access_code {
    my $self = shift;
    my $user = shift;
    my $conf = $self->{CONF};

    my @chars = ( 0 .. 9, 'a'..'z', 'A'..'Z' );
    my $code = '';
    for ( 0 .. $conf->{code_length} ) {
        $code .= $chars[ rand @chars ];
    }

    my $dbh = $self->dbh;

    # delete old entries
    $dbh->do(
        'DELETE FROM `' . $conf->{code_table}
        . '` WHERE `time` < ?',
        undef,
        time() - $conf->{code_expiry},
    );

    $dbh->do(
        'INSERT INTO `' . $conf->{code_table}
            . '` (`login`, `time`, `code`) VALUES (?, ?, ?)',
        undef,
        $user->{login},
        time(),
        $code,
    );

    return $code;
}

sub check_abuse {
    my $self = shift;
    my $user = shift;

    my $max_abuse = $self->{CONF}{max_abuse}
        or return;

    $max_abuse =~ /^\d+:\d+:\d+$/
        or die 'Invalid value for `max_abuse` parameter in'
            . ' UserLogin::ForgotPassword plugin; must'
            . ' match qr/^\d+:\d+:\d+$/.';

    my ( $interval, $attempts, $period ) = split /:/, $max_abuse;
    my $dbh = $self->dbh;
    my $previous_tries = $dbh->selectall_arrayref(
        'SELECT * FROM `' . $self->{CONF}{code_table}
            . '` WHERE `login` = ? AND `time` > ?'
            . ' ORDER BY `time`+0 DESC',
        { Slice => {} },
        $user->{login},
        time() - $period*60,
    ) || [];

    return 1
        if @$previous_tries > $attempts;

    return 1
        if @$previous_tries
            and $previous_tries->[0]{time} > time() - $interval*60;

    return 0;
}

sub set_stage {
    my ( $self, $stage ) = @_;

    $self->{T}{t}{"plug_forgot_password_stage_$stage"} = 1
        if $self->{CONF}{use_stage_indicators};
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

sub create_code_table {
    my $conf = shift;

    my $dbh = DBI->connect_cached(
        @$conf{ qw/dsn user pass opt/ },
    );

    $dbh->do(
        'CREATE TABLE `' . $conf->{code_table} . '` (
            `login`     TEXT,
            `time`      VARCHAR(10),
            `code`      TEXT
        );'
    );
}

sub change_pass_form_template {
    return <<'END_HTML';
<form action="" method="POST" id="plug_forgot_password_new_pass_form">
<div>
    <p>Please enter your new password.</p>

    <input type="hidden" name="page" value="<tmpl_var escape='html'
        name='page'>">
    <input type="hidden" name="<tmpl_var escape='html' name='code_name'>"
        value="<tmpl_var escape='html' name='code_value'>">
    <input type="hidden" name="pulfp_has_change_pass" value="1">
    <tmpl_if name='error'>
        <p class="error"><tmpl_var escape='html' name='error'></p>
    </tmpl_if>

    <ul>
        <li>
            <label for="pulfp_pass">New password: </label
            ><input type="password"
                class="input_password"
                name="pulfp_pass"
                id="pulfp_pass">
        </li>
        <li>
            <label for="pulfp_repass">Retype new password: </label
            ><input type="password"
                class="input_password"
                name="pulfp_repass"
                id="pulfp_repass">
        </li>
    </ul>

    <tmpl_var name="submit_button">
</div>
</form>
END_HTML
}

sub email_template {
    return <<'END_EMAIL_HTML';
<h2>Password Reset</h2>

<p>Hello. Someone (possibly you) requested a password reset. If that
was you, please follow this link to complete the action:
<a href="<tmpl_var escape='html' name='link'>"><tmpl_var escape='html'
name='link'></a></p>

<p>If you did not request anything, simply ignore this email.</p>
END_EMAIL_HTML
}

sub ask_login_form_template {
    return <<'END_FORM';

<form action="" method="POST" id="plug_forgot_password_form">
<div>
    <p>Please enter your login into the form below and an email with
        further instructions will be sent to you.</p>

    <input type="hidden" name="page" value="<tmpl_var escape='html'
        name='page'>">
    <input type="hidden" name="pulfp_ask_link" value="1">
    <tmpl_if name='error'>
        <p class="error"><tmpl_var escape='html' name='error'></p>
    </tmpl_if>

    <label for="pulfp_login">Your login: </label
    ><input type="text"
        class="input_text"
        name="pulfp_login"
        id="pulfp_login">

    <tmpl_var name="submit_button">
</div>
</form>
END_FORM
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::UserLogin::ForgotPassword - addon plugin that adds functionality to let users reset passwords

=head1 SYNOPSIS

In your L<HTML::Template> template:

    <tmpl_var name='plug_forgot_password'>

In your Main Config File or ZofCMS Template:

    plugins => [ qw/UserLogin::ForgotPassword/ ],

    plug_user_login_forgot_password => {
        # mandatory
        dsn                  => "DBI:mysql:database=test;host=localhost",

        # everything below is optional...
        # ...arguments' default values are shown
        user                 => '',
        pass                 => undef,
        opt                  => { RaiseError => 1, AutoCommit => 1 },
        users_table          => 'users',
        code_table           => 'users_forgot_password',
        q_code               => 'pulfp_code',
        max_abuse            => '5:10:60', # 5 min. intervals, max 10 attempts per 60 min.
        min_pass             => 6,
        code_expiry          => 24*60*60, # 1 day
        code_length          => 6,
        subject              => 'Password Reset',
        email_link           => undef, # this will be guessed
        from                 => undef,
        email_template       => undef, # use plugin's default template
        create_table         => undef,
        login_page           => '/',
        mime_lite_params     => undef,
        email                => undef, # use `email` column in users table
        button_send_link => q|<input type="submit" class="input_submit"|
            . q| value="Send password">|,
        button_change_pass => q|<input type="submit" class="input_submit"|
            . q| value="Change password">|,
        use_stage_indicators => 1,
        no_run               => undef,
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that adds functionality to
L<App::ZofCMS::Plugin::UserLogin> plugin; that being the "forgot password?"
operations. Namely, this involves showing the user the form to ask for
their login, emailing the user special link which to follow (this is to
establish ligitimate reset) and, finally, to provide a form where a user
can enter their new password (and of course, the plugin will update
the password in the C<users> table). Wow, a mouthful of functionality! :)

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>. Whilst not necessary,
being familiar with L<App::ZofCMS::Plugin::UserLogin> might be helpful.

=head1 GENERAL OUTLINE OF THE WAY PLUGIN WORKS

Here's the big picture of what the plugin does: user visits a page, plugin
shows the HTML form that asks the user to enter their login in order to
request password reset.

Once the user does that, the plugin checks that the provided login indeed
exists, checks that there's no abuse going on (flooding with reset
requests), generates a special "code" that, as part of a full
link-to-follow, is sent to the user inviting them to click it to proceed
with the reset.

Once the user clicks the link in their email (and thus ends up back on your
site), the plugin will invite them to enter (and reenter to confirm)
their new password. Once the plugin ensures the password looks good,
it will update user's password in the database.

All this can be enabled on your site with a few keystroke, thanks to this
plugin :)

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        { 'UserLogin::ForgotPassword' => 2000 },
    ],

B<Mandatory>. You need to include the plugin in the list of plugins
to execute.

=head2 C<plug_user_login_forgot_password>

    plug_user_login_forgot_password => {
        # mandatory
        dsn                  => "DBI:mysql:database=test;host=localhost",

        # everything below is optional...
        # ...arguments' default values are shown
        user                 => '',
        pass                 => undef,
        opt                  => { RaiseError => 1, AutoCommit => 1 },
        users_table          => 'users',
        code_table           => 'users_forgot_password',
        q_code               => 'pulfp_code',
        max_abuse            => '5:10:60', # 5 min. intervals, max 10 attempts per 60 min.
        min_pass             => 6,
        code_expiry          => 24*60*60, # 1 day
        code_length          => 6,
        subject              => 'Password Reset',
        email_link           => undef, # this will be guessed
        from                 => undef,
        email_template       => undef, # use plugin's default template
        create_table         => undef,
        login_page           => '/',
        mime_lite_params     => undef,
        email                => undef, # use `email` column in users table
        button_send_link => q|<input type="submit" class="input_submit"|
            . q| value="Send password">|,
        button_change_pass => q|<input type="submit" class="input_submit"|
            . q| value="Change password">|,
        use_stage_indicators => 1,
        no_run               => undef,
    },

    # or
    plug_user_login_forgot_password => sub {
        my ( $t, $q, $config ) = @_;
        ...
        return $hashref_to_assign_to_plug_user_login_forgot_password_key;
    },

B<Mandatory>. Takes either a hashref or a subref as a value.
If subref is specified, its return value will be assigned to
C<plug_user_login_forgot_password> key as if it was already there.
If sub returns an C<undef>, then plugin will stop further processing.
The C<@_> of the subref will contain C<$t>, C<$q>, and C<$config>
(in that order), where C<$t> is ZofCMS Tempalate hashref,
C<$q> is query parameters hashref, and C<$config> is the
L<App::ZofCMS::Config> object. The hashref has a whole ton of possible
keys/values that control plugin's behavior; luckily, virtually all of them
are optional with sensible defaults. Possible keys/values for the hashref
are as follows:

=head3 C<dsn>

    plug_user_login_forgot_password => {
        dsn => "DBI:mysql:database=test;host=localhost",
    ...

B<Mandatory>. The C<dsn> key will be passed to L<DBI>'s
C<connect_cached()> method, see documentation for L<DBI> and
C<DBD::your_database> for the correct syntax for this one.
The example above uses MySQL database called C<test> which is
located on C<localhost>.
B<Defaults to:> C<"DBI:mysql:database=test;host=localhost">, which is
rather useless, so make sure to set your own :)

=head3 C<user>

    plug_user_login_forgot_password => {
        user => '',
    ...

B<Optional>. Specifies the user name (login) for the database. This can be
an empty string if, for example, you are connecting using SQLite
driver. B<Defaults to:> C<''> (empty string)

=head3 C<pass>

    plug_user_login_forgot_password => {
        pass => undef,
    ...

B<Optional>. Same as C<user> except specifies the password for the
database. B<Defaults to:> C<undef> (no password)

=head3 C<opt>

    plug_user_login_forgot_password => {
        opt => { RaiseError => 1, AutoCommit => 1 },
    ...

B<Optional>. Will be passed directly to L<DBI>'s C<connect_cached()> method
as "options". B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<users_table>

    plug_user_login_forgot_password => {
        users_table => 'users',
    ...

B<Optional>. Specifies the name of the SQL table that you're using
for storing I<user records>. This would be the
L<App::ZofCMS::Plugin::UserLogin>'s C<table> argument. If you're not
using that plugin, your users table should have logins stored in
C<login> column, passwords in C<password> columns. If you're B<not
planning to specify> the C<email> argument (see below), your users
table need to have email addresses specified in the C<email> table column;
these will be the email addresses to which the reset links will be emailed.
B<Defaults to:> C<users>

=head3 C<code_table>

    plug_user_login_forgot_password => {
        code_table => 'users_forgot_password',
    ...

    CREATE TABLE `users_forgot_password` (
        `login` TEXT,
        `time`  VARCHAR(10),
        `code`  TEXT
    );'

B<Optional>. Specifies the name of SQL table into which to store
reset codes. This table will be used when user submits password reset
request, and the added entry will be deleted when user successfully enters
new password. Above SQL code shows the needed structure of the table,
but see C<create_table> argument (below) for more on this.
B<Defaults to:> C<users_forgot_password>

=head3 C<create_table>

    plug_user_login_forgot_password => {
        create_table => undef,
    ...

B<Optional>. Takes true or false values. When set to a true value,
the plugin will automatically create the needed table where to store
reset codes (see C<code_table> above). Note: if the table already exists,
plugin will crap out with an error - that's the intended behaviour, simply
set C<create_table> back to false value. B<Defaults to:> C<undef>

=head3 C<q_code>

    plug_user_login_forgot_password => {
        q_code => 'pulfp_code',
    ...

B<Optional>. Takes a scalar as a value that indicates the name of
the query parameter that will be used by the plugin to reteive the
"special" code. Plugin uses several query parameter names during its
operation, but the code is sent via email and is directly visible to
the user; the idea is that that might give you enough reason to wish
control the name of that parameter. B<Defaults to:> C<pulfp_code>

=head3 C<max_abuse>

    plug_user_login_forgot_password => {
        max_abuse => '5:10:60', # 5 min. intervals, max 10 attempts per 60 min.
    ...

    plug_user_login_forgot_password => {
        max_abuse => undef, # turn off abuse control
    ...

B<Optional>. B<Defaults to:> C<5:10:60> (5 minute intervals, maximum 10
attempts per 60 minutes). Takes either C<undef> or specially formatted
"time code". This argument is responsible for abuse control (yey); abuse
being the case when an idiot enters some user's login in the reset form and
then hits browser's REFRESH a billion times, flooding said user. The values
for this argument are:

=head4 C<undef>

    plug_user_login_forgot_password => {
        max_abuse => undef, # turn off abuse control
    ...

If set to C<undef>, abuse control will be disabled.

=head4 first time code number

    plug_user_login_forgot_password => {
        max_abuse => '5:10:60',
    ...

Unless set to C<undef>, the argument's value must be three numbers
separated by colons. The first number indicates, in minutes, the interval
of time that must pass after a password reset request until another request
can be sent I<using the same login> (there's no per-IP protection, or
anything like that). B<Default first number is> C<5>.

=head4 second time code number

The second number indicates the maximum number of reset attempts
(again, per-login) that can be done in C<third number> interval of time.
For example, if the second number is 10 and third is 60, a user can request
password reset 10 times in 60 minutes and no more.
B<Default second number> is C<10>.

=head4 third time code number

The third number indicates, in minutes, the time interval used by the
second number. B<Default third number is> C<60>.

=head3 C<min_pass>

    plug_user_login_forgot_password => {
        min_pass => 6,
    ...

B<Optional>. Takes a positive integer as a value. Specifies the minimum
length (number of characters) for the new password the user provides.
B<Defaults to:> C<6>

=head3 C<code_expiry>

    plug_user_login_forgot_password => {
        code_expiry => 24*60*60, # 1 day
    ...

B<Optional>. Takes, in seconds, the time after which to deem the
reset code (request) as expired. In other words, if the user requests
password reset, then ignores his email for C<code_expiry> seconds,
then the link in his email will no longer work, and he would have to
request the reset all over again. B<Defaults to:> C<86400> (24 hours)

=head3 C<code_length>

    plug_user_login_forgot_password => {
        code_length => 6,
    ...

B<Optional>. Specifies the length of the randomly generated code that
is used to identify legitimate user. Since this code is sent to the
user via email, and is directly visible, specifying the code to be
of too much length will look rather ugly. On the other hand, too short
of a code can be easily guessed by a vandal.
B<Defaults to:> C<6>

=head3 C<subject>

    plug_user_login_forgot_password => {
        subject => 'Password Reset',
    ...

B<Optional>. Takes a string as a value, this will be used as the subject
line of the email sent to the user (the one containing the link to click).
B<Defaults to:> C<Password Reset>

=head3 C<from>

    plug_user_login_forgot_password => {
        from => undef,
    ...

    plug_user_login_forgot_password => {
        from => 'Zoffix Znet <zoffix@cpan.org>',
    ...

B<Optional>. Takes a scalar as a value that specifies the C<From> field for
your email. If not specified, the plugin will simply not set the C<From>
argument in L<MIME::Lite>'s C<new()> method (which is what this plugin uses
under the hood). See L<MIME::Lite>'s docs for more description.
B<Defaults to:> C<undef> (not specified)

=head3 C<email_link>

    plug_user_login_forgot_password => {
        email_link => undef, # guess the right page
    ...

    # note how the URI ends with the "invitation" to append the reset
    # ... code right to the end
    plug_user_login_forgot_password => {
        email_link => 'http://foobar.com/your_page?foo=bar&pulfp_code=',
    ...

B<Optional>. Takes either C<undef> or a string containing a link
as a value. Specifies the link to the page with this plugin enabled, this
link will be emailed to the user so that they could proceed to
enter their new password. When set to C<undef>, the plugin guesses the
current page (using C<%ENV>) and that's what it will use for the link.
If you specify the string, make sure to end it with C<pulfp_code=> (note
the equals sign at the end), where C<pulfp_code> is the value you have set
for C<q_code> argument. B<Defaults to:> C<undef> (makes the plugin guess
the right link)

=head3 C<email_template>

    plug_user_login_forgot_password => {
        email_template => undef, # use plugin's default template
    ...

    plug_user_login_forgot_password => {
        email_template => \'templates/file.tmpl', # read template from file
    ...

    plug_user_login_forgot_password => {
        email_template => '<p>Blah blah blah...', # use this string as template
    ...

B<Optional>. Takes a scalar, a scalar ref, or C<undef> as a value.
Specifies L<HTML::Template> template to use when generating the email
with the reset link. When set to C<undef>, plugin will use its default
template (see OUTPUT section below). If you're using your own template,
the C<link> template variable will contain the link the user needs to follow
(i.e., use C<< <tmpl_var escape='html' name='link'> >>).
B<Defaults to:> C<undef> (plugin's default, see OUTPUT section below)

=head3 C<login_page>

    plug_user_login_forgot_password => {
        login_page => '/',
    ...

    plug_user_login_forgot_password => {
        login_page => '/my-login-page',
    ...

    plug_user_login_forgot_password => {
        login_page => 'http://lolwut.com/your-login-page',
    ...

B<Optional>. As a value, takes either C<undef> or a URI. Once the user is
through will all the stuff plugin wants them to do, the plugin will tell
them that the password has been changed, and that they can no go ahead
and "log in". If C<login_page> is specified, the "log in" text will be
a link pointing to whatever you set in C<login_page>; otherwise, the
"log in" text will be just plain text. B<Defaults to:> C</> (i.e. web root)

=head3 C<mime_lite_params>

    plug_user_login_forgot_password => {
        mime_lite_params => undef,
    ...

    plug_user_login_forgot_password => {
        mime_lite_params => [
            'smtp',
            'meowmail',
            Auth   => [ 'FOO/bar', 'p4ss' ],
        ],
    ...

B<Optional>. Takes an arrayref or C<undef> as a value.
If specified, the arrayref will be directly dereferenced into
C<< MIME::Lite->send() >>. Here you can set any special send arguments you
need; see L<MIME::Lite> docs for more info. B<Note:> if the plugin refuses
to send email, it could well be that you need to set some
C<mime_lite_params>; on my box, without anything set, the plugin behaves
as if everything went through fine, but no email arrives.
B<Defaults to:> C<undef>

=head3 C<email>

    plug_user_login_forgot_password => {
        email => undef,
    ...

    plug_user_login_forgot_password => {
        email => 'foo@bar.com,meow.cans@catfood.com',
    ...

B<Optional>. Takes either C<undef> or email address(es) as a value.
This argument tells the plugin where to send the email containing password
reset link. If set to C<undef>, plugin will look into C<users_table> (see
above) and will assume that email address is associated with the user's
account and is stored in the C<email> column of the C<users_table> table.
If you don't want that, set the email address directly here. Note: if you
want to have multiple email addresses, simply separate them with commas.
B<Defaults to:> C<undef> (take emails from C<users_table> table)

=head3 C<button_send_link>

    plug_user_login_forgot_password => {
        button_send_link => q|<input type="submit" class="input_submit"|
            . q| value="Send password">|,
    ...

B<Optional>. Takes HTML code as a value. This code represents the
submit button in the first form (the one that asks the user to enter
their login). This, for example, allows you to use image buttons instead
of regular ones. Also, feel free to use this as the insertion point
for any extra HTML form you need in this form. B<Defaults to:>
C<< <input type="submit" class="input_submit" value="Send password"> >>

=head3 C<button_change_pass>

    plug_user_login_forgot_password => {
        button_change_pass => q|<input type="submit" class="input_submit"|
            . q| value="Change password">|,
    ...

B<Optional>. Takes HTML code as a value. This code represents the
submit button in the second form (the one that asks the user to enter
and reconfirm their new password). This, for example, allows you to use
image buttons instead of regular ones. Also, feel free to use this as the
insertion point for any extra HTML form you need in this form.
B<Defaults to:>
C<< <input type="submit" class="input_submit" value="Change password"> >>

=head3 C<no_run>

    plug_user_login_forgot_password => {
        no_run => undef,
    ...

    plug_user_login_forgot_password => {
        no_run => 1,
    ...

B<Optional>. Takes either true or false values as a value. This
argument is a simple control switch that you can use to tell the plugin
not to execute. If set to a true value, plugin will not run.
B<Defaults to:> C<undef> (for obvious reasons :))

=head3 C<use_stage_indicators>

    plug_user_login_forgot_password => {
        use_stage_indicators => 1,
    ...

B<Optional>. Takes either true or false values as a value. When set
to a true value, plugin will set "stage indicators" (see namesake section
below for details); otherwise, it won't set anything. B<Defaults to:> C<1>

=head1 STAGE INDICATORS & PLUGIN'S OUTPUT VARIABLE

All of plugin's output is spit out into a single variable in your
L<HTML::Template> template:

    <tmpl_var name='plug_forgot_password'>

This raises the question of controlling the bells and whistles on your
page with regard to what stage the plugin is undergoing
(i.e. is it displaying that form that asks for a login or the one that
is asking the user for a new password?). This is where I<stage indicators>
come into play.

Providing C<use_stage_indicators> argument (see above) is set to a true
value, the plugin will set the key with the name of
appropriate stage indicator to a true value. That key resides in the
C<{t}> ZofCMS Template special key, so that you could use it in your
L<HTML::Template> templates. Possible stage indicators as well as
explanations of when they are set are as follows:

=head2 C<plug_forgot_password_stage_initial>

    <tmpl_if name='plug_forgot_password_stage_initial'>
        Forgot your pass, huh?
    </tmpl_if>

This indicator shows that the plugin is in its initial stage; i.e. the
form asking the user to enter their login is shown.

=head2 C<plug_forgot_password_stage_ask_error_login>

    <tmpl_if name='plug_forgot_password_stage_ask_error_login'>
        Yeah, that ain't gonna work if you don't tell me your login...
    </tmpl_if>

This indicator will be active if the user submits the form that is
asking for his login, but does not specify his login.

=head2 C<plug_forgot_password_stage_ask_error_no_user>

    <tmpl_if name='plug_forgot_password_stage_ask_error_no_user'>
        Are you sure you got the right address, bro?
    </tmpl_if>

This indicator shows that the plugin did not find user's login in the
C<users_table> table.

=head2 C<plug_forgot_password_stage_ask_error_abuse>

    <tmpl_if name='plug_forgot_password_stage_ask_error_abuse'>
        Give it a rest, idiot!
    </tmpl_if>

This indicator shows that the plugin detected abuse (see C<max_abuse>
plugin's argument for details).

=head2 C<plug_forgot_password_stage_emailed>

    <tmpl_if name='plug_forgot_password_stage_emailed'>
        Sent ya an email, dude!
    </tmpl_if>

This indicator turns on when the plugin successfully sent the user
an email containing reset pass link.

=head2 C<plug_forgot_password_stage_code_invalid>

    <tmpl_if name='plug_forgot_password_stage_code_invalid'>
        Your reset code has expired, buddy. Hurry up, next time!
    </tmpl_if>

This indicator is active when the plugin can't find the code the user
is giving it. Under natural circumstances, this will only occur when
the code has expired.

=head2 C<plug_forgot_password_stage_change_pass_ask>

    <tmpl_if name='plug_forgot_password_stage_change_pass_ask'>
        What's the new pass you want, buddy?
    </tmpl_if>

This indicator turns on when the form asking the user for the new password
is active.

=head2 C<plug_forgot_password_stage_code_bad_pass_length>

    <tmpl_if name='plug_forgot_password_stage_code_bad_pass_length'>
        That pass's too short, dude.
    </tmpl_if>

This indicator signals that the user attempted to use too short of a new
password (the length is controlled with the C<min_pass> plugin's argument).

=head2 C<plug_forgot_password_stage_code_bad_pass_copy>

    <tmpl_if name='plug_forgot_password_stage_code_bad_pass_copy'>
        It's really hard to type the same thing twice, ain't it?
    </tmpl_if>

This indicator turns on if the user did not retype the new password
correctly.

=head2 C<plug_forgot_password_stage_change_pass_done>

    <tmpl_if name='plug_forgot_password_stage_change_pass_done'>
        Well, looks like you're all done with reseting your pass and what not.
    </tmpl_if>

This indicator shows that the final stage of plugin's run has been reached;
i.e. the user has successfully reset the password and can go on with
their other business.

=head1 OUTPUT

The plugin generates a whole bunch of various output; what's below should
cover all the bases:

=head2 Default Email Template

    <h2>Password Reset</h2>

    <p>Hello. Someone (possibly you) requested a password reset. If that
    was you, please follow this link to complete the action:
    <a href="<tmpl_var escape='html' name='link'>"><tmpl_var escape='html'
    name='link'></a></p>

    <p>If you did not request anything, simply ignore this email.</p>

You can change this using C<email_template> argument. When using your
own, use C<< <tmpl_var escape='html' name='link'> >> to insert the
link the user needs to follow.

=head2 "Ask Login" Form Template

    <form action="" method="POST" id="plug_forgot_password_form">
    <div>
        <p>Please enter your login into the form below and an email with
            further instructions will be sent to you.</p>

        <input type="hidden" name="page" value="<tmpl_var escape='html'
            name='page'>">
        <input type="hidden" name="pulfp_ask_link" value="1">
        <tmpl_if name='error'>
            <p class="error"><tmpl_var escape='html' name='error'></p>
        </tmpl_if>

        <label for="pulfp_login">Your login: </label
        ><input type="text"
            class="input_text"
            name="pulfp_login"
            id="pulfp_login">

        <input type="submit"
            class="input_submit"
            value="Send password">
    </div>
    </form>

This is the form that asks the user for their login in order to reset
the password. Submit button is plugin's default code, you can control
it with the C<button_send_link> plugin's argument.

=head2 "New Password" Form Template

    <form action="" method="POST" id="plug_forgot_password_new_pass_form">
    <div>
        <p>Please enter your new password.</p>

        <input type="hidden" name="page" value="<tmpl_var escape='html'
            name='page'>">
        <input type="hidden" name="<tmpl_var escape='html'
            name='code_name'>"
            value="<tmpl_var escape='html' name='code_value'>">
        <input type="hidden" name="pulfp_has_change_pass" value="1">
        <tmpl_if name='error'>
            <p class="error"><tmpl_var escape='html' name='error'></p>
        </tmpl_if>

        <ul>
            <li>
                <label for="pulfp_pass">New password: </label
                ><input type="password"
                    class="input_password"
                    name="pulfp_pass"
                    id="pulfp_pass">
            </li>
            <li>
                <label for="pulfp_repass">Retype new password: </label
                ><input type="password"
                    class="input_password"
                    name="pulfp_repass"
                    id="pulfp_repass">
            </li>
        </ul>

        <input type="submit"
            class="input_submit"
            value="Change password">
    </div>
    </form>

This is the template for the form that asks the user for their new
password, as well as the retype of it for confirmation purposes. The code
for the submit button is what the plugin uses by default
(see C<button_change_pass> plugin's argument).

=head2 "Email Sent" Message

    <p class="reset_link_send_success">Please check your email
        for further instructions on how to reset your password.</p>

This message is shown when the user enters correct login and the
plugin successfully sents the user their reset link email.

=head2 "Expired Reset Code" Message

    <p class="reset_code_expired">Your reset code has expired. Please try
        resetting your password again.</p>

This will be shown if the user follows a reset link that contains
invalid (expired) reset code.

=head2 "Changes Successfull" Message

    <p class="reset_pass_success">Your password has been successfully
        changed. You can now use it to <a href="/">log in</a>.</p>

This will be shown when the plugin has done its business and the password
has been reset. Note that the "log in" text will only be a link if
C<login_page> plugin's argument is set; otherwise it will be plain text.

=head1 REQUIRED MODUILES

The plugin requires the following modules/versions for healthy operation:

    App::ZofCMS::Plugin::Base  => 0.0105
    DBI                        => 1.607
    Digest::MD5                => 2.36_01
    HTML::Template             => 2.9
    MIME::Lite                 => 3.027

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