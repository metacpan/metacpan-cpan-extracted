package CGI::Builder::SessionManager;

require 5.005;
use strict;
use vars qw($VERSION);
$VERSION = '1.00';

use Apache::SessionManager;

use Object::props (
	{
		name => 'sm',
		default => sub { Apache::SessionManager::get_session(Apache->request) if $ENV{MOD_PERL} }
	}
);

sub sm_destroy {
	Apache::SessionManager::destroy_session(Apache->request) if $ENV{MOD_PERL};
}

1;

__END__

=pod

=head1 NAME

CGI::Builder::SessionManager - CGI::Builder / Apache::SessionManager integration

=head1 SYNOPSIS

   package WebApp;
   use CGI::Builder qw/ CGI::Builder::SessionManager /;

   sub PH_session {
      my $cbf = shift;
      $cbf->page_content = 'Session test page!';
      $cbf->sm->{'foo'} = 'baz';
      $cbf->page_content .= $cbf->sm->{'foo'};
   }

=head1 DESCRIPTION

CGI::Builder::SessionManager is a L<CGI::Builder|CGI::Builder> extension that
integrates L<Apache::SessionManager|Apache::SessionManager> session management
into L<CGI::Builder|CGI::Builder> framework (CBF).

L<Apache::SessionManager|Apache::SessionManager> is a mod_perl (1.0 and 2.0)
module that helps session management of a web application. This module is a
wrapper around L<Apache::Session|Apache::Session> persistence framework for
session data. It creates a session object and makes it available to all other
handlers transparenlty. 
See 'perldoc Apache::SessionManager' for module documentation and use.

=head1 INSTALLATION

In order to install and use this package you will need Perl version 5.005 or
better.

Prerequisites:

=over 4

=item * CGI::Builder >= 1.2

=item * Apache::SessionManager >= 1.01

=back 

Installation as usual:

   % perl Makefile.PL
   % make
   % make test
   % su
     Password: *******
   % make install

=head1 PROPERTIES 

This module adds C<sm> property to the standard CBF properties. 

It's possible to set a value in current session with:

   $cbf->sm->{'foo'} = 'baz';

and it's possible to read value session with:

   print $cbf->sm->{'foo'};   

=head1 METHODS

=head2 sm_destroy

Destroy the current session object.

   $cbf->sm_destroy;

=head1 EXAMPLES

This is a simple CGI::Builder application, (save it, for example, as
F</some/path/cgi-builder/WebApp.pm>):

   package WebApp;    # your class name
   use CGI::Builder qw/ CGI::Builder::SessionManager /;
   use Data::Dumper;
  
   sub PH_AUTOLOAD {                           # always called for all requested pages
      my $cbf = shift;
      $cbf->page_content = "Default content";  # defines the page content
   }

   sub PH_session {
      my $cbf = shift;
      $cbf->page_content = "Session test!<BR>\n";
      $cbf->sm->{"$$-" . rand()} = rand;
      $cbf->page_content .= '<PRE>' . Dumper($s->cbf) . '</PRE>';
	}

   sub PH_delete_session {
      my $cbf = shift;
      $cbf->page_content = "Session test! (deletion)";
      $cbf->sm_destroy;
   }

and the correspondent configuration lines in F<httpd.conf>:

   <IfModule mod_perl.c>

      PerlModule Apache::SessionManager
      PerlTransHandler Apache::SessionManager

      Alias /cgi-builder "/usr/local/apache/cgi-builder"
      <Location /cgi-builder>
         SetHandler perl-script
         PerlHandler Apache::Registry
         PerlSendHeader On
         PerlSetupEnv   On
         Options +ExecCGI

         PerlSetVar SessionManagerTracking On
         PerlSetVar SessionManagerExpire 1800
         PerlSetVar SessionManagerInactivity 900
         PerlSetVar SessionManagerName CBFSESSIONID
         PerlSetVar SessionManagerStore File
         PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_session_data/cbf"
         PerlSetVar SessionManagerDebug 1
      </Location>   

   </IfModule>

In order to test this simple application you must implement the Instance Script
that is what is actually called by your web server.

It is a very small, simple file which simply creates an instance of your
application and calls an inherited method, C<process()>. Following is the
entirely of F</some/path/cgi-builder/webapp.cgi>:

   #!/usr/local/bin/perl -w
   use WebApp;
   my $webapp = new WebApp;
   $webapp->process();

Restart the httpd server and launch I<http://localhost/cgi-builder/webapp.cgi> .

=head1 BUGS 

Please submit bugs to CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Builder-SessionManager or by
email at bug-cgi-builder-sessionmanager@rt.cpan.org

Patches are welcome and I'll update the module if any problems will be found.

=head1 VERSION

Version 1.00

=head1 SEE ALSO

L<Apache::SessionManager|Apache::SessionManager>, L<CGI::Builder|CGI::Builder>

=head1 AUTHOR

Enrico Sorcinelli, E<lt>enrico at sorcinelli.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Enrico Sorcinelli

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.2 or, at your option,
any later version of Perl 5 you may have available.

=cut
