package Catalyst::Helper::AuthDBIC;
use strict;
use warnings;
use Catalyst::Helper;
our $VERSION = '0.17';
use Carp;
use DBI;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;
use Memoize;
use PPI;
use PPI::Find;
use Catalyst::Utils;
use File::Spec;
use Config;

memoize('app_name');

=head1 NAME

Catalyst::Helper::AuthDBIC (EXPERIMENTAL)

=head1 SUMMARY

This is an experimental module to bootstrap the authentication portion
of a Catalyst application.  It creates a Catalyst model,
DBIx::Class::Schema classes, basic templates adjusts the required
plugins for you, and configures authentication.  There are no options,
and it doesn't do much inthe way of error checking for you, so you are
recommended to back up your application before using this module.

=head2 USAGE

Run the auth_bootstrap.pl in your application's root dir.

The helper also creates a script in the script dir.  To add a user
(with an optional role) do:

 myapp_auth_admin.pl -user username -passwd password [-role role] [-email me@example.com]

=head2 sub app_name()

Get the name of the application from Makefile.PL

=cut

sub app_name {
    my $app_name;
    my $file = "Makefile.PL";
    open my ($FH), "<", $file or croak "Makefile.PL not found, run this script from your application root dir\n";
    while (<$FH>) {
        next unless /^name '(.*?)';/;
        $app_name=$1;
        $app_name =~ s/-/::/g; # only unsafe if you are already insane
                              # because everything else in
                              # Catalyst::Helper will also be broken
                              # for you.
        croak "Makefile.PL appears to have no name for the application\n" unless $app_name;
        last;
    }
    return $app_name
}

=head2 sub make_model()

Creates the sqlite auth db in ./db and makes the dbic schema and
catalyst model with Catalyst::Helper::Model::DBIC::Schema

=cut

sub make_model {
    # put sqlitedb in __path_to('db')__;
    my $helper = Catalyst::Helper->new();
    $helper->mk_dir('db');
    my $dbh = DBI->connect("dbi:SQLite:dbname=db/auth.db","","");
    my @sql = ("CREATE TABLE role (
                id   INTEGER PRIMARY KEY,
                role TEXT UNIQUE );",
               "CREATE TABLE user (
                id       INTEGER PRIMARY KEY,
                username TEXT UNIQUE,
                email    TEXT,
                password TEXT,
                status   TEXT,
                role_text TEXT,
                session_data TEXT );",
               "CREATE TABLE user_role (
                id   INTEGER PRIMARY KEY,
                user INTEGER REFERENCES user(id),
                roleid INTEGER REFERENCES role(id) );"
           );

    map { $dbh->do($_) } @sql;
    my $app_prefix = Catalyst::Utils::appprefix(app_name());

    make_schema_at(app_name() . "::Auth::Schema",
                   {  components => ['EncodedColumn'],
                      dump_directory => 'lib' ,
                  },
                   ["dbi:SQLite:dbname=db/auth.db", "",""]);
    my $create_file = File::Spec->catfile(File::Spec->curdir(),
                                          'script',
                                          "${app_prefix}_create.pl");
    my @cmd = ( "$create_file",
                 'model',
                 'Auth',
                 'DBIC::Schema',
                 app_name() . "::Auth::Schema",
            );
    system( @cmd );
    my $schema_name = app_name() . "::Auth::Schema";
    my $user_schema = "$schema_name"."::Result::User";
    my @path = split /::/, $user_schema;
    my $user_schema_path = join '/', @path;
    my $module = "lib/$user_schema_path.pm";
    my $doc = PPI::Document->new($module);
    my $digest_code = $helper->get_file(__PACKAGE__, 'digest');

    my $comments = $doc->find(
        sub { $_[1]->isa('PPI::Token::Comment')}
    );
    my $last_comment = $comments->[$#{$comments}];
    $last_comment->set_content($digest_code);
    $doc->save($module);

    # we need to specify the dsn with __path_to(db/auth.db)__ in
    # .conf, rather than code in the model.
    my $conf_file = "$app_prefix.conf";

    open my $FH, ">>", $conf_file;
    my $conf = <<EOF;
    <Model Auth>
      schema_class $schema_name
      connect_info dbi:SQLite:__path_to(db/auth.db)__
      connect_info user
      connect_info passwd # keep these here for dsns that need 'em
    </Model>
EOF
    print $FH $conf;
    close $FH;
}

=head2 sub mk_auth_controller()

uses Catalyst::Helper to make a ::Controller::Auth

=cut

sub mk_auth_controller {
    my $helper = Catalyst::Helper->new();
    my $app_path = app_name();
    $app_path =~ s/::/\//g;
    my $controller_file = "lib/$app_path/Controller/Auth.pm";
    $helper->render_file ('auth_controller',
                          $controller_file,
                          {app_name => app_name()});
}

=head2 sub add_plugins()

    uses ppi to add the auth plugins in the use Catalyst qw// statement

=cut

sub add_plugins {
    my ($module, $doc) = _get_ppi();

    my $find = PPI::Find->new( \&_find_use_catalyst);
    my ($found) = $find->in($doc);
    my $find_plugins = PPI::Find->new(\&_find_plugins);
    my ($plugins) = $find_plugins->in($found);
    croak "Your app is not using any plugins, so we can't continue\n" if !$plugins;
    my $plugin_str = scalar($plugins);
    my $tail = chop $plugin_str;
    $plugin_str .= "\n               Authentication\n               Authorization::Roles\n               Session\n               Session::State::Cookie\n               Session::Store::FastMmap $tail";
    $plugins->set_content($plugin_str);
    $doc->save($module);
}

sub _find_plugins {
    my ($element, $search) = @_;
    return 1 if $element->isa('PPI::Token::QuoteLike::Words');
    return 0
}

sub _find_use_catalyst {
    my ($element, $search) = @_;
    if ( $element->isa('PPI::Statement::Include') &&
         $element->type eq 'use' &&
         $element->module eq 'Catalyst'
     ) {
        return 1;
    }
    return 0;
}

=head2 sub add_config()

Add the auth configuration in MyApp.pm

=cut

sub add_config {
    my ($credential) = @_;
    my ($module, $doc) = _get_ppi();
    my $found = PPI::Find->new(\&_find_setup);
    my ($setup) = $found->in($doc);
    croak "unable to find __PACKAGE__->setup in $module\n" if !$setup;
    my $auth_doc_plain;

    if ( $credential eq 'http' ) {
        warn "Configuring http credential\n";
        $auth_doc_plain = Catalyst::Helper->get_file(__PACKAGE__, 'auth_conf_http');
    }
    elsif ( $credential eq 'password' ) {
        warn "Configuring password (web based) authentication credential\n";
        $auth_doc_plain = Catalyst::Helper->get_file(__PACKAGE__, 'auth_conf_passwd');
    }

    $auth_doc_plain =~ s/__MYSCHEMA__/Auth/msg;
    my $auth_doc = PPI::Document->new(\$auth_doc_plain);
    my $auth_conf = $auth_doc->find_first('PPI::Statement');
    # the code produced here is a little ugly and lacks a \n between
    # the config and the __PACKAGE__->setup declaration. The usage of
    # PPI to modify source is also inconsistent here to elewhere.
    $setup->insert_before($auth_conf);
    $doc->save($module);
}

sub _find_setup {
    my ($element, $search) = @_;
    if ( $element->isa('PPI::Statement')
         && $element =~ /setup.*?;/
     ) {
        return 1;
    }
    return 0;
}

sub _get_ppi {
    my $app_name = app_name() || 'TestApp';
    my @path = split /::/, $app_name;
    my $app_path = join '/', @path;
    my $module = "lib/$app_path.pm";
    my $doc = PPI::Document->new($module);
    return ($module, $doc);
}

=head2 sub write_templates()

make the login, logout and unauth templates

=cut

sub write_templates {
    my $helper = Catalyst::Helper->new();
    my $login = $helper->get_file(__PACKAGE__, 'login.tt');
    my $logout = $helper->get_file(__PACKAGE__, 'logout.tt');
    my $unauth = $helper->get_file(__PACKAGE__, 'unauth.tt');
    $helper->mk_dir("root/auth");
    $helper->mk_file("root/auth/login.tt", $login);
    $helper->mk_file("root/auth/logout.tt", $logout);
    $helper->mk_file("root/auth/unauth.tt", $unauth);
}

=head2 sub update_makefile()

Adds the auth and session dependencies to Makefile.PL

=cut

sub update_makefile {
    my $deps = Catalyst::Helper->get_file(__PACKAGE__, 'requires');
    my $doc = PPI::Document->new('Makefile.PL');
    my $find = PPI::Find->new( \&_find_install_script );
    my ($found) = $find->in($doc);
    croak "There's something wrong with your Makefile.PL so we can't continue (can't find  the install_script directive\n" if ! $found;
    my $install_script = $found->find_first('PPI::Token::Word');
    my $install_script_str = scalar($install_script);
    $install_script->set_content($deps . "\n" . $install_script_str);
    $doc->save('Makefile.PL')
}

sub _find_install_script {
    my ($element, $search) = @_;
    if ($element->isa('PPI::Statement')
            && $element =~ 'install_script') {
        return 1;
    }
    return 0;
}

=head2 sub add_user_helper()

A little script to add a user to the database.

=cut

sub add_user_helper {
    my $helper = Catalyst::Helper->new;
    my $app_prefix = Catalyst::Utils::appprefix(app_name());
    my $script_dir = File::Spec->catdir( '.', 'script' );
    my $script = "$script_dir\/$app_prefix\_auth_admin.pl";
    my $startperl = "#!$Config{perlpath} -w";
    $DB::single=1;
    $helper->render_file('auth_admin',
                         $script,
                         { start_perl => $startperl,
                           appprefix  => $app_prefix,
                           startperl => $startperl,
                           app_name => app_name(),
                       });
    chmod 0700, $script;
}

=head2 BUGS

This is experimental, fairly rough code.  It's a proof of concept for
helper modules for Catalyst that need to alter the application
configuration, Makefile.PL and other parts of the application.  Bug
reports, and patches are encouraged.  Report bugs or provide patches
to http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Helper-AuthDBIC.

=head2 AUTHOR

Kieren Diment <zarquon@cpan.org>


=head1 COPYRIGHT AND LICENCE

Copyright (c) 2008 Kieren Diment

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;

__DATA__

=begin pod_to_ignore

__auth_controller__
package [% app_name %]::Controller::Auth;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    $c->detach('get_login');
}

sub get_login : Local {
    my ($self, $c) = @_;
    $c->stash->{destination} = $c->req->path;
    $c->stash->{template} = 'auth/login.tt';
}

sub logout : Local {
    my ( $self, $c ) = @_;
    $c->logout;
    $c->stash->{template} = 'auth/logout.tt';
}

sub login : Local {
    my ( $self, $c ) = @_;
    my $user = $c->req->params->{user};
    my $password = $c->req->params->{password};
    $c->flash->{destination} = $c->req->params->{destination} || $c->req->path;
    $c->stash->{remember} = $c->req->params->{remember};
    if ( $user && $password ) {
        if ( $c->authenticate( { username => $user,
                                 password => $password } ) ) {
            $c->{session}{expires} = 999999999999 if $c->req->params->{remember};
            $c->res->redirect($c->uri_for($c->flash->{destination}));
        }
        else {
            # login incorrect
            $c->stash->{message} = 'Invalid user and/or password';
            $c->stash->{template} =  'auth/login.tt';
        }
    }
    else {
        # invalid form input
        $c->stash->{message} = 'invalid form input';
        $c->stash->{template} =  'auth/login.tt';
    }
}

sub unauthorized : Private {
    my ($self, $c) = @_;
    $c->stash->{template}= 'auth/unauth.tt';
}

1;

=pod

=head1 NAME

[% app_name %]Controller::Auth

=head2 SUMMARY

This is a controller to provide simple authentication provided by
Catalyst::Helper::AuthDBIC. The database schema provided by the Helper
will also provide autheorization facilities.  As an example, If you
wanted to use this controller to provide application wide requirement
for login you would put something like the following in
MyApp::Controller::Root:

 sub auto : Private {
      my ( $self, $c) = @_;
      if ( !$c->user && $c->req->path !~ /^auth.*?login/) {
          $c->forward('[% app_name %]::Controller::Auth');
          return 0;
      }
      return 1;
 }

=cut

__auth_conf_http__
 __PACKAGE__->config( authentication => {
    'default_realm' => 'users',
    'realms' => {
        'users' => {
            'store' => {
                'role_column' => 'role_text',
                'user_class' => '__MYSCHEMA__::User',
                'class' => 'DBIx::Class',
            },
            'credential' => {
                 'password_type' => 'hashed',
                 'password_field' => 'password',
                 'password_hash_type' => 'SHA-1',
                 'class' => 'HTTP',
                 'type' => 'basic',
             }
        }
    },
});


__auth_conf_password__
 __PACKAGE__->config( authentication => {
    'default_realm' => 'users',
    'realms' => {
        'users' => {
            'store' => {
                'role_column' => 'role_text',
                'user_class' => '__MYSCHEMA__::User',
                'class' => 'DBIx::Class',
            },
           'credential' => {
                'password_type' => 'hashed',
                'password_field' => 'password',
                'password_hash_type' => 'SHA-1',
                'class' => 'Password'
            }
        }
    },
});

__digest__

      __PACKAGE__->add_columns(
        'password' => {
          data_type     => 'CHAR',
          size          => 40,
          encode_column => 1,
          encode_class  => 'Digest',
          encode_args   => {algorithm => 'SHA-1', format => 'hex'},
      });

__requires__
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Authentication::Credential::HTTP';
requires 'DBIx::Class::EncodedColumn';
__login.tt__
<h1> Please login</h1>
[% IF c.stash.message != '' %] <h2 style='color:red'> [% c.stash.message %] </h2
> [% END %]
<form name="login" method='post' action='[% c.uri_for('/auth/login')  %]'>
User: <input name='user' type='text' /><br />
Password: <input name='password' type='password' /><br />
<input type='checkbox' name='remember' >Remember me</input> <br />
<input type='hidden' value='[% c.flash.destination  %]' />
<input type='submit' name='Log In' /> &nbsp; <input type='reset' name='Reset' />
</form>

__logout.tt__
<h1> Logout successful</h1>
<a href='[% c.uri_for('/') %]'>Return to home page</a>
__unauth.tt__
<h1> [%c.user.id %]: You are not allowed to view this page.</h1>
You can <a href="[% c.req.referrer  %]">go back</a> where you came from, or <a h
ref="[% c.uri_for('/auth/logout') %]">logout</a> and try logging in again as a d
ifferent user.  If you think this is an error, please contact <a href="mailto:[%
c.config.admin %]">[% c.config.admin %]</a>

__auth_admin__
[% startperl %]

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use [% app_name %]::Auth::Schema;

my $user = undef;
my $passwd = undef;
my $help = undef;
my $role = undef;
my $email = undef;
my $schema = [% app_name %]::Auth::Schema->connect("dbi:SQLite:$Bin/../db/auth.db");

GetOptions(
    'user=s'    => \$user,
    'pass|password|passwd=s' => \$passwd,
    'role:s' => \$role,
    'help' => \$help,
    'email:s' => \$email,
);

pod2usage(1) if ( $help || !$user || !$passwd );

add_user($schema, $user,$passwd,$role, $email);

sub add_user {
    my ($schema, $user, $passwd, $role, $email ) = @_;
    my %user_insert = (
        username => $user,
        password => $passwd,
        email   => $email,
        role_text => $role,
    );

    my $role_rs = undef;
    if ($role) {
        $role_rs = $schema->resultset('Role')->find_or_create({role => $role});
        $user_insert{role_text} = $role;
    }
    my $user_rs = $schema->resultset('User')->create(\%user_insert);
    if ($role_rs) {
        my $user_role_rs = $schema->resultset('UserRole')
            ->create({ user => $user_rs,
                       roleid => $role_rs});
    }
}

=head1 NAME

[% appprefix %]_auth_admin.pl - Sets the username and password for the generated authentication database

=head1 SYNOPSIS

[% appprefix %]_auth_admin.pl -user username -passwd password [-role role]

 Options:
   -user      username
   -passwd    password
   -role      role (optional)
   -email     email address (optional)
   -help      display this help and exit

=cut
