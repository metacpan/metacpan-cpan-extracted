# -*- perl -*-
#
#   $Id: Roaming.pm,v 1.4 1999/04/23 15:29:45 joe Exp $
#
#
#   Apache::Roaming - A mod_perl handler for Roaming Profiles
#
#
#   Based on mod_roaming by
#	Vincent Partington <vincentp@xs4all.nl>
#	See http://www.xs4all.nl/~vincentp/software/mod_roaming.html
#
#
#   Copyright (C) 1999    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;


use Apache ();
use Apache::File ();
use File::Spec ();
use File::Path ();
use File::Basename ();
use Symbol ();
use URI::Escape ();


package Apache::Roaming;

$Apache::Roaming::VERSION = '0.1003';


=pod

=head1 NAME

    Apache::Roaming - A mod_perl handler for Roaming Profiles


=head1 SYNOPSIS

      # Configuration in httpd.conf or srm.conf
      # Assuming DocumentRoot /home/httpd/html

      PerlModule Apache::Roaming
      <Location /roaming>
        PerlHandler Apache::Roaming->handler
        PerlTypeHandler Apache::Roaming->handler_type
        AuthType Basic
        AuthName "Roaming User"
        AuthUserFile /home/httpd/.htusers
        require valid-user
        PerlSetVar BaseDir /home/httpd/html/roaming
      </Location>

  In theory any AuthType and require statement should be possible
  as long as the $r->connection()->user() method returns something
  non trivial.


=head1 DESCRIPTION

With Apache::Roaming you can use your Apache webserver as a Netscape
Roaming Access server. This allows you to store you Netscape
Communicator 4.5 preferences, bookmarks, address books, cookies etc.
on the server so that you can use (and update) the same settings from
any Netscape Communicator 4.5 that can access the server.

The source is based on mod_roaming by Vincent Partington
<vincentp@xs4all.nl>, see

    http://www.xs4all.nl/~vincentp/software/mod_roaming.html

Vincent in turn was inspired by a Perl script from Frederik
Vermeulen <Frederik.Vermeulen@imec.be>, see

    http://www.esat.kuleuven.ac.be/~vermeule/roam/put

Compared to Apache::Roaming, this script doesn't need mod_perl. On
the other hand it doesn't support the MOVE method, thus you need
to set the li.prefs.http.useSimplePut attribute in your Netscape
preferences. Due to the missing MOVE method, it may be even slower
than Apache::Roaming and perhaps a little bit less stable.


The modules features are:

=over 8

=item *

GET, HEAD, PUT, DELETE and MOVE are handled by the module. In particular
the Non-standard MOVE method is implemented, although Apache doesn't know
it by default. Thus you need no set the li.prefs.http.useSimplePut
attribute to true.

=item *

Directories are created automatically.

=item *

The module is subclassable, so that you can create profiles on the fly
or parse and modify the user preferences. See L<Apache::Roaming::LiPrefs(3)>
for an example subclass.

=back


=head1 INSTALLATION

First of all you need an Apache Web server with mod_perl support. The
TypeHandler must be enabled, so you need to set PERL_TYPE=1 when
running Makefile.PL. For example, I use the following statements to
build Apache:

    cd mod_perl-1.16
    perl Makefile.PL APACHE_SRC=../apache_1.3.X/src DO_HTTPD=1 \
        USE_APACI=1 PERL_METHOD_HANDLERS=1 PERL_AUTHEN=1 \
        PERL_CLEANUP=1 PREP_HTTPD=1 PERL_STACKED_HANDLERS=1 \
	PERL_FILE_API=1
    cd ../apache-1.3.3
    ./configure --activate-module=src/modules/perl/libperl.a
    make
    make install
    cd ../mod_perl-1.16
    make
    make install

See the mod_perl docs for details.

Once the web server is installed, you need to create a directory for
roaming profiles, I assume /home/httpd/html/roaming in what follows,
with /home/httpd/html being the servers root directory. Be sure, that
this directory is writable for the web server, better for the web
server only. For example I do

    mkdir /home/httpd/html/roaming
    chown nobody /home/httpd/html/roaming
    chgrp nobody /home/httpd/html/roaming
    chmod 700 /home/httpd/html/roaming

with I<nobody> being the web server user.

Access to the roaming directory must be restricted and enabled via
password only. Finally tell the web server, that Apache::Roaming is
handling requests to this directory by adding something like this
to your srm.conf or access.conf:

    PerlModule Apache::Roaming
    <Location /roaming>
      PerlHandler Apache::Roaming->handler
      PerlTypeHandler Apache::Roaming->handler_type
      AuthType Basic
      AuthName "Roaming User"
      AuthUserFile /home/httpd/.htusers
      require valid-user
      PerlSetVar BaseDir /home/httpd/html/roaming
    </Location>

That's it!


=head1 NETSCAPE COMMUNICATOR CONFIGURATION

Assuming your document root directory is /home/httpd/html and you
want your profile files being located under http://your.host/roaming,
do the following:

=over 8

=item 1.)

Create a directory /home/httpd/html/roaming. Make it writable by the
web server and noone else, for example by doing a

    mkdir /home/httpd/html/roaming
    chown nobody /home/httpd/html/roaming
	# Insert your web servers UID here
    chmod 700 /home/httpd/html/roaming

=item 2.)

Start your communicator and open Preferences/Roaming User. Click the
"Enable Roaming Access for this profile" checkbox.

=item 3.)

Open Preferences/Roaming User/Server Information. Click the "HTTP Server"
checkbox and enter the Base URL "http://your.host/roaming/$USERID".

=back

That's all. Now hit the Ok button. A directory with the name of your
user id should automatically be generated under /roaming and files
should be stored there.


=head1 METHOD INTERFACE

As already said, the Apache::Roaming module is subclassable. You can
well use it by itself, but IMO the most important possibility is
overwriting the GET method for complete control over the users
settings.


=head2 handler

  $result = Apache::Roaming->handler($r);

(Class Method) The I<handler> method is called by the Apache server
for any request. It receives an Apache request B<$r>. The methods
main task is creating an instance of Apache::Roaming by calling the
I<new> method and then passing control to the I<Authenticate>,
I<CheckDir> and I<GET>, I<PUT>, I<DELETE> or I<MOVE>, respectively,
methods.

=cut

sub handler ($$) {
    my($class, $r) = @_;

    my $file = File::Spec->canonpath(URI::Escape::uri_unescape($r->filename()));

    if ($file=~/IMAP$/) {
        my $addon=$r->the_request();
        $addon=~s/IMAP\s(.*)\s.*$/$1/;
        $file="$file%20$addon";
    }

    if (my $pi = $r->path_info()) {
	my @dirs = grep { length $_ } split(/\//, $pi);
	my $f = pop @dirs;
	$file = File::Spec->catfile($file, @dirs, $f) if $f;
    }

    my $self = eval {
	$class->new('file'    => $file,
		    'basedir' => $r->dir_config('BaseDir'),
		    'user'    => $r->connection()->user(),
		    'method'  => $r->method(),
		    'status'  => Apache::Constants::SERVER_ERROR(),
		    'request' => $r)
    };
    if ($@) {
	$r->log_reason($@, $file);
	return Apache::Constants::SERVER_ERROR();
    }

    eval {
	$self->Authenticate();
	$self->CheckDir();
	if ($self->{'method'} !~ /(?:GET|PUT|DELETE|MOVE)/) {
	    $self->{'status'} = Apache::Constants::HTTP_METHOD_NOT_ALLOWED();
	    die "Unknown method: $self->{'method'}";
	}

	my $method = $self->{'method'};
	my $f = File::Basename::basename($file);
	$f =~ s/\W//g;
	my $m = "$method\_$f";
	UNIVERSAL::can($self, $m) ? $self->$m() : $self->$method();
    };

    if ($@) {
	$r->log_reason($@, $file);
	return Apache::Constants::SERVER_ERROR();
    }
    return Apache::Constants::OK();
}


=pod

=head2 handler_type

  $status = Apache::Roaming->handler_type($r)

(Class Method) This method is required only, because the Apache server
would refuse other methods than GET otherwise. It checks whether the
requested method is GET, PUT, HEAD, DELETE or MOVE, in which case it
returns the value OK. Otherwise the value DECLINED is returned.

=cut


sub handler_type ($$) {
    my($class, $r) = @_;

    if ($r->method() =~ /(?:GET|PUT|DELETE|MOVE)/) {
	$r->handler('perl-script');
	return Apache::Constants::OK();
    }
    return Apache::Constants::DECLINED();
}


=pod

=head2 new

  $ar_req = Apache::Roaming->new(%attr);

(Class Method) This is the modules constructor, called by the I<handler>
method. Instances of Apache::Request have the following attributes:

=over 8

=item basedir

The roaming servers base directory, as an absolute path. You set this
using a PerlSetVar instruction, see L<INSTALLATION> above for an
example.

=item file

This is the path of the file being created (PUT), read (GET), deleted
(DELETE) or moved (MOVE). It's an absolute path.

=item method

The requested method, one of HEAD, GET, PUT, MOVE or DELETE.

=item request

This is the Apache request object.

=item status

If a method dies, it should set this value to a return code like
SERVER_ERROR (default), FORBIDDEN, METHOD_NOT_ALLOWED, or something
similar from Apache::Constants. See L<Apache::Constants(3)>.
The I<handler> method will catch Perl exceptions for you and generate
an error page.

=item user

Name the user authenticated as.

=back

=cut

sub new {
    my $proto = shift;
    my $self = { @_ };
    bless($self, (ref($proto) || $proto));
    $self;
}


=pod

=head2 Authenticate

  $ar_req->Authenticate();

(Instance Method) This method is checking whether the user has authorized
himself. The current implementation is checking only whether user name
is given via $r->connection()->user(), in other words you can use simple
basic authentication or something similar.

The method should throw an exception in case of problems.

=cut

sub Authenticate {
    my $self = shift;
    my $r = $self->{'request'};

    # Check whether the user is authenticated.
    my $user = $self->{'user'};
    if (!$user) {
	$self->{'status'} = Apache::Constants::FORBIDDEN();
	die "Not authenticated as any user";
    }

    $user;
}


=pod

=head2 CheckDir

  $ar_req->CheckDir();

(Instance method) Once the user is authenticated, this method should
determine whether the user is permitted to access the requested URI.
The current implementation verifies whether the user is accessing
a file in the directory $basedir/$user. If not, a Perl exception is
thrown with $ar_req->{'status'} set to FORBIDDEN.

=cut

sub CheckDir {
    my $self = shift;
    my $file = $self->{'file'};
    my $basedir = $self->{'basedir'};
    my $dir = $file;
    my $user = $self->{'user'};
    my $prevdir;

    while (($dir = File::Basename::dirname($dir))
	   and  (!$prevdir  or  ($dir ne $prevdir))) {
	if ($basedir eq $dir) {
	    my $userdir;
	    $userdir = File::Basename::basename($prevdir) if $prevdir;
	    if (!$prevdir  or  $userdir ne $user) {
		$self->{'status'} = Apache::Constants::FORBIDDEN();
		die "Access to $file not permitted for user $user";
	    }
	    return;
	}
	$prevdir = $dir;
    }
    $self->{'status'} = Apache::Constants::FORBIDDEN();
    die "Access to $file not permitted for user $user";
}


=pod

=head2 GET, PUT, MOVE, DELETE

  $ar_req->GET();
  $ar_req->PUT();
  $ar_req->MOVE();
  $ar_req->DELETE();

(Instance Methods) These methods are called finally for performing the
real action. With the exception of GET, they call I<Success> finally
for reporting Ok.

Alternative method names are possible, depending on the name of the
requested file. For example, if you request the file I<liprefs> via
GET, then it is checked whether your sublass has a method I<GET_liprefs>.
If so, this method is called rather than the default method I<GET>.
The alternative method names are obtained by removing all non-alpha-
numeric characters from the files base name. That is, if you request
a file I<pab.na2>, then the alternative name is I<pabna2>. Note, these
method names are case sensitive!

=cut

sub GET {
    my $self = shift;
    my $file = $self->{'file'};
    my $r = $self->{'request'};

    if (! -f $file) {
	$self->{'status'} = Apache::Constants::NOT_FOUND();
	die "No such file: $file";
    }
#    return Apache::DECLINED();
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime) = stat _;
    my $fh = Symbol::gensym();
    if (!open($fh, "<$file")  ||  !binmode($fh)) {
  	die "Failed to open file $file: $!";
    }
    $r->set_last_modified($mtime);
    $r->content_type('text/plain');
    $r->no_cache(1);
    $r->header_out('content_length', $size);
    $r->send_http_header();
    if (!$r->header_only()) {
  	$r->send_fd($fh) or die $!;
    }
    return Apache::OK();
}


sub PUT {
    my $self = shift;
    my $file = $self->{'file'};
    my $r = $self->{'request'};

    $self->MkDir($file);

    my $fh = Symbol::gensym();

    open($fh, ">$file")
	or die "Failed to open $file: $!";
    binmode($fh)
	or die "Failed to request binmode for $file: $!";

    my $size = $r->header_in('Content-length');
    $r->hard_timeout("Apache->read");
    while ($size > 0) {
	my $buf = '';
	my $rdn = $r->read_client_block($buf, ($size < 1024) ? $size : 1024);
	if (!defined($rdn)) {
	    die "Error while reading $file from client: $!";
	}
	print $fh ($buf)
	    or die "Error while writing to client: $!";
	$size -= $rdn;
    }
    $r->kill_timeout();
    close($fh);
    $self->Success(201, 'URI created');
}


sub DELETE {
    my $self = shift;
    my $file = $self->{'file'};
    if (-f $file  and  !unlink $file) {
	$self->{'status'} = Apache::Constants::NOT_FOUND();
	die "Error while unlinking $file: $!";
    }
    $self->Success(201, 'URI deleted');
}


sub MOVE {
    my $self = shift;
    my $file = $self->{'file'};
    my $dir = File::Basename::dirname($file);
    my $r = $self->{'request'};
    my $uri = $r->uri();
    my $new_uri = $r->header_in('New-uri');

    unless ($new_uri) {
	$self->{'status'} = Apache::Constants::BAD_REQUEST();
	die "Missing header: New-uri";
    }
    if ($uri !~ /(.*)\//) {
	$self->{'status'} = Apache::Constants::BAD_REQUEST();
	die "URI $uri doesn't contain a '/'";
    }
    $uri = $1;
    if ($new_uri !~ /(.*)\/([^\/]+)/) {
	$self->{'status'} = Apache::Constants::BAD_REQUEST();
	die "New URI $new_uri doesn't contain a '/'";
    }
    $new_uri = $1;
    my $new_file = File::Spec->catfile($dir, $2);
    if ($uri ne $new_uri) {
	$self->{'status'} = Apache::Constants::FORBIDDEN();
	die "New URI $new_uri refers to another directory than $uri";
    }

    rename $file, $new_file
	or die "Error while renaming $file to $new_file: $!";
    $self->Success(201, 'URI moved');
}


=pod

=head2 MkDir

  $ar_req->MkDir($file);

(Instance Method) Helper function of I<PUT>, creates the directory
where $file is located, if it doesn't yet exist. Works recursively,
if more than one directory must be created.

=cut

sub MkDir {
    my $self = shift;  my $file = shift;
    my $dir = File::Basename::dirname($file);
    return if -d $dir;
    $self->MkDir($dir);
    mkdir($dir, 0700)  or  die "Cannot create directory $dir: $!";
}


=pod

=head2 Success

  $ar_req->Success($status, $text);

(Instance Method) Creates an HTML document with status $status,
containing $text as success messages.

=cut

sub Success {
    my($self, $code, $text) = @_;
    my $r = $self->{'request'};
    $r->status($code);
    $r->content_type("text/html");
    $r->send_http_header;
	print <<EOM;
<HTML><HEAD><TITLE>Success</TITLE></HEAD>
<BODY>$text</BODY></HTML;
EOM
}


1;

__END__

=pod

=head1 AUTHOR AND COPYRIGHT

This module is

    Copyright (C) 1998    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Phone: +49 7123 14887
                          Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<Apache(3)>, L<mod_perl(3)>

An example subclass is Apache::Roaming::LiPrefs.
See L<Apache::Roaming::LiPrefs(3)>.

A C module for Apache is mod_roaming, by Vincent Partington
<vincentp@xs4all.nl>, see

    http://www.xs4all.nl/~vincentp/software/mod_roaming.html


Frederic Vermeulen <Frederik.Vermeulen@imec.be> has written a CGI
binary for roaming profiles. It's missing a MOVE method, though.

    http://www.esat.kuleuven.ac.be/~vermeule/roam/put

=cut
