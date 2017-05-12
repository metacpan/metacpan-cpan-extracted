package App::perlfind::Plugin::Perlvar;
use strict;
use warnings;
use App::perlfind;
our $VERSION = '2.07';

# Generate %is_var with "util/perlvar-extract.pl". The value is what
# the query key gets rewritten as.

# TODO generate this hash at runtime just like perlvar-extract does.
# Needs to find perlvar.pod; at the moment I use "perldoc -l perlvar"
# for that, but it seems bad to call perldoc more or less within
# itself. Pod::Perldoc doesn't provide a method just to find the POD
# file, though.

my %is_var = (
            '%+' => '%+',
            'INPUT_LINE_NUMBER' => '$INPUT_LINE_NUMBER',
            '$ERRNO' => '$ERRNO',
            '$OSNAME' => '$OSNAME',
            '$b' => '$b',
            'ERRNO' => '%ERRNO',
            'SIG' => '%SIG',
            '$OUTPUT_FIELD_SEPARATOR' => '$OUTPUT_FIELD_SEPARATOR',
            '@_' => '@_',
            'UNICODE' => '${^UNICODE}',
            'LAST_SUBMATCH_RESULT' => '$LAST_SUBMATCH_RESULT',
            '$COMPILING' => '$COMPILING',
            '%ERRNO' => '%ERRNO',
            '$OUTPUT_RECORD_SEPARATOR' => '$OUTPUT_RECORD_SEPARATOR',
            '$FORMAT_NAME' => '$FORMAT_NAME',
            '${^RE_DEBUG_FLAGS}' => '${^RE_DEBUG_FLAGS}',
            '$EUID' => '$EUID',
            'OPEN' => '${^OPEN}',
            'EXECUTABLE_NAME' => '$EXECUTABLE_NAME',
            'EFFECTIVE_USER_ID' => '$EFFECTIVE_USER_ID',
            '$OS_ERROR' => '$OS_ERROR',
            'CHILD_ERROR_NATIVE' => '$^CHILD_ERROR_NATIVE',
            'ENCODING' => '${^ENCODING}',
            '$`' => '$`',
            '$~' => '$~',
            '$^T' => '$^T',
            'PROCESS_ID' => '$PROCESS_ID',
            'WARNING' => '$WARNING',
            '$EXCEPTIONS_BEING_CAUGHT' => '$EXCEPTIONS_BEING_CAUGHT',
            '$)' => '$)',
            '$2' => '$2',
            '$ORS' => '$ORS',
            '$^A' => '$^A',
            'LIST_SEPARATOR' => '$LIST_SEPARATOR',
            '${^UTF8CACHE}' => '${^UTF8CACHE}',
            '$OFS' => '$OFS',
            '%SIG' => '%SIG',
            '$EFFECTIVE_GROUP_ID' => '$EFFECTIVE_GROUP_ID',
            '$ARGV' => '$ARGV',
            '$^O' => '$^O',
            'DEBUGGING' => '$DEBUGGING',
            'EGID' => '$EGID',
            'MATCH' => '${^MATCH}',
            '$GID' => '$GID',
            'TAINT' => '${^TAINT}',
            '$MATCH' => '$MATCH',
            '${^WARNING_BITS}' => '${^WARNING_BITS}',
            '$^W' => '$^W',
            '$^E' => '$^E',
            '${^GLOBAL_PHASE}' => '${^GLOBAL_PHASE}',
            'PERLDB' => '$PERLDB',
            '$ARG' => '$ARG',
            '$:' => '$:',
            '$+' => '$+',
            '$RS' => '$RS',
            'UID' => '$UID',
            '@LAST_MATCH_START' => '@LAST_MATCH_START',
            'FORMAT_LINES_LEFT' => '$FORMAT_LINES_LEFT',
            'PERL_VERSION' => '$PERL_VERSION',
            '$/' => '$/',
            '2' => '$2',
            '$LAST_SUBMATCH_RESULT' => '$LAST_SUBMATCH_RESULT',
            'NR' => '$NR',
            'OUTPUT_FIELD_SEPARATOR' => '$OUTPUT_FIELD_SEPARATOR',
            '${^RE_TRIE_MAXBUF}' => '${^RE_TRIE_MAXBUF}',
            '$0' => '$0',
            'RE_TRIE_MAXBUF' => '${^RE_TRIE_MAXBUF}',
            '$^X' => '$^X',
            'OFS' => '$OFS',
            '$WARNING' => '$WARNING',
            'FORMAT_NAME' => '$FORMAT_NAME',
            '$=' => '$=',
            'ARGV' => '@ARGV',
            'INC' => '%INC',
            '${^UTF8LOCALE}' => '${^UTF8LOCALE}',
            '@INC' => '@INC',
            '${^PREMATCH}' => '${^PREMATCH}',
            '$FORMAT_FORMFEED' => '$FORMAT_FORMFEED',
            '$PERL_VERSION' => '$PERL_VERSION',
            '$[' => '$[',
            '$CHILD_ERROR' => '$CHILD_ERROR',
            '%-' => '%-',
            '$$' => '$$',
            '$FORMAT_TOP_NAME' => '$FORMAT_TOP_NAME',
            '$^V' => '$^V',
            '$EVAL_ERROR' => '$EVAL_ERROR',
            '$-' => '$-',
            '$ACCUMULATOR' => '$ACCUMULATOR',
            '$^I' => '$^I',
            '$^R' => '$^R',
            '%ENV' => '%ENV',
            '$&' => '$&',
            'OUTPUT_RECORD_SEPARATOR' => '$OUTPUT_RECORD_SEPARATOR',
            'ARRAY_BASE' => '$ARRAY_BASE',
            'EXCEPTIONS_BEING_CAUGHT' => '$EXCEPTIONS_BEING_CAUGHT',
            '$]' => '$]',
            '$LAST_PAREN_MATCH' => '$LAST_PAREN_MATCH',
            'PROGRAM_NAME' => '$PROGRAM_NAME',
            '$BASETIME' => '$BASETIME',
            '0' => '$0',
            '$UID' => '$UID',
            '${^WIN32_SLOPPY_STAT}' => '${^WIN32_SLOPPY_STAT}',
            '$^P' => '$^P',
            '$^N' => '$^N',
            'FORMAT_PAGE_NUMBER' => '$FORMAT_PAGE_NUMBER',
            'OSNAME' => '$OSNAME',
            'ARG' => '@ARG',
            '8' => '$8',
            'LAST_MATCH_END' => '@LAST_MATCH_END',
            '%!' => '%!',
            'LAST_PAREN_MATCH' => '%LAST_PAREN_MATCH',
            'OS_ERROR' => '%OS_ERROR',
            '$"' => '$"',
            '$EFFECTIVE_USER_ID' => '$EFFECTIVE_USER_ID',
            '$_' => '$_',
            '5' => '$5',
            'SUBSEP' => '$SUBSEP',
            '7' => '$7',
            '$EXTENDED_OS_ERROR' => '$EXTENDED_OS_ERROR',
            '${^MATCH}' => '${^MATCH}',
            '$PREMATCH' => '$PREMATCH',
            '$OFMT' => '$OFMT',
            'GID' => '$GID',
            '$a' => '$a',
            '$*' => '$*',
            '$PID' => '$PID',
            'OUTPUT_AUTOFLUSH' => '$OUTPUT_AUTOFLUSH',
            'PREMATCH' => '$PREMATCH',
            '%LAST_PAREN_MATCH' => '%LAST_PAREN_MATCH',
            '$FORMAT_LINES_LEFT' => '$FORMAT_LINES_LEFT',
            'GLOBAL_PHASE' => '${^GLOBAL_PHASE}',
            '$EXECUTABLE_NAME' => '$EXECUTABLE_NAME',
            '$POSTMATCH' => '$POSTMATCH',
            'INPUT_RECORD_SEPARATOR' => '$INPUT_RECORD_SEPARATOR',
            '${^UNICODE}' => '${^UNICODE}',
            '$^CHILD_ERROR_NATIVE' => '$^CHILD_ERROR_NATIVE',
            'FORMAT_LINES_PER_PAGE' => '$FORMAT_LINES_PER_PAGE',
            'OFMT' => '$OFMT',
            '$FORMAT_LINES_PER_PAGE' => '$FORMAT_LINES_PER_PAGE',
            'FORMAT_TOP_NAME' => '$FORMAT_TOP_NAME',
            '$EGID' => '$EGID',
            '$OUTPUT_AUTOFLUSH' => '$OUTPUT_AUTOFLUSH',
            '$3' => '$3',
            '$REAL_GROUP_ID' => '$REAL_GROUP_ID',
            '$;' => '$;',
            '$^L' => '$^L',
            'OLD_PERL_VERSION' => '$OLD_PERL_VERSION',
            '$SYSTEM_FD_MAX' => '$SYSTEM_FD_MAX',
            'POSTMATCH' => '${^POSTMATCH}',
            '$INPUT_LINE_NUMBER' => '$INPUT_LINE_NUMBER',
            '_' => '$_',
            '@LAST_MATCH_END' => '@LAST_MATCH_END',
            '$^S' => '$^S',
            '$LAST_REGEXP_CODE_RESULT' => '$LAST_REGEXP_CODE_RESULT',
            '${^OPEN}' => '${^OPEN}',
            '$1' => '$1',
            '@-' => '@-',
            'EFFECTIVE_GROUP_ID' => '$EFFECTIVE_GROUP_ID',
            '$|' => '$|',
            '%OS_ERROR' => '%OS_ERROR',
            '$^H' => '$^H',
            '%^H' => '%^H',
            '$.' => '$.',
            'WIN32_SLOPPY_STAT' => '${^WIN32_SLOPPY_STAT}',
            '$^D' => '$^D',
            '1' => '$1',
            'RS' => '$RS',
            '%INC' => '%INC',
            '$LIST_SEPARATOR' => '$LIST_SEPARATOR',
            'WARNING_BITS' => '${^WARNING_BITS}',
            '$(' => '$(',
            '$#' => '$#',
            '$@' => '$@',
            'EXTENDED_OS_ERROR' => '$EXTENDED_OS_ERROR',
            'CHILD_ERROR' => '$CHILD_ERROR',
            'EUID' => '$EUID',
            '$,' => '$,',
            'ENV' => '%ENV',
            '$DEBUGGING' => '$DEBUGGING',
            '$INPUT_RECORD_SEPARATOR' => '$INPUT_RECORD_SEPARATOR',
            '$?' => '$?',
            '$REAL_USER_ID' => '$REAL_USER_ID',
            '$NR' => '$NR',
            '$^M' => '$^M',
            '${^TAINT}' => '${^TAINT}',
            'REAL_GROUP_ID' => '$REAL_GROUP_ID',
            '@ARGV' => '@ARGV',
            'LAST_REGEXP_CODE_RESULT' => '$LAST_REGEXP_CODE_RESULT',
            'UTF8CACHE' => '${^UTF8CACHE}',
            'FORMAT_FORMFEED' => '$FORMAT_FORMFEED',
            'ORS' => '$ORS',
            '$^F' => '$^F',
            '$%' => '$%',
            '$OLD_PERL_VERSION' => '$OLD_PERL_VERSION',
            '$ARRAY_BASE' => '$ARRAY_BASE',
            '${^POSTMATCH}' => '${^POSTMATCH}',
            'RE_DEBUG_FLAGS' => '${^RE_DEBUG_FLAGS}',
            '$SUBSEP' => '$SUBSEP',
            '$!' => '$!',
            '@ARG' => '@ARG',
            '$PROGRAM_NAME' => '$PROGRAM_NAME',
            '$FORMAT_PAGE_NUMBER' => '$FORMAT_PAGE_NUMBER',
            '6' => '$6',
            'PID' => '$PID',
            '$^C' => '$^C',
            '3' => '$3',
            'ACCUMULATOR' => '$ACCUMULATOR',
            '$INPLACE_EDIT' => '$INPLACE_EDIT',
            '@F' => '@F',
            '9' => '$9',
            'LAST_MATCH_START' => '%LAST_MATCH_START',
            '$\\' => '$\\',
            '${^ENCODING}' => '${^ENCODING}',
            '4' => '$4',
            'REAL_USER_ID' => '$REAL_USER_ID',
            '$^' => '$^',
            'BASETIME' => '$BASETIME',
            'COMPILING' => '$COMPILING',
            '@+' => '@+',
            '$PROCESS_ID' => '$PROCESS_ID',
            '$PERLDB' => '$PERLDB',
            'INPLACE_EDIT' => '$INPLACE_EDIT',
            'EVAL_ERROR' => '$EVAL_ERROR',
            'SYSTEM_FD_MAX' => '$SYSTEM_FD_MAX',
            'UTF8LOCALE' => '${^UTF8LOCALE}',
            '$\'' => '$\'',
            '%LAST_MATCH_START' => '%LAST_MATCH_START'
          );

# find __WARN__, INT etc. as %SIG.
$is_var{$_} = '%SIG' for qw(__WARN__ __DIE__ INT QUIT PIPE), keys %SIG;

App::perlfind->add_trigger(
    'matches.add' => sub {
        my ($class, $word, $matches) = @_;
        if (my $rewrite = $is_var{$$word}) {
            $$word = $rewrite;
            push @$matches, 'perlvar';
        }
    }
);
1;

__END__

=pod

=head1 NAME

App::perlfind::Plugin::Perlvar - Plugin to find documentation for predefined variables

=head1 SYNOPSIS

    # all of the following run "perldoc -v %SIG":
    # perlfind %SIG
    # perlfind SIG
    # perlfind QUIT
    # perlfind __WARN__
    # perlfind WARN

=head1 DESCRIPTION

This plugin for L<App::perlfind> knows where to find documentation for
predefined variables and signals. It knows about things like

    OUTPUT_RECORD_SEPARATOR
    $^R
    __WARN__
    WARN
    QUIT

