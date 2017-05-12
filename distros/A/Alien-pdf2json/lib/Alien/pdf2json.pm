package Alien::pdf2json;
$Alien::pdf2json::VERSION = '0.002';
use strict;
use warnings;

use parent 'Alien::Base';
use File::Spec;

sub pdf2json_path {
  my ($self) = @_;
  File::Spec->catfile( $self->dist_dir , 'bin', 'pdf2json' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::pdf2json

=head1 VERSION

version 0.002

=head1 METHODS

=head2 pdf2json_path

Returns a C<Str> which contains the absolute path
to the C<pdf2json> binary.

=head1 NAME

Alien::pdf2json - Alien package for the pdf2json PDF extraction library

=head1 LICENSE

pdf2json is licensed under GNU GPL v2.

=head1 SEE ALSO

=over 4

=item * L<pdf2json|https://code.google.com/p/pdf2json/>

=item * L<pdf2json Git repository|https://github.com/flexpaper/pdf2json>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
