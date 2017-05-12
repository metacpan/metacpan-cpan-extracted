package Chart::Clicker::Renderer::Bubble;
$Chart::Clicker::Renderer::Bubble::VERSION = '2.90';
use Moose;

# ABSTRACT: Bubble render

extends 'Chart::Clicker::Renderer::Point';


override('draw_point', sub {
    my ($self, $x, $y, $series, $count) = @_;

    my $shape = $self->shape->scale($series->get_size($count));
    $shape->origin(Geometry::Primitive::Point->new(x => $x, y => $y));
    $self->path->add_primitive($shape);
});

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Renderer::Bubble - Bubble render

=head1 VERSION

version 2.90

=head1 SYNOPSIS

  my $pr = Chart::Clicker::Renderer::Bubble->new({
    shape => Geometry::Primitive::Circle->new({
        radius => 3
    })
  });

=head1 DESCRIPTION

Chart::Clicker::Renderer::Bubble is a subclass of the Point renderer where
the points' radiuses are determined by the size value of a Series::Size.

Note: B<This renderer requires you to use a
Chart::Clicker::Data::Series::Size>.

=for HTML <p><img src="http://gphat.github.com/chart-clicker/static/images/examples/bubble.png" width="500" height="250" alt="Bubble Chart" /></p>

=head1 METHODS

=head2 draw_point

Called for each point.  Implemented as a separate method so that subclasses
such as Bubble may override the drawing.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
