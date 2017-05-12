package DBIx::DBHResolver::Strategy::RoundRobin;
use strict;
use warnings;
our $VERSION = '0.02';

sub connect_info {
    my ($class, $resolver, $label, ) = @_;

    $resolver->config->{round_robin}->{$label} ||= $resolver->cluster($label);

    my $node_label = shift @{$resolver->config->{round_robin}->{$label}};

    push @{$resolver->config->{round_robin}->{$label}}, $node_label;

    $node_label;
}

1;

__END__

=head1 NAME

DBIx::DBHResolver::Strategy::RoundRobin - round robin sharding strategy.

=head1 SYNOPSIS

  use DBIx::DBHResolver;

  DBIx::DBHResolver->load('/path/to/config.yaml');

  my $conn_info = DBIx::DBHResolver->connect_info('SLAVE', +{ strategy => 'RoundRobin' });

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

L<DBIx::DBHResolver>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
