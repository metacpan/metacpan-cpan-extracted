use v5.12.0;
use warnings;
package Data::Rx::CommonType 0.200008;
# ABSTRACT: base class for core Rx types

use Carp ();
use Scalar::Util ();
use Data::Rx::Failure;
use Data::Rx::FailureSet;

# requires: new_checker, type, type_uri, rx, assert_valid

sub new_checker  { Carp::croak "$_[0] did not implement new_checker" }
sub type_uri     { Carp::croak "$_[0] did not implement type_uri" }
sub type         { Carp::croak "$_[0] did not implement type" }
sub rx           { Carp::croak "$_[0] did not implement rx" }
sub assert_valid { Carp::croak "$_[0] did not implement assert_valid" }

sub check {
  my ($self, $value) = @_;
  local $@;

  return 1 if eval { $self->assert_valid($value); };
  my $error = $@;

  # If you wanted the failure, you should've used assert_valid.
  return 0 if eval { $error->isa('Data::Rx::FailureSet') };

  die $error;
}

sub new_fail {
  my ($self, $struct) = @_;

  $struct->{type} ||= $self->type;

  Data::Rx::FailureSet->new({
    rx => $self->rx,
    failures => [
      Data::Rx::Failure->new({
        rx     => $self->rx,
        struct => $struct,
      })
    ]
  });
}

sub fail {
  my ($self, $struct) = @_;

  die $self->new_fail($struct);
}

sub perform_subchecks {
  my ($self, $subchecks) = @_;

  my @fails;

  foreach my $subcheck (@$subchecks) {
    if (Scalar::Util::blessed($subcheck)) {
      push @fails, $subcheck;
      next;
    }

    my ($value, $checker, $context) = @$subcheck;

    next if eval { $checker->assert_valid($value) };

    my $failure = $@;
    Carp::confess($failure)
      unless eval { $failure->isa('Data::Rx::FailureSet') ||
                    $failure->isa('Data::Rx::Failure') };

    $failure->contextualize({
      type  => $self->type,
      %$context,
    });

    push @fails, $failure;
  }

  if (@fails) {
    die Data::Rx::FailureSet->new( { rx => $self->rx, failures => \@fails } );
  }

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CommonType - base class for core Rx types

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
