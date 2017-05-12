package CGI::Application::Plugin::HTDot;

use strict;

=head1 NAME

CGI::Application::Plugin::HTDot - Enable "magic dot" notation in
L<CGI::Application>-derived applications that use L<HTML::Template> for their
templating mechanism.

=head1 VERSION

Version 0.07

=cut

$CGI::Application::Plugin::HTDot::VERSION = '0.07';

=head1 SYNOPSIS

    # In your CGI::Application-derived base class. . .
    use base ("CGI::Application::Plugin::HTDot", "CGI::Application");

    # Later, in a run mode far, far away. . .
    sub view {
        my $self     = shift;
        my $username = $self->query->param( 'user' );
        my $user     = My::Users->retrieve( $username );

        my $tmpl_view = $self->load_tmpl( 'view_user.tmpl' );

        # The magic happens here!  Pass our Class::DBI object
        # to the template and display it
        $tmpl_view->param( user => $user );

        return $tmpl_view->output;
    }

=head1 DESCRIPTION

Imagine this: you've written a lot of code based upon L<CGI::Application>, and
also with L<HTML::Template> because the two have always had such a high level
of integration.  You reach a situation (many times, perhaps) where you could
really use the power and convenience of being able to pass objects to your
templates and call methods of those objects from within your template (ala
Template Toolkit), but your development schedule doesn't give you the time
to learn (much less migrate to!) Template Toolkit or AnyTemplate.  Well, you
need fret no more!  C<CGI::Application::Plugin::HTDot> helps you bring the
power of the magic dot to your L<HTML::Template>-based templates from within
your L<CGI::Application>-derived webapps.

L<CGI::Application::Plugin::HTDot> provides the glue between
L<CGI::Application>, L<HTML::Template::Pluggable> and
L<HTML::Template::Plugin::Dot>.  It overrides the C<load_tmpl()> method
provided with L<CGI::Application> and replaces it with one that turns on the
magic dot in L<HTML::Template>.  The C<load_tmpl()> method provided here is
100% compatible with the one found in a stock L<CGI::Application> app, so
using this plugin does not require refactoring of any code.  You can use the
magic dot in your application and templates going forward, and refactor older
code to use it as your schedule permits.

When you have lots of apps and lots of templates, and no means to switch to
Template Toolkit, this will make your life infinitely easier.

For more information about the magic dot, see L<HTML::Template::Plugin::Dot>.

As of version 4.31 of L< CGI::Application >, you can use the 
C< html_tmpl_class() > method as an alternative to this plugin.  TIMTOWTDI.

=head1 METHODS

=head2 load_tmpl()

For the most part, this is the exact C<load_tmpl()> method from
L<CGI::Application>, except it uses L<HTML::Template::Pluggable> and
L<HTML::Template::Plugin::Dot> instead of L<HTML::Template>.

See the L<CGI::Application> reference for more detailed information
on what parameters can be passed to C<load_tmpl()>.

=cut

sub load_tmpl {
	my $self = shift;
	my ( $tmpl_file, @extra_params ) = @_;

	# Add tmpl_path to path array if one is set, otherwise add a path arg
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
		push( @extra_params, path => [ @tmpl_paths ] ) unless $found;
	}

    my %tmpl_params = ();
    my %ht_params   = @extra_params;
    %ht_params      = () unless keys %ht_params;

    # Define our extension if one doesn't already exist
    $self->{__CURRENT_TMPL_EXTENSION} = '.html' unless defined $self->{__CURRENT_TMPL_EXTENSION};

    # Define a default template name based on the current run mode
    unless (defined $tmpl_file) {
        $tmpl_file = $self->get_current_runmode . $self->{__CURRENT_TMPL_EXTENSION};
    }

    $self->call_hook('load_tmpl', \%ht_params, \%tmpl_params, $tmpl_file);

    # This is really where the magic occurs.  We replace HTML::Template with
    # the magic-dot enabled version, and the rest really works itself out.
    use HTML::Template::Pluggable;
    use HTML::Template::Plugin::Dot;

    # Check $tmpl_file and see what kind of parameter it is:
    # - scalar (filename)
	# - ref to scalar (the actual html/template content)
	# - reference to filehandle
    my $t = undef;
    if ( ref $tmpl_file eq 'SCALAR' ) {
        $t = HTML::Template::Pluggable->new_scalar_ref( $tmpl_file, %ht_params );
    }
	elsif ( ref $tmpl_file eq 'GLOB' ) {
        $t = HTML::Template::Pluggable->new_filehandle( $tmpl_file, %ht_params );
    }
	else {
        $t = HTML::Template::Pluggable->new_file( $tmpl_file, %ht_params );
    }

    if ( keys %tmpl_params ) {
        $t->param( %tmpl_params );
    }

	# Pass the CGI::Application object to the template (if it's being referenced
    # somewhere in the template...)
    my @vars = $t->query;
    foreach my $var ( @vars ) {
        $t->param( c => $self ) if $var =~ /^c\./;
    }

	# Give the user back their template
	return $t;
}

=head2 Extending load_tmpl()

There are times when the basic C<load_tmpl()> functionality just isn't
enough.  Many L<HTML::Template> developers set C<die_on_bad_params> to C<0>
on all of their templates.  The easiest way to do this is by replacing or
extending the functionality of L<CGI::Application>'s C<load_tmpl()> method.
This is still possible using the plugin.

The following code snippet illustrates one possible way of achieving this:

  sub load_tmpl {
      my ($self, $tmpl_file, @extra_params) = @_;

      push @extra_params, "die_on_bad_params", "0";
      push @extra_params, "cache",             "1";

      return $self->SUPER::load_tmpl($tmpl_file, @extra_params);
  }

This plugin honors the C<load_tmpl()> callback.  Any C<load_tmpl()>-based
callbacks you have created will be executed as intended:

=head1 DEFAULT PARAMETERS

By default, this plugin will automatically add a parameter 'c' to your
template that will return your L<CGI::Application> object.  This will allow
you to access any methods in your application from within your template.
This allows for some powerful actions in your templates.  For example, your
templates can access query parameters, or if you use the excellent
L<CGI::Application::Plugin::Session> module, you can access session parameters:

	Hello <tmpl_var c.session.param('username')>!

	<a href="<tmpl_var c.query.self_url>">Reload this page</a>

Another useful plugin that can use this feature is the
L<CGI::Application::Plugin::HTMLPrototype> plugin, which gives easy access to
the F<prototype.js> JavaScript library:

	<tmpl_var c.prototype.define_javascript_functions>
	<a href="#" onclick="javascript:<tmpl_var c.prototype.visual_effect( 'Appear', 'extra_info' )>; return false;">Extra Info</a>
	<div style="display: none" id="extra_info">Here is some more extra info</div>

With this extra flexibility comes some responsibilty as well. It could lead
down a dangerous path if you start making alterations to your object from
within the template. For example you could call c.header_add to add new
outgoing headers, but that is something that should be left in your code,
not in your template. Try to limit yourself to pulling in information into
your templates (like the session example above does).

This plugin will respect your current C<die_on_bad_params> setting.  If
C<die_on_bad_params> is set to C<1> and your template does not use 'c', the
plugin will not attempt to pass the L<CGI::Application> object to your
template.  In other words, it does not force your application to set
C<die_on_bad_params> to C<0> to accomplish this action.

=head1 AUTHOR

Jason A. Crome, C<< <cromedome@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-htdot@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-HTDot>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGMENTS

Thanks and credit needs to be given to Jesse Erlbaum and Mark Stosberg for the
original C<load_tmpl()> method that this is based on, to Rhesa Rozendaal and
Mark Stosberg for their work on enabling the magic dot in L<HTML::Template>,
Cees Hek for his idea (and tutorial on how) to use multiple inheritance to
make this plugin work, and to the usual crowd in #cgiapp on irc.perl.org for
making this all worthwhile for me :)

An extra special thanks to Cees Hek for the inspiration, code, and examples to
implement the 'c' parameter in templates.

=head1 SEE ALSO

L<CGI::Application>, L<HTML::Template>, L<HTML::Template::Pluggable>,
L<HTML::Template::Plugin::Dot>, L<CGI::Application::Plugin::TT>.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2005-2007, Jason A. Crome.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::HTDot
