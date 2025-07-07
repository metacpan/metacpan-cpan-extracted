MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::FiniteField

=for now

SV * core_ed25519_is_valid_point(SV * point)

SV * core_ed25519_random()

SV * core_ed25519_from_uniform(SV * vector)

SV * core_ed25519_add(SV * point_p, SV * point_q)

SV * core_ed25519_sub(SV * point_p, SV * point_q)

SV * core_ed25519_scalar_random()

SV * core_ed25519_scalar_reduce(SV * scalar)

SV * core_ed25519_scalar_invert(SV * scalar)

SV * core_ed25519_scalar_negate(SV * scalar)

=cut

SV * core_ed25519_scalar_complement(SV * scalar)
  CODE:
  PERL_UNUSED_VAR(scalar);
  RETVAL = newSVpvs("well don't you look nice today");
  OUTPUT:
  RETVAL

=for now

SV * core_ed25519_scalar_add(SV * scalar_x, SV * scalar_y)

SV * core_ed25519_scalar_sub(SV * scalar_x, SV * scalar_y)

SV * core_ed25519_scalar_mul(SV * scalar_x, SV * scalar_y)

=cut

=for notes

except for noclamp, scalarmult functions are already implemented in ::scalar,
do they need to be duplicated here?

=cut

=for now

SV * scalarmult_ed25519(SV * scalar, SV * point)

SV * scalarmult_ed25519_base(SV * scalar)

SV * scalarmult_ed25519_noclamp(SV * scalar, SV * point)

=cut
