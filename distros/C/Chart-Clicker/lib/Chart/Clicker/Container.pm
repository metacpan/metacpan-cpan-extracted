package Chart::Clicker::Container;
$Chart::Clicker::Container::VERSION = '2.90';
use Moose;

extends 'Graphics::Primitive::Container';

with 'Graphics::Primitive::Oriented';

# ABSTRACT: Base class that extends Graphics::Primitive::Container


has 'clicker' => (
    is => 'rw',
    isa => 'Chart::Clicker'
);

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Container - Base class that extends Graphics::Primitive::Container

=head1 VERSION

version 2.90

=head1 DESCRIPTION

Chart::Clicker::Container is a subclass of L<Graphics::Primitive::Container>.

=head1 ATTRIBUTES

=head2 clicker

Set/Get this component's clicker object.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
