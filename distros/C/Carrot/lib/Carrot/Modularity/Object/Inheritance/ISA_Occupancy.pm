package Carrot::Modularity::Object::Inheritance::ISA_Occupancy
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Inheritance/ISA_Occupancy./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE');

	$named_re->provide(
		my $re_perl_pkg_prefix = 'perl_pkg_prefix');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	monads
#	universal
# //returns
{
	my ($this, $monads, $universal) = @ARGUMENTS;

	$this->[ATR_MONADS] = $monads;
	$this->[ATR_UNIVERSAL] = $universal;

	return;
}

sub collect_occupied
# /type method
# /effect ""
# //parameters
#	perl_isa
# //returns
#	?
{
	my ($this, $perl_isa) = @ARGUMENTS;

	my $monads = $this->[ATR_MONADS];
	my $parent_classes = [];
	foreach my $parent_class (@$perl_isa)
	{
		next unless (exists($monads->{$parent_class}));
		push($parent_classes, $monads->{$parent_class});
	}
	return($parent_classes);
}

sub call_occupied
# /type method
# /effect ""
# //parameters
#	perl_isa
#	method
#	*
# //returns
{
	my ($this, $perl_isa, $method) = splice(\@ARGUMENTS, 0, 3);

	my $monads = $this->[ATR_MONADS];
	foreach my $parent_class (@$perl_isa)
	{
		next unless (exists($monads->{$parent_class}));
		$method->($monads->{$parent_class}, @ARGUMENTS);
	}
	return;
}

sub first_defined_skip_seen
# /type method
# /effect ""
# //parameters
#	perl_isa
#	method
#	seen
# //returns
#	?
{
	my ($this, $perl_isa, $method, $seen) = splice(\@ARGUMENTS, 0, 4);

	my $monads = $this->[ATR_MONADS];
	foreach my $parent_class (@$perl_isa, @{$this->[ATR_UNIVERSAL]})
	{
		next unless (exists($monads->{$parent_class}));
		next if (exists($seen->{$parent_class}));
		$seen->{$parent_class} = IS_EXISTENT;
		my $result = $method->($monads->{$parent_class}, $seen, @ARGUMENTS);
		next unless (defined($result));
		return($result);
	}
	return(IS_UNDEFINED);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.131
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"

__END__
sub first_defined
# /type method
# /effect ""
# //parameters
#	perl_isa
#	method
#	*
# //returns
#	?
{
	my ($this, $perl_isa, $method) = splice(\@ARGUMENTS, 0, 3);

	my $monads = $this->[ATR_MONADS];
	foreach my $parent_class (@$perl_isa, @{$this->[ATR_UNIVERSAL]})
	{
		next unless (exists($monads->{$parent_class}));
		my $result = $method->($monads->{$parent_class}, @ARGUMENTS);
		next unless (defined($result));
		return($result);
	}
	return(IS_UNDEFINED);
}

sub homonymous_first_defined
# /type method
# /effect ""
# //parameters
#	perl_isa
#	*
# //returns
#	?
{
	my ($this, $perl_isa) = splice(\@ARGUMENTS, 0, 2);
	my $method = (caller(1))[RDX_CALLER_SUB_NAME];
	$method =~ s{$re_perl_pkg_prefix}{}o;

	my $monads = $this->[ATR_MONADS];
	foreach my $parent_class (@$perl_isa)
	{
		next unless (exists($monads->{$parent_class}));
		my $result = ($monads->{$parent_class})->$method(@ARGUMENTS);
		next unless (defined($result));
		return($result);
	}
	return(IS_UNDEFINED);
}

sub homonymous_first_defined_skip_seen
# /type method
# /effect ""
# //parameters
#	perl_isa
#	seen             ::Modularity::Object::Inheritance::ISA_Occupancy::Seen
#	*
# //returns
#	?
{
	my ($this, $perl_isa, $seen) = splice(\@ARGUMENTS, 0, 3);
	my $method = (caller(1))[RDX_CALLER_SUB_NAME];
	$method =~ s{$re_perl_pkg_prefix}{}o;

	my $monads = $this->[ATR_MONADS];
	foreach my $parent_class (@$perl_isa)
	{
		next unless (exists($monads->{$parent_class}));
		next if (exists($seen->{$parent_class}));
		$seen->{$parent_class} = IS_EXISTENT;
		my $result = ($monads->{$parent_class})->$method($seen, @ARGUMENTS);
		next unless (defined($result));
		return($result);
	}
	return(IS_UNDEFINED);
}

sub accumulate_defined
# /type method
# /effect ""
# //parameters
#	perl_isa
#	method
#	*
# //returns
#	?
{
	my ($this, $perl_isa, $method) = splice(\@ARGUMENTS, 0, 3);

	my $monads = $this->[ATR_MONADS];
	my $rv = [];
	foreach my $parent_class (@$perl_isa, @{$this->[ATR_UNIVERSAL]})
	{
		next unless (exists($monads->{$parent_class}));
		my $result = $method->($monads->{$parent_class}, @ARGUMENTS);
		next unless (defined($result));
		push($rv, $result);
	}
	return($rv);
}
