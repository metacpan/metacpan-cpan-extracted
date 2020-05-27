package Employee::Search;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use namespace::autoclean;

with 'Employee::Role::Elasticsearch';

__PACKAGE__->meta->make_immutable;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

