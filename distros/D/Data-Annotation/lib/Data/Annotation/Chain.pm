package Data::Annotation::Chain;
use v5.24;
use Moo;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use Scalar::Util qw< blessed >;
use Data::Annotation::Rule;
use namespace::clean;

has description => (is => 'ro', default => '');
has default_retval => (is => 'ro', init_arg => 'default', predicate => 1);
has parse_context => (is => 'ro', default => sub { return {} },
   init_arg => 'condition-parse-context');
has rules => (is => 'ro', default => sub { [] });

sub evaluate ($self, $state, $overlay) {
   my $rules = $self->rules;
   my $ri = \($state->{idx} //= 0);
   while ($$ri <= $rules->$#*) {
      $rules->[$$ri] = Data::Annotation::Rule->new(
         'condition-parse-context' => $self->parse_context,
         $rules->[$$ri]->%*,
      ) unless blessed($rules->[$$ri]);
      my $rule = $rules->[$$ri++];
      if (defined(my $outcome = $rule->evaluate($overlay))) {
         my $name = $rule->has_name ? $rule->name : "#@{[ $$ri - 1 ]}";
         return ($outcome, $name);
      }
   }
   return $self->has_default_retval ? ($self->default_retval, undef) : ();
}

1;
