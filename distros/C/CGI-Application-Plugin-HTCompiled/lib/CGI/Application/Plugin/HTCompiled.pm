package CGI::Application::Plugin::HTCompiled;

use CGI::Application 4.31;

use 5.008;

use strict;
use warnings;
use Carp;
use UNIVERSAL::isa qw/isa/;

=head1 NAME

CGI::Application::Plugin::HTCompiled - Integrate with HTML::Template::Compiled

=cut

$CGI::Application::Plugin::HTCompiled::VERSION = '1.06';

=head1 SYNOPSIS

    # In your CGI::Application-derived base class. . . 
    use base "CGI::Application";
    use CGI::Application::Plugin::HTCompiled;

    # Later, in a run mode far, far away. . . 
    sub view
    {
        my $self = shift;
        my $username = $self->query->param("user");
        my $user     = My::Users->retrieve($username);

        my $tmpl_view = $self->load_tmpl( "view_user.tmpl" );

        $tmpl_view->param( user => $user );

        return $tmpl_view->output();
    }

=head1 DESCRIPTION

Allows you to use L<HTML::Template::Compiled> as a seamless replacement 
for L<HTML::Template>.


=head1 DEFAULT PARAMETERS

By default, the HTCompiled plugin will automatically add a parameter 'c' to the template that
will return to your CGI::Application object $self.  This allows you to access any
methods in your CGI::Application module that you could normally call on $self
from within your template.  This allows for some powerful actions in your templates.
For example, your templates will be able to access query parameters, or if you use
the CGI::Application::Plugin::Session module, you can access session parameters.

 <a href="<tmpl_var c.query.self_url>">Reload this page</a>

With this extra flexibility comes some responsibilty as well.  It could lead down a
dangerous path if you start making alterations to your object from within the template.
For example you could call c.header_add to add new outgoing headers, but that is something
that should be left in your code, not in your template. Try to limit yourself to
pulling in information into your templates (like the session example above does).

=head2 Extending load_tmpl()

There are times when the basic C<load_tmpl()> functionality just isn't 
enough.   The easiest way to do this is by replacing or
extending the functionality of L<CGI::Application>'s C<load_tmpl()> method.
This is still possible using the plugin.  

The following code snippet illustrates one possible way of achieving this:

  sub load_tmpl
  {
      my ($self, $tmpl_file, @extra_params) = @_;

      push @extra_params, "cache",             "1";
      return $self->SUPER::load_tmpl($tmpl_file, @extra_params);
  }



=head1 FUNCTIONS

This is documentation of how it is done internally. If you actually are looking
for how to use this module, see SYNOPSIS. There isn't anything else to do than
using this plugin.

=head2 import()

Will be called when your Module uses L<HTML::Template::Compiled>. Registers
callbacks at the C<init> and the C<load_tmpl> stages. This is how the plugin
mechanism works.

=cut

sub import {
    my $caller = scalar( caller );
	
	# -- determine if the module has been used as base class or as plugin.
	return unless $caller->isa('CGI::Application');
	
	$caller->add_callback( 'init' => \&_add_init );
    $caller->add_callback( 'load_tmpl' => \&_pass_in_self );
    goto &Exporter::import;
} # /import




=head2 _pass_in_self()

Adds the parameter c each template that will be processed. See
DEFAULT PARAMETERS for more information.

=cut

sub _pass_in_self {
	my ( $self, $one, $tmpl_params, $template_file ) = @_;
	
	# we won't warn, assuming that the user set param "c" intensionally
	#warn("Template param 'c' will be overwritten.") if exists $tmpl_params->{c};
	$tmpl_params->{c} = $self;
} # /_pass_in_self




=head2 _add_init()

Set html_tmpl_class to L<HTML::Template::Compiled> at the init stage. That way,
each time a template is loaded using load_tmpl, an instance of
HTML::Template::Compiled will be created instead of the defualt HTML::Template.
See the L<CGI::Appliaction> manpage for more information.

=cut

sub _add_init {
	my $self = shift;
	$self->html_tmpl_class('HTML::Template::Compiled');
} # /_add_init




=head2 load_tmpl()

This method exists to ensure backward compatibility only. It overrides
CGI::Application's load_tmpl() when this plugin is used the old way.
See BACKWARD COMPATIBILITY for more information and please just don't use it
that way anymore.

For the most part, this is the exact C<load_tmpl()> method from 
L<CGI::Application>, except it uses L<HTML::Template::Compiled> instead of L<HTML::Template>.

See the L<CGI::Application> reference for more detailed information
on what parameters can be passed to C<load_tmpl()>.

=cut

sub load_tmpl {
	my $self = shift;
	return $self->SUPER::load_tmpl(@_) unless $self->isa('CGI::Application::Plugin::HTCompiled');
	
	my ($tmpl_file, @extra_params) = @_;

	# add tmpl_path to path array if one is set, otherwise add a path arg
	if (my $tmpl_path = $self->tmpl_path) {
		my @tmpl_paths = (ref $tmpl_path eq 'ARRAY') ? @$tmpl_path : $tmpl_path;
		my $found = 0;
		for( my $x = 0; $x < @extra_params; $x += 2 ) {
			if ($extra_params[$x] eq 'path' and
			ref $extra_params[$x+1] eq 'ARRAY') {
				unshift @{$extra_params[$x+1]}, @tmpl_paths;
				$found = 1;
				last;
			}
		}
		push(@extra_params, path => [ @tmpl_paths ]) unless $found;
	}

    # Since we have method call access in the templates, add the CGI::App object
    # as "c" by default. 
    my %tmpl_params = (c=>$self);
    my %ht_params = @extra_params;
    %ht_params = () unless keys %ht_params;

    # Define our extension if doesn't already exist;
    $self->{__CURRENT_TMPL_EXTENSION} = '.html' unless defined $self->{__CURRENT_TMPL_EXTENSION};

    # Define a default templat name based on the current run mode
    unless (defined $tmpl_file) {
        $tmpl_file = $self->get_current_runmode . $self->{__CURRENT_TMPL_EXTENSION};    
    }

    $self->call_hook('load_tmpl', \%ht_params, \%tmpl_params, $tmpl_file);

    use HTML::Template::Compiled;
    # let's check $tmpl_file and see what kind of parameter it is - we
    # now support 3 options: scalar (filename), ref to scalar (the
    # actual html/template content) and reference to FILEHANDLE
    my $t = undef;

    if ( ref $tmpl_file eq 'SCALAR' ) {
        $t = HTML::Template::Compiled->new( scalar_ref => $tmpl_file, %ht_params );
    } elsif ( ref $tmpl_file eq 'GLOB' ) {
        $t = HTML::Template::Compiled->new( filehandle => $tmpl_file, %ht_params );
    } else {
        $t = HTML::Template::Compiled->new( filename   => $tmpl_file, %ht_params);
    }

    (defined $t) || croak "problem creating template object. Check args to new()";

    if (keys %tmpl_params) {
        $t->param(%tmpl_params);
    }

	return $t;
}





=head1 BACKWARD COMPATIBILITY

You can still use the old method using the module by inheriting from it.
This is not recommended, as it overrides L<CGI::Application>'s C<load_tmpl()>.

    # In your CGI::Application-derived base class. . . 
    use base ("CGI::Application::Plugin::HTCompiled", "CGI::Application");

    # Later, in a run mode far, far away. . . 
    sub view
    {
        my $self = shift;
        my $username = $self->query->param("user");
        my $user     = My::Users->retrieve($username);

        my $tmpl_view = $self->load_tmpl( "view_user.tmpl" );

        $tmpl_view->param( user => $user );

        return $tmpl_view->output();
    }


=head1 EXAMPLE

Define your CGI::Application derived base class.
	
	package CGIApplicationDerivedBaseClass;
	
	use strict;
	use warnings;
	
	use FindBin qw/$Bin/;
	use lib $Bin . '/lib';
	
	use base qw/CGI::Application/;
	
	use CGI::Application::Plugin::HTCompiled;
	
	=head1 NAME
	
	CGIApplicationDerivedBaseClass - Perl extension for demonstrating
	CGI::Application::Plugin::HTCompiled.
	
	=head1 SYNOPSIS
	
		use strict;
		use warnings;
	
		my $app = CGIApplicationDerivedBaseClass->new();
		$app->run();
	
	=head1 DESCRIPTION
	
	This demonstrates, how to use CGI::Application::Plugin::HTCompiled.
	
	
	=head1 METHODS
	
	=head2 setup()
	
	Defined runmodes, etc.
	
	=cut
	
	sub setup {
		my $self = shift;
		
		$self->start_mode('start');
		$self->run_modes([qw/
			start
		/]);
		
	} # /setup
	
	
	
	
	=head2 start()
	
	=cut
	
	sub start {
		my $self 	= shift;
		
		my $tmpl_content = qq~
	<h1>Hi!</h1>
	
	<p>You are here: <TMPL_VAR c.query.url> (this is HTML::Compiled magic)</p>
	<p>You are using CAP::HTC version <TMPL_VAR version></p>
		~;
		
		my $t = $self->load_tmpl(\$tmpl_content);
		$t->param(version => $CGI::Application::Plugin::HTCompiled::VERSION);
		return $t->output();
	} # /start
	
	
	
	
	=head1 SEE ALSO
	
	CGI::Application, CGI::Application::Plugin::HTCompiled.
	
	=head1 AUTHOR
	
	Alexander Becler, E<lt>c a p f a n < a t > g m x . d eE<gt>
	
	=head1 COPYRIGHT AND LICENSE
	
	Copyright (C) 2009 by Alexander Becker
	
	This library is free software; you can redistribute it and/or modify it under
	the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
	any later version of Perl 5 you may have available.
	
	=cut
	
	1;
	

Create an instance and run.

	#!/usr/bin/perl
	
	use strict;
	use warnings;
	use CGIApplicationDerivedBaseClass;
	
	my $app = CGIApplicationDerivedBaseClass->new();
	$app->run();



=head1 AUTHOR

Alexander Becker C<< <asb@cpan.org> >>, 
Mark Stosberg C<< <mark@summersault.com> >>
...but largely modeled on HTDot plugin by Jason A. Crome. 

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-htcompiled@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-HTCompiled>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The usual crowd in #cgiapp on irc.perl.org 

=head1 SEE ALSO

L<CGI::Application>, L<HTML::Template>, L<HTML::Template::Compiled>,

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mark Stosberg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::HTCompiled

