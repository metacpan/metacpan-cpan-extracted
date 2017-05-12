# -----------------------------------------------------------------------------
#
#  CGI::Application::Plugin::Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón Barbero
#
#  Plugin for use Nes in CGI::Application
#  Requires Nes 1.04 or higher
#
# -----------------------------------------------------------------------------

package CGI::Application::Plugin::Nes;

our $VERSION = '0.01';

use warnings;
use strict;

use Nes;
use base 'CGI::Application';

$ENV{'CGI_APP_RETURN_ONLY'} = 1;
$ENV{'CGI_APP_NES_BY_CGI'}  = 0;
$ENV{'CGI_APP_NES_DIR'}     = '';
$ENV{'CGI_APP_NES_DIR_CGI'} = '';

$CGI::Application::Plugin::Nes::top_script   = $ENV{'SCRIPT_FILENAME'} || ''; 
$CGI::Application::Plugin::Nes::top_dir      = $CGI::Application::Plugin::Nes::top_script;
$CGI::Application::Plugin::Nes::top_dir      =~ s/\/[^\/]*\.cgi|pl$//;
$CGI::Application::Plugin::Nes::top_template = $CGI::Application::Plugin::Nes::top_script;
$CGI::Application::Plugin::Nes::top_template =~ s/\.cgi|pl$/\.nhtml/;

sub cgiapp_init {
  my $self = shift;
  my @args = (@_);

  $self->SUPER::cgiapp_init(@args);
  
  $self->{'nes'} = Nes::Singleton->new({
                      template    => $CGI::Application::Plugin::Nes::top_template,
                      nes_top_dir => $ENV{'CGI_APP_NES_DIR'},
                      nes_dir     => $ENV{'CGI_APP_NES_DIR_CGI'}
                   });
}

sub cgiapp_get_query {
  my $self = shift;

  my $q;
  
  if ( $ENV{'CGI_APP_NES_BY_CGI'} ) {

    $q = $self->{'nes'}->{'query'}->by_CGI;

  } else {

    $q = $self->{'nes'}->{'query'};

  }
  
  return $q;
    
}


=head1 NAME

CGI::Application::Plugin::Nes - Nes templates in CGI::Application

=head1 SYNOPSIS

  use base 'CGI::Application::Plugin::Nes';

  # compatibility with CGI.pm (slightly slower)
  # $ENV{CGI_APP_NES_BY_CGI} = 1;

  # require if exec by .cgi
  # $ENV{CGI_APP_NES_DIR} = '/full/path/to/cgi-bin/nes';

=head1 DESCRIPTION

Plugin for use L<Nes> templates in L<CGI::Application>. You can use any Nes 
object or plugin in CGI::Application.

Include Nes Templates, PHP, PYTHON and others live sample: 

  L<http://nes.sourceforge.net/hello_nes/tests-cgiapp/index.cgi?action=Inludes>

Include Nes Objects live sample: 

  L<http://nes.sourceforge.net/hello_nes/tests-cgiapp/index.cgi?action=Objects>

Nes Tags and Debug Info live sample: 

  L<http://nes.sourceforge.net/hello_nes/tests-cgiapp/index.cgi?action=others>

=head1 INPLEMENTATION

In your .pm file instead of:

  use base 'CGI::Application'; 

used:

  use base 'CGI::Application::Plugin::Nes';

In addition to your myapp.cgi file, creates a nhtml file with the same name
for the Top Nes template:

myapp.cgi:

  use MyApp;
  my $app = MyApp->new();
  $app->run();
  1; # in Nes cgi should return 1 as the pm files.

myapp.nhtml:

  {: NES 1.0 ('myapp.cgi') :}
  <html>
    <head>
    ...

If you run your application by the CGI, you need to put the following
variable the full path to Nes cgi-bin directory in your .pm or .cgi file:

  $ENV{CGI_APP_NES_DIR} = '/full/path/to/cgi-bin/nes';

This is necessary for:

  http://example.com/myapp.cgi

It is not necessary for:

  http://example.com/myapp.nhtml

For compatibility with CGI.pm:

  $ENV{CGI_APP_NES_BY_CGI} = 1;

It's a bit slower than letting to Nes handle the query. 
Not support for upload.

=head1 Compare

See L<http://cgi-app.org/index.cgi?LoginLogoutExampleApp>

Code in CGI::Application::Plugin::Nes for a similar result:

  package MinimalAppNes;
  use base 'CGI::Application::Plugin::Nes';
  use strict;

  # require if exec by .cgi
  # $ENV{CGI_APP_NES_DIR} = '/full/path/to/cgi-bin/nes';

  sub setup {
      my $self = shift;
      $self->start_mode('index');
      $self->mode_param('action');
      $self->run_modes(
          'index'  => 'index',
          'logout' => 'logout',
      );
  }

  sub index {
      my $self = shift;
      # only three lines of Perl script is necessary for generate form login
      my %nes_tags;
      $nes_tags{'action'} = 'login.nhtml';
      Nes::Singleton->instance->out(%nes_tags);
  }

  sub logout {
      my $self = shift;
      my %nes_tags;
      $nes_tags{'action'} = 'logout.nhtml';
      Nes::Singleton->instance->out(%nes_tags);
  }


In the instalation package see share/examples/compare directory

=head1 BUGS



=head1 TODO



=head1 AUTHOR

Skriptke: Enrique Castañón

=head1 VERSION

Version 0.01

=head1 COPYRIGHT

Copyright (c) Enrique F. Castanon Barbero. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://dev.perl.org/licenses/

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.

Use of this software in any way or in any form, source or binary,
is not allowed in any country which prohibits disclaimers of any
implied warranties of merchantability or fitness for a particular
purpose or any disclaimers of a similar nature.

IN NO EVENT SHALL I BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
SPECIAL, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF I HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE

=head1 SEE ALSO

Sample to use Nes; L<http://nes.sourceforge.net/>, 
L<Nes>, L<CGI::Application>


=cut



1;


