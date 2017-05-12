package Catalyst::View::HTML::Embperl;

use strict;
use base 'Catalyst::Base';
use HTML::Embperl;

our $VERSION = '0.01';

=head1 NAME

Catalyst::View::HTML::Embperl - HTML::Embperl View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view HTML::Embperl HTML::Embperl

    # lib/MyApp/View/HTML/Embperl.pm
    package MyApp::View::HTML::Embperl;

    use base 'Catalyst::View::HTML::Embperl';

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::HTML::Embperl');


=head1 DESCRIPTION

This is the C<HTML::Embperl> view class. Your subclass should inherit from this
class.

=head2 METHODS

=over 4

=item process

Renders the template specified in C<< $c->stash->{template} >> or C<<
$c->request->match >>.
Template params FDAT are set up from the contents of C<< $c->req->parameters >> first,
then overwritten by C<< $c->stash >>.
Global variables C<base> set to C<< $c->req->base >>,
C<name> to C<< $c->config->{name} >> and C<c> to Catalyst context.
Output is stored in C<< $c->response->body >>.

=cut

sub process {
  my ( $self, $c ) = @_;

  my $filename = $c->stash->{template} || $c->req->match;

  unless ( $filename ) {
    $c->log->debug('No template specified for rendering') if $c->debug;
    return 0;
  }

  $c->log->debug( "Rendering template \"$filename\"" ) if $c->debug;

  $Catalyst::View::HTML::Embperl::T::base = $c->req->base;
  $Catalyst::View::HTML::Embperl::T::name = $c->config->{name};
  $Catalyst::View::HTML::Embperl::T::c = $c;

  my $body;

  eval { 
    HTML::Embperl::Execute( {
      'path'      => $c->config->{root},
      'inputfile' => $filename,
      'package'   => 'Catalyst::View::HTML::Embperl::T',
      'fdat'      => { %{$c->req->parameters}, %{$c->stash} },
      'output'    => \$body
    } );
  };

  if ( my $error = $@ ) {
    chomp $error;
    $error = "Couldn't render template \"$filename\". Error: \"$error\"";
    $c->log->error( $error );
    $c->error( $error );
    return 0;
  }

  unless ( $c->response->headers->content_type ) {
    $c->res->headers->content_type( 'text/html' );
  }

  $c->response->body( $body );

  return 1;
}

=head1 SEE ALSO

L<HTML::Embperl>, L<Catalyst>, L<Catalyst::Base>.

=head1 AUTHOR

Aldo LeTellier, C<aldoletellier@bigfoot.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
