package Apache2::Controller::Directives;

=head1 NAME

Apache2::Controller::Directives - server config directives for A2C

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

 # apache2 config file
 PerlLoadModule Apache2::Controller::Directives

 # for Apache2::Controller::Render::Template settings:
 A2C_Render_Template_Path /var/myapp/templates

 # etc.

All values are detainted using C<< m{ \A (.*) \z }mxs >>,
since they are assumed to be trusted because they come
from the server config file.  As long as you don't give
your users the ability to set directives, it should be okay.

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use Carp qw( croak );
use Log::Log4perl qw(:easy);
use YAML::Syck;
use Readonly;

use Apache2::Module ();
use Apache2::Const -compile => qw( OR_ALL NO_ARGS TAKE1 ITERATE ITERATE2 RAW_ARGS );
use Apache2::Controller::X;

use Apache2::Controller::Const qw( @RANDCHARS );

my @directives = (

    # dispatch
    {
        name            => 'A2C_Dispatch_Map',
        func            => __PACKAGE__.'::A2C_Dispatch_Map',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::ITERATE,
        errmsg          => 'A2C_Dispatch_Map /path/to/yaml/syck/dispatch/map/file',
    },

    # template rendering
    { 
        name            => 'A2C_Render_Template_Path',
        func            => __PACKAGE__.'::A2C_Render_Template_Path',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::ITERATE,
        errmsg          => 'A2C_Render_Template_Path /primary/path [/second ... [/n]]',
    },
    {
        name            => 'A2C_Render_Template_Opts',
        func            => __PACKAGE__.'::A2C_Render_Template_Opts',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::ITERATE2,
        errmsg          => q{
            # specify Template Toolkit options:
            A2C_Render_Template_Opts INTERPOLATE 1
            A2C_Render_Template_Opts PRE_PROCESS header scripts style
            A2C_Render_Template_Opts POST_CHOMP  1
        },
    },

    # session stuff
    {
        name            => 'A2C_Session_Class',
        func            => __PACKAGE__.'::A2C_Session_Class',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Session_Class Apache::Session::File'
    },
    {
        name            => 'A2C_Session_Opts',
        func            => __PACKAGE__.'::A2C_Session_Opts',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::ITERATE2,
        errmsg          => q{
            # specify options for chosen Apache::Session subclass.
            # example:
            A2C_Session_Opts   Directory       /tmp/sessions
            A2C_Session_Opts   LockDirectory   /var/lock/sessions
        },
    },
    {
        name            => 'A2C_Session_Secret',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
        errmsg          => q{
            # specify a constant secret for continuity across server restarts
            A2C_Session_Secret  foobar

            # if no parameters, server startup will generate a secret,
            # but this won't work for cluster farms etc.
            A2C_Session_Secret
        },
    },
    {
        name            => 'A2C_Session_Always_Save',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::NO_ARGS,
        errmsg          => 'example: A2C_Session_Always_Save',
    },
    {
        name            => 'A2C_Session_Cookie_Opts',
        func            => __PACKAGE__.'::A2C_Session_Cookie_Opts',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::ITERATE2,
        errmsg          => q{
            # specify Apache2::Cookie options for session cookie.
            # example:
            A2C_Session_Cookie_Opts   name       myapp_sessionid
            A2C_Session_Cookie_Opts   expires    +3M
        },
    },

    # A2C:Methods
    {
        name            => 'A2C_Skip_Bogus_Cookies',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::NO_ARGS,
        errmsg          => 'example: A2C_Skip_Bogus_Cookies',
    },

    # A2C:DBI::Connector
    {
        name            => 'A2C_DBI_DSN',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_DBI_DSN DBI:mysql:database=foo',
    },
    {
        name            => 'A2C_DBI_User',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_DBI_User database_username',
    },
    {
        name            => 'A2C_DBI_Password',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_DBI_Password database_password',
    },
    {
        name            => 'A2C_DBI_Options',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::ITERATE2,
        errmsg          => q{
            # specify DBI connect() options:
            A2C_DBI_Options RaiseError 1
            A2C_DBI_Options AutoCommit 0
        },
    },
    {
        name            => 'A2C_DBI_Cleanup',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_DBI_Cleanup 1',
    },
    {
        name            => 'A2C_DBI_Class',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_DBI_Class MyApp::DBI',
    },
    {
        name            => 'A2C_DBI_Pnotes_Name',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_DBI_Pnotes_Name reader',
    },

    # A2C:Auth::OpenID
    {
        name            => 'A2C_Auth_OpenID_Login',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_Login /myapp/login',
    },
    {
        name            => 'A2C_Auth_OpenID_Logout',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_Logout /myapp/logout',
    },
    {
        name            => 'A2C_Auth_OpenID_Register',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_Register /myapp/register',
    },
    {
        name            => 'A2C_Auth_OpenID_Timeout',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_Timeout +1h',
    },
    {
        name            => 'A2C_Auth_OpenID_Table',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_Table openid',
    },
    {
        name            => 'A2C_Auth_OpenID_User_Field',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_User_Field uname',
    },
    {
        name            => 'A2C_Auth_OpenID_URL_Field',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_URL_Field openid_url',
    },
    {
        name            => 'A2C_Auth_OpenID_DBI_Name',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_DBI_Name dbh',
    },
    {
        name            => 'A2C_Auth_OpenID_Trust_Root',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_Trust_Root http://blah.tld/blah',
    },
    {
        name            => 'A2C_Auth_OpenID_LWP_Class',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::TAKE1,
        errmsg          => 'example: A2C_Auth_OpenID_LWP_Class LWPx::ParanoidAgent',
    },
    {
        name            => 'A2C_Auth_OpenID_LWP_Opts',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::ITERATE2,
        errmsg          => q{
            # specify options to the LWP class.  example:
            A2C_Auth_OpenID_LWP_Opts timeout           10
            A2C_Auth_OpenID_LWP_Opts agent             A2C-openid
            A2C_Auth_OpenID_LWP_Opts whitelisted_hosts 127.0.0.1  foo.bar.tld
            # (don't whitelist stuff for ParanoidAgent unless you know
            # what you're doing... we do this for the test suite)
        },
    },
    {
        name            => 'A2C_Auth_OpenID_Allow_Login',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::NO_ARGS,
        errmsg          => 'example: A2C_Auth_OpenID_Allow_Login',
    },
    {
        name            => 'A2C_Auth_OpenID_Consumer_Secret',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
        errmsg          => q{
            # specify a constant secret for continuity across server restarts
            A2C_Auth_OpenID_Consumer_Secret  foobar

            # if no parameters, server startup will generate a secret,
            # but this won't work for cluster farms etc.
            A2C_Auth_OpenID_Consumer_Secret
        },
    },
    {
        name            => 'A2C_Auth_OpenID_NoPreserveParams',
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::NO_ARGS,
        errmsg          => 'example: A2C_Auth_OpenID_NoPreserveParams',
    },
);

Apache2::Module::add(__PACKAGE__, \@directives);

=head1 Apache2::Controller::Dispatch

See L<Apache2::Controller::Dispatch>

=head2 A2C_Dispatch_Map

This is the path to a file compatible with L<YAML::Syck>.
If you do not provide a C<< dispatch_map() >> subroutine,
the hash will be loaded with this file.

Different subclasses of L<Apache2::Controller::Dispatch>
have different data structures.  YMMV.

Or, if you just specify a package name, it will generate
a dispatch map with one 'default' entry with that package.

=cut

sub A2C_Dispatch_Map {
    my ($self, $parms, $value) = @_;

    ($value) = $value =~ m{ \A (.*) \z }mxs;

    if ($value =~ m{ :: }mxs) {
        $self->{A2C_Dispatch_Map} = { default => $value };
        return;
    }

    my $file = $value;
  # DEBUG("using file '$file' as A2C_Dispatch_Map");
    croak "A2C_Dispatch_Map $file does not exist or is not readable."
        if !(-e $file && -f _ && -r _);
    
    # why not go ahead and load the file!

    # slurp it in so it can be detainted.

    my $file_contents;
    {   local $/;
        open my $loadfile_fh, '<', $file 
            || croak "Cannot read A2C_Dispatch_Map $file: $OS_ERROR";
        $file_contents = <$loadfile_fh>;
        close $loadfile_fh;
    }

    eval { $self->{A2C_Dispatch_Map} = Load($file_contents) };
    croak "Could not load A2C_Dispatch_Map $file: $EVAL_ERROR" if $EVAL_ERROR;

  # DEBUG("success!");
    return;
}

=head1 Apache2::Controller::Render::Template

See L<Apache2::Controller::Render::Template>.

=head2 A2C_Render_Template_Path

This is the base path for templates used by 
Apache2::Controller::Render::Template.  The directive takes only
one parameter and verifies that the directory exists and is readable.

(At startup time Apache2 is root... this should verify readability by 
www user?  Hrmm how is it going to figure out what user that is?
It will have to access the server config via $parms. Except that
this does not appear to work?  It returns an empty hash.)

=cut

sub A2C_Render_Template_Path {
    my ($self, $parms, @directories_untainted) = @_;

    my @directories = map { 
        my ($val) = $_ =~ m{ \A (.*) \z }mxs;
        $val;
    } @directories_untainted;

    # uhh... this doesn't work?
  # my $srv_cfg = Apache2::Module::get_config($self, $parms->server);
  # DEBUG(sub{"SERVER CONFIG:\n".Dump({
  #     map {("$_" => $srv_cfg->{$_})} keys %{$srv_cfg}
  # }) });
  # DEBUG("server is ".$parms->server);

    # I need to figure out how to merge these or something

    croak("A2C_Render_Template_Path '$_' does not exist or is not readable.") 
        for grep !( -d $_ && -r _ ), @directories;

    my $current = $self->{A2C_Render_Template_Path} ||= [ ];
    DEBUG sub { "pushing (@directories) to (@{$current})" };

    push @{ $self->{A2C_Render_Template_Path} }, @directories;
}

=head2 A2C_Render_Template_Opts

 <location "/where/template/is/used">
     A2C_Render_Template_Opts INTERPOLATE 1
     A2C_Render_Template_Opts PRE_PROCESS header meta style scripts
     A2C_Render_Template_Opts POST_CHOMP  1
 </location>

Options for Template Toolkit.  See L<Template>.

You can also implement C<<get_template_opts>> in your controller subclass,
which simply returns the hash reference of template options.
See L<Apache2::Controller::Render::Template>.

Note the behavior is to merge values specified at multiple levels
into array references.  i.e. a subdirectory could specify an
additional C<<PRE_PROCESS>> template or whatever.  YMMV.
It should be this way, at any rate!

=cut

sub A2C_Render_Template_Opts {
    my ($self, $parms, $key, $val) = @_;
    $self->hash_assign('A2C_Render_Template_Opts', $key, $val);
    return;
}

=head1 Apache2::Controller::Session

See L<Apache2::Controller::Session>.

=head2 A2C_Session_Class

 A2C_Session_Class Apache::Session::File

Single argument, the class for the tied session hash.  L<Apache::Session>.

=cut

sub A2C_Session_Class {
    my ($self, $parms, $class) = @_;
    ($class) = $class =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Session_Class} = $class;
}

=head2 A2C_Session_Opts

Multiple arguments

 A2C_Session_Opts   Directory       /tmp/sessions
 A2C_Session_Opts   LockDirectory   /var/lock/sessions

=cut

sub A2C_Session_Opts {
    my ($self, $parms, $key, $val) = @_;
    $self->hash_assign('A2C_Session_Opts', $key, $val);
    return;
}

=head2 A2C_Session_Secret

 # generate a random 30-character string:
 A2C_Session_Secret

 # specify your own string:
 A2C_Session_Secret jsd9e9j#*@JMf39kc3

This server-wide constant string will used to verify the session id.
See L<Apache2::Controller::Session>.

If you don't specify the value, it will generate a default 30-character
random string, but this will regenerate on server restarts, and would not
work for a cluster of servers serving the same application.

=cut

sub A2C_Session_Secret {
    my ($self, $parms, $val) = @_;
    if (!defined $val || $val =~ m{ \A \s* \z }mxs) {
        srand;
        $val = join('', map $RANDCHARS[int(rand(@RANDCHARS))], 1..30);
    }
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Session_Secret} = $val;
}

=head2 A2C_Session_Always_Save

 A2C_Session_Always_Save

Takes no arguments.  If directed, L<Apache2::Controller::Session>
will update a top-level timestamp in 
C<< $r->pnotes->{a2c}{session}{a2c_timestamp} >> so that
L<Apache::Session> will always save.

=cut

sub A2C_Session_Always_Save {
    my ($self, $parms) = @_;
    $self->{A2C_Session_Always_Save} = 1;
}

=head2 A2C_Session_Cookie_Opts

 A2C_Session_Cookie_Opts name    myapp_sessionid
 A2C_Session_Cookie_Opts expires +3M

Multiple arguments.  
L<Apache2::Controller::Session::Cookie>,
L<Apache2::Cookie>

=cut

sub A2C_Session_Cookie_Opts {
    my ($self, $parms, $key, $val) = @_;
    $self->hash_assign('A2C_Session_Cookie_Opts', $key, $val);
    return;
}

=head1 Apache2::Controller::Methods

Misc. directives that apply to most A2C objects that inherit
L<Apache2::Controller::Methods>.

=head2 A2C_Skip_Bogus_Cookies 

 A2C_Skip_Bogus_Cookies

Takes no arguments.  If present, cookie jar will be constructed
using C<< eval { } >> that skips NOTOKEN errors.  
See L<Apache2::Controller::Methods/get_cookie_jar>.

=cut

sub A2C_Skip_Bogus_Cookies {
    my ($self, $parms) = @_;
    $self->{A2C_Skip_Bogus_Cookies} = 1;
}

=head1 Apache2::Controller::DBI::Connector

See L<Apache2::Controller::DBI::Connector>.

=head2 A2C_DBI_DSN 

 A2C_DBI_DSN        DBI:mysql:database=foobar;host=localhost

Single argument, the DSN string.  L<DBI>

=cut

sub A2C_DBI_DSN {
    my ($self, $parms, $dsn) = @_;
    ($dsn) = $dsn =~ m{ \A (.*) \z }mxs;
    $self->{A2C_DBI_DSN} = $dsn;
}

=head2 A2C_DBI_User

 A2C_DBI_User       heebee

Single argument, the DBI username.

=cut

sub A2C_DBI_User {
    my ($self, $parms, $user) = @_;
    ($user) = $user =~ m{ \A (.*) \z }mxs;
    $self->{A2C_DBI_User} = $user;
}

=head2 A2C_DBI_Password

 A2C_DBI_Password   jeebee

Single argument, the DBI password.

=cut

sub A2C_DBI_Password {
    my ($self, $parms, $password) = @_;
    ($password) = $password =~ m{ \A (.*) \z }mxs;
    $self->{A2C_DBI_Password} = $password;
}

=head2 A2C_DBI_Options

Multiple arguments.

 A2C_DBI_Options    RaiseError  1
 A2C_DBI_Options    AutoCommit  0

=cut

sub A2C_DBI_Options {
    my ($self, $parms, $key, $val) = @_;
    $self->hash_assign('A2C_DBI_Options', $key, $val);
    return;
}

=head2 A2C_DBI_Cleanup

Boolean.  

 A2C_DBI_Cleanup        1

=cut

sub A2C_DBI_Cleanup {
    my ($self, $parms, $val) = @_;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_DBI_Cleanup} = $val;
    return;
}

=head2 A2C_DBI_Pnotes_Name

String value.

 A2C_DBI_Pnotes_Name    reader

=cut

sub A2C_DBI_Pnotes_Name {
    my ($self, $parms, $val) = @_;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_DBI_Pnotes_Name} = $val;
    return;
}

=head2 A2C_DBI_Class

If you subclass DBI, specify the name of your DBI subclass here.

 A2C_DBI_Class      MyApp::DBI

Note that this is connected with a string eval which is slow.
If you don't use it, it uses a block eval to connect DBI.

=cut

sub A2C_DBI_Class {
    my ($self, $parms, $val) = @_;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_DBI_Class} = $val;
}

=head1 Apache2::Controller::Auth::OpenID

See L<Apache2::Controller::Auth::OpenID>.

=head2 A2C_Auth_OpenID_Login

 A2C_Auth_OpenID_Login  login

The URI path for your login controller page. 

If you start the value with a '/', it thinks you mean
an absolute URI.

If you do not start the value with a '/', it thinks you
mean a uri relative to 
the location path where the directive was declared.

Examples:

 <Location '/foo/bar'>
     A2C_Auth_OpenID_Login  /login
 </Location>

The user would be redirected to absolute uri '/login'.

 <Location '/loungy/vegas/entertainment'>
     A2C_Auth_OpenID_Login  kenny_loggins
 </Location>

The user would be redirected to 
C<< /loungy/vegas/entertainment/kenny_loggins >> 
if they are not logged in.

These conventions are the same for C<< A2C_Auth_OpenID_Logout >>
and C<< A2C_Auth_OpenID_Register >>.

Default is the path where the controller is declared, appended with '/login'.
Access will be allowed.

=cut

sub A2C_Auth_OpenID_Login {
    my ($self, $parms, $val) = @_;
    $val = 'login' if !defined $val;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $val = $parms->path.'/'.$val if $val !~ m{ \A / }mxs;
    $self->{A2C_Auth_OpenID_Login} = $val;
}

=head2 A2C_Auth_OpenID_Logout

 A2C_Auth_OpenID_Logout  logout

The URI path for your logout controller page.

Logout is processed automatically, resetting the flag and
timestamp in the session hash.  So you just need to present
a page that says "Good riddance" or something.

Same conventions apply as to C<< A2C_Auth_OpenID_Login >>.
Default is the path where the controller is declared, appended with '/logout'.
Access will be allowed.

=cut

sub A2C_Auth_OpenID_Logout {
    my ($self, $parms, $val) = @_;
    $val = 'logout' if !defined $val;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $val = $parms->path.'/'.$val if $val !~ m{ \A / }mxs;
    $self->{A2C_Auth_OpenID_Logout} = $val;
}

=head2 A2C_Auth_OpenID_Register

 A2C_Auth_OpenID_Register  register

The path for your registration page, where you will ask the user
to sign up and associate a username with the openid url.

Same conventions apply as to C<< A2C_Auth_OpenID_Login >>.
Default is the path where the controller is declared, appended with '/register'.
Access will be allowed.

=cut

sub A2C_Auth_OpenID_Register {
    my ($self, $parms, $val) = @_;
    $val = 'register' if !defined $val;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $val = $parms->path.'/'.$val if $val !~ m{ \A / }mxs;
    $self->{A2C_Auth_OpenID_Register} = $val;
}

=head2 A2C_Auth_OpenID_Timeout

 A2C_Auth_OpenID_Timeout  +1h

Idle timeout in seconds, +2m, +3h, +4D, +6M, +7Y, or 'no timeout'.
Default is 1 hour.  A month is actually 30 days, a year 365.

If you use 'no timeout' then logins will never expire.
This probably is not a good idea because OpenID url's can
be revoked, and because the login process can be a transparent
series of redirects if the user has something like
Verisign's SeatBelt plugin.

If you're doing some sort of cluster application or load balancing
and sharing the session between servers, make sure all your servers
are synchronized with NTP.  

=cut

my %time_multiplier = (
    s       => 1,
    m       => 60,
    h       => 60 * 60,
    D       => 60 * 60 * 24,
    M       => 60 * 60 * 24 * 30,
    Y       => 60 * 60 * 24 * 365,
);

sub A2C_Auth_OpenID_Timeout {
    my ($self, $parms, $val) = @_;
    $val ||= '+1h';
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    if ($val ne 'no timeout') {
        my ($num, $period) = $val =~ m{ \A \+? (\d+) ([YMDhms]?) \z }mxs;
        $period ||= 's';
        croak("A2C_Auth_OpenID_Timeout invalid format") 
            if !$num || !exists $time_multiplier{$period};
        $val = $num * $time_multiplier{$period};
    }

    $self->{A2C_Auth_OpenID_Timeout} = $val;
}

=head2 A2C_Auth_OpenID_Table

 A2C_Auth_OpenID_Login  openid

Name of the table in your connected database containing the 
user name and OpenID url fields.  Default == "openid".

=cut

sub A2C_Auth_OpenID_Table {
    my ($self, $parms, $val) = @_;
    $val ||= 'openid';
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Auth_OpenID_Table} = $val;
}

=head2 A2C_Auth_OpenID_User_Field

 A2C_Auth_OpenID_User_Field  uname

Name of username field in table.  Default == "uname".

=cut

sub A2C_Auth_OpenID_User_Field {
    my ($self, $parms, $val) = @_;
    $val ||= 'uname';
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Auth_OpenID_User_Field} = $val;
}

=head2 A2C_Auth_OpenID_URL_Field

 A2C_Auth_OpenID_URL_Field  openid_url

Name of OpenID URL field in table.  Default == "openid_url".

=cut

sub A2C_Auth_OpenID_URL_Field {
    my ($self, $parms, $val) = @_;
    $val ||= 'openid_url';
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Auth_OpenID_URL_Field} = $val;
}

=head2 A2C_Auth_OpenID_DBI_Name

 A2C_Auth_OpenID_DBI_Name  dbh

Name in C<< $r->pnotes->{a2c} >> of the connected L<DBI> handle.
Default == "dbh".

=cut

sub A2C_Auth_OpenID_DBI_Name {
    my ($self, $parms, $val) = @_;
    $val ||= 'dbh';
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Auth_OpenID_DBI_Name} = $val;
}

=head2 A2C_Auth_OpenID_Trust_Root

 A2C_Auth_OpenID_Trust_Root  http://blah.tld/blah

The trust_root param to pass to the user's OpenID server.
See L<Net::OpenID::Consumer>.  Default is the top of 
the web site with whatever scheme, host and port that
is currently being requested.

=cut

sub A2C_Auth_OpenID_Trust_Root {
    my ($self, $parms, $val) = @_;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Auth_OpenID_Trust_Root} = $val;
}

=head2 A2C_Auth_OpenID_LWP_Class

 A2C_Auth_OpenID_LWP_Class  LWPx::ParanoidAgent

Name of the L<LWP> class to use.  By default it uses
L<LWPx::ParanoidAgent> but not L<LWPx::ParanoidAgent::DashT>,
as that one is not available as a Debian package, I
was unsuccessful building it with dh-make-perl, and I
want to be able to distribute to Debian.

=cut

sub A2C_Auth_OpenID_LWP_Class {
    my ($self, $parms, $val) = @_;
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Auth_OpenID_LWP_Class} = $val || 'LWPx::ParanoidAgent';
}

=head2 A2C_Auth_OpenID_LWP_Opts

Specify options to the LWP class.

 A2C_Auth_OpenID_LWP_Opts timeout           10
 A2C_Auth_OpenID_LWP_Opts agent             A2C-openid
 A2C_Auth_OpenID_LWP_Opts whitelisted_hosts [ 127.0.0.1  foo.bar.com ]

Don't whitelist stuff for ParanoidAgent unless you know
what you're doing... I was going do this for the test suite to let
the module call the temporary OpenID server set up on localhost.

But that ends up not working in the test suite because of some other 
problem trying to connect to a port which I don't know necessarily?
("Error fetching URL: No sock from bgsend").
So the test suite just uses plain old LWP::UserAgent.

This uses C<< hash_assign() >> to assign the options.

Use [ ] to force an array ref for a single option that has
to be an arrayref: 

 A2C_Auth_OpenID_LWP_Opts whitelisted_hosts [ 192.168.34.5 ]

but don't use commas, it's tricky.
 
=cut

sub A2C_Auth_OpenID_LWP_Opts {
    my ($self, $parms, $key, $val) = @_;
    $self->hash_assign('A2C_Auth_OpenID_LWP_Opts', $key, $val);
    return;
}

=head2 A2C_Auth_OpenID_Allow_Login

 A2C_Auth_OpenID_Allow_Login

Takes no arguments.  If directed, L<Apache2::Controller::Auth::OpenID>
will allow all login attempts and will not attempt to authenticate 
with OpenID.  Useful for debugging your application on your laptop
when you are not connected to the Internet.

=cut

sub A2C_Auth_OpenID_Allow_Login {
    my ($self, $parms) = @_;
    $self->{A2C_Auth_OpenID_Allow_Login} = 1;
}

=head2 A2C_Auth_OpenID_Consumer_Secret

 # generate a random 30-character string:
 A2C_Auth_OpenID_Consumer_Secret

 # specify your own string:
 A2C_Auth_OpenID_Consumer_Secret jsd9e9j#*@JMf39kc3

This server-wide constant string will be appended to the value of 
time() for the sha224_base64 hash provided as the consumer_secret.
See L<Net::OpenID::Consumer/consumer_secret>.

If you don't specify the value, it will generate a default 30-character
random string, but this will regenerate on server restarts, and would not
work for a cluster of servers serving the same application.


=cut

sub A2C_Auth_OpenID_Consumer_Secret {
    my ($self, $parms, $val) = @_;
    if (!defined $val || $val =~ m{ \A \s* \z }mxs) {
        srand;
        $val = join('', map $RANDCHARS[int(rand(@RANDCHARS))], 1..30);
    }
    ($val) = $val =~ m{ \A (.*) \z }mxs;
    $self->{A2C_Auth_OpenID_Consumer_Secret} = $val;
}

=head2 A2C_Auth_OpenID_NoPreserveParams

 A2C_Auth_OpenID_NoPreserveParams

Takes no arguments.  If directed, L<Apache2::Controller::Auth::OpenID>
will not preserve GET/POST params.  I know a double-negative is
frowned upon, but it makes the most sense here, because preserving
GET/POST params should be the default behavior, and this turns
off that behavior.

=cut

sub A2C_Auth_OpenID_NoPreserveParams {
    my ($self, $parms) = @_;
    $self->{A2C_Auth_OpenID_NoPreserveParams} = 1;
}

=head2 hash_assign 

This is not a configuration option, but an internal routine
that we use to assign ITERATE2 options in a consistent way,
or so one might hope.  I'm not sure I fully understand the
behavior and I haven't written tests for directives.

If a single value is specified, it is assigned as a scalar.

If multiple values are specified (on the same configuration
directive call or in multiple calls) they are successively 

This is sort of similar the way that C<< $r->param >> will get
a string or an array ref depending if the var has been named
more than once.

Use [ ] to force an array ref for a single option that has
to be an arrayref: 

 A2C_Auth_OpenID_LWP_Opts whitelisted_hosts [ 127.0.0.1 ]

but don't use commas, it's tricky.  The closing ] is actually
ignored, but you should use it to make it look sensible.

As a result, you can't use '[' or ']' for the values of 
any of these options... but you "shouldn't need to do that."

See L<Apache2::Const/ITERATE2>.

=cut

sub hash_assign {
    my ($self, $directive, $key, $val) = @_;

    croak "No value for $directive {$key}." if !$val;

    ($key) = $key =~ m{ \A (.*) \z }mxs;
    ($val) = $val =~ m{ \A (.*) \z }mxs;

    if ($val eq '[') {
        $self->{$directive}{$key} = [ ] if !exists $self->{$directive}{$key};
        return;
    }

    return if $val eq ']';
    
    if (exists $self->{$directive}{$key}) {
        $self->{$directive}{$key} = [ $self->{$directive}{$key} ]
            if !ref $self->{$directive}{$key};
        push @{$self->{$directive}{$key}}, $val;
    }
    else {
        $self->{$directive}{$key} = $val;
    }
    return;
}

=head1 SEE ALSO

L<Apache2::Controller>

L<Apache2::Controller::Methods/get_directive>

L<Apache2::Controller::Session>

L<Apache2::Module>

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)- formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut

1;

