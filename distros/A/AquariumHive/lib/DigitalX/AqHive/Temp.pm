package DigitalX::AqHive::Temp;
BEGIN {
  $DigitalX::AqHive::Temp::AUTHORITY = 'cpan:GETTY';
}
$DigitalX::AqHive::Temp::VERSION = '0.003';
use Digital::Driver;

with qw(
  DigitalX::AqHive
);

to K => sub { ( $_ - 25 ) / 10 }, 'fixed';

overload_to C => sub { $_ - 273.15 }, 'K';

to F => sub { ( $_ * ( 9 / 5 ) ) - 459.67 }, 'K';

1;

__END__

=pod

=head1 NAME

DigitalX::AqHive::Temp

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
