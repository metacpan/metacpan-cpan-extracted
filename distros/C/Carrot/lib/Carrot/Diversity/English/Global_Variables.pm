package Carrot::Diversity::English::Global_Variables
# /type class
# /capability "Define replacements for global interpunctation variables"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/English/Global_Variables./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;

	my $aliases = {
		'ACCUMULATOR'             => '^A',
#		'ARG' # English is English, but ARG isn't
		'ARGUMENTS'               => '_', # English.pm ARG
		'ARGUMENT'                => '_', # English.pm ARG
#		'ARGUMENTS'               => '_{ARRAY}', # won't do
#		'ARGUMENT'                => '_{SCALAR}', # won't do
		'BASE_TIME'               => '^T', # English.pm BASETIME
		'CHILD_ERROR'             => '?',
		'COMPILING'               => '^C',
		'DEBUGGING'               => '^D',
		'EFFECTIVE_GROUP_ID'      => ')',
		'EFFECTIVE_USER_ID'       => '>',
		'EVAL_ERROR'              => '@',
		'EXCEPTIONS_BEING_CAUGHT' => '^S',
		'EXECUTABLE_NAME'         => '^X',
		'EXTENDED_OS_ERROR'       => '^E',
		'INPLACE_EDIT'            => '^I',
		'INPUT_LINE_NUMBER'       => '.',
		'INPUT_RECORD_SEPARATOR'  => '/',
		'LAST_MATCH_END'          => '+{ARRAY}',
		'LAST_MATCH_START'        => '-{ARRAY}',
		'LAST_PAREN_MATCH'        => '+',
		'LAST_REGEXP_CODE_RESULT' => '^R',
		'LAST_SUBMATCH_RESULT'    => '^N ',
		'LIST_SEPARATOR'          => '"',
		'MODULE_SEARCH_PATH'      => 'main::INC{ARRAY}', # not in English.pm
		'MODULES_LOADED'          => 'main::INC{HASH}', # not in English.pm
		'OS_ERROR'                => '!',
		'OS_NAME'                 => '^O',   # English.pm OSNAME
		'OS_SIGNALS'              => 'main::SIG{HASH}', # not in English.pm
		'OUTPUT_AUTOFLUSH'        => '|',
		'OUTPUT_FIELD_SEPARATOR'  => ',',
		'OUTPUT_RECORD_SEPARATOR' => '\\',
		'PARENT_CLASSES'          => 'ISA', # not in English.pm
		'PERL_DB'                 => '^P',  # English.pm PERLDB
		'PERL_VERSION'            => '^V',
		'PROCESS_ENVIRONMENT'     => 'main::ENV{HASH}', # not in English.pm
		'PROCESS_EXIT_CODE'       => '?',
		'PROCESS_ID'              => '$',
		'PROGRAM_NAME'            => '0',
		'PROGRAM_ARGUMENTS'       => 'main::ARGV{ARRAY}', # not in English.pm
		'REAL_GROUP_ID'           => '(',
		'REAL_USER_ID'            => '<',
		'SUBSCRIPT_SEPARATOR'     => ';',
		'SYSTEM_FD_MAX'           => '^F',
		'WARNING'                 => '^W'
	};
	my $aliases_re =
		'(?:\$|\@)('
		# sorting for length
		. join('|', reverse(sort(keys($aliases))))
		. ')';

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub managed_modularity
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
#	definitions
# //returns
{
	my ($this, $meta_monad, $definitions) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	my $source_code = $meta_monad->source_code;
	my $english = $source_code->unique_matches($aliases_re);
	return unless (@$english);

	my $code = join("\n",
		"package main_ {",
		map("\t\*${pkg_name}::$_ = \*$aliases->{$_};", @$english),
		'}');
	$definitions->add_code($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.92
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
