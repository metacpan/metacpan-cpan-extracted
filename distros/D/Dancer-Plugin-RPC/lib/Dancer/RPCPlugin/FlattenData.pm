package Dancer::RPCPlugin::FlattenData;
use warnings;
use strict;
use Scalar::Util 'blessed';

use Exporter 'import';
our @EXPORT = qw/ flatten_data /;

sub flatten_data {
    my $to_flatten = shift;

    my $ref_check = ref($to_flatten);
    if (blessed($to_flatten)) {
        $ref_check = $to_flatten->isa('HASH')
            ? 'HASH'
            : $to_flatten->isa('ARRAY')
                ? 'ARRAY'
                : 'SCALAR';
    }

    if ($ref_check eq 'HASH') {
        my $flat = {
            map {
                $_ => flatten_data($to_flatten->{$_})
            } keys %$to_flatten
        };
        return $flat;
    }
    elsif ($ref_check eq 'ARRAY') {
        my $flat = [
            map { flatten_data($_) } @$to_flatten
        ];
        return $flat;
    }
    elsif ($ref_check eq 'SCALAR') {
        return $$to_flatten;
    }
    else {
        return $to_flatten;
    }
}

1;

=head1 NAME

Dancer::RPCPlugin::DataFlatten - Simple routine to flatten (blessed) data

=head1 SYNOPSIS

  use Dancer::RPCPlugin::DataFlatten;
  my $data = bless({some => 'data'}, 'AnyClass');
  my $flat = flatten_data($data); # {some => 'data'}

=head1 DESCRIPTION

=head2 flatten_data($any_data)

This makes a deep-copy of the datastructure presented.

=head3 Arguments

Only the first argument is considered.

=head3 Response

A deep copy of the data structure presented.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>.

=cut
