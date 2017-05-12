package Apache2::Controller::X;
use warnings FATAL => 'all';
use strict;

=head1 NAME

Apache2::Controller::X - Exception::Class hierarchy for Apache2::Controller

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

 package MyApp::C::Foo;
 use base qw( Apache2::Controller MyApp::Blabber ); 
 use Apache2::Controller::X;
 # ...
 sub some_page_controller_method {
    my ($self, @path_args) = @_;
    $self->print( $self->blabber() || a2cx "Cannot blabber: $OS_ERROR" );
 }

 # or subclass and extend the errors...
 
 package MyApp::X;
 use base qw( Apache2::Controller::X );
 use Exception::Class (
     'MyApp::X' => { 
         isa => 'Apache2::Controller::X',
         fields => [qw( message status dump action )],
     },
     alias => 'myx',
 );

 package MyApp::C::Bar;
 use base qw( Apache2::Controller );
 use Apache2::Const -compile => qw( :http );
 use MyApp::X;
 # ...
 sub page_controller_method {
     myx  message => q{ You're not supposed to be here. },
          status => Apache2::Const::FORBIDDEN,
          action => sub {"not sure how you'd implement this actually"},
          dump => {
            this    => q{structure will get YAML::Syck::Dump'd},
            that    => [qw( to the error log )],
          };
 }

TODO: when $X is intercepted by handler() in each of the controller layers,
attach it to pnotes.

=head1 DESCRIPTION

Hierarchy of L<Exception::Class> objects for L<Apache2::Controller>.
All are subclasses of Apache2::Controller::X.

=head1 FIELDS

All Apache2::Controller::X exceptions implement three fields:

=head2 message

Required.
The standard L<Exception::Class> message field.  If you call C<throw()>
or the alias C<a2cx()>
with only one argument, a string, then this gets set as the message
field, which is displayed when the object is referred to in string context.

 eval { a2cx "booyeah" };
 if (my $X = Exception::Class->caught('Apache2::Controller::X')) {
     warn "my exception 'message' was '$X'\n";
     warn $X->trace;
 }

=head2 status

This can be set to an L<Apache2::Const/:http> constant, which
will then be set as the status for the request.

 a2cx message => "oh no!",
      status => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;

=head2 status_line

Combined with status, when intercepted by L<Apache2::Controller/handler>
this sets a custom message with L<Apache2::RequestRec/status_line>.

 a2cx message => "Warp injection coil failure in unit 3-A-73",
     status => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR,
     status_line => "Turbulence ahead. Please buckle your safety belts.";

This differentiation can be used to display technical information
in the log while giving a nice message to the user.

If L<Apache2::Controller::Render::Template/error> is used,
status_line is preferentially used to translate the error code,
otherwise it uses L<HTTP::Status/status_message>.

=head2 dump

An arbitrary data structure which Apache2::Controller will send
through L<YAML::Syck> Dump() when printing to the error log.

=head1 SUBCLASSES

=head2 Apache2::Controller::X

The basic exception object that implements the three basic fields.

After abandoning redirects, I have no use for any subclasses.
Should not re-invent the wheel, after all.  Just set the
outgoing location header and return REDIRECT from a controller
if you want to do that.  Or other actions should be done.

=cut

use base qw( Exporter );
our @EXPORT = qw( a2cx );

use Exception::Class (
    'Apache2::Controller::X' => { 
        alias   => 'a2cx',
        fields  => [qw( message dump status status_line )],
    },
);  # whoopdeedoo

=head1 METHODS

=head2 Fields

This is the Fields() method provided by L<Exception::Class>.
For some reason the pod test wants this method enumerated.

=head1 SEE ALSO

L<Exception::Class>

L<Apache2::Controller>

L<Apache2::Controller::NonResponseBase>

L<Apache2::Controller::NonResponseRequest>

=head1 AUTHOR

Mark Hedges, C<< <hedges ||at formdata.biz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut


1;
