package Carrot::Diversity::English::Regular_Expression
# /type class
# /instances singular
# /capability "Defines English names for regular expression magic"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/English/Regular_Expression./manual_modularity.pl');
		require Carrot::Modularity::Constant::Global::Operating_System;
	} #BEGIN

	my $english = {
		'ON_LINE_START' => '^',
		'ON_LINE_END' => '$',
		'ON_START' => '\A',
		'ON_END' => '\z',
		'AFTER_LAST_MATCH' => '\G',

		'ANY_TIMES' => '*',
		'MANY_TIMES' => '+',
		'ONCE_OR_NOT' => '?',

		'ALTERNATIVELY' => '|',
		'NON_GREEDY' => '?',
		'TOO_GREEDY' => '+',
		'COMPLEMENT' => '^',

		'NULL' => '\x00',

		'SPACE' => '\ ',
		'EXCLAMATION_MARK' => '\!',
		'DOUBLE_QUOTES' => '"',
		'NUMBER_SIGN' => '#',
		'DOLLAR_SIGN' => '\$',
		'PERCENT' => '%',
		'AMPERSAND' => '&',
		'SINGLE_QUOTE' => "'",
		'PAREN_OPEN' => '\(',
		'PAREN_CLOSE' => '\)',
		'ASTERISK' => '\*',
		'PLUS' => '\+',
		'COMMA' => ',',
		'MINUS' => '-',
		'PERIOD' => '\.',
		'SLASH' => '/',

		'COLON' => ':',
		'SEMICOLON' => ';',
		'LESS_SIGN' => '<',
		'EQUAL_SIGN' => '=',
		'GREATER_SIGN' => '>',
		'QUESTION_MARK' => '\?',

		'AT_SIGN' => '@',
		'BRACKET_OPEN' => '\[',
		'BACKSLASH' => '\\\\',
		'BRACKET_CLOSE' => '\]',
		'CARET' => '\^',
		'UNDERSCORE' => '_',

		'GRAVE' => '`',
		'BRACE_OPEN' => '\{',
		'BAR_SIGN' => '\|',
		'BRACE_CLOSE' => '\}',

		'TILDE' => '~',

		'KEEP_THAT' => '\K',
		'LOWER_CASE' => '\l',
		'UPPER_CASE' => '\u',

		'LOWER_CASE_CONTEXT' => '\L',
		'UPPER_CASE_CONTEXT' => '\U',
		'LITERAL_CONTEXT' => '\Q',
		'CONTEXT_END' => '\E',

		'ANY_LINE_START' => '(?:\A|\012|\015\012?)',
		'ANY_LINE_END' => '(?:\z|\012|\015\012?)',
		'ANY_LINE_BREAK' => '(?:\012|\015\012?)',
		'DOS_LINE_BREAK' => '\015\012',
		'MACOS_LINE_BREAK' => '\015',
		'UNIX_LINE_BREAK' => '\012',

		'PERL_PKG_DELIMITER' => '::',
		'PERL_PKG_VALID_CHARACTERS' => '[\w:]+',

		'OS_FS_PATH_DELIMITER' => Carrot::Modularity::Constant::Global::Operating_System::OS_FS_PATH_DELIMITER,
		'OS_FS_PARENT_DIRECTORY' => Carrot::Modularity::Constant::Global::Operating_System::OS_FS_PARENT_DIRECTORY,
		'OS_FS_CURRENT_DIRECTORY' => Carrot::Modularity::Constant::Global::Operating_System::OS_FS_CURRENT_DIRECTORY,

		'INTERNET_LINE_DELIMITER' => '\015\012',

		'ANY_CHARACTER' => '.',
		'NEWLINE' => '\n',
		'NON_NEWLINE' => '\N',
		'WHITE_SPACE' => '\s',
		'NON_WHITE_SPACE' => '\S',
		'VERTICAL_SPACE' => '\v',
		'NON_VERTICAL_SPACE' => '\V',
		'HORIZONTAL_SPACE' => '\h',
		'NON_HORIZONTAL_SPACE' => '\H',
		'DIGIT' => '\d',
		'NON_DIGIT' => '\D',
		'WORD_CHARACTER' => '\w',
		'NON_WORD_CHARACTER' => '\W',
		'TABULATOR' => '\t',
		'ESCAPE' => '\e',

		'WORD_BOUNDARY' => '\b',
		'NON_WORD_BOUNDARY' => '\B',

		'NO_BACKREFERENCE' => '?:',
		'BRANCH_RESET' => '?|',
		'POSITIVE_LOOK_AHEAD' => '?=',
		'NEGATIVE_LOOK_AHEAD' => '?!',
		'POSITIVE_LOOK_BEHIND' => '?<=',
		'NEGATIVE_LOOK_BEHIND' => '?<!',
#		'' => '',

		'FIRST_BACKREFERENCE' => '\g{1}',
		'SECOND_BACKREFERENCE' => '\g{2}',
		'THIRD_BACKREFERENCE' => '\g{3}',

		'MULTIPLE_LINES_MODIFIER' => 'm',
		'SINGLE_LINE_MODIFIER' => 's',
		'IGNORE_CASE_MODIFIER' => 'i',
		'RELAXED_WHITESPACE_MODIFIER' => 'x',
		'PRESERVE_MATCH_MODIFIER' => 'p',
		'LOCALE_MODIFIER' => 'l',
		'UNICODE_MODIFIER' => 'u',
		'SAFE_UNICODE_MODIFIER' => 'a',
		'SAFER_UNICODE_MODIFIER' => 'aa',
	};
	my $re_english = '('.join('|', keys($english)).')';

	my $all_modifiers = {
		'MULTIPLE_LINES' => 'm',
		'SINGLE_LINE' => 's',
		'IGNORE_CASE' => 'i',
		'RELAXED_WHITESPACE' => 'x',
		'PRESERVE_MATCH' => 'p',
		'LOCALE' => 'l',
		'UNICODE' => 'u',
		'SAFE_UNICODE' => 'a',
		'SAFER_UNICODE' => 'aa',

# experimental::regex_sets, RXP = Regexp Extended Operator
		'RXP_SET_INTERSECTION' => '&',
		'RXP_SET_UNION' => '+',
		'RXP_SET_UNION' => '|',
		'RXP_SET_SUBTRACTION' => '-',
		'RXP_SET_SYMMETRIC_DIFFERENCE' => '^',
	};

	my $factors = {
		'' => 1,
		'SINGLE' => 1,
		'DOUBLE' => 2,
		'TRIPLE' => 3
	};

# =--------------------------------------------------------------------------= #

sub translate
# /type method
# /effect "Translates an descriptive English expression into a native RE"
# //parameters
#	description  ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $description) = @ARGUMENTS;

	$description =~ s{\s+}{ }saag;
	$description =~ s{(?:\012|\A|\015\012?)\h*(?:\#[^\012\015]+)?}{ }saag;
	$description =~ s{([\]\)])\s+([\[\(])}{$1$2}saag;
	$description =~ s{  +}{ }saag;

	$description =~ s
		{(?:\A|\ )
		 (?:(SINGLE|DOUBLE|TRIPLE)\ |)
		 $re_english
		 (?:\ ([\[\]\(\)])|(?=\ |\z))}
		{$english->{$2} x
			 (defined($1) ? $factors->{$1} : 1) . ($3//'')}saagoex;

	return($description);
}

sub compile
# /type method
# /effect "Translates an English RE into a raw RE and adds modifiers."
# //parameters
#	description  ::Personality::Abstract::Text
#	modifiers  ::Personality::Abstract::Array
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $description, $modifiers) = @ARGUMENTS;

	$description = $this->translate($description);

	if (defined($modifiers))
	{
		foreach my $modifier (@$modifiers)
		{
			next if (length($modifier) == 1);
			next unless (exists($all_modifiers->{$modifier}));
			$modifier = $all_modifiers->{$modifier};
		}

		unshift(@$modifiers, 'x') unless (grep($_ eq 'x', @$modifiers));
		$modifiers = join('', @$modifiers);
		$description = "(?$modifiers)$description";
	}

	return(qr{$description});
}

sub resolve_modifiers
# /type method
# /effect "Resolves English modifiers to characters and returns those unknown."
# //parameters
#	modifiers  ::Personality::Abstract::Array
#	specific  ::Personality::Abstract::Hash
# //returns
{
	my ($this, $modifiers, $specific) = @ARGUMENTS;

	if (ref($modifiers) eq '')
	{
		$modifiers =~ s{\s+}{}sg;
		$modifiers = [split(qr{\s*,\s*},
			$modifiers,
			PKY_SPLIT_IGNORE_EMPTY_TRAIL)];
		$_[SPX_MODIFIERS] = $modifiers;
	}

	my $unresolved = [];
	foreach my $modifier (@$modifiers)
	{
		next if (length($modifier) == 1);
		if (exists($all_modifiers->{$modifier}))
		{
			$modifier = $all_modifiers->{$modifier};
		} elsif (exists($specific->{$modifier}))
		{
			$specific->{$modifier} = IS_TRUE;
			$modifier = '';

		} else {
			die("Unknown modifier '$modifier'.");
		}
	}

	return(join('', $modifiers));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.197
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
