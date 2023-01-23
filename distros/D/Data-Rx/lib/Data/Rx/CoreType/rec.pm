use v5.12.0;
use warnings;
package Data::Rx::CoreType::rec 0.200008;
# ABSTRACT: the Rx //rec type

use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub subname   { 'rec' }

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new") unless
    Data::Rx::Util->_x_subset_keys_y($arg, {
      rest     => 1,
      required => 1,
      optional => 1,
    });

  my $guts = {};

  my $content_schema = {};

  $guts->{rest_schema} = $rx->make_schema($arg->{rest}) if $arg->{rest};

  TYPE: for my $type (qw(required optional)) {
    next TYPE unless my $entries = $arg->{$type};

    for my $entry (keys %$entries) {
      Carp::croak("$entry appears in both required and optional")
        if $content_schema->{ $entry };

      $content_schema->{ $entry } = {
        optional => $type eq 'optional',
        schema   => $rx->make_schema($entries->{ $entry }),
      };
    }
  };

  $guts->{content_schema} = $content_schema;
  return $guts;
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'HASH') {
    $self->fail({
      error   => [ qw(type) ],
      message => "value is not a hashref",
      value   => $value,
    });
  }

  my $c_schema = $self->{content_schema};

  my @subchecks;

  my @rest_keys = grep { ! exists $c_schema->{$_} } keys %$value;
  if (@rest_keys and not $self->{rest_schema}) {
    @rest_keys = sort @rest_keys;
    push @subchecks,
      $self->new_fail({
        error    => [ qw(unexpected) ],
        keys     => [@rest_keys],
        message  => "found unexpected entries: @rest_keys",
        value    => $value,
      });
  }

  for my $key ($self->rx->sort_keys ? sort keys %$c_schema : keys %$c_schema) {
    my $check = $c_schema->{$key};

    if (not $check->{optional} and not exists $value->{ $key }) {
      push @subchecks,
        $self->new_fail({
          error    => [ qw(missing) ],
          keys     => [$key],
          message  => "no value given for required entry $key",
          value    => $value,
        });
      next;
    }

    if (exists $value->{$key}) {
      push @subchecks, [
        $value->{$key},
        $check->{schema},
        { data_path  => [ [$key, 'key' ] ],
          check_path => [
            [ $check->{optional} ? 'optional' : 'required', 'key' ],
            [ $key, 'key' ],
          ],
        },
       ];
    }
  }

  if (@rest_keys && $self->{rest_schema}) {
    my %rest = map { $_ => $value->{$_} } @rest_keys;

    push @subchecks, [
      \%rest,
      $self->{rest_schema},
      { check_path => [ ['rest', 'key' ] ],
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

Data::Rx::CoreType::rec - the Rx //rec type

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
