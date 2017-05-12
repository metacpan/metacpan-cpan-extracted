package Chart::Clicker::Decoration::Glass;
$Chart::Clicker::Decoration::Glass::VERSION = '2.90';
use Moose;

extends 'Chart::Clicker::Decoration';

# ABSTRACT: Under-chart gradient decoration

use Graphics::Color::RGB;
use Graphics::Primitive::Operation::Fill;
use Graphics::Primitive::Paint::Solid;


has 'background_color' => (
    is => 'rw',
    isa => 'Graphics::Color::RGB',
    default => sub {
        Graphics::Color::RGB->new(
            red => 1, green => 0, blue => 0, alpha => 1
        )
    }
);


has 'glare_color' => (
    is => 'rw',
    isa => 'Graphics::Color::RGB',
    default => sub {
       Graphics::Color::RGB->new(
            red => 1, green => 1, blue => 1, alpha => 1
        )
    },
);

override('finalize', sub {
    my ($self) = @_;

    my $twentypofheight = $self->height * .20;

    $self->move_to(1, $twentypofheight);

    $self->rel_curve_to(
        0, 0,
        $self->width / 2, $self->height * .30,
        $self->width, 0
    );

    $self->line_to($self->width, 0);
    $self->line_to(0, 0);
    $self->line_to(0, $twentypofheight);

    my $fillop = Graphics::Primitive::Operation::Fill->new(
        paint => Graphics::Primitive::Paint::Solid->new(
            color => $self->glare_color
        )
    );
    $self->do($fillop);
});

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Decoration::Glass - Under-chart gradient decoration

=head1 VERSION

version 2.90

=head1 DESCRIPTION

A glass-like decoration.

=head1 ATTRIBUTES

=head2 background_color

Set/Get the background L<color|Graphics::Color::RGB> for this glass.

=head2 glare_color

Set/Get the glare L<color|Graphics::Color::RGB> for this glass.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
