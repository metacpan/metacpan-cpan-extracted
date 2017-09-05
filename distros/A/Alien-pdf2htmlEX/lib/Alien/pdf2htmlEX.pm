package Alien::pdf2htmlEX;
# ABSTRACT: Alien package for the pdf2htmlEX PDF-to-HTML conversion tool.
$Alien::pdf2htmlEX::VERSION = '0.001';
use strict;
use warnings;

use base qw( Alien::Base );
use Role::Tiny::With qw( with );

with 'Alien::Role::Dino';

use File::Spec;

sub pdf2htmlEX_path {
	my ($self) = @_;
	File::Spec->catfile( File::Spec->rel2abs($self->dist_dir) , qw(bin pdf2htmlEX) );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::pdf2htmlEX - Alien package for the pdf2htmlEX PDF-to-HTML conversion tool.

=head1 VERSION

version 0.001

=head1 METHODS

=head2 pdf2htmlEX_path

Returns a C<Str> which contains the absolute path
to the C<pdf2htmlEX> binary.

=head1 SEE ALSO

L<pdf2htmlEX|http://coolwanglu.github.io/pdf2htmlEX/>

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Alien-pdf2htmlEX/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
