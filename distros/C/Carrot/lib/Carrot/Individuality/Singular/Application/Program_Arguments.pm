package Carrot::Individuality::Singular::Application::Program_Arguments
# /type class
# /instances singular
# /attribute_type ::One_Anonymous::Hash
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my ($class) = @ARGUMENTS;

	my $this = bless({}, $class);
	$this->argv_as_hash(\@PROGRAM_ARGUMENTS);

	return($this);
}

sub argv_as_hash
# /type method
# /effect ""
# //parameters
#	argv
# //returns
{
	my ($this) = @ARGUMENTS;

	foreach my $argument (@{$_[SPX_ARGV]})
	{
		if ($argument !~ m,\A--,s)
		{
			$this->{''} = [] unless (exists($this->{''}));
			push($this->{''}, $argument);

		} elsif ($argument =~ m{\A--(.+?)=(.*)\z}s)
		{
			$this->{$1} = [] unless (exists($this->{$1}));
			push($this->{$1}, $2);

		} elsif ($argument =~ m{\A--(.+?)\z}s)
		{
			$this->{$1} = [] unless (exists($this->{$1}));
			push($this->{$1}, IS_UNDEFINED);
		}
	}

	return;
}

sub provide
# /type method
# /effect "Replaces the supplied string with an instance."
# //parameters
#	key  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $key (@ARGUMENTS)
	{
		if (exists($this->{$key}))
		{
			$key = delete($this->{$key});
		} else {
			$key = IS_UNDEFINED;
		}
	}
	return;
}

sub fully_consumed
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(scalar(keys(%{$_[THIS]})) == 0);
}

sub keys
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(keys(%{$_[THIS]}));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.112
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
