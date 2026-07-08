# ABSTRACT: Role providing common output format options

package App::karr::Role::Output;
our $VERSION = '0.400';
use Moo::Role;
use MooX::Options;


option json => (
  is => 'ro',
  doc => 'JSON output',
);

option compact => (
  is => 'ro',
  doc => 'Compact output',
);

sub print_json {
  my ($self, $data) = @_;
  require JSON::MaybeXS;
  print JSON::MaybeXS::encode_json($data) . "\n";
}


sub print_json_results {
  my ($self, @results) = @_;
  return unless $self->json;
  $self->print_json(@results == 1 ? $results[0] : \@results);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::Output - Role providing common output format options

=head1 VERSION

version 0.400

=head1 DESCRIPTION

Small role that adds shared output options for commands with alternate
renderings and provides a JSON printer used throughout the CLI.

=head2 print_json_results

  $self->print_json_results(@results);

Emits a batch of per-item result hashes as JSON when C<--json> is active, and
is a no-op otherwise. A single result is rendered as a bare JSON object and
multiple results as a JSON array, matching the output convention shared by the
C<move>, C<edit>, C<delete>, and C<archive> commands.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
