package Chart::Clicker::Decoration::Plot;
$Chart::Clicker::Decoration::Plot::VERSION = '2.90';
use Moose;

# ABSTRACT: Area on which renderers draw

use Layout::Manager::Axis;
use Layout::Manager::Single;

use Chart::Clicker::Decoration::Grid;

extends 'Chart::Clicker::Container';


has 'clicker' => (
    is => 'rw',
    isa => 'Chart::Clicker',
);


has 'grid' => (
    is => 'rw',
    isa => 'Chart::Clicker::Decoration::Grid',
    default => sub {
        Chart::Clicker::Decoration::Grid->new( name => 'grid' )
    }
);


has '+layout_manager' => (
    default => sub { Layout::Manager::Axis->new }
);


has 'render_area' => (
    is => 'rw',
    isa => 'Chart::Clicker::Container',
    default => sub {
        Chart::Clicker::Container->new(
            name => 'render_area',
            layout_manager => Layout::Manager::Single->new
        )
    }
);

override('prepare', sub {
    my ($self) = @_;

    # TODO This is also happening in Clicker.pm
    foreach my $c (@{ $self->components }) {
        $c->clicker($self->clicker);
    }

    # TODO This is kinda messy...
    foreach my $c (@{ $self->render_area->components }) {
        $c->clicker($self->clicker);
    }

    super;
});

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Decoration::Plot - Area on which renderers draw

=head1 VERSION

version 2.90

=head1 DESCRIPTION

A Component that handles the rendering of data via Renderers.  Also
handles rendering the markers that come from the Clicker object.

=head1 ATTRIBUTES

=head2 background_color

Set/Get this Plot's background color.

=head2 border

Set/Get this Plot's border.

=head2 grid

Set/Get the Grid component used on this plot.

=head2 layout_manager

Set/Get the layout manager for this plot.  Defaults to
L<Layout::Manager::Axis>.

=head2 render_area

Set/Get the container used to render within.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
