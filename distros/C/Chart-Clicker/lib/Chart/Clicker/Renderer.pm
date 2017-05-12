package Chart::Clicker::Renderer;
$Chart::Clicker::Renderer::VERSION = '2.90';
use Moose;

extends 'Graphics::Primitive::Canvas';

# ABSTRACT: Base class for renderers


has 'additive' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'clicker' => (
  is => 'rw',
  isa => 'Chart::Clicker',
  weak_ref => 1
);


has 'context' => ( is => 'rw', isa => 'Str' );

override('prepare', sub {
    my ($self) = @_;

    return 1;
});

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Renderer - Base class for renderers

=head1 VERSION

version 2.90

=head1 SYNOPSIS

  my $renderer = Chart::Clicker::Renderer::Foo->new;

=head1 DESCRIPTION

Chart::Clicker::Renderer represents the plot of the chart.

=head1 ATTRIBUTES

=head2 additive

Read-only value that informs Clicker that this renderer uses the combined ranges
of all the series it charts in total.  Used for 'stacked' renderers like
StackedBar, StackedArea and Line (which will stack if told to).  Note: If you
set a renderer to additive that B<isn't> additive, this will produce wonky
results.

=head2 context

The context to which this Renderer is attached.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
