package Catalyst::View::Seamstress;

use strict;
# [10:05:57] <@andyg> Catalyst::View is the correct base class
use base qw/Catalyst::View/; 

use Data::Dumper;

our $VERSION = '2.2';


=head1 NAME

Catalyst::View::Seamstress - HTML::Seamstress View Class for Catalyst

=head1 SYNOPSIS

# use the helper to create MyApp::View::Seamstress
# where comp_root and skeleton are optional

    myapp_create.pl view Seamstress Seamstress /path/to/html html::skeleton
                         ^-modulenm ^-helpernm ^-comp_root   ^-skeleton

# optionally edit the skeleton and meat_pack routines
# in lib/MyApp/View/Seamstress.pm

# create your seamstress template packaged with spkg.pl
# see HTML::Seamstress.. This will give you a .pm file to go with your html, 
# so something like html::helloworld

# render view from lib/MyApp.pm or lib/MyApp::C::SomeController.pm

    sub message : Global {
        my ( $self, $c ) = @_;

        # LOOM points to our template class made with spkg.pl or
        # manually:
        $c->stash->{LOOM} = 'html::hello_world';
        $c->stash->{name}     = 'Mister GreenJeans';
        $c->stash->{date}     = 'Today';

        # the DefaultEnd plugin would mean no need for this line
        $c->forward('MyApp::View::Seamstress');
    }

# and in your html::helloworld you can do something like:

 sub process{
     my( $tree, $c, $stash ) = @_;
     
     $tree->look_down( id => 'name' )->replace_content( $stash->{name} );
 }


=head1 DESCRIPTION


This is the Catalyst view class for L<HTML::Seamstress|HTML::Seamstress>. It allows 
templating with proper seperation between code and HTML. This means you can get a 
designer/friend/client/stooge to make your templates for you without having to 
teach them a mini-language!

Your application should define a view class which is a subclass of
this module.  The easiest way to achieve this is using the
F<myapp_create.pl> script (where F<myapp> should be replaced with
whatever your application is called).  This script is created as part
of the Catalyst setup.

    $ script/myapp_create.pl view Seamstress Seamstress

This creates a MyApp::View::Seamstress.pm module in the 
F<lib> directory (again, replacing C<MyApp> with the name of your
application).


Now you can modify your action handlers in the main application and/or
controllers to forward to your view class.  You might choose to do this
in the end() method, for example, to automatically forward all actions
to the Seamstress view class.

    # In MyApp or MyApp::Controller::SomeController

    sub end : Private {
        my( $self, $c ) = @_;
        $c->forward('MyApp::View::Seamstress');
    }

Or you might like to use 
L<Catalyst::Plugin::DefaultEnd|Catalyst::Plugin::DefaultEnd>

..or even
L<Catalyst::Action::RenderView|Catalyst::Action::RenderView>


=head1 CONFIGURATION

The helper app automatically puts the per-application
configuration info in C<MyApp::View::Seamstress>. You configure the
per-request information (e.g. C<< $c->stash->{LOOM} >> and
variables for this template) in your controller.

The two main options which control how View::Seamtress renders HTML are the
LOOM (which is taken from the stash) and optionally the skeleton, which is
stored in the app config.

If you just configure a LOOM then you are most likely using the "plain meat" method described below. If you also configure a skeleton in your config as well then you're using the "meat and skeleton" method. See below for a more detailed discussion of this!

=over

=item * C<< $c->stash->{LOOM} >>

The Seamstress view plugin MUST have a LOOM
to work on or it
will balk with an error:

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{LOOM} = 'html::hello_world';
        $c->stash->{name}     = 'Billy Bob';
        $c->stash->{date}     = 'medjool sahara';
        $c->forward('MyApp::View::Seamstress');
    }


=item * C<< MyApp::View::Seamstress->config->{skeleton} >>

By default this is not set and the HTML output is simply the result of
taking  C<< $c->stash->{LOOM} >>, calling C<new()> to create
an HTML tree and then passing this to C<process()> so that it can rework
the tree.

However, if C<< MyApp::View::Seamstress->config->{skeleton} >> is
set, then both its value and the values of
C<< MyApp::View::Seamstress->config->{meat_pack} >>
and C<< $stash->{LOOM}->fixup() >>
come into effect
as described in L<HTML::Seamstress/"The_meat-skeleton_paradigm">.

Let's take that a little slower: C<< $stash->{LOOM}->fixup() >>
means: given a Seamstress-style Perl class, whose name is
C<< $stash->{LOOM} >>, call the method C<fixup()> in that
class so that it can do a final fixup of the entire HTML that is about
to be shipped back to the client.

=back

The output generated from the LOOM
(and possibly its interaction with a skeleton)
is stored in
C<< $c->response->body >>.


=head2 Other Config Options

=over

=item config->{fixup}

Set this to a coderef to allow the view to change the tree after the main
processing phase. 

=item config->{use_xhtml}

By default the view will generate html 4 style html by calling as_HTML on the
tree object. If you set this to a true value it will generate XHTML style HTML
by calling as_XML on the tree object. See L<HTML::Element> for details for
these methods.

Also note that this won't apply proper HTML doctypes and what-have-you unless
you have them in your original HTML.

=item config->{meat_pack}

This is the subref which is called to pack meat into the skeleton for the meat
skeleton method. Tinker with this to have more creative LOOMS. See "Funny
LOOMs" and the meat/skeleton discussions.

=back

=head2 Funny LOOMs

In the examples so far the LOOM has always been a class name.

If instead LOOM is an object then we'll assume that is a useful HTML::Element style
object and just use that instead of calling C<new> on the LOOM. In this case we'll also not ->delete it at the end of the request so you'll have to do that yourself!

If the LOOM is in fact an ARRAY reference filled with class names we'll send the meat_pack a hash of class names mapped to objects.

=cut


# process()

# C<< eval-requires >> the module specified in C<< $c->stash->{LOOM} >>. 
# Gets the 
# C<HTML::Tree> representation of the file via C<new> and then calls 
# C<< $self->process($c, $c->stash) >> to rewrite the tree. 

sub page2tree {
  my ($self, $c, $page_class, $process_method) = @_;

  $c->log->debug(qq/Rendering template "$page_class"/) if $c->debug;

  $process_method ||= 'process';

  my $page_object;

  # IF we've been passed a page class, build an object:
  if (not ref $page_class) {

      # pull in the page class:
      eval "require $page_class";

      # emit errors if there were problems with the page_class:
      if ($@) {
          my $error = qq/Couldn't load $page_class -- "$@"/;
          $c->log->error($error);
          $c->error($error);
          return 0;
      }

      $page_object = $page_class->new($c); # e.g html::hello_world->new
  }
  # IF we've been passed a page object, just use it:
  else {
      $page_object = $page_class;
  }

  # Run the process hook:
  my $tree;  eval { $tree = $page_object->$process_method($c, $c->stash) } ;

  if ( my $error = $@ ) {

    chomp $error;
    $error = qq/process() failed in "$page_class". Error: "$error"/;
    $c->log->error($error);
    $c->error($error);
    return undef;

  } else {

    return $tree;

  }

}

# Main view process hook:
sub process {
    my ( $self, $c ) = @_;

    my $body_is_skeleton = 0;

    my ($skeleton, $meat, $body) ;

    my $loom = $c->stash->{LOOM};

    # check we actually got a loom to  work with:
    unless ($loom) {
        $c->log->debug('No LOOM specified for rendering') if $c->debug;
        return 0;
    }

    unless ( $c->response->content_type ) {
      $c->response->content_type('text/html; charset=utf-8');
    }


    if (ref($loom) eq 'ARRAY') {
        map {
            $meat->{$_} = $self->page2tree($c, $_);
        } @$loom;
    } else {
      $meat = $body = $self->page2tree($c, $loom);
    }

    #
    # render and pack MyApp::View::Seamstress->config->{skeleton}
    # if defined
    #


    if ($skeleton = $self->config->{skeleton}) {
      $skeleton = $self->page2tree($c, $skeleton);

      $self->config->{meat_pack}->(
          $self, $c, $c->stash, $meat, $skeleton
       );

      $body_is_skeleton = 1;
      $body = $skeleton ;
    }

    # give the main view config an opportunity to twiddle the tree a bit:
    if ( ref $self->config->{fixup} ) {
        $self->config->{fixup}->($body, $c);
    }


    # take the the body and make some REAL html out of it!
    my $response_body;
    if ( $c->config->{use_xhtml} ) {
        $response_body = $body->as_XML( undef, ' ' );
    }
    else {
        $response_body = $body->as_HTML(undef, ' ')
    }

    # stuff the response_body in the response body!
    $c->response->body( $response_body );


    # we delete the body unless our loom ( or skeleton if we have one) is a reference
    # which we take as a sign that the user is doing something more elaborate caching or something..
    unless( (! $body_is_skeleton && ref $loom)  ||  ( $body_is_skeleton && ref $self->config->{skeleton} ) ) {
        $body->delete;
    }

    return 1;
}

;1;
__END__

=head1 The meat-skeleton paradigm

Generally Catalyst::View::Seamstress operates in one of 2 ways: a plain meat
way or a meat-skeleton way.

Plain meat is simple: the View takes C<$c->stash->{LOOM} > and calls
C<new()> and C<process()> on it and stores the result in C<$c->response->body>.

Meat-skeleton is designed to facilitate the way that most web sites are
typically designed:

HTML pages typically have meat and a skeleton. The meat varies from page
to page while the skeleton is fairly (though not completely) 
static. For example, the skeleton of a webpage is usually a header, a
footer, and a navbar. The meat is what shows up when you click on a
link on the page somewhere. While the meat will change with each
click, the skeleton is rather static.


Mason accomodates the meat-skeleton paradigm via
an C<autohandler> and C<< $m->call_next() >>. Template 
accomodates it via its C<WRAPPER> directive.

And Seamstress? Well, here's what you _can_ do:

=over

=item 1 generate the meat, C<$meat>

This is typically what you see in the C<body> part of an HTML page

=item 2 generate the skeleton, C<$skeleton>

This is typically the html, head, and maybe some body 

=item 3 put the meat in the skeleton

=back

So, nothing about this is forced. This is just how I typically do
things and that is why
L<Catalyst::View::Seamstress|Catalyst::View::Seamstress> has support
for this.

=head1 Tips to View Writers

=head2 The order of use base is VERY significant

When your helper module creates C<MyApp::View::Seamstress> it is B<very> 
important for the C<use base> to look this way:

  use base qw(Catalyst::View::Seamstress HTML::Seamstress );

and not this way:

  use base qw(HTML::Seamstress Catalyst::View::Seamstress );

so that certain calls (probably new) get handled properly.

=head2 Getting config information from MyApp and MyApp::View::*

assuming C<Catalyst::View::Seamstress::new()> starts off
like this:

 sub new {
    my $self = shift;
    my $c    = shift;

C<< $self->config >> contains things set in C<MyApp::View::*>.
C<< $c->config >>    contains things set in C<MyApp>

assuming C<Catalyst::View::Seamstress::process()> starts off
similarly:

 sub process {
    my ( $self, $c ) = @_;

C<< $self->config >> contains things set in C<MyApp::View::*>.
C<< $c->config >>    contains things set in C<MyApp>.

There is no automatic merging of the two sources of configuration: you 
have to do that yourself if you want to do it.


=head2 


=head1 SEE ALSO

L<Catalyst>,
L<Catalyst::View>,
L<Catalyst::Helper::View::Seamstress>,
L<HTML::Seamstress>

=head2 A working sample app

The best way to see a fully working Seamstress-style Perl class is to
pull down the working sample app from sourceforge.

A working sample app, which does both simple and
meat-skeleton rendering is available from github:

 git clone   git://github.com/draxil/catalyst--view--seamstress-sample-app.git

=head1 SUPPORT

Email the author or ping him on C<#catalyst> on C<irc.perl.org>

=head1 AUTHORS

Terrence Brannon <metaperl@gmail.com>

With some additional hacking by:

Joe Higton <draxil@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


