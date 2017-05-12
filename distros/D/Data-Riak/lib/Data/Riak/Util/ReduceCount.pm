package Data::Riak::Util::ReduceCount;
{
  $Data::Riak::Util::ReduceCount::VERSION = '2.0';
}

use strict;
use warnings;

use Moose;

extends 'Data::Riak::MapReduce::Phase::Reduce';

has '+language' => (
    default => 'erlang'
);

has '+function' => (
    default => 'reduce_count_inputs'
);

has '+arg' => (
    default => 'filter_notfound'
);

has '+module' => (
    default => 'riak_kv_mapreduce'
);

no Moose;

1;

__END__

=pod

=head1 NAME

Data::Riak::Util::ReduceCount

=head1 VERSION

version 2.0

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
