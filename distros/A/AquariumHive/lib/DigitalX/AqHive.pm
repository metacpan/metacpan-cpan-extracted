package DigitalX::AqHive;
BEGIN {
  $DigitalX::AqHive::AUTHORITY = 'cpan:GETTY';
}
$DigitalX::AqHive::VERSION = '0.003';
use Moo::Role;

has adc_fix => (
  is => 'lazy',
);

sub _build_adc_fix { 4.8828125 }

has fixed => (
  is => 'lazy',
);

sub _build_fixed { $_[0]->in * $_[0]->adc_fix }

has correct_sens => (
  is => 'lazy',
);

sub _build_correct_sens { 2500 }

has corrected => (
  is => 'lazy',
);

sub _build_corrected { $_[0]->correct_sens - $_[0]->fixed }

# sub _build_correct_sens { 512 }

# has corrected => (
#   is => 'lazy',
# );

# sub _build_corrected { ( $_[0]->correct_sens - $_[0]->in ) * $_[0]->adc_fix }

1;

__END__

=pod

=head1 NAME

DigitalX::AqHive

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
