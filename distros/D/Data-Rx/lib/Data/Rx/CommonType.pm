use strict;
use warnings;
package Data::Rx::CommonType;
# ABSTRACT: base class for core Rx types
$Data::Rx::CommonType::VERSION = '0.200007';
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

version 0.200007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
