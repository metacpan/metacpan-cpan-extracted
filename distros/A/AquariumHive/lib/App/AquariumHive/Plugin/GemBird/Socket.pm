package App::AquariumHive::Plugin::GemBird::Socket;
BEGIN {
  $App::AquariumHive::Plugin::GemBird::Socket::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::Plugin::GemBird::Socket::VERSION = '0.003';
use Moo;

with qw(
  App::AquariumHive::Role
);

use String::Trim;

has socket_id => (
  is => 'lazy',
);

sub _build_socket_id {
  my ( $self ) = @_;
  my $socket_id = $self->serial_number;
  $socket_id =~ s/://g;
  return $socket_id;
}

has serial_number => (
  is => 'ro',
  required => 1,
);

has device_type => (
  is => 'ro',
  required => 1,
);

sub set {
  my ( $self, $no, $state ) = @_;
  my $function = $state ? 'o' : 'f';
  my $cmd = 'sudo sispmctl -D'.$self->serial_number.' -'.$function.$no;
  $self->run_cmd($cmd);
}

sub state {
  my ( $self ) = @_;
  my @lines = $self->run_cmd('sudo sispmctl -D'.$self->serial_number.' -gall');
  my %state;
  for (@lines) {
    if ($_ =~ m/^Status of outlet (\d+):(.+)$/) {
      my $no = $1;
      my $onoff = trim($2);
      $state{$no} = $onoff eq 'on' ? 1 : 0;
    }
  }
  return \%state;
}

1;

__END__

=pod

=head1 NAME

App::AquariumHive::Plugin::GemBird::Socket

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
