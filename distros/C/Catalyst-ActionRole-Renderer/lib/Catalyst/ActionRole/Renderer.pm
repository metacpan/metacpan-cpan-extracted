package Catalyst::ActionRole::Renderer;

use strict;
use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.02';


around execute => sub {
    my $orig = shift;
    my $self = shift;
    my ($controller, $c) = @_;
    
    my $view = $self->attributes->{View}->[0];
    unless ($view) {
        $view = $c->config->{default_view};
    }
    
    my $renderer = sprintf "View::%s", $view;
    $c->log->debug($renderer);

    my $response = $self->$orig(@_);
    $c->forward($renderer);

    return $response;
};

1;

__END__

=encoding utf-8

=head1 NAME

Catalyst::ActionRole::Renderer - Rendering views for Catalyst action

=head1 SYNOPSIS

  package MyApp::Controller::Root;
  use Moose;
  use namespace::autoclean;

  BEGIN { extends 'Catalyst::Controller'; }

  sub lookup :Local :Does(Renderer) :View(TT) {
      my ( $self, $c ) = @_;
      $c->stash->{template} = 'helloworld.tt';
  }


=head1 DESCRIPTION

Catalyst::ActionRole::Renderer is rendering views for Catalyst action.

capable of declaratively rendering views.

=over 2

=item No C<$c.forward> 

=item No C<sub end : ActionClass('RenderView') {}> 

=back


=head1 SEE ALSO


=over 2

=item L<Catalyst::Controller>

=item L<Catalyst::View>

=back

=head1 AUTHOR

Masaaki Saito E<lt>masakyst.public@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Masaaki Saito

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
