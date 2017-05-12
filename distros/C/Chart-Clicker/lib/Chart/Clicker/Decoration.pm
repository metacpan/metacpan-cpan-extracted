package Chart::Clicker::Decoration;
$Chart::Clicker::Decoration::VERSION = '2.90';
use Moose;

# ABSTRACT: Shiny baubles!

extends 'Graphics::Primitive::Canvas';


has 'clicker' => ( is => 'rw', isa => 'Chart::Clicker' );

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Decoration - Shiny baubles!

=head1 VERSION

version 2.90

=head1 DESCRIPTION

Chart::Clicker::Decoration is a straight subclass of
L<Graphics::Primitive::Canvas>.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
