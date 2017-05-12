package DigitalX::AqHive::pH;
BEGIN {
  $DigitalX::AqHive::pH::AUTHORITY = 'cpan:GETTY';
}
$DigitalX::AqHive::pH::VERSION = '0.003';
use Digital::Driver;

with qw(
  DigitalX::AqHive
);

# has delta_0 => (
#   is => 'lazy',
# );

# sub _build_delta_0 { 54.20 }

# has delta_20 => (
#   is => 'lazy',
# );

# sub _build_delta_20 { 58.16 }

has delta_25 => (
  is => 'lazy',
);

sub _build_delta_25 { 59.16 }

# has delta_grad => (
#   is => 'lazy',
# );

# sub _build_delta_grad { 0.1984 }

overload_to pH => sub {
  my ( $self, $val ) = @_;
  if ($val > 0) {
    return 7 - ( $val / $self->delta_25 );
  } elsif ($val < 0) {
    return 7 + ( abs() / $self->delta_25 );
  } else {
    return 7;
  }
}, 'corrected';

1;

__END__

=pod

=head1 NAME

DigitalX::AqHive::pH

=head1 VERSION

version 0.003

=head1 DESCRIPTION

B<IN DEVELOPMENT, DO NOT USE YET>

See L<http://aquariumhive.com/> for now.

=head1 SUPPORT

IRC

  Join #AquariumHive on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  https://github.com/homehivelab/aquariumhive
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/homehivelab/aquariumhive/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
