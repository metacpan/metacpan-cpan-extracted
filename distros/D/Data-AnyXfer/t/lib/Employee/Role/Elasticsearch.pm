package Employee::Role::Elasticsearch;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::autoclean;

use Employee::IndexInfo;

has index_info => (
    is       => 'ro',
    isa      => InstanceOf['Employee::IndexInfo'],
    lazy     => 1,
    default  => sub { return Employee::IndexInfo->new; }
);

with 'Data::AnyXfer::Elastic::Role::Project';

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
