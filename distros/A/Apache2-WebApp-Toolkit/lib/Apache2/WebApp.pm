#----------------------------------------------------------------------------+
#
#  Apache2::WebApp - Simplified web application framework
#
#  DESCRIPTION
#  mod_perl request handler that provides URI to class/method dispatching.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp;

use strict;
use warnings;
no  warnings qw( uninitialized );
use base 'Apache2::WebApp::Base';
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Connection;
use Apache2::Upload;
use Apache2::Const qw( :common :http );
use Apache2::Log;

our $VERSION = 0.391;

use Apache2::WebApp::AppConfig;
use Apache2::WebApp::Plugin;
use Apache2::WebApp::Stash;
use Apache2::WebApp::Template;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# handler(\%request_rec)
#
# mod_perl handler - Instanciate Apache2::WebApp::Toolkit objects.

sub handler : method {
    my ($self, $r) = @_;

    my $config = Apache2::WebApp::AppConfig->new;

    $self->{CONFIG} = $config->parse( $ENV{'WEBAPP_CONF'} );

    $self->{REQUEST} = Apache2::Request->new($r,
        DISABLE_UPLOADS => $self->{CONFIG}->{apache_disable_uploads},
        POST_MAX        => $self->{CONFIG}->{apache_post_max},
        TEMP_DIR        => $self->{CONFIG}->{apache_temp_dir}
      );

    $self->{PLUGIN}   = Apache2::WebApp::Plugin->new;
    $self->{STASH}    = Apache2::WebApp::Stash->new;
    $self->{TEMPLATE} = Apache2::WebApp::Template->new( $self->{CONFIG} ); 

    $self->dispatch;
}

#----------------------------------------------------------------------------+
# config()
#
# Return a reference to the new Apache2::WebApp::AppConfig object.

sub config {
    my $self = shift;
    return $self->{CONFIG} if (defined $self->{CONFIG});
}

#----------------------------------------------------------------------------+
# request()
#
# Return a reference to the new Apache2::Request object.

sub request {
    my $self = shift;
    return $self->{REQUEST} if (defined $self->{REQUEST});
}

#----------------------------------------------------------------------------+
# template()
#
# Return a reference to the new Apache2::WebApp::Template object.

sub template {
    my $self = shift;
    return $self->{TEMPLATE} if (defined $self->{TEMPLATE});
}

#----------------------------------------------------------------------------+
# plugin($name)
#
# Return a reference to the new Apache2::WebApp::Plugin object.

sub plugin {
    my ($self, $name) = @_;
    $self->{PLUGIN}->{ uc($name) } = $self->{PLUGIN}->load($name);
    return $self->{PLUGIN}->{ uc($name) };
}

#----------------------------------------------------------------------------+
# stash($name, \%object)
#
# Return a reference to the new Apache2::WebApp::Stash object.

sub stash {
    my ($self, $name, $obj) = @_;
    if ($obj) {
        $self->{STASH}->{ uc($name) } = $self->{STASH}->set($name, $obj);
    }
    else {
        $self->{STASH}->{ uc($name) } = $self->{STASH}->get($name);
    }
    return
        $self->{STASH}->{ uc($name) };
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# dispatch()
#
# Translate the $r->uri to class/method and execute.

sub dispatch {
    my $self = shift;

    my $uri
      = substr($self->request->uri, length($self->request->location) + 1);

    unless ($uri =~ /\A (\w+\/)*\w+ /xs) {
        $self->error("Malformed URI request");
        return HTTP_BAD_REQUEST;
    }

    $uri =~ s/\/+$//g;

    my ($module, $method);

    unless ( $module = $self->module_exists($uri) ) {
        $method = $uri;
        $method =~ s/(?:.*?)\/(\w+?)(?:\/|)\z/$1/g;
        $uri    =~ s/(.*?)\/(?:\w+?)(?:\/|)\z/$1/g;
    }

    unless ( $module = $self->module_exists($uri) ) {
        $self->error("Failed to map URI ($uri) request");
        return DECLINED;
    }

    $module =~ s/\//::/g;
    $module =~ s/\.pm$//;

    unless ( $module->can('isa') ) {
        eval "require $module";
        $self->error("Failed to load class '$module': $@") if $@;
        return DECLINED;   
    }

    my $class = ( $module->can('_new') )
        ? $module->_new
        : bless ({}, $module)
      ;

    my $c = ( $module->can('_global') )
        ? $module->_global($self)
        : $self
      ;

    if ($method) {
        if ($method =~ /^\_/) {
            $self->error("The method ($method) contains a leading underscore");
            return HTTP_BAD_REQUEST;
        }

        if ( $module->can($method) ) {
            $class->$method($c);
        }
        else {
            $self->error("The method ($method) doesn't exist in ($module)");
            return DECLINED;
        }
    }
    else {
        if ( $module->can('_default') ) {
            $class->_default($c);
        }
        else {
            $self->error("The class ($module) is missing a _default() method");
            return DECLINED;
        }
    }

    return OK;
}

#----------------------------------------------------------------------------+
# module_exists($file)
#
# Search %INC for the selected module; return filename if exists.

sub module_exists {
    my ($self, $file) = @_;
    return unless $file;

    my $project = $self->config->{project_title};
    foreach (sort keys %INC) {
        return $_ if (/\A $project\/$file\.pm \z/xi);
    }
    return;
}

#----------------------------------------------------------------------------+
# error(\%controller, $mesg)
#
# Quietly, output errors/exceptions to error_log

sub error {
    my ($c, $mesg) = @_;
    $c->request->log_error($mesg);
}

1;

__END__

=head1 NAME

Apache2::WebApp - Simplified web application framework - EOL (for reference only)

=head1 SYNOPSIS

This module should not be used directly; it is intended to be run as a I<mod_perl> handler 
that can be configured as such by adding the following directives to your C<httpd.conf>

  PerlRequire /path/to/project/bin/startup.pl

  <Perl>
      use Apache2::WebApp;
      $Apache2::WebApp = Apache2::WebApp->new;
  </Perl>

  <Location /app>
      SetHandler perl-script
      PerlHandler $Apache2::WebApp->handler
      SetEnv WEBAPP_CONF /path/to/project/conf/webapp.conf
  </Location>

=head1 DESCRIPTION

The WebApp::Toolkit is a I<mod_perl> web application framework for the Perl programming 
language.  It defines a set of methods, processes, and conventions that help provide a 
consistent application environment.

The way this package works is actually pretty simple.  For every HTTP request, a I<mod_perl>
handler is executed that instanciates a new C<WebApp> controller object.  This object is 
then passed to a C<dispatch()> method that parses the URI request and maps the result to
a public class/method while passing the C<%controller> as the first argument.

Example:

  # URI                                    # Class                          # Method
  /app/project           --> maps to -->   Project
  /app/project/foo       --> maps to -->   Project::Foo        --> or -->   Project->foo()
  /app/project/foo/bar   --> maps to -->   Project::Foo::Bar   --> or -->   Project::Foo->bar()

If the target method does not exist, the C<distpatch()> will execute the class C<_global()>
and C<_default()> methods.  Below is an example of what a class (.pm) would look like.

Example:

  package Project::Foo;

  use strict;
  use warnings;

  # construct as an object (optional)
  sub _new {
      my $class = shift;
      return bless({
          attr1 => 'biz',
          attr2 => 'baz',
      }, $class);
  }

  # this method is executed for every request (optional)
  sub _global {
      my ($self, $c) = @_;

      $c->stash('baz','qux');

      return $c;
  }

  # if the target method doesn't exist, this will be executed
  sub _default {
      my ($self, $c) = @_;

      $self->_print_result($c, 'bar');
  }

  # _ always denotes a private method (not URI accessible)
  sub _print_result {
      my ($self, $c, $output) = @_;

      $c->request->content_type('text/html');

      print $output;
      exit;
  }

  # /app/project/foo/bar --> maps to Project::Foo->bar()
  sub bar {
      my ($self, $c) = @_;

      $self->_print_result( $c, $c->stash('baz') );     # output 'qux'
  }

  1;

=head1 PREREQUISITES

  Apache2::Request
  AppConfig
  Template::Toolkit
  Getopt::Long
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Toolkit-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 GETTING STARTED

=head2 HELPER SCRIPTS

=head3 Create a new project

  $ webapp-project --project_title Project --apache_doc_root /var/www

    or

  $ webapp-project --config /path/to/conf/webapp.conf

=head3 Export project settings to the Unix shell

  $ source /path/to/project/.projrc

=head3 Create a new class

  $ webapp-class --name ClassName

=head3 Add a pre-packaged I<Extra> to an existing project

  $ webapp-extra --install PackageName 

=head3 Start your application

  $ webapp-kickstart

=head3 Standard output

  /var/www/project/app                              <-- A
  /var/www/project/app/Project
  /var/www/project/app/Project/Base.pm              <-- B
  /var/www/project/app/Project/Example.pm           <-- C
  /var/www/project/bin
  /var/www/project/bin/startup.pl                   <-- D
  /var/www/project/conf
  /var/www/project/conf/htpasswd                    <-- E
  /var/www/project/conf/httpd.conf                  <-- F
  /var/www/project/conf/webapp.conf                 <-- G
  /var/www/project/htdocs                           <-- H
  /var/www/project/templates/example.tt             <-- I
  /var/www/project/templates/error.tt               <-- J
  /var/www/project/logs                             <-- K
  /var/www/project/logs/access_log
  /var/www/project/logs/errror_log
  /var/www/project/tmp                              <-- L
  /var/www/project/tmp/cache
  /var/www/project/tmp/cache/templates
  /var/www/project/tmp/uploads

A) Application directory.  All classes I<(*.pm)> within this directory are precompiled
into memory when Apache starts/restarts.

B) Base class that can be C<included> from other classes.  Contains C<_global()>
and C<_error()> methods that can be inherited using:

Example:

  use base 'Project::Base';

C) Basic class.

D) This is executed when the Apache server starts.  It's used to reset Perl module search
paths in @INC, preload web application classes, precompile constants, etc.

Example:

  #!/usr/bin/env perl

  $ENV{MOD_PERL} or die "Not running under mod_perl";

  use lib '/var/www/project/app';

  ..

  # Modules added here will be URI accessible 
  __DATA__ 
  Project::Foo
  Project::Foo::Bar

E) Password file used for restricting access to a specified path (see C<httpd.conf>).

The login information below is currently set-up by default.

  User Name       admin
  Password        password

You can change the login password using the C<htpasswd> command-line script.

  $ htpasswd /var/www/project/conf/htpasswd admin

F) Apache server I<Virtual Host> configuration.

G) Application configuration.  This file contains your project settings.  Due to
security reasons, this file should always remain outside the I</htdocs> directory path.

Example:

  [project]
  title              = Project                                 # must not contain spaces or special characters
  author             = Your Name Here
  email              = email@domain.com
  version            = 0.01

  [apache]
  doc_root           = /var/www/project                        # path to project directory
  domain             = www.domain.com                          # valid domain name
  disable_uploads    = 0                                       # allow file uploads
  post_max           = 5242880                                 # post max in bytes (example 5MB)
  temp_dir           = /var/www/project/tmp/uploads

  [template]
  cache_size         = 100                                     # total files to store in cache
  compile_dir        = /var/www/project/tmp/cache/templates    # path to template cache
  include_path       = /var/www/project/templates              # path to template directory
  stat_ttl           = 60                                      # template to HTML build time (in seconds)
  encoding           = utf8                                    # template output encoding

H) Website sources.  This includes HTML, CSS, Javascript, and images.  When setting
up FTP access - restrict access to this directory only.

I) Basic template.

J) Application error templates.

K) Apache log directory that contains both access and error logs.  Due to security
reasons, this directory should always remain outside the I</htdocs> directory path.

L) Temporary shared space for file processing.

=head1 CAVEATS

Since your classes get compiled at Apache start-up the server must be restarted
when any code changes take place.  You can do this easily using the C<webapp-kickstart>
script provided with this package.

=head1 WARNING

In Perl, variables do not need to be declared and are by default globally scoped.
The issue with I<mod_perl> is that global variables can persist between requests.  To
avoid this problem, you should always have the following line in your code:

  use strict;

=head1 SEE ALSO

perl(1), mod_perl(2), Apache(2), L<Apache2::Request>, L<Apache2::RequestRec>,
L<Apache2::RequestUtil>, L<Apache2::Connection>, L<Apache2::Upload>, L<Apache2::Const>,
L<Apache2::Log>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
