package Data::AnyXfer::Elastic::Import::Storage::TempDirectory;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);



extends 'Data::AnyXfer::Elastic::Import::Storage::Directory';


=head1 NAME

Data::AnyXfer::Elastic::Import::Storage::TempDirectory -
Filesystem temp directory-based import storage

=head1 DESCRIPTION

Descriptive subclass of
L<Data::AnyXfer::Elastic::Import::Storage::Directory>, for working on
a temp directory.

=head1 SEE ALSO

L<Data::AnyXfer::Elastic::Import::Storage::Directory>,
L<Data::AnyXfer::Elastic::Import::Storage>

=cut


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

