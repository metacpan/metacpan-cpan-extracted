package AtteanX::Plan::LDF::Triple::EnterCache;
use v5.14;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION = '0.002';

use Moo;
use Class::Method::Modifiers;
use Attean;
use Carp;
use namespace::clean;

extends 'AtteanX::Plan::LDF::Triple';

around 'impl' => sub {
	my $orig = shift;
	my @params = @_;
	my $self	= shift;
	my $model	= shift;
	$model->publisher->publish('prefetch.triplepattern', $self->tuples_string);
	return $orig->(@params);
};

around 'plan_as_string' => sub {
	my $orig = shift;
	return $orig->(@_) . ' (publish)';
};

1;
