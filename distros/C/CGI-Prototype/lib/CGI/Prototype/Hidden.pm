package CGI::Prototype::Hidden;
our $_mirror = __PACKAGE__->reflect;

use base CGI::Prototype;
use strict;

=head1 NAME

CGI::Prototype::Hidden - Create a CGI application by subclassing - hidden field

=head1 SYNOPSIS

  # in My/App.pm ---
  package My::App;
  use base qw(CGI::Prototype::Hidden);

  # in /some/cgi-bin/program

  use lib qw(/location);
  use My::App;
  My::App->activate;

=head1 DESCRIPTION

L<CGI::Prototype::Hidden> extends L<CGI::Prototype> by providing a hidden
field mechanism for state, and a dispatching algorithm based on that hidden
field.  In particular,

=over 4

=item 1

Dispatching to a particular paged based on the "state" of the application
is performed according to param field.

=item 2

The name of the state is appended to an application-wide package prefix
to determine an appropriate class to handle the request.

=item 3

The package for the class is autoloaded if needed.

=item 4

The template for the class replaces C<.pm> with C<.tt> (configurable),
found in the same C<@INC> path, and is therefore likely to be in the
same directory.

=item 5

A "wrapper" template is automatically provided.

=back

Thus, a simple 10-page CGI application will require 23 files: 10
classes, 10 corresponding templates, a wrapper template, a master
application class, and a CGI script that loads the master application
class and activates it.

The default class is C<My::App>, but this can be overridden.  The
default state is C<welcome>, but this too can be overridden.  The
default hidden param name for the state is C<_state>, and if you think
this can be overridden, you are correct.  See the trend here?

A sample app is the best way to show all of this, of course.  We don't
have one yet... that's on the TODO list.  However, the functions have
all been exercised in the tests for this module, including an
artificial application, so check that out for at least an example of
the interfaces.

=head2 CONFIGURATION SLOTS

These methods or values are the ones you'll most likely change in your
application, although you can leave them all alone and it'll still be
a valid framework to create your entire application.

=over 4

=item config_state_param

The name of the hidden field which will contain the state, defaulting
to C<_state>.

In any form you create, or any constructed URL, you must be sure to
include this param as part of the form so that the right response can
be matched up for the submitted data.  For example:

<form>
[% self.CGI.hidden(self.config_state_param) %]
First name:[% self.CGI.textfield("first_name") %]<br>
Last name: [% self.CGI.textfield("last_name") %]
<input type=submit>
</form>

=cut

sub config_state_param { "_state" }

=item config_class_prefix

The class prefix placed ahead of the state name, default C<My::App>.
For example, the controller class for the C<welcome> state will be
<My::App::welcome>.

You should change this if you are using L<mod_perl> to something that
won't conflict with other usages of the same server space.  For CGI
scripts, the default is an easy classname to remember.

Note that the template also use this name as their prefix, so that
your controller and template files end up in the same directory.

=cut

sub config_class_prefix { "My::App" }

=item config_default_page

The initial page if the state is missing, default C<welcome>.

=cut

sub config_default_page { "welcome" }

=item config_wrapper

The name of the WRAPPER template, default C<My/App/WRAPPER.tt>.

If you change C<config_class_prefix>, you'll want to change this as
well so that C<WRAPPER.tt> ends up in the right directory.  (I debated
doing that for you so you could just say C<"WRAPPER.TT">, but that'd
make more complicated versions of this callback be even more and more
complicated.)

The wrapper template is called with C<template> set to the wrapped
template, which B<should> be processed in the wrapper.  The smallest
wrapper is therefore:

  [% PROCESS $template %]

However, typically, you'll want to define app-wide blocks and variables,
and maybe wrap the statement above in an exception catcher.  For example:

  [%-
  TRY;
    content = PROCESS $template;
    self.CGI.header;
    self.CGI.start_html;
    content;
    self.CGI.end_html;
  ### exceptions
  ## for errors:
  CATCH;
    CLEAR;
    self.CGI.header('text/plain');
  -%]
  An error has occurred.  Remain calm.
  Authorities have been notified.  Do not leave the general area.
  [%-
    FILTER stderr -%]
  ** [% template.filename %] error: [% error.info %] **
  [%
    END; # FILTER
  END; # TRY
  -%]

This sends back a plain message to the browser, as well as logging the
precise error text to C<STDERR>, and hopefully the web error log.

=cut

sub config_wrapper { "My/App/WRAPPER.tt" }

=item config_compile_dir

The location of the compiled Perl templates, default
C<"/tmp/compile-dir.$<"> (where C<$<> is the current user's numeric
user ID).  You'll want this to be some place that the process can
write, but nobody else can.  The default is functional, but not immune
to other hostile users on the same box, so you'll want to override
that for those cases.

=cut

sub config_compile_dir { "/tmp/compile-dir.$<" }

=item config_tt_extension

The suffix replacing C<.pm> when the module name is mapped
to the template name.  By default, it's C<.tt>.

=cut

sub config_tt_extension { ".tt" }

=back

=head2 MANAGEMENT SLOTS

You will most likely not need to change these, but you'll want
to stay away from their names.

=over 4

=item name_to_page

Called with a page name, returns a page object.  Will also
autoload the package.

=cut

sub name_to_page {
  my $self = shift;
  my $page = shift;

  die "bad page name: $page" unless $page and $page =~ /^([\w]+)$/;
  $page = $1;

  my $package = $self->config_class_prefix;
  $package .= "::$page";
  eval "require $package" unless eval "%${package}::";
  die if $@;
  return $package->reflect->object;
}

=item plugin

B<This is still an experimental feature that will be reworked in
future releases.>

Called with a page name, returns a new page object that can be used as
C<self> in a template, mixing in the code from the page's class for
additional heavy lifting.

For example, to have a "subpage" plugin, create a C<subpage.tt>
and C<subpage.pm> file, then include the tt with:

  [% INCLUDE My/App/subpage.tt
       self = self.plugin("subpage")
       other = parms
       go = here
  %]

Now, within C<subpage.tt>, calls to C<self.SomeMethod> will first
search the original page's lineage, and then the plugin class lineage
for a definition for C<SomeMethod>.

=cut

sub plugin {
  my $self = shift;
  my $name = shift;
  return $self->new('*' => $self->name_to_page($name));
}

=item dispatch

Overridden from L<CGI::Prototype>.  Selects either the hidden field
state, or the default state, and returns the page object.

=cut

sub dispatch {
  my $self = shift;

  my $name = $self->param($self->config_state_param) ||
    $self->config_default_page;
  return $self->name_to_page($name);
}

=item shortname

Returns the simple name for the current page object by stripping off
the C<config_class_prefix>.  Note that this will fail in the event of
prototype page constructed on the fly, rather than a named class.
Hmm, I'll have to think about what that implies.

=cut

sub shortname {
  my $self = shift;
  my $package = ref $self || $self;
  my $prefix = $self->config_class_prefix;
  $package =~ /^${prefix}::(\w+)$/ or die "name mismatch for $package!";
  "$1";
}

=item render_enter

Overridden from L<CGI::Prototype>.  Forces the hidden state param to
the shortname of the current object, then calls
C<render_enter_per_page>.

=cut

sub render_enter {
  my $self = shift;
  $self->param($self->config_state_param, $self->shortname);
  $self->render_enter_per_page; # additional hook
}

=item render_enter_per_page

If you need page-specific render_enter items, put them here.  The
default definition does nothing.  This is to keep from having to call
superclass methods for C<render_enter>.

=cut

sub render_enter_per_page { }	# default action is nothing

=item respond

Overridden from L<CGI::Prototype>.  Calls C<respond_per_app> and then
C<respond_per_page>, looking for a true value, which is then returned.

If you have site-wide buttons (like a button-bar on the side or top of
your form), look for them in C<respond_per_app>, and return the new
page from there.  Otherwise, return C<undef>, and it'll fall through
to the per-page response.

=cut

sub respond {
  my $self = shift;

  return
    $self->respond_per_app ||
    $self->respond_per_page;
}

=item respond_per_app

A hook for application-wide responses, defaulting to C<undef>.  Should
return either a page object (to be rendered) or a false value
(selecting the per-page respond).

=cut

sub respond_per_app { undef }	# respond to app-wide buttons

=item respond_per_page

If C<respond_per_app> returns false, this hook is then evaluated.  It
should return a page object to be rendered.  The default returns the
current page object, so you "stay here" for rendering.

=cut

sub respond_per_page {
  return shift;			# default is stay here
}

=item template

Overridden from L<CGI::Prototype>.  Returns the name of a template,
defined by replacing the double-colons in the classname of the current
page with forward slashes, and then appending C<.tt> (by default, see
C<config_tt_extension>).  Because C<@INC> is added to the
C<INCLUDE_PATH> for the engine, this B<should> find the C<.tt> file in
the same directory as the C<.pm> file.

=cut

sub template {
  my $self = shift;

  my $mirror = $self->reflect;
  my $package = $mirror->package;

  ## default template is classname with ".tt":
  (my $template = $package) =~ s{::}{/}g;
  $template .= $self->config_tt_extension;
  return $template;
}

=item engine_config

Overridden from L<CGI::Prototype>, so that the cached L<Template>
object that is essentially:

  Template->new
    (
     POST_CHOMP => 1,
     INCLUDE_PATH => [@INC],
     COMPILE_DIR => $self->config_compile_dir,
     PROCESS => [$self->config_wrapper],
    )

=cut

sub engine_config {
  my $self = shift;
  return {
	  POST_CHOMP => 1,
	  INCLUDE_PATH => [@INC],
	  COMPILE_DIR => $self->config_compile_dir,
	  PROCESS => [$self->config_wrapper],
	 };
}

=back

=head1 SEE ALSO

L<CGI::Prototype>, L<Template::Manual>

=head1 BUG REPORTS

Please report any bugs or feature requests to
bug-cgi-prototype@rt.cpan.org, or through the web interface at
http://rt.cpan.org. I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Randal L. Schwartz, E<lt>merlyn@stonehenge.comE<gt>

Special thanks to Geekcruises.com and an unnamed large university
for providing funding for the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003, 2004, 2005 by Randal L. Schwartz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
