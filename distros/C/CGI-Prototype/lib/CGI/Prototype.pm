package CGI::Prototype;

use 5.006;
use strict;
use warnings;

use base qw(Class::Prototyped);

## no exports

our $VERSION = '0.9054';

our $_mirror = __PACKAGE__->reflect; # for slots that aren't subs

=head1 NAME

CGI::Prototype - Create a CGI application by subclassing

=head1 SYNOPSIS

  package My::HelloWorld;
  use base CGI::Prototype;

  sub template { \ <<'END_OF_TEMPLATE' }
  [% self.CGI.header; %]
  Hello world at [% USE Date; Date.format(date.now) | html %]!
  END_OF_TEMPLATE

  My::HelloWorld->activate;

=head1 DESCRIPTION

The core of every CGI application seems to be roughly the same:

=over 4

=item *

Analyze the incoming parameters, cookies, and URLs to determine the
state of the application (let's call this "dispatch").

=item *

Based on the current state, analyze the incoming parameters to respond
to any form submitted ("respond").

=item *

From there, decide what response page should be generated, and produce
it ("render").

=back

L<CGI::Prototype> creates a C<Class::Prototyped> engine for doing all
this, with the right amount of callback hooks to customize the
process.  Because I'm biased toward Template Toolkit for rendering
HTML, I've also integrated that as my rendering engine of choice.
And, being a fan of clean MVC designs, the classes become the
controllers, and the templates become the views, with clean separation
of responsibilities, and C<CGI::Prototype> a sort of "archetypal"
controller.

You can create the null application by simply I<activating> it:

  use CGI::Prototype;
  CGI::Prototype->activate;

But this won't be very interesting.  You'll want to subclass this
class in a C<Class::Prototyped>-style manner to override most of its
behavior.  Slots can be added to add or alter behavior.  You can
subclass your subclasses when groups of your CGI pages share similar
behavior.  The possibilities are mind-boggling.

Within the templates, C<self> refers to the current controller.  Thus,
you can define callbacks trivially.  In your template, if you need some
data, you can pull it as a request:

  [% my_data = self.get_some_big_data %]

which is supplied by simply adding the same slot (method or data) in
the controlling class:

  sub get_some_big_data {
    my $self = shift;
    return $self->some_other_method(size => 'big');
  }

And since the classes are hierarchical, you can start out with an
implementation for one page, then move it to a region or globally
quickly.

Although the name C<CGI::Prototype> implies a CGI protocol, I see no
reason that this would not work with C<Apache::Registry> in a
C<mod_perl> environment, or a direct content handler such as:

  package My::App;
  use base CGI::Prototype;
  sub handler {
    __PACKAGE__->activate;
  }

Note that the C<$r> request object will have to be created if needed
if you use this approach.

=head2 CORE SLOTS

These slots provide core functionality.  You will probably not
need to override these.

=over 4

=item activate

Invoke the C<activate> slot to "activate" your application,
causing it to process the incoming CGI values, select a page to be
respond to the parameters, which in turn selects a page to render, and
then responds with that page.  For example, your App might consist
only of:

  package My::App;
  use base qw(CGI::Prototype);
  My::App->activate;

Again, this will not be interesting, but it shows that the null app
is easy to create.  Almost always, you will want to override some
of the "callback" slots below.

=cut

sub activate {
  my $self = shift;
  eval {
    $self->prototype_enter;
    $self->app_enter;
    my $this_page = $self->dispatch;
    $this_page->control_enter;
    $this_page->respond_enter;
    my $next_page = $this_page->respond;
    $this_page->respond_leave;
    if ($this_page ne $next_page) {
      $this_page->control_leave;
      $next_page->control_enter;
    }
    $next_page->render_enter;
    $next_page->render;
    $next_page->render_leave;
    $next_page->control_leave;
    $self->app_leave;
    $self->prototype_leave;
  };
  $self->error($@) if $@;	# failed something, go to safe mode
}

=item CGI

Invoking C<< $self->CGI >> gives you access to the CGI.pm object
representing the incoming parameters and other CGI.pm-related values.
For example,

  $self->CGI->self_url

generates a self-referencing URL.  From a template, this is:

  [% self.CGI.self_url %]

for the same thing.

See C<initialize_CGI> for how this slot gets established.

=cut

$_mirror->addSlot
  (CGI => sub { die shift, "->initialize_CGI not called" });

=item render

The C<render> method uses the results from C<engine> and C<template>
to process a selected template through Template Toolkit.  If the
result does not throw an error, C<< $self->display >> is called to
show the result.

=cut

sub render {
  my $self = shift;
  my $tt = $self->engine;
  my $self_object = $self->reflect->object; # in case we have a classname
  $tt->process($self->template, { self => $self_object }, \my $output)
    or die $tt->error;	# passes Template::Exception upward
  $self->display($output);
}

=item display

The C<display> method is called to render the output of the template
under normal circumstances, normally dumping the first parameter to
C<STDOUT>.  Test harnesses may override this method to cause the
output to appear into a variable, but normally this method is left
alone.

=cut

sub display {			# override this to grab output for testing
  my $self = shift;
  my $output = shift;
  print $output;
}

=item param

The C<param> method is a convenience method that maps to
C<< $self->CGI->param >>, because accessing params is a very common thing.

=cut

sub param {
  shift->CGI->param(@_);	# convenience method
}

=item interstitial

B<Please note that this feature is still experimental
and subject to change.>

Use this in your per-page respond methods if you have a lot of heavy
processing to perform.  For example, suppose you're deleting
something, and it takes 5 seconds to do the first step, and 3 seconds
to do the second step, and then you want to go back to normal web
interaction.  Simulating the heavy lifting with sleep, we get:

  my $p = $self->interstitial
    ({ message => "Your delete is being processed...",
       action => sub { sleep 5 },
     },
     { message => "Just a few seconds more....",
       action => sub { sleep 3 },
     },
    );
  return $p if $p;

C<interstitial> returns either a page that should be returned so that
it can be rendered (inside a wrapper that provides the standard top
and bottom of your application page), or C<undef>.

The list passed to
C<interstitial> should be a series of hashrefs with one or more
parameters reflecting the steps:

=over 4

=item message

What the user should see while the step is computing.
(Default: C<Working...>.)

=item action

A coderef with the action performed server-side during the message.
(Default: no action.)

=item delay

The number of seconds the browser should wait before initiating
the next connection, triggering the start of C<action>.
(Default: 0 seconds.)

=back

The user sees the first message at the first call to C<interstitial>
(via the first returned page), at which time a meta-refresh will
immediately repost the same parameters as on the call that got you
here.  (Thus, it's important not to have changed the params yet, or
you might end up in a different part of your code.)  When the call to
C<interstitial> is re-executed, the first coderef is then performed.
At the end of that coderef, the second interstitial page is returned,
and the user sees the second message, which then performs the next
meta-refresh, which gets us back to this call to C<interstitial> again
(whew).  The second coderef is executed while the user is seeing the
second message, and then C<interstitial> returns C<undef>, letting us
roll through to the final code.  Slick.

=cut

sub interstitial {
  my $self = shift;
  my @steps = @_;

  my $cip = $self->config_interstitial_param;
  my $step = $self->param($cip) || 0;
  ## todo: validate $state is a small integer in range

  if ($step >= 1 and $step <= @steps) { # we got work to do
    if (defined (my $code = $steps[$step - 1]{action})) {
      $code->();		# run the action
    }
  }

  ## now show the user the message during the next step
  $step++;

  unless ($step >= 1 and $step <= @steps) {
    $self->CGI->delete($cip);
    return undef;		# signal steps being done
  }
  $self->param($cip, $step);

  my $message = $steps[$step - 1]{message} || "Working...";
  my $delay = $steps[$step - 1]{delay} || 0;

  ## generate interstitial page as light class
  return $self->new(
		    url => $self->CGI->self_url,
		    message => $message,
		    delay => $delay,
		    shortname => $self->shortname,
		    template => \ <<'',
<META HTTP-EQUIV=Refresh CONTENT="[% self.delay %]; URL=[% self.url | html %]">
[% self.message %]<br>
(If your browser isn't automatically trying to fetch a page right now,
please <a href="[% self.url | html %]">continue manually</a>.)

		   );
}

=item config_interstitial_param

This parameter is used by C<interstitial> to determine the
processing step.  You should ensure that the name doesn't conflict
with any other param that you might need.

The default value is C<_interstitial>.

=cut

sub config_interstitial_param { "_interstitial" }

=back

=head2 CALLBACK SLOTS

=over 4

=item engine

The engine returns a Template object that will be generating any
response.  The object is computed lazily (with autoloading) when
needed.

The Template object is passed the configuration returned from
the C<engine_config> callback.

=cut

$_mirror->addSlot
  ([qw(engine FIELD autoload)] => sub {
     my $self = shift;
     require Template;
     Template->new($self->engine_config)
       or die "Creating tt: $Template::ERROR\n";
   });

=item engine_config

Returns a hashref of desired parameters to pass to
the C<Template> C<new> method as a configuration.  Defaults
to an empty hash.

=cut

sub engine_config {
  return {};
}

=item prototype_enter

Called when the prototype mechanism is entered, at the very beginning
of each hit.  Defaults to calling C<->initialize_CGI>, which see.

Generally, you should not override this method. If you do, be sure to
call the SUPER method, in case future versions of this module need
additional initialization.

=cut

sub prototype_enter {
  shift->initialize_CGI;
}

=item prototype_leave

Called when the prototype mechanism is exited, at the very end of each hit.
Defaults to no action.

Generally, you should not override this method. If you do, be sure to
call the SUPER method, in case future versions of this module need
additional teardown.

=cut

sub prototype_leave {}

=item initialize_CGI

Sets up the CGI slot as an autoload, defaulting to creating a new
CGI.pm object.  Called from C<prototype_enter>.

=cut

sub initialize_CGI {
  my $self = shift;
  $self->reflect->addSlot
    ([qw(CGI FIELD autoload)] => sub {
       require CGI;
       CGI::_reset_globals();
       CGI->new;
     });
}

=item app_enter

Called when the application is entered, at the very beginning of each
hit.  Defaults to no action.

=cut

sub app_enter {}

=item app_leave

Called when the application is left, at the very end of each hit.
Defaults to no action.

=cut

sub app_leave {}

=item control_enter

Called when a page gains control, either at the beginning for a
response, or in the middle when switched for rendering.  Defaults to
nothing.

This is a great place to hang per-page initialization, because you'll
get this callback at most once per hit.

=cut

sub control_enter {}

=item control_leave

Called when a page loses control, either after a response phase
because we're switching to a new page, or render phase after we've
delivered the new text to the browser.

This is a great place to hang per-page teardown, because you'll get
this callback at most once per hit.

=cut

sub control_leave {}

=item render_enter

Called when a page gains control specifically for rendering (delivering
text to the browser), just after C<control_enter> if needed.

=cut

sub render_enter {}

=item render_leave

Called when a page loses control specifically for rendering (delivering
text to the browser), just before C<control_leave>.

=cut

sub render_leave {}

=item respond_enter

Called when a page gains control specifically for responding
(understanding the incoming parameters, and deciding what page should
render the response), just after C<control_enter>.

=cut

sub respond_enter {}

=item respond_leave

Called when a page loses control specifically for rendering
(understanding the incoming parameters, and deciding what page should
render the response), just before C<control_leave> (if needed).

=cut

sub respond_leave {}

=item template

Delivers a template document object (something compatible to the
C<Template> C<process> method, such as a C<Template::Document> or a
filehandle or a reference to a scalar).  The default is a simple "this
page intentionally left blank" template.

When rendered, the B<only> extra global variable passed into the
template is the C<self> variable, representing the controller object.
However, as seen earlier, this is sufficient to allow access to
anything you need from the template, thanks to Template Toolkit's
ability to call methods on an object and understand the results.

For example, to get at the C<barney> parameter:

  The barney field is [% self.param("barney") | html %].

=cut

sub template {
  \ '[% self.CGI.header %]This page intentionally left blank.';
}

=item error

Called if an uncaught error is triggered in any of the other steps,
passing the error text or object as the first method parameter.  The
default callback simply displays the output to the browser, which is
highly insecure and should be overridden, perhaps with something that
logs the error and puts up a generic error message with an incident
code for tracking.

=cut

sub error {
  my $self = shift;
  my $error = shift;
  $self->display("Content-type: text/plain\n\nERROR: $error");
}

=item dispatch

Called to analyze the incoming parameters to define which page object
gets control based on the incoming CGI parameters.

This callback B<must return> a page object (the object taking control
during the response phase).  By default, this callback returns the
application itself.

=cut

sub dispatch {
  my $self = shift;
  return $self;		# do nothing, stay here
}

=item respond

Called to determine how to respond specifically to this set of
incoming parameters.  Probably updates databases and such.

This callback B<must return> a page object (the object taking control
during the render phase).  By default, this callback returns the same
object that had control during the response phase ("stay here" logic),
which works most of the time.

=cut

sub respond {
  my $self = shift;
  return $self;		# do nothing, stay here
}

=back

=head1 SEE ALSO

L<Class::Prototyped>, L<Template::Manual>,
L<http://www.stonehenge.com/merlyn/LinuxMag/col56.html>.

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
