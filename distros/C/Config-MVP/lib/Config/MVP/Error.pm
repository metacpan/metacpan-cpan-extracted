package Config::MVP::Error 2.200013;
# ABSTRACT: common exceptions class

use Moose;

has message => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
  lazy     => 1,
  default  => sub { $_->ident },
);

sub as_string {
  my ($self) = @_;
  join qq{\n}, $self->message, "\n", $self->stack_trace;
}

use overload (q{""} => 'as_string');

with(
  'Throwable',
  'Role::Identifiable::HasIdent',
  'Role::HasMessage',
  'StackTrace::Auto',
  'MooseX::OneArgNew' => {
    type     => 'Str',
    init_arg => 'ident',
  },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP::Error - common exceptions class

=head1 VERSION

version 2.200013

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
