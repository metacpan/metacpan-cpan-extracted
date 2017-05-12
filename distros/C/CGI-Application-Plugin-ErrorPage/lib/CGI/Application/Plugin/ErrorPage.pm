package CGI::Application::Plugin::ErrorPage;
use strict;
use warnings;

BEGIN {
    use base 'Exporter';
    our $VERSION     = '1.21';
    our @EXPORT_OK   = 'error';
}


=head1 NAME

CGI::Application::Plugin::ErrorPage - A simple error page plugin for CGI::Application

=head1 SYNOPSIS

  use CGI::Application::Plugin::ErrorPage 'error';

  sub my_run_mode {
    my $self = shift;

    eval { .... };

    if ($@) {
        # Send the gory details to the log for the developers
        warn "$@";
        
        # Send a comprehensible message to the users
        return $self->error(
            title => "Technical Failure',
            msg   => "There was a techical failure during the operation.",
        );
    }

  }

=head1 DESCRIPTION

This plugin provides a shortcut for the common need of returning a simple error
message to the user.  

You are encouraged to provide a template file so that the error messages can
be presented with a design consistent with the rest of your application. 

A simple design is provided below to get to you started. 

=head2 A better default error page. 

If you don't install an AUTOLOAD run mode in the normal way in C<< setup >>, this plugin
will automatically install a reasonable default at the C<< prerun >> stage, which returns an error page like this:

  return $c->error(
      title => 'The requested page was not found.',
      msg => "(The page tried was: ".$c->get_current_runmode.")"
  );

=head2 Relation to error_mode()

CGI::Application includes C<error_mode()> to provide custom handling when the application dies.
This error() routine provides a shortcut for displaying error messages to the user. So, they both have a
place on their own, and it could make sense to use them together. In your 'error_mode' routine, you might
call error() to return a message to the user:

    $self->error( title => 'Technical Failure', msg => 'There was a technical failure' );

=head2 Suggested Uses

Some common cases for returning error messages to the user include:

  * "Technical Failure" - The software failed unexpectedly  
  * "Insufficient Information" - some required query parameter was missing 
  * "Request Not Understood" - Some value we received in the query just didn't make sense. 

=head2 Silliness

  [22:36] <rjbs> Techno Failure.  We were cruising along and rocking out while fulfilling your request, but then the music stopped and we sort of got distracted.
  [22:36] <rjbs> Tek Failure.  Too busy reading Shatner novels to respond to your request.

=head1 METHODS

=head2 error()

        return $self->error(
            title => "Technical Failure',
            msg   => "There was a techical failure during the operation",
        );


Nothing fancy, just a shortcut to load a template meant to display errors. I've used 
it for the past several years, and it's been very handy to always have around on
projects to quickly write error handling code. 

It tries to load a template file named 'error.html' to display the error page.

If you want to use a different location, I recommend putting something like this in your base class,
so you only have to provide your error template location once. 


 # In this case, intentionally *don't* import 'error' to avoid a "redefined" warning.
 use CGI::Application::Plugin::ErrorPage;
 sub error {
      my $c = shift;
      return $c->CGI::Application::Plugin::ErrorPage::error(
          tmpl => $self->cfg('ROOT_URI').'/path/to/my/alternate/error/file.html',
          @_,
      );
 }

This module intentionally ignores any C<tmpl_path()> set by application, since
this is usually an indication of where the intended file is located, not the
error template.  This exceptional handling of the C<tmpl_path()> is one of the
only value added bits of logic that this plugin adds. The rest of it is
primarily a simple recommendation for error page handling wrapped up as a
module.

If you don't want this behavior, it's simple enough just to roll your own error() page method
and skip using this plugin. Here's the simple essential code:

    use Params::Validate ':all';
    sub error {
        my $self  = shift;
        my %p = validate(@_, { title => SCALAR, msg => SCALAR });
        my $t = $self->load_tmpl;
        $t->param( title => $p{title}, msg => $p{msg} );
        return $t->output;
    }


=cut 

sub import {
    my $caller = scalar(caller);
    $caller->add_callback('prerun', \&add_page_not_found_rm);
    goto &Exporter::import;
}

sub add_page_not_found_rm {
    my $c = shift;

     my %rms = $c->run_modes;

     unless( exists $rms{'AUTOLOAD'}) {
         $c->run_modes(
             AUTOLOAD => sub {
                 my $self = shift;
                 return $self->error(
                     title => 'The requested page was not found.',
                     msg => "(The page tried was: ".$self->get_current_runmode.")"
                 )
         });
     }
}





use Params::Validate ':all';
sub error {
    my $c = shift;
    my %p = validate(@_, {
        title => SCALAR,
        msg   => SCALAR,
        # tmpl can be various types
        tmpl  => { default => 'error.html' }, 
    });

    # If a tmpl_path has been set, we want to ignore it, because it was most
    # likely meant for the template itself, not for the error page.
    
    # We are careful to put the value back how we found it after we are done with it here!

    my @path_to_restore = $c->tmpl_path();
    $c->tmpl_path('');
    my $t = $c->load_tmpl($p{tmpl});
    $c->tmpl_path(@path_to_restore);
    
    $t->param( 
        title => $p{title},
        msg   => $p{msg},
    );

    return $t->output;
}




=head2 Example error.html

Here's a very basic example of an C<error.html> file to get you started.

 <!DOCTYPE html
         PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
 <html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
 <head>
 <title><!-- tmpl_var title escape=HTML --></title>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 </head>
 <body>
 <h1><!-- tmpl_var title escape=HTML--></h1>
 <p><!-- tmpl_var msg escape=HTML --></p>
 </body>
 </html>

We manage site-wide designs with Dreamweaver and keep a basic 'error.html' that
uses a generic Dreamweaver 'page.dwt' template with standard EditableRegion
names. That way, we can copy this error.html into a new Dreamweaver-managed
project and have the new design applied to it easily through Dreamweaver.

=head1 SUPPORT

Ask for help on the L<CGI::Application> mailing list. Report bugs and wishes
through the rt.cpan.org bug tracker. 

=head1 AUTHOR

    Mark Stosberg
    CPAN ID: MARKSTOS
    mark@summersault.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut


1;
# The preceding line will help the module return a true value

