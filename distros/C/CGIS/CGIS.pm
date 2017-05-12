package CGIS;

# $Id: CGIS.pm,v 1.6 2003/03/12 11:43:34 sherzodr Exp $

use strict;
#use diagnostics;
use base 'CGI';

($CGIS::VERSION) = '$Revision: 1.6 $' =~ m/Revision:\s*(\S+)/;

# Preloaded methods go here.

sub session {
  my $self = shift;
      
  my $session_obj = $self->{_CGI_SESSION_OBJ};
  unless ( defined $session_obj ) {
    require CGI::Session;
    my $session_dir = $self->cgi_session_dir();
    $session_obj = new CGI::Session(undef, $self, {Directory=>$session_dir});
    $self->{_CGI_SESSION_OBJ} = $session_obj;
    $self->param($session_obj->name, $session_obj->id);
  }
  unless ( @_ ) {
    return $session_obj;
  }
  return $session_obj->param(@_);
}


# returns the folder to store session files in
sub cgi_session_dir {
  my $self = shift;

  require File::Spec;
  # getting the temporary directory
  my $tmpdir = File::Spec->tmpdir();
  # directory name to store cgisession data in:
  my $session_dir = File::Spec->catfile($tmpdir, 'cgi_session');
  unless ( -d $session_dir ) {
    require File::Path;
    unless(File::Path::mkpath($session_dir)) {
      # if fails to create the folder, fall back to default tmpdir
      $session_dir = File::Spec->tmpdir();
    }
  }  
  return $session_dir;
}



# alias to cgi_session_dir()
sub session_dir {
  my $self = shift;
  return $self->cgi_session_dir();
}



sub header {
  my $self = shift;

  my $session   = $self->session();
  my $cookie    = $self->cookie($session->name, $session->id);
  return $self->SUPER::header(-cookie=>$cookie, @_);
}



sub urlf {
  my $self = shift;

  my $session = $self->session();
  my $name = $session->name;

  my %args = (
    $name => $session->id,
    @_
  );  

  require URI;
  my $url = new URI( $self->url )->canonical();
  $url->query_form( %args );

  return $url->as_string();
}


sub session_id {
  my $self = shift;

  return $self->session()->id;
}








1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CGIS - Session enabled CGI.pm

=head1 SYNOPSIS

    use CGIS;
    
    $cgi = new CGIS;
    my $first_name = $cgi->session("f_name");

    # use it the way you have been using CGI.pm

=head1 DESCRIPTION

CGIS is a simple, session-enabled extension for Lincoln Stein's L<CGI|CGI>.
Instead of loading CGI, you load CGIS, and use it the way you have been using
CGI.pm, without any exceptions.

In addition, CGIS provides C<session()> method, to support persistent session
management accross subsequent HTTP requests, and partially overrides header()
method to ensure proper HTTP headers are sent out with valid session cookies.

CGIS also modifies your CGI environement by appending 'CGISESSID' parameter
with session id as a value. It means, self_url() method (L<CGI>) will print
URL with session related data intact.

CGIS requires CGI::Session installed properly. Uses its CGI::Session::File driver,
and stores session data in a designated directory created in your system's temporary
folder.


=head1 METHODS

=over 4

=item *

C<session()> - if used without argument returns CGI::Session object.
Extra arguments passed will be directly sent along to CGI::Session's param()
methods and their values will be returned.

=item *

C<session_dir()> - returns full path to a folder where your session data are stored

=item *

C<header()> - the same as standard version of header() with session cookies
prepended. You can override it if you want by passing your own "-cookie" option.

=item *

C<urlf()> - returns formated URL with proper session data appended. Arguments
should be in the form of a hash (or hashref), which will be treated as a set
of key/value pairs generated as a query string. For example:

  my $home = $cgi->urlf(_cmd => 'read', message=>'1001');

The above example generates a url similar to something like:

  /cgi-bin/script.cgi?_cmd=read&message=1001&CGISESSID=6d084d93399ce7c07926ca11843b9334

=back


=head1 EXAMPLES

A tiny example of a cgi program can be found in examples/ folder of the distribution.
You may as well be able to see it in action at http://www.handalak.com/cgi-bin/cgis
This script simply displays your session id as well as sample outputs of 
urlf() and self_url() methods for you to have an idea.


=head2 SENDING THE SESSION COOKIE

In session management enabled sites, you most likely
send proper session cookie to the user's browser at each request.
Instead of doing it manual, simply call CGIS's header() method, 
as you would that of CGI.pm's:

    print $cgi->header();

And you are guaranteed proper cookie's sent out to the user's
computer.

=head2 STORING DATA IN THE SESSION
    
    # store user's name in the session for later use:
    $cgi->session("full_name", "Sherzod Ruzmetov");

    # store user's email for later:
    $cgi->session("email", 'sherzodr@cpan.org');

=head2 READING DATA OFF THE SESSION

    my $full_name = $cgi->session("full_name");
    my $email     = $cgi->session('email');
    print qq~<a href="mailto:$email">$full_name</a>~;

=head2 GETTING CGI::Session OBJECT

For performing more sophisticated oprations, you may need to
get underlying CGI::Session object directly. To do this, simply call session()
with no arguments:

    $session = $cgi->session();    

    # set expiration ticker for session object
    $session->expire("+10m");
    
For more tricks, consult L<CGI::Session|CGI::Session> manual.

=head1 AUTHOR

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>

=head1 COPYRIGHT

This library is free software. You can modify and/or distribute it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Session>, L<CGI>

=cut
