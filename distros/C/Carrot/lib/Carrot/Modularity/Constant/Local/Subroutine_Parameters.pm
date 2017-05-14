package Carrot::Modularity::Constant::Local::Subroutine_Parameters
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Local/Subroutine_Parameters./manual_modularity.pl');
	} #BEGIN

	my $subroutine_re = q{
		\nsub\s+
		(\w+)(?:\([^\)]*\))? # name+prototype
		\n[^\{]+             # options
		\n\{(.*?)            # code
		\n\}
	};

# =--------------------------------------------------------------------------= #

sub constants_definitions
# /type method
# /effect "Adds definitions required for the perl code of the requester."
# //parameters
#	definitions
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad, $definitions) = @ARGUMENTS;

	my $source_code = $meta_monad->source_code;
	return unless ($$source_code =~ m{\bSPX_\w+\b}s);

	my $manual = $source_code->unique_matches(qr{\nsub\s+SPX_(\w+)\(\)\s+{\s+(\d+)\s+}});
	my $case_cache = {};
	foreach my $key (@$manual)
	{
		$case_cache->{lc($key)} = $manual->{$key};
	}

#FIXME: take name from \w+ and splice 3 for error message
	my $sub_options = $meta_monad->block_modifiers
		->all_blocks->get('sub');

	while ($$source_code =~ m{$subroutine_re}sgox)
	{
		my ($sub_name, $code) = ($1, $2);

		my $options = $sub_options->{$sub_name};
#FIXME: subroutine might not exist in the hash

		my $used = [$code =~ m{\$_\[SPX_(\w+)\]}sg];
		@$used = keys({map(($_ => 1), @$used)});
		next if ($#$used == ADX_NO_ELEMENTS);

		unless (exists($options->{'type'}))
		{
			die("Could not find type parameter for subroutine '$sub_name'.");
		}
		my $offset = (($options->{'type'}->modifier_value eq 'method')
			? 1 : 0);
		my $parameters = $options->{'parameters'}->named_types
			->enumerated_hash($offset);

		foreach my $NAME (@$used)
		{
			my $name = lc($NAME);
			unless (exists($parameters->{$name}))
			{
				require Data::Dumper;
				print STDERR Data::Dumper::Dumper($options);
#FIXME: highly misleading
				die("SPX_$NAME has no parameter entry in ", $meta_monad->package_name->value. "."); #FIXME
			}

			if (exists($case_cache->{$name}))
			{
				unless ($case_cache->{$name} == $parameters->{$name})
				{
#FIXME:
					die("Inconsistent subroutine parameter index for '$name': $case_cache->{$name} != $parameters->{$name}.");
				};
			}

			$case_cache->{$name} = $parameters->{$name};
			$definitions->add_constant_function(
				"SPX_$NAME",
				$parameters->{$name},
				IS_FALSE);
		}
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.182
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
