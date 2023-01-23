use v5.12.0;
use warnings;
package Data::Rx::CoreType::any 0.200008;
# ABSTRACT: the Rx //any type

use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { of  => 1});

  my $guts = {};

  if (my $of = $arg->{of}) {
    Carp::croak("invalid 'of' argument to //any") unless
      Scalar::Util::reftype $of eq 'ARRAY' and @$of;

    $guts->{of} = [ map {; $rx->make_schema($_) } @$of ];
  }

  return $guts;
}

sub assert_valid {
  return 1 unless $_[0]->{of};

  my ($self, $value) = @_;

  my @failures;
  for my $i (0 .. $#{ $self->{of} }) {
    my $check = $self->{of}[ $i ];
    return 1 if eval { $check->assert_valid($value) };

    my $failure = $@;
    $failure->contextualize({
      type       => $self->type,
      check_path => [ [ 'of', 'key'], [ $i, 'index' ] ],
    });

    push @failures, $failure;
  }

  $self->fail({
    error    => [ qw(none) ],
    message  => "matched none of the available alternatives",
    value    => $value,
    failures => \@failures,
  });
}

sub subname   { 'any' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType::any - the Rx //any type

=head1 VERSION

version 0.200008

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
