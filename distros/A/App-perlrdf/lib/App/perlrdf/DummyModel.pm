package App::perlrdf::DummyModel;

BEGIN {
	$App::perlrdf::DummyModel::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::DummyModel::VERSION   = '0.006';
}

use strict qw(vars subs);
no warnings;
use base 'RDF::Trine::Model';
use Carp 'confess';

sub new
{
	my $size = 0;
	bless \$size, shift;
}

*temporary_model = \&new;

sub _store
{
	return;
}

sub add_statement
{
	my $self = shift;
	++$$self;
}

sub die_write_only
{
	confess "this model is write-only!";
}

*{$_} = \&die_write_only
for qw(
	get_statements get_pattern get_sparql get_contexts get_list get_sequence
	remove_list remove_statement remove_statements
	count_statements
	as_stream as_hashref as_graphviz as_string
	subjects predicates objects objects_for_predicate_list bounded_description
);

sub size
{
	my $self = shift;
	$$self;
}

1;

