package Carrot::Meta::Greenhouse::Named_RE
# /type class
# /instances singular
# /capability "Maintains a library of commonly used REs"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Named_RE./manual_modularity.pl');
	} #BEGIN

	my $library = {
		'file_name_extension' =>
			['PERIOD  WORD_CHARACTER MANY_TIMES  ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'file_extension_pl' =>
			['PERIOD  pl  ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'file_extension_ini' =>
			['PERIOD  ini  ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

#FIXME: remove perl_ prefix, rename to pkg_valid_name
		'perl_pkg_name' =>
			['ON_START
			( NO_BACKREFERENCE
				WORD_CHARACTER MANY_TIMES )
			( NO_BACKREFERENCE
				PERL_PKG_DELIMITER  WORD_CHARACTER MANY_TIMES )
			ANY_TIMES ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'perl_pkg_prefix' =>
			['ON_START  ANY_CHARACTER ANY_TIMES  PERL_PKG_DELIMITER',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'perl_pkg_last_element' =>
			['( ON_START  ALTERNATIVELY  PERL_PKG_DELIMITER )
			WORD_CHARACTER MANY_TIMES  ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'pkg_delimiter_remove_trailing' =>
			['PERL_PKG_DELIMITER  ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'perl_pkg_n_sub' =>
			['ON_START
			( PERL_PKG_VALID_CHARACTERS ) PERL_PKG_DELIMITER
			( WORD_CHARACTER MANY_TIMES ) ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'perl_remove_data_or_end' =>
			['ANY_LINE_START __(DATA|END)__ ANY_CHARACTER ANY_TIMES',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'trim_horizonal_space' =>
			['ON_START  HORIZONTAL_SPACE
			ALTERNATIVELY
			HORIZONTAL_SPACE  MANY_TIMES  ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'delimiting_comma' =>
			['HORIZONTAL_SPACE ANY_TIMES
			COMMA  HORIZONTAL_SPACE ANY_TIMES',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

#		'carrot_dot_directory_cut' =>
#			['PERIOD (
#				WORD_CHARACTER MANY_TIMES NON_GREEDY
#				ALTERNATIVELY
#				SLASH  ANY_CHARACTER MANY_TIMES NON_GREEDY
#			 ) ON_END',
#				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'carrot_dot_directory' =>
			['ON_START  ( ANY_CHARACTER MANY_TIMES NON_GREEDY )
			PERIOD ( NO_BACKREFERENCE
				SLASH shadow MINUS ANY_CHARACTER MANY_TIMES
				ALTERNATIVELY
				[ COMPLEMENT  SLASH ] MANY_TIMES )
			ON_END',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

		'carrot_placeholder' =>
			['BRACKET_OPEN  EQUAL_SIGN
				( WORD_CHARACTER  MANY_TIMES )
			EQUAL_SIGN  BRACKET_CLOSE',
				[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]],

	};

	require Carrot::Diversity::English::Regular_Expression;
	my $re_english = Carrot::Diversity::English::Regular_Expression
		->constructor;

	foreach my $key (keys($library))
	{
		$library->{$key} = $re_english->compile(@{$library->{$key}});
	}

	my $matchers = {{'' => {}}, {'g' => {}}};

# =--------------------------------------------------------------------------= #

sub provide
# /type method
# /effect "Fatally retrieves entries from the RE library"
# //parameters
#	name  +multiple  ::Personality::Abstract::Text::Word
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $re_name (@ARGUMENTS)
	{
		unless (exists($library->{$re_name}))
		{
			if ($re_name =~ m{\A[A-Z0-9_]+\z}s)
			{
				$library->{$re_name} =
					$re_english->compile(
						$re_name,
						[RE_MOD_SAFER_UNICODE,
						RE_MOD_SINGLE_LINE]);
			} else {
#FIXME: activate as a generic package loading event again?
#				if (defined($translated_errors))
#				{
#					$translated_errors->advocate(
#						're_non_existing',
#						[$re_name]);
#				} else {
#FIXME: a hardcoded English error message isn't so nice here
					die("Couldn't find RE '$re_name' in the library.");
#				}
			}
		}
		$re_name = $library->{$re_name}
	}
	return;
}

sub provide_matcher
# /type method
# /effect "Fatally retrieves a matcher from the RE library"
# //parameters
#	name  +multiple  ::Personality::Abstract::Text::Word
# /returns *
{
	my $this = shift(\@ARGUMENTS);

	my $first_matchers = $matchers->{''};
	foreach my $re_name (@ARGUMENTS)
	{
		unless (exists($first_matchers->{$re_name}))
		{
			my $re = $re_name;
			$this->provide($re);
			$first_matchers->{$re_name} =
				sub { return($_[0] =~ m{$re}o) };
		}
		$re_name = $first_matchers->{$re_name}
	}
	return;
}

sub provide_global_matcher
# /type method
# /effect "Fatally retrieves a matcher from the RE library"
# //parameters
#	re_name  +multiple  ::Personality::Abstract::Text::Word
# /returns *
{
	my $this = shift(\@ARGUMENTS);

	my $global_matchers = $matchers->{'g'};
	foreach my $re_name (@ARGUMENTS)
	{
		unless (exists($global_matchers->{$re_name}))
		{
			my $re = $re_name;
			$this->provide($re);
			$global_matchers->{$re_name} =
				sub { return($_[0] =~ m{$re}go) };
		}
		$re_name = $global_matchers->{$re_name}
	}
	return;
}

#NOTE: this couldn't handle interpolation of backreferences - reserved s magic
#sub provide_substitution ...

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.220
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
