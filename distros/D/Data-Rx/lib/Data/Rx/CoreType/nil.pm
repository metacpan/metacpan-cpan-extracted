use strict;
use warnings;
package Data::Rx::CoreType::nil;
# ABSTRACT: the Rx //nil type
$Data::Rx::CoreType::nil::VERSION = '0.200007';
use parent 'Data::Rx::CoreType';

sub assert_valid {
  my ($self, $value) = @_;

  return 1 if ! defined $value;

  $self->fail({
    error   => [ qw(type) ],
    message => "found value is defined",
    value   => $value,
  });
}

sub subname   { 'nil' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType::nil - the Rx //nil type

=head1 VERSION

version 0.200007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
