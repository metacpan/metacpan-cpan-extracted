use v5.12.0;
use warnings;
package Data::Rx::CoreType::arr 0.200008;
# ABSTRACT: the Rx //arr type

use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub subname { 'arr' }

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {length=>1, contents=>1,
                                                   skip=>1});

  Carp::croak("no contents schema given")
    unless $arg->{contents} and (ref $arg->{contents} || 'HASH' eq 'HASH');

  my $guts = {
    content_check => $rx->make_schema($arg->{contents}),
  };

  $guts->{length_check} = Data::Rx::Util->_make_range_check($arg->{length})
    if $arg->{length};

  $guts->{skip} = $arg->{skip} || 0;

  return $guts;
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'ARRAY') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not an arrayref",
      value   => $value,
    });
  }

  my @subchecks;

  if ($self->{length_check} and
      ! $self->{length_check}->(@$value - $self->{skip})) {
    push @subchecks,
      $self->new_fail({
        error   => [ qw(size) ],
        size    => 0 + @$value,  # note: actual size, not size - skip
        message => "number of entries is outside permitted range",
        value   => $value,
      });
  }

  for my $i ($self->{skip} .. $#$value) {
    push @subchecks, [
      $value->[$i],
      $self->{content_check},
      {
        data_path   => [ [ $i, 'index' ] ],
        check_path  => [ [ 'contents', 'key'] ],
      },
    ];
  }

  $self->perform_subchecks(\@subchecks);

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType::arr - the Rx //arr type

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
