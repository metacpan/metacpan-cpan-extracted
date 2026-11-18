package API::Docker::Role::JSONBody;
# ABSTRACT: coerce known boolean keys of a request body to JSON booleans
our $VERSION = '0.006';
use Moo::Role;
use namespace::clean;


sub _json_bools {
  my ($self, $hash, @keys) = @_;
  for my $key (@keys) {
    next unless exists $hash->{$key};
    my $value = $hash->{$key};
    next if ref $value;
    $hash->{$key} = $value ? \1 : \0;
  }
  return $hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::JSONBody - coerce known boolean keys of a request body to JSON booleans

=head1 VERSION

version 0.006

=head1 DESCRIPTION

The Docker Engine type-checks a JSON request body: a field the swagger declares
C<boolean> must arrive as a JSON C<true>/C<false>, and a number in its place is
rejected outright. Measured non-mutating against Docker 29.7.2 (API 1.55),
C<< POST /containers/no-such/exec >> with C<< {"Cmd":["true"],"AttachStdout":1}
>> answers C<400> C<json: cannot unmarshal number into Go struct field ... of
type bool>; Podman 5.8.4 (compat API 1.44) answers C<500> with the same Go
message. The query string is not type-checked, which is why C<1>/C<0> is right
there and wrong here.

Every resource API that forwards a caller HashRef as a JSON body therefore
normalises its own boolean keys on the way out, the same C<\1>/C<\0> encoding
L<API::Docker::API::Exec/start> already used. Which keys are boolean is the
swagger's answer and belongs to each method (the sets are declared beside the
call); this role carries only the mechanical coercion they share.

=head2 _json_bools

    $self->_json_bools(\%body, qw( Tty OpenStdin AttachStdout ));

Coerce the named keys of C<$hash> in place to JSON booleans and return the same
HashRef. A key that is absent is left alone (so an unset option sends nothing),
and a value that is already a reference -- a C<\1>/C<\0> or a
L<JSON::PP::Boolean> -- is left as it is, which keeps the coercion idempotent
and lets a caller who already passes C<< JSON->true >> through untouched. Any
other value becomes C<\1> when true and C<\0> when false, so a caller passing
C<1>/C<0> gets a real JSON boolean on the wire.

This mutates the HashRef it is given, so a caller normalising a nested
sub-object (a C<HostConfig>, say) must hand it a copy it owns rather than the
caller's own nested HashRef.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
