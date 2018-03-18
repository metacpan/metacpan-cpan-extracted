package Dwarf::Module;
use Dwarf::Pragma;
use Dwarf::Module::DSL;
use Dwarf::Util qw/load_class dwarf_log/;
use Scalar::Util qw/weaken/;

use Dwarf::Accessor {
	ro => [qw/context dsl/],
	rw => [qw/prefix/]
};

sub _build_prefix { shift->context->namespace . '::Model' }

sub _build_dsl {
	my $self = shift;
	my $dsl = Dwarf::Module::DSL->new(
		context => $self->context,
		module  => $self,
	);
	weaken $dsl->{context};
	weaken $dsl->{module};
	return $dsl;
}

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	dwarf_log 'new Module';
	$self->dsl->export_symbols($class);
	return $self;
}

sub DESTROY {
	my $self = shift;
	dwarf_log 'DESTROY Module';
	if (defined $self->{dsl}) {
		$self->dsl->delete_symbols(ref $self);
	}
}

sub init {}

sub on_error {}

1;
