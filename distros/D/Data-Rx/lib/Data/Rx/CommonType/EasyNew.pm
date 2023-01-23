use v5.12.0;
use warnings;
package Data::Rx::CommonType::EasyNew 0.200008;
# ABSTRACT: base class for core Rx types, with some defaults

use parent 'Data::Rx::CommonType';

use Carp ();

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak "$class does not take check arguments" if %$arg;

  return {};
}

sub new_checker {
  my ($class, $arg, $rx, $type) = @_;

  my $guts = $class->guts_from_arg($arg, $rx, $type);

  # Carp::confess "underscore-led entry in guts!" if grep /\A_/, keys %$guts;
  $guts->{_type} = $type;
  $guts->{_rx}   = $rx;

  bless $guts => $class;
}

sub type { $_[0]->{_type} }

sub rx { $_[0]->{_rx} }

#pod =pod
#pod
#pod =head1 NOTE
#pod
#pod For examples on how to subclass this, see L<Data::Rx::Manual::CustomTypes>.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CommonType::EasyNew - base class for core Rx types, with some defaults

=head1 VERSION

version 0.200008

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 NOTE

For examples on how to subclass this, see L<Data::Rx::Manual::CustomTypes>.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
