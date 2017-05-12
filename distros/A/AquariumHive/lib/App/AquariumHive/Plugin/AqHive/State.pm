package App::AquariumHive::Plugin::AqHive::State;
BEGIN {
  $App::AquariumHive::Plugin::AqHive::State::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::Plugin::AqHive::State::VERSION = '0.003';
use Moo;

our @attributes;

for my $pwm_no (1..6) {
  my $pwm_step = 'pwm'.$pwm_no.'_step';
  push @attributes, $pwm_step;
  has $pwm_step, (
    is => 'rw',
  );
}

sub data {
  my ( $self ) = @_;
  return {map {
    $_, $self->$_()
  } @attributes};
}

sub update {
  my ( $self, $data ) = @_;
  for (@attributes) {
    $self->$_($data->{$_}) if defined $data->{$_};
  }
  return $self;
}

1;

__END__

=pod

=head1 NAME

App::AquariumHive::Plugin::AqHive::State

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
