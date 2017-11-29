package App::EvalServerAdvanced::Seccomp::Syscall;
use Moo;
use Function::Parameters;
use Permute::Named::Iter qw/permute_named_iter/;
use Data::Dumper;

has syscall => (is => 'ro', required => 1);
has tests => (is => 'ro', default => sub {[]});
has action => (is => 'ro', default => "ALLOW");

# take the test and return however many seccomp rules it needs.  doing any permutated arguments, and looking up of constants
method resolve_syscall($seccomp) {
  my @rendered_tests;

  my %permuted_on;
  my $perm_re = qr/^\s*\{\{\s*(.*)\s*\}\}\s*$/;

  for my $test ($self->tests->@* ) {
    my ($arg, $operator, $value) = $test->@*;

    # If it has any non-digit characters, assume it needs to be calculated from constants, or permuted
    if ($value =~ $perm_re) {
      my $permuted_name = $1;

      # permutation values get calculated already

      $permuted_on{$permuted_name} = 1;
      push @rendered_tests, $test;
    } elsif ($value =~ /\D/) {
      push @rendered_tests, [$arg, $operator, $seccomp->constants->calculate($value)];
    } else { # We're a simple test, we just go straight through.
      push @rendered_tests, $test;
    }
  }

  unless (%permuted_on) { # no permutations, don't do weird shit.
    return {syscall => $self->syscall, rules => \@rendered_tests, action => $self->action};
  } else {
    my @syscalls;
    my %permutations = $seccomp->_fullpermutes->%*;
    my $iter = permute_named_iter(%permutations{keys %permuted_on});

    while (my $each = $iter->()) {
      my @rules = map {
        my @ar = @$_; # make a copy, so we don't mutate
        $ar[2] =~ s/$perm_re/$each->{$1}/g;
        \@ar
        } @rendered_tests;

      push @syscalls, {syscall => $self->syscall, rules => \@rules, action => $self->action};
    }

    return @syscalls;
  }
}

# TODO importable API to aid in syscall rule creation

1;
