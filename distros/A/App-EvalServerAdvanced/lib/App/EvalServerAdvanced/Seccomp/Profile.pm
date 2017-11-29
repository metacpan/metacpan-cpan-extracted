package App::EvalServerAdvanced::Seccomp::Profile;

use v5.20;

use Moo;
use Function::Parameters;
use App::EvalServerAdvanced::Seccomp::Syscall;

has rules => (is => 'ro', default => sub {[]}, coerce => sub {[ map {App::EvalServerAdvanced::Seccomp::Syscall->new(%$_)} $_[0]->@* ]});
has permute => (is => 'ro', default => sub {+{}});
has include => (is => 'ro', default => sub {[]});
has rule_generator => (is => 'ro', predicate => 1);
has name => (is => 'ro');

method get_rules($seccomp) {
  my @rules = map {$seccomp->get_profile_rules($_, $self->name)} $self->include->@*;
  push @rules, $self->rules->@*;

  if ($self->has_rule_generator()) {
    my ($class, $method) = ($self->rule_generator =~ /^(.*)::([^:]+)$/);

    my $plugin = $seccomp->load_plugin($class);
    push @rules, $plugin->$method($seccomp);
  }

  return @rules;
}

method to_seccomp($seccomp) {
  my @rules = $self->get_rules($seccomp);

  my @seccomp = map {$_->resolve_syscall($seccomp)} @rules;

  return @seccomp;
}

method load_permutes($seccomp) {
  for my $permute_key (keys $self->permute->%* ) {
    my $permute_data = $self->permute->{$permute_key};

    $seccomp->_permutes->{$permute_key} //= []; # Preload an arrayref if needed

    for my $value_str ($permute_data->@* ) {
      my $value = $seccomp->constants->calculate($value_str);

      push $seccomp->_permutes->{$permute_key}->@*, $value;
    }
  }
}

1;
