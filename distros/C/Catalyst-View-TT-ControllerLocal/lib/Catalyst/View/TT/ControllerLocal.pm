package Catalyst::View::TT::ControllerLocal;

use strict;
use base 'Catalyst::View::TT';
use Data::Dumper;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors('include_path');





=head1 NAME

Catalyst::View::TT::ControllerLocal - Catalyst TT View with template
names relative to the Controller



=head1 SYNOPSIS


=head2 Use the helper to create a View class for your

    script/myapp_create.pl view TT TTControllerLocal

This creates the MyApp::View::TT class.


=head2 Forward to the View like you normally would

    #Meanwhile, maybe in a private end action
    if(!$c->res->body) {
        if($c->stash->{template}) {
            $c->forward('MyApp::View::TT');
        } else {
            die("No output method!\n");
        }
    }





=head1 DESCRIPTION

Catalyst::View::TT::ControllerLocal is like a normal Catalyst TT View,
but with template file names relative to the current Controller. So
with a set of templates like:

 ./root/edit.html
 ./root/add.html
 ./root/Frobniz/add.html

and an action C<add> in the Controller C<MyApp::Controller::Frobniz>,
you set C<$c-E<gt>stash-E<gt>{template}> to C<add.html> in order for
it to pick up the C<./root/frobbiz/add.html> template.

Setting the C<$c-E<gt>stash-E<gt>{template}> from Controller
C<MyApp::Controller::Bogon> would instead pick the default template in
C<./root/add.html> (since there is no Bogon subdirectory under root).

In addition, since there is no file C<edit.html> except in the Frobniz
directory, C::V::TT::ControllerLocal will default to looking for
C<edit.html> in ./root/ and ./root/base (or whatever you set
MyApp->config->{INCLUDE_PATH} to).

=cut



=head1 METHODS

=head2 new

The constructor for the TT view. Sets up the template provider, and
reads the application config.

=cut
sub new {
    my ($class, $c, $arguments) = @_;

    my $root = $c->config->{root};

    #Note: Tight coupling with the parent class: Repeat of the
    #default and overridden values
    my $include_path =    
            $arguments->{INCLUDE_PATH} ||
            $class->config->{INCLUDE_PATH} ||
            [ $root, "$root/base" ];
    $arguments->{INCLUDE_PATH} = $include_path;
    
    my $self = $class->SUPER::new($c, $arguments);
    $self->include_path($include_path);

    return($self);
}





=head2 process

Render the template specified in C<$c-E<gt>stash-E<gt>{template}> or
C<$c-E<gt>request-E<gt>match>.

The template file name is fetched from one of the Template's
include_paths. The name of the current action's namespace is prepended
to this list, so for the action C<edit> in
C<MyApp::Controller::Frobniz>, the prepended directory is
C<./root/frobniz>.

Example: If C<$c-E<gt>stash-E<gt>{template}> = C<edit.html> you can put a
specific template in ./root/myaction/edit.html, or a general template
in ./root/base/edit.html or ./root/edit.html.

If the action is MyApp::Controller::MyAction, the specific template is
used. If the action is MyApp::Controller::MyOtherAction, the
./root/base/edit.html is used.

See also: L<Catalyst::View::TT>::process.

=cut
sub process {
    my ($self, $c) = @_;

    my $dir_action = $c->path_to('root', $c->namespace || "base");

    unshift(@{$self->include_path}, $dir_action);
    eval { $self->SUPER::process($c); };
    shift(@{$self->include_path});
    $@ and die;

    return 1;
}

        



=head1 AUTHOR

Johan Lindstrom <johanl ÄT cpan.org>



=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
