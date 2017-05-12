use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::GeneratorsQueue;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(generators));

sub new {
	my ($class, $args) = @_;
	my $tree = Apache::SWIT::Maker::Config->instance;
	my $gclasses = $args->{generator_classes} ? 
			$args->{generator_classes} : $tree->{generators};
	my @gens;
	for my $c (@$gclasses) {
		eval "use $c";
		die "Unable to use $c : $@" if $@;
		push @gens, $c->new;
	}
	$args = { generators => \@gens };
OUT:	
	return $class->SUPER::new($args);
}

sub run {
	my ($self, $func, @args) = @_;
	my $res;
	for my $g (@{ $self->generators }) {
		next unless $g->can($func);
		$res = $g->$func($res, @args);
	}
	return $res;
}

1;

