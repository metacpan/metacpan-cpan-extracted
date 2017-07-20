use strict;
use warnings;
package AI::PredictionClient::Testing::PredictionLoopback;
$AI::PredictionClient::Testing::PredictionLoopback::VERSION = '0.03';

# ABSTRACT: A loopback interface for client testing and development

use 5.010;
use Data::Dumper;
use Moo;

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if (@_ == 1 && !ref $_[0]) {
    return $class->$orig(server_port => $_[0]);
  } else {
    return $class->$orig(@_);
  }
};

has server_port => (is => 'rw',);

sub callPredict {
  my ($self, $request_data) = @_;

  my $test_return01
    = '{"outputs":{"classes":{"dtype":"DT_STRING","tensorShape":{"dim":[{"size":"1"},{"size":"6"}]},"stringVal":["bG9vcGJhY2sgdGVzdCBkYXRhCg==","bWlsaXRhcnkgdW5pZm9ybQ==","Ym93IHRpZSwgYm93LXRpZSwgYm93dGll","bW9ydGFyYm9hcmQ=","c3VpdCwgc3VpdCBvZiBjbG90aGVz","YWNhZGVtaWMgZ293biwgYWNhZGVtaWMgcm9iZSwganVkZ2UncyByb2Jl"]},"scores":{"dtype":"DT_FLOAT","tensorShape":{"dim":[{"size":"1"},{"size":"6"}]},"floatVal":[9.8765432,7.8828206,6.8400025,6.4891167,5.6658578,5.538981]}}}';

  my $test_return02
    = '{"outputs":{"classes":{"dtype":"DT_STRING","tensorShape":{"dim":[{"size":"1"},{"size":"5"}]},"stringVal":["bG9hZCBpdAo=","Y2hlY2sgaXQK","cXVpY2sgLSByZXdyaXRlIGl0Cg==","dGVjaG5vbG9naWMK","dGVjaG5vbG9naWMK"]},"scores":{"dtype":"DT_FLOAT","tensorShape":{"dim":[{"size":"1"},{"size":"5"}]},"floatVal":[9.8765432,7.8828206,6.8400025,6.4891167,5.6658578]}}}';

  my $return_ser = '{"Status": "OK", ';
  $return_ser .= '"StatusCode": "42", ';
  $return_ser .= '"StatusMessage": "", ';
  $return_ser .= '"DebugRequestLoopback": ' . $request_data . ', ';

  if ($self->server_port eq 'technologic:2004') {
    $return_ser .= '"Result": ' . $test_return02 . '}';
  } else {
    $return_ser .= '"Result": ' . $test_return01 . '}';
  }

  return $return_ser;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::PredictionClient::Testing::PredictionLoopback - A loopback interface for client testing and development

=head1 VERSION

version 0.03

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
