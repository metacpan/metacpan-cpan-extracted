# ABSTRACT: Role providing common output format options

package App::karr::Role::Output;
our $VERSION = '0.003';
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::Output - Role providing common output format options

=head1 VERSION

version 0.003

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
