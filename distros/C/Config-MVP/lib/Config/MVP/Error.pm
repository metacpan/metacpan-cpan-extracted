package Config::MVP::Error;
# ABSTRACT: common exceptions class
$Config::MVP::Error::VERSION = '2.200010';
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

version 2.200010

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
