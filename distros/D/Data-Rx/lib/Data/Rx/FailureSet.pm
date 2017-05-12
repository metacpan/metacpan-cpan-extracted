use strict;
use warnings;
package Data::Rx::FailureSet;
# ABSTRACT: multiple structured failure reports from an Rx checker
$Data::Rx::FailureSet::VERSION = '0.200007';
#pod =head1 SYNOPSIS
#pod
#pod This is what is thrown when a schema's C<assert_valid> method finds a problem
#pod with the input.  For more information on it, look at the documentation for
#pod L<Data::Rx>.
#pod
#pod =cut

use overload '""' => \&stringify;

sub new {
  my ($class, $arg) = @_;

  my $failures;

  my $guts = {
    failures => [ map $_->isa('Data::Rx::FailureSet')
                        ? @{ $_->{failures} }
                        : $_,
                      @{ $arg->{failures} || [] },
                ]
  };

  bless $guts => $class;
}

sub failures { $_[0]->{failures} }

sub contextualize {
  my ($self, $struct) = @_;

  foreach my $failure (@{ $self->{failures} }) {
    $failure->contextualize($struct);
  }

  return $self;
}

sub stringify {
  my ($self) = @_;

  if (@{$self->{failures}}) {
    return join "\n", map "$_", @{$self->{failures}};
  } else {
    return "No failures\n";
  }
}

sub build_struct {
  my ($self) = @_;

  return unless @{$self->{failures}};

  my $data;

  foreach my $failure (@{$self->{failures}}) {

    my @path = $failure->data_path;
    my @type = $failure->data_path_type;

    @path == @type or die "bad path info in build_struct()";

    # go to the appropriate location in the struct, vivifying as necessary

    my $p = \$data;

    for (my $i = 0; $i < @path; ++$i) {
      if ($type[$i] eq 'k') {
        if (ref $$p && ref $$p ne 'HASH') {
          die "conflict in path info in build_struct()";
        }
        # if $$p already points to an error, replace it with the ref
        # I believe this can only happen with type errors in //all  -- rjk
        $$p = {} unless ref $$p;
        $p = \$$p->{$path[$i]};
      } elsif ($type[$i] eq 'i') {
        if (ref $$p && ref $$p ne 'ARRAY') {
          die "conflict in path info in build_struct()";
        }
        # if $$p already points to an error, replace it with the ref
        # I believe this can only happen with type errors in //all  -- rjk
        $$p = [] unless ref $$p;
        $p = \$$p->[$path[$i]];
      } else {
        die "bad path type in build_struct()";
      }
    }


    # insert the errors into the struct at the current location

    my $error = ($failure->error_types)[0];

    if ($error eq 'missing' || $error eq 'unexpected') {

      if (defined $$p && ref $$p ne 'HASH') {
        die "conflict in path info in build_struct()";
      }

      my @keys = $failure->keys;

      $$p ||= {};
      @{$$p}{@keys} = ($error) x @keys;

    } elsif ($error eq 'size') {

      if (defined $$p && ref $$p ne 'ARRAY') {
        die "conflict in path info in build_struct()";
      }

      my $size = $failure->size;

      $$p ||= [];
      $$p->[$size] = $error;

    } else {

      if (ref $$p) {
        # if $$p already points to a ref, leave it and skip the error
        # I believe this can only happen with type errors in //all  -- rjk
      } else {
        $$p .= ',' if defined $$p;
        $$p .= $error;
      }

    }
  }

  return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::FailureSet - multiple structured failure reports from an Rx checker

=head1 VERSION

version 0.200007

=head1 SYNOPSIS

This is what is thrown when a schema's C<assert_valid> method finds a problem
with the input.  For more information on it, look at the documentation for
L<Data::Rx>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
