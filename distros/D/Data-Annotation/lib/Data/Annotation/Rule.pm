package Data::Annotation::Rule;
use v5.24;
use utf8;
use Moo;
use warnings;
use experimental qw< signatures >;
{ our $VERSION = '0.006' }

use Data::Annotation::Expression qw< evaluator_factory >;
use namespace::clean;

has name => (is => 'ro', predicate => 1);
has description => (is => 'ro', default => '');
has record => (is => 'ro', predicate => 1);
has retval => (is => 'ro', init_arg => 'return', predicate => 1);
has parse_context => (is => 'ro', default => undef,
   init_arg => 'condition-parse-context');
has condition => (is => 'ro', default => 1);
has _condition => (is => 'lazy');

sub _build__condition ($self) {
   my $condition = $self->condition;
   return evaluator_factory($condition, $self->parse_context // {})
      if ref($condition) eq 'HASH';
   return sub { $condition };
}

sub evaluate ($self, $overlay) {
   return unless $self->_condition->($overlay);
   if ($self->has_record) {
      my $record = $self->record;
      if (exists($record->{delete})) {
         for my $skey ($record->{delete}->@*) {
            my $key = $skey =~ s{\A \.?}{}rmxs;
            $overlay->delete($key);
         }
      }
      if (exists($record->{set})) {
         my $set = $record->{set};
         for my $skey (keys($set->%*)) {
            my $key = $skey =~ s{\A \.?}{}rmxs;
            $overlay->set($key, $set->{$skey});
         }
      }
   }
   return $self->retval if $self->has_retval;
   return;
}

1;
