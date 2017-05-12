package CGI::Application::Plugin::Redirect;

use strict;
use vars qw($VERSION @EXPORT);

$VERSION = '1.00';

require Exporter;

@EXPORT = qw(
  redirect
);

sub import { goto &Exporter::import }

sub redirect {
    my $self     = shift;
    my $location = shift;
    my $status   = shift;

    # The eval may fail, but we don't care
    eval {
        $self->run_modes( dummy_redirect => sub { } );
        $self->prerun_mode('dummy_redirect');
    };

    if ($status) {
        $self->header_add( -location => $location, -status => $status );
    } else {
        $self->header_add( -location => $location );
    }
    $self->header_type('redirect');
    return;
}

1;
__END__

=head1 NAME

CGI::Application::Plugin::Redirect - Easy external redirects in CGI::Application


=head1 SYNOPSIS

 package My::App;

 use CGI::Application::Plugin::Redirect;

 sub cgiapp_prerun {
     my $self = shift;

     if ( << not logged in >> ) {
         return $self->redirect('login.html');
     }
 }

 sub byebye {
     my $self = shift;

     return $self->redirect('http://www.example.com/', '301 Moved Permanently');
 }


=head1 DESCRIPTION

This plugin provides an easy way to do external redirects in CGI::Application.
You don't have to worry about setting headers or worrying about return types, as
that is all handled for you.

C<redirect> does an external redirect, which means that the browser will receive
a command to load a new page, and a fresh request will come in.  If you just want to
display the results of another runmode within the same module, then it is often
sufficient to use the C<forward> method in L<CGI::Application::Plugin::Forward> instead.


=head1 METHODS


=head2 redirect($url, $status)

Interupt the current request, and redirect to an external URL.  If
you happen to be inside a prerun method when you call this, the
current runmode will automatically be short circuited so that it
will not execute.  As soon as all prerun method have finished,
the redirect will happen without the runmode being executed.

The $status paramater is optional as the CGI module will default to something
suitable.

  return $self->redirect('http://www.example.com/');

  - or -

  return $self->redirect('http://www.example.com/', '301 Moved Permanently');
 

=head1 SEE ALSO

L<CGI::Application>, L<CGI::Application::Plugin::Forward>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Cees Hek.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED ORIMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSESSUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut
