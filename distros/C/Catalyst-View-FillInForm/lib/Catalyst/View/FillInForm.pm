package Catalyst::View::FillInForm;

use Moose::Role;
use HTML::FillInForm;

requires 'render';

our $VERSION = '0.03';

=head1 NAME

Catalyst::View::FillInform - Moose role for HTML::FillInform

=head1 SYNOPSIS

In your TT view:

   package 'MyApp::View::TT';
   use Moose;
   extends 'Catalyst::View::TT';
   with 'Catalyst::View::FillInForm';

To use $c->req->parameters to fill in a form:

  $c->stash( fillinform => 1 );

To use some other hashref to fill in a form:

  $c->stash( fillinform => $params );

=head1 DESCRIPTION

This role will use L<HTML::FillInForm> to fill in fields in an HTML
form. 

=cut

around 'render' => sub {
   my $orig = shift;
   my $self = shift;

   my $output = $self->$orig( @_ );
   my $c = shift;

   return $output unless $c->stash->{fillinform};

   my $fillinform = $c->stash->{fillinform} 
               if ref $c->stash->{fillinform} eq 'HASH';
   $fillinform ||= $c->request->parameters;

   return $output unless $fillinform;

   return HTML::FillInForm->fill(
      scalarref => \$output,
      fdat      => $fillinform,
   );
};

=head1 AUTHOR

Gerda Shank (gshank) - C<< <gshank@cpan.org> >>

=head1 COPYRIGHT

This module itself is copyright (c) 2009 Gerda Shank and is licensed under the
same terms as Perl itself.

=cut

no Moose::Role;
1;
