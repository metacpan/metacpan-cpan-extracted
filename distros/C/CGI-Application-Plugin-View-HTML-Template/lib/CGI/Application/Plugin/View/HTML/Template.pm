package CGI::Application::Plugin::View::HTML::Template;

use strict;
use warnings;

use vars qw($VERSION);
require Exporter;


$VERSION = '0.02';

sub import { my $caller = scalar(caller);
             $caller->add_callback('postrun', \&my_postrun);
             goto &Exporter::import }

 
sub my_postrun {

my ($self, $bodyref) = @_;

# Don't do anything for 'redirect' and 'none'.
if ($self->header_type() ne 'header') {
  return;
}


# Try to automatically populate the template.
my $template = $self->param('template');

# Not an H::T template? 
if (ref($template) ne 'HTML::Template' and ref($template) ne 'HTML::Template::Compiled') {
  return;
}

# If the template param name is in the stash, set the template using it.
foreach my $name ($template->param()) {

  my $param = $self->param($name);

  if ($param) {
    $template->param($name => $param);
  }
}

# Add to what this plugin was called with.
${$bodyref} .= $template->output();

return;

}

1;


__END__


=head1 NAME

CGI::Application::Plugin::View::HTML::Template - Automatically render HTML::Templates in CGI::Application

=head1 SYNOPSIS

  use base CGI::Application;
  use CGI::Application::Plugin::View::HTML::Template;
  use CGI::Application::Plugin::Stash; # Recommended
  
  sub setup {
    my $self = shift;
    $self->start_mode('mode1');
    $self->mode_param('rm');
    $self->run_modes(
            'mode1' => 'do_stuff',
             ...
    );
  }
  
  sub do_stuff {
  
    $self->stash->{foo} = 'bar';
  
    $self->stash->{template} = $self->load_tmpl('some.tmpl');
  
    return;
  
  }
 

=head1 DESCRIPTION

CGI::Application::Plugin::View adds L<Catalyst>-like view processing to CGI::Application. This 
module automatically renders templates without setting template params or calling the template
output method.

This module has no methods. Simply store your template and var(s) (L<CGI::Application::Plugin::Stash>
is recommended), and return from your runmode without returning template output. This module will
automatically populate variables found in your template, and output it.

This module was inspired by Plugin::Stash. When I read the L<Catalyst::Manual::Tutorial> two
things seemed elegant to me: Stash and the way the template is processed automatically when the
controller method is left. When I saw Plugin::Stash it caused me to remember the other thing I 
liked. So, I created this module. It doesn't do much. At a minimum it's a simple example of how to
use CGI::Application's "add_callback" to postrun.

=head1 SEE ALSO

L<CGI::Application>

L<HTML::Template>

L<Catalyst>

For additonal Catalyst-like functionality, see:

L<CGI::Application::Plugin::ActionDispatch>

L<CGI::Application::Plugin::DebugScreen>

L<CGI::Application::Plugin::Forward>

L<CGI::Application::Plugin::Stash>

=head1 AUTHOR

Mark Fuller, mfuller at c p a n /.\ o r g

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Mark Fuller

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
