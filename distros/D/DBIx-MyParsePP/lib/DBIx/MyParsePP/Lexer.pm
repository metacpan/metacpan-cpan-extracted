# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Based on code Copyright (C) 2000-2006 MySQL AB

package DBIx::MyParsePP::Lexer;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(MODE_PIPES_AS_CONCAT MODE_ANSI_QUOTES MODE_IGNORE_SPACE MODE_NO_BACKSLASH_ESCAPES
		CLIENT_MULTI_STATEMENTS MODE_HIGH_NOT_PRECEDENCE);

use strict;

use DBIx::MyParsePP::Symbols;
use DBIx::MyParsePP::Charsets;
use DBIx::MyParsePP::Token;

use constant CTYPE_U	=> 01;		# Uppercase
use constant CTYPE_L	=> 02;		# Lowercase
use constant CTYPE_NMR 	=> 04;		# Numeral (digit)
use constant CTYPE_SPC	=> 010;		# Spacing character
use constant CTYPE_PNT	=> 020;		# Punctuation
use constant CTYPE_CTR	=> 040;		# Control character
use constant CTYPE_B	=> 0100;	# Blank
use constant CTYPE_X	=> 0200;	# heXadecimal digit

use constant LEXER_STRING		=> 0;
use constant LEXER_CHARSET		=> 1;
use constant LEXER_VERSION		=> 2;
use constant LEXER_SQL_MODE		=> 3;
use constant LEXER_OPTIONS		=> 4;
use constant LEXER_CLIENT_CAPABILITIES	=> 5;
use constant LEXER_STMT_PREPARE_MODE	=> 6;

use constant LEXER_PTR			=> 7;
use constant LEXER_TOK_START		=> 8;

use constant LEXER_TOKENS		=> 9;

use constant LEXER_YYLINENO		=> 10;
use constant LEXER_NEXT_STATE		=> 11;
use constant LEXER_IN_COMMENT		=> 12;
use constant LEXER_FOUND_SEMICOLON	=> 13;
use constant LEXER_SAFE_TO_CACHE_QUERY	=> 14;
use constant LEXER_SERVER_STATUS	=> 15;
use constant LEXER_CTYPE		=> 16;


use constant OPTION_FOUND_COMMENT	=> 1 << 15;
use constant CLIENT_MULTI_STATEMENTS	=> 1 << 16;
use constant SERVER_MORE_RESULTS_EXISTS	=> 8;
use constant NAMES_SEP_CHAR		=> '\377';


use constant MODE_PIPES_AS_CONCAT	=> 2;		# USE ME!
use constant MODE_ANSI_QUOTES		=> 4;
use constant MODE_IGNORE_SPACE		=> 8;
use constant MODE_MYSQL323		=> 65536;
use constant MODE_MYSQL40		=> MODE_MYSQL323 * 2;
use constant MODE_ANSI			=> MODE_MYSQL40 * 2;
use constant MODE_NO_AUTO_VALUE_ON_ZERO	=> MODE_ANSI * 2;
use constant MODE_NO_BACKSLASH_ESCAPES	=> MODE_NO_AUTO_VALUE_ON_ZERO * 2;
use constant MODE_STRICT_TRANS_TABLES	=> MODE_NO_BACKSLASH_ESCAPES * 2;
use constant MODE_STRICT_ALL_TABLES        	=> MODE_STRICT_TRANS_TABLES * 2;
use constant MODE_NO_ZERO_IN_DATE           	=> MODE_STRICT_ALL_TABLES * 2;
use constant MODE_NO_ZERO_DATE               	=> MODE_NO_ZERO_IN_DATE * 2;
use constant MODE_INVALID_DATES              	=> MODE_NO_ZERO_DATE * 2;
use constant MODE_ERROR_FOR_DIVISION_BY_ZERO 	=> MODE_INVALID_DATES * 2;
use constant MODE_TRADITIONAL                	=> MODE_ERROR_FOR_DIVISION_BY_ZERO * 2;
use constant MODE_NO_AUTO_CREATE_USER        	=> MODE_TRADITIONAL * 2;
use constant MODE_HIGH_NOT_PRECEDENCE        	=> MODE_NO_AUTO_CREATE_USER * 2;

my %state_maps;
my %ident_maps;

my %args = (
	string			=> LEXER_STRING,
	charset			=> LEXER_CHARSET,
	client_capabilities	=> LEXER_CLIENT_CAPABILITIES,
	stmt_prepare_mode	=> LEXER_STMT_PREPARE_MODE,
	sql_mode		=> LEXER_SQL_MODE,
	version			=> LEXER_VERSION
);

1;

sub new {
	my $class = shift;
	my $lexer = bless([], $class);

	my $max_arg = (scalar(@_) / 2) - 1;

	foreach my $i (0..$max_arg) {
		if (exists $args{$_[$i * 2]}) {
			$lexer->[$args{$_[$i * 2]}] = $_[$i * 2 + 1];
		} else {
			warn("Unkown argument '$_[$i * 2]' to DBIx::MyParsePP::Lexer->new()");
		}
        }

	$lexer->[LEXER_STRING]			= $lexer->[LEXER_STRING]."\0";
	$lexer->[LEXER_YYLINENO]		= 1;
	$lexer->[LEXER_TOK_START]		= 0;
	$lexer->[LEXER_PTR]			= 0;
	$lexer->[LEXER_NEXT_STATE]		= 'MY_LEX_START';

	$lexer->[LEXER_CLIENT_CAPABILITIES]	= CLIENT_MULTI_STATEMENTS if not defined $lexer->[LEXER_CLIENT_CAPABILITIES];
	$lexer->[LEXER_STMT_PREPARE_MODE]	= 0 if not defined $lexer->[LEXER_STMT_PREPARE_MODE];
	$lexer->[LEXER_SQL_MODE]		= 0 if not defined $lexer->[LEXER_SQL_MODE];	# CHECKME

	$lexer->[LEXER_VERSION]			= '50045' if not defined $lexer->[LEXER_VERSION];
	$lexer->[LEXER_CHARSET]			= 'ascii' if not defined $lexer->[LEXER_CHARSET]; # FIXME

	my $charset_uc = ucfirst($lexer->[LEXER_CHARSET]);
	eval('
		use DBIx::MyParsePP::'.$charset_uc.';
		$lexer->[LEXER_CTYPE] = $DBIx::MyParsePP::'.$charset_uc.'::ctype;
	');

	if ($@) {
		print STDERR "DBIx::MyParsePP::Lexer->new() failed: $@\n";
		return undef;
	}

	$lexer->[LEXER_TOKENS] 			= [];

	$lexer->init_state_maps($lexer->[LEXER_CHARSET]);

	return $lexer;
	
}

sub getLine {
	return $_[0]->[LEXER_YYLINENO];
}

sub line {
	return $_[0]->[LEXER_YYLINENO];
}

sub pos {
	return $_[0]->[LEXER_PTR];
}

sub getPos {
	return $_[0]->[LEXER_PTR];
}

sub getTokens {
	return $_[0]->[LEXER_TOKENS];
}

sub tokens {
	return $_[0]->[LEXER_TOKENS];
}

sub yyGet { return ord(substr($_[0]->[LEXER_STRING], $_[0]->[LEXER_PTR]++, 1)) };
sub yyGetLast { ord(substr($_[0]->[LEXER_STRING], $_[0]->[LEXER_PTR] - 1, 1)) };
sub yyPeek { ord(substr($_[0]->[LEXER_STRING], $_[0]->[LEXER_PTR], 1)) };
sub yyPeek2 { ord(substr($_[0]->[LEXER_STRING], $_[0]->[LEXER_PTR] + 1, 1)) };
sub yyUnget { $_[0]->[LEXER_PTR]-- };
sub yySkip { $_[0]->[LEXER_PTR]++ };
sub yyLength { ($_[0]->[LEXER_PTR] - $_[0]->[LEXER_TOK_START]) - 1 };

sub yylex {
	my $lexer = shift;
	my @res = $lexer->MYSQLlex();
	if (($res[0] eq '0') && ($res[1] eq '0')) {
		return (undef, '');	# EOF
	} else {
		my $token = DBIx::MyParsePP::Token->new(@res);
		push @{$lexer->[LEXER_TOKENS]}, $token;
		return ($res[0], $token);
	}
}

sub MYSQLlex {
	my $lexer = shift;

	my $string = $lexer->[LEXER_STRING];
	my $state_map = $state_maps{$lexer->[LEXER_CHARSET]};
	my $ident_map = $ident_maps{$lexer->[LEXER_CHARSET]};
	
	my $c = 0;
	my @token;
	my $result_state;
	my $state;

	$lexer->[LEXER_TOK_START] = $lexer->[LEXER_PTR];


	$state = $lexer->[LEXER_NEXT_STATE];
	$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_OPERATOR_OR_IDENT';

	my $char = substr($string, $lexer->[LEXER_PTR], 1);

	for (;;) {
		if (
			($state eq 'MY_LEX_OPERATOR_OR_IDENT') ||
			($state eq 'MY_LEX_START')
		) {
			for ($c = $lexer->yyGet(); $state_map->[$c] eq 'MY_LEX_SKIP'; $c = $lexer->yyGet()) {
				$lexer->[LEXER_YYLINENO]++ if $c == ord("\n");
			}
			$lexer->[LEXER_TOK_START] = $lexer->[LEXER_PTR] - 1;
			$state = $state_map->[$c];
		}
		
		if ($state eq 'MY_LEX_ESCAPE') {
			return ("NULL_SYM","NULL") if $lexer->yyGet() == ord('N');
		}
	
		if (
			($state eq 'MY_LEX_ESCAPE') ||
			($state eq 'MY_LEX_CHAR') ||
			($state eq 'MY_LEX_SKIP')
		) {
			if (
				($c == ord('-')) &&
				($lexer->yyPeek() == ord('-')) &&
				(
					($lexer->my_isspace($lexer->yyPeek2())) ||
					($lexer->my_iscntrl($lexer->yyPeek2()))
				)
			) {
				$state = 'MY_LEX_COMMENT';
				next;
			}
			$lexer->[LEXER_PTR] = $lexer->[LEXER_TOK_START];
			my $lex_str = substr($string, $lexer->[LEXER_PTR], 1);
			$c = $lexer->yyGet();
			
			$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_START' if $c != ord (')');

			if ($c == ord(',')) {
				$lexer->[LEXER_TOK_START] = $lexer->[LEXER_PTR];
			} elsif (($c == ord('?')) && (!$ident_map->[$lexer->yyPeek()])) {		# CHANGED
				return ("PARAM_MARKER","?");
			}
			return (chr($c), $lex_str);
		} elsif ($state eq 'MY_LEX_IDENT_OR_NCHAR') {
			if ($lexer->yyPeek() != ord("'")) {
				$state = 'MY_LEX_IDENT';
				next;
			}
			$lexer->[LEXER_TOK_START]++;
			$lexer->yySkip();
			my $lex_str;
			if (!defined ($lex_str = $lexer->get_text())) {
				$state = 'MY_LEX_CHAR';
				next;
			}
			return ('NCHAR_STRING',$lex_str);
		} elsif ($state eq 'MY_LEX_IDENT_OR_HEX') {
			if ($lexer->yyPeek() == ord("'")) {
				$state = 'MY_LEX_BIN_NUMBER';
				next;
			}
		} elsif ($state eq 'MY_LEX_IDENT_OR_BIN') {
			if ($lexer->yyPeek() == ord("'")) {
				$state = 'MY_LEX_BIN_NUMBER';
				next;
			}
		}

		if (
			($state eq 'MY_LEX_IDENT_OR_HEX') ||
			($state eq 'MY_LEX_IDENT_OR_BIN') ||
			($state eq 'MY_LEX_IDENT')
		) {
			my $start;
			## FIXME - multibyte

			for ($result_state = $c; $ident_map->[$c = $lexer->yyGet()]; $result_state |= $c) {};
			
			$result_state = $result_state & 0x80 ? 'IDENT_QUOTED' : 'IDENT';

			my $length = $lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START] - 1;
			$start = $lexer->[LEXER_PTR];

			if ($lexer->[LEXER_SQL_MODE] & MODE_IGNORE_SPACE) {
				for(; $state_map->[$c] eq 'MY_LEX_SKIP'; $c = $lexer->yyGet()) {};
			}

			if (
				($start == $lexer->[LEXER_PTR]) &&
				($c == ord('.')) &&
				($ident_map->[$lexer->yyPeek()])
			) {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_IDENT_SEP';
			} else {
				$lexer->yyUnget();
				if (@token = $lexer->find_keyword($length, $c == ord('('))) {
					$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_START';
					return @token;
				}
				$lexer->yySkip();
			} 
			my $lex_str = $lexer->get_token($length);

			if (
				(substr($lex_str,0,1) eq '_') &&
				(exists $DBIx::MyParsePP::Charsets::charsets->{substr($lex_str,1)})
			) {
				return ('UNDERSCORE_CHARSET', substr($lex_str,1));
			}

			return($result_state, $lex_str);
		} elsif ($state eq 'MY_LEX_IDENT_SEP') {
			my $lex_str = substr($string, $lexer->[LEXER_PTR], 1);
			$c = $lexer->yyGet();
			$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_IDENT_START';
			if (!$ident_map->[$lexer->yyPeek()]) {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_START';
			}
			return (chr($c), $lex_str);
		} elsif ($state eq 'MY_LEX_NUMBER_IDENT') {
			while ($lexer->my_isdigit($c = $lexer->yyGet())) {} ;
			if (!$ident_map->[$c]) {
				$state = 'MY_LEX_INT_OR_REAL';
				next;
			}
			if (($c == ord('e')) || ($c == ord('E'))) {
				if (
					($lexer->my_isdigit($lexer->yyPeek())) ||
					($c = $lexer->yyGet() == ord('+')) ||
					($c == ord('-'))
				) {
					if ($lexer->my_isdigit($lexer->yyPeek())) {
						$lexer->yySkip();
						while ($lexer->my_isdigit($lexer->yyGet())) {};
						my $lex_str = $lexer->get_token($lexer->yyLength());
						return ('FLOAT_NUM', $lex_str);
					}
				}
				$lexer->yyUnget();
			} elsif (
				($c == ord('x')) &&
				($lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START] == 2) &&
				(substr($string, $lexer->[LEXER_TOK_START], 1) eq '0')
			) {
				while($lexer->my_isxdigit($c = $lexer->yyGet())) {};
				if (($lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START]) >= 4 && (!$ident_map->[$c])) {
					my $lex_str = $lexer->get_token($lexer->yyLength());
					$lex_str = substr($lex_str, 2);
					return ('HEX_NUM', $lex_str);
				}
				$lexer->yyUnget();
			} elsif (
				($c == ord('b')) &&
				($lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START] == 2) &&
				(substr($string, $lexer->[LEXER_TOK_START], 1) eq '0')
			) {
				while($lexer->my_isxdigit($c = $lexer->yyGet())) {};
				if (($lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START]) >= 4 && (!$ident_map->[$c])) {
					my $lex_str = $lexer->get_token($lexer->yyLength());
					$lex_str = substr($lex_str, 2);
					return ('BIN_NUM', $lex_str);
				}
				$lexer->yyUnget();
			}
		}

		if ($state eq 'MY_LEX_IDENT_START') {
			$result_state = 'IDENT';
			# FIXME multibyte
			for ($result_state = 0; $ident_map->[$c = $lexer->yyGet()]; $result_state |= $c) {};
			$result_state = $result_state & 0x80 ? 'IDENT_QUOTED' : 'IDENT';

			if (($c == ord('.')) && ($ident_map->[$lexer->yyPeek()])) {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_IDENT_SEP';
			}

			my $lex_str = $lexer->get_token($lexer->yyLength());
			return($result_state, $lex_str);
		} elsif ($state eq 'MY_LEX_USER_VARIABLE_DELIMITER') {
			my $double_quotes = 0;
			my $quote_char = $c;
			$lexer->[LEXER_TOK_START] = $lexer->[LEXER_PTR];
			while ($c = $lexer->yyGet()) {
				my $var_length = $lexer->my_mbcharlen($c);
				if ($var_length == 1) {
					last if $c == ord(NAMES_SEP_CHAR);
					if ($c == $quote_char) {
						last if $lexer->yyPeek() != $quote_char;
						$c = $lexer->yyGet();
						$double_quotes++;
						next;
					}
				}
			}
			# MULTIBYTE!!

			my $lex_str;
				
			if ($double_quotes) {
				$lex_str = $lexer->get_quoted_token($lexer->yyLength() - $double_quotes, $quote_char);
			} else {
				$lex_str = $lexer->get_token($lexer->yyLength());
			}
		
			$lexer->yySkip() if $c == $quote_char;
			$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_START';
			return ('IDENT_QUOTED', $lex_str);
		} elsif ($state eq 'MY_LEX_INT_OR_REAL') {
			if ($c != ord ('.')) {
				my $lex_str = $lexer->get_token($lexer->yyLength());
				return $lexer->int_token($lex_str);
			}
		}

		if (
			($state eq 'MY_LEX_INT_OR_REAL') ||
			($state eq 'MY_LEX_REAL')
		) {
			while ($lexer->my_isdigit($c = $lexer->yyGet())) {};
			if (
				($c == ord('e')) ||
				($c == ord('E'))
			) {
				$c = $lexer->yyGet();
				if (
					($c == ord('+')) ||
					($c == ord('-'))
				) {
					$c = $lexer->yyGet();
				}
			
				if (!$lexer->my_isdigit($c)) {
					$state = 'MY_LEX_CHAR';
					next;
				}

				while ($lexer->my_isdigit($lexer->yyGet())) {};
			
				my $lex_str = $lexer->get_token($lexer->yyLength());
				return ('FLOAT_NUM', $lex_str);
			}
			
			my $lex_str = $lexer->get_token($lexer->yyLength());
			return ('DECIMAL_NUM', $lex_str);
		} elsif ($state eq 'MY_LEX_HEX_NUMBER') {
			$lexer->yyGet();
			while ($lexer->my_isdigit($lexer->yyGet())) {};
			my $length = $lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START];
			if (!($length & 1) || ($c != ord ("'"))) {
				return ('ABORT_SYM','ABORT_SYM');
			}
			$lexer->yyGet();
			my $lex_str = $lexer->get_token($length);
			$lex_str = substr($lex_str, 2, length($lex_str) - 3);
			return ('HEX_NUM', $lex_str);
		} elsif ($state eq 'MY_LEX_BIN_NUMBER') {
			$lexer->yyGet();
			while (($c = $lexer->yyGet()) == ord('0') || $c == ord ('1')) {};
			my $length = $lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START];
			if ($c != ord("'")) {
				return ('ABORT_SYM','ABORT_SYM');
			}
			$lexer->yyGet();
			my $lex_str = $lexer->get_token($length);
			$lex_str = substr($lex_str, 2, length($lex_str) - 3);
			return ('BIN_NUM', $lex_str);
		} elsif ($state eq 'MY_LEX_CMP_OP') {
			if (
				($state_map->[$lexer->yyPeek()] eq 'MY_LEX_CMP_OP') ||
				($state_map->[$lexer->yyPeek()] eq 'MY_LEX_LONG_CMP_OP')
			) {
				$lexer->yySkip();
			}
			if (@token = $lexer->find_keyword($lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START], 0)) {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_START';
				return @token;				# ADDED
			}
			$state = 'MY_LEX_CHAR';
			next;
		} elsif ($state eq 'MY_LEX_LONG_CMP_OP') {
			if (
				($state_map->[$lexer->yyPeek()] eq 'MY_LEX_CMP_OP') ||
				($state_map->[$lexer->yyPeek()] eq 'MY_LEX_LONG_CMP_OP')
			) {
				$lexer->yySkip();
				if ($state_map->[$lexer->yyPeek()] eq 'MY_LEX_CMP_OP') {
					$lexer->yySkip();
				}
			}
			if (@token = $lexer->find_keyword($lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START], 0)) {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_START';
				return @token;
			}
			$state = 'MY_LEX_CHAR';
			next;
		} elsif ($state eq 'MY_LEX_BOOL') {
			if ($c != $lexer->yyPeek()) {
				$state = 'MY_LEX_CHAR';
				next;
			}
			$lexer->yySkip();
			@token = $lexer->find_keyword(2, 0);
			$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_START';
			return @token;
		} elsif ($state eq 'MY_LEX_STRING_OR_DELIMITER') {
			if ($lexer->[LEXER_SQL_MODE] & MODE_ANSI_QUOTES) {
				$state = 'MY_LEX_USER_VARIABLE_DELIMITER';
				next;
			}
		}
		
		if (
			($state eq 'MY_LEX_STRING_OR_DELIMITER') ||
			($state eq 'MY_LEX_STRING')
		) {
			my $lex_str;
			if (!defined ($lex_str = $lexer->get_text())) {
				$state = 'MY_LEX_CHAR';
				next;
			}
			return ('TEXT_STRING', $lex_str);
		} elsif ($state eq 'MY_LEX_COMMENT') {
			$lexer->[LEXER_OPTIONS] |= OPTION_FOUND_COMMENT;
			while (($c = $lexer->yyGet()) != ord("\n") && $c) {};
			$lexer->yyUnget();
			$state = 'MY_LEX_START';
			next;
		} elsif ($state eq 'MY_LEX_LONG_COMMENT') {
			if ($lexer->yyPeek() != ord('*')) {
				$state = 'MY_LEX_CHAR';
				next;
			}
			$lexer->yySkip();
			$lexer->[LEXER_OPTIONS] |= OPTION_FOUND_COMMENT;
			if ($lexer->yyPeek() == ord('!')) {
				$lexer->yySkip();
				my $version = $lexer->[LEXER_VERSION];
				$state = 'MY_LEX_START';
				if ($lexer->my_isdigit($lexer->yyPeek())) {
					$version = substr($string, $lexer->[LEXER_PTR], 5);
					$lexer->[LEXER_PTR] += 5;	# FIXME for version numbers different from 5 characters
				}

				if ($version <= $lexer->[LEXER_VERSION]){
					$lexer->[LEXER_IN_COMMENT] = 1;
					next;
				}
			}

			while (
				($lexer->[LEXER_PTR] != length($string) - 1) && 
				(
					($c = $lexer->yyGet() != ord('*')) ||
					($lexer->yyPeek() != ord('/'))
				)
			) {
				$lexer->[LEXER_YYLINENO]++ if $c == ord("\n");
			}
			
			$lexer->yySkip() if $lexer->[LEXER_PTR] != length($string) - 1;

			$state = 'MY_LEX_START';
			next;
		} elsif ($state eq 'MY_LEX_END_LONG_COMMENT') {
			if ($lexer->[LEXER_IN_COMMENT] && $lexer->yyPeek() == ord('/')) {
				$lexer->yySkip();
				$lexer->[LEXER_IN_COMMENT] = 0;
				$state = 'MY_LEX_START';
			} else {
				$state = 'MY_LEX_CHAR';
			}
			next;
		} elsif ($state eq 'MY_LEX_SET_VAR') {
			if ($lexer->yyPeek() != ord ('=')) {
				$state = 'MY_LEX_CHAR';
				next;
			}
			$lexer->yySkip();
			return('SET_VAR','SET_VAR');
		} elsif ($state eq 'MY_LEX_SEMICOLON') {
			if ($lexer->yyPeek()) {
				if (
					($lexer->[LEXER_CLIENT_CAPABILITIES] & CLIENT_MULTI_STATEMENTS) && 
					(!$lexer->[LEXER_STMT_PREPARE_MODE])
				) {
					$lexer->[LEXER_SAFE_TO_CACHE_QUERY] = 0;
					$lexer->[LEXER_FOUND_SEMICOLON] = $lexer->[LEXER_PTR];
					$lexer->[LEXER_SERVER_STATUS] |= SERVER_MORE_RESULTS_EXISTS;
					$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_END';
					return ('END_OF_INPUT','');
				}
				$state = 'MY_LEX_CHAR';
				next;
			}
		}
		
		if (
			($state eq 'MY_LEX_SEMICOLON') ||
			($state eq 'MY_LEX_EOL')
		) {
			if ($lexer->[LEXER_PTR] >= length($string) - 1) {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_END';
				return ('END_OF_INPUT','');
			}
			$state = 'MY_LEX_CHAR';
			next;
		} elsif ($state eq 'MY_LEX_END') {
			$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_END';
			return (0,0);
		} elsif ($state eq 'MY_LEX_REAL_OR_POINT') {
			if ($lexer->my_isdigit($lexer->yyPeek())) {
				$state = 'MY_LEX_REAL';
			} else {
				$state = 'MY_LEX_IDENT_SEP';
				$lexer->yyUnget();
			}
			next;
		} elsif ($state eq 'MY_LEX_USER_END') {
			if (
				($state_map->[$lexer->yyPeek()] eq 'MY_LEX_STRING') ||
				($state_map->[$lexer->yyPeek()] eq 'MY_LEX_USER_VARIABLE_DELIMITER') ||
				($state_map->[$lexer->yyPeek()] eq 'MY_LEX_STRING_OR_DELIMITER')
			) {
				next;
			} elsif ($state_map->[$lexer->yyPeek()] eq 'MY_LEX_USER_END') {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_SYSTEM_VAR';
			} else {
				$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_HOSTNAME';
			}
			my $lex_str = substr($string, $lexer->[LEXER_PTR], 1);
			return ('@', $lex_str);
		} elsif ($state eq 'MY_LEX_HOSTNAME') {
			for ($c = $lexer->yyGet(); $lexer->my_isalnum($c) || $c == ord('.') || $c == ord('_') || $c == ord('$'); $c = $lexer->yyGet()) {};
			my $lex_str = $lexer->get_token($lexer->yyLength());
			return ('LEX_HOSTNAME', $lex_str);
		} elsif ($state eq 'MY_LEX_SYSTEM_VAR') {
			my $lex_str = substr($string, $lexer->[LEXER_PTR], 1);
			$lexer->yySkip();
			$lexer->[LEXER_NEXT_STATE] = $state_map->[$lexer->yyPeek()] eq 'MY_LEX_USER_VARIABLE_DELIMITER' ? 'MY_LEX_OPERATOR_OR_IDENT' : 'MY_LEX_IDENT_OR_KEYWORD';
			return ('@', $lex_str);
		} elsif ($state eq 'MY_LEX_IDENT_OR_KEYWORD') {
			for ($result_state = 0; $ident_map->[$c = $lexer->yyGet()]; $result_state |= $c) {};
			$result_state = $result_state & 0x80 ? 'IDENT_QUOTED' : 'IDENT';

			$lexer->[LEXER_NEXT_STATE] = 'MY_LEX_IDENT_SEP' if $c == ord('.');
	
			my $length = ($lexer->[LEXER_PTR] - $lexer->[LEXER_TOK_START]) - 1;
			return ('ABORT_SYM','ABORT_SYM') if $length == 0;
			if (@token = $lexer->find_keyword($length, 0)) {
				$lexer->yyUnget();
				return @token;
			}
			my $lex_str = $lexer->get_token($length);
			return ($result_state, $lex_str);
		}
	}
}

sub init_state_maps {

	my $lexer = shift;

	return if exists $state_maps{$lexer->[LEXER_CHARSET]};

	my @state_map;
	my @ident_map;

	for (my $i = 0; $i < 256; $i++) {
		if ($lexer->my_isalpha($i)) {
			$state_map[$i] = 'MY_LEX_IDENT';
		} elsif ($lexer->my_isdigit($i)) {
			$state_map[$i] = 'MY_LEX_NUMBER_IDENT';
		# FIXME MULTI-BYTE
		} elsif ($lexer->my_isspace($i)) {
			$state_map[$i] = 'MY_LEX_SKIP';
		} else {
			$state_map[$i] = 'MY_LEX_CHAR';
		}
	}

	$state_map[ord('_')] = $state_map[ord('$')] = 'MY_LEX_IDENT';
	$state_map[ord("'")] = 'MY_LEX_STRING';
	$state_map[ord('.')] = 'MY_LEX_REAL_OR_POINT';

	$state_map[ord('>')] = $state_map[ord('=')] = $state_map[ord('!')] = 'MY_LEX_CMP_OP';
	$state_map[ord('<')] = 'MY_LEX_LONG_CMP_OP';
	$state_map[ord('&')] = $state_map[ord('|')] = 'MY_LEX_BOOL';
	$state_map[ord('#')] = 'MY_LEX_COMMENT';
	$state_map[ord(';')] = 'MY_LEX_SEMICOLON';
	$state_map[ord(':')] = 'MY_LEX_SET_VAR';
	$state_map[0] = 'MY_LEX_EOL';
	$state_map[ord("\\")] = 'MY_LEX_ESCAPE';
	$state_map[ord('/')] = 'MY_LEX_LONG_COMMENT';
	$state_map[ord('*')] = 'MY_LEX_END_LONG_COMMENT';
	$state_map[ord('@')] = 'MY_LEX_USER_END';
	$state_map[ord('`')] = 'MY_LEX_USER_VARIABLE_DELIMITER';
	$state_map[ord('"')] = 'MY_LEX_STRING_OR_DELIMITER';

	for (my $i=0; $i < 256 ; $i++) {
		$ident_map[$i] = ($state_map[$i] eq 'MY_LEX_IDENT') || ($state_map[$i] eq 'MY_LEX_NUMBER_IDENT');
	}

	$state_map[ord('x')] = $state_map[ord('X')] = 'MY_LEX_IDENT_OR_HEX';
	$state_map[ord('b')] = $state_map[ord('B')] = 'MY_LEX_IDENT_OR_BIN';
	$state_map[ord('n')] = $state_map[ord('N')] = 'MY_LEX_IDENT_OR_NCHAR';

	$state_maps{$lexer->[LEXER_CHARSET]} = \@state_map;
	$ident_maps{$lexer->[LEXER_CHARSET]} = \@ident_map;
}


sub my_mbcharlen { 1 };

sub my_isalpha { $_[0]->[LEXER_CTYPE]->[$_[1] + 1] & (CTYPE_U | CTYPE_L) }

sub my_isalnum { $_[0]->[LEXER_CTYPE]->[$_[1] + 1] & (CTYPE_U | CTYPE_L | CTYPE_NMR) }

sub my_isxdigit { $_[0]->[LEXER_CTYPE]->[$_[1] + 1] & CTYPE_X }

sub my_isdigit { $_[0]->[LEXER_CTYPE]->[$_[1] + 1] & CTYPE_NMR }

sub my_isspace { $_[0]->[LEXER_CTYPE]->[$_[1] + 1] & CTYPE_SPC }

sub my_iscntrl { $_[0]->[LEXER_CTYPE]->[$_[1] + 1] & CTYPE_CTR }

sub get_text {
	my $lexer = shift;
	my $string = $lexer->[LEXER_STRING];
	my $sep = $lexer->yyGetLast();
	my $found_escape = 0;
	while ($lexer->[LEXER_PTR] != length($lexer->[LEXER_STRING]) - 1) {
		my $c = $lexer->yyGet();
		if (
			($c == ord("\\")) &&
			(!($lexer->[LEXER_SQL_MODE] & MODE_NO_BACKSLASH_ESCAPES))
		) {
			$found_escape = 1;
			return undef if $lexer->[LEXER_PTR] == length($lexer->[LEXER_STRING]);
			$lexer->yySkip();
		} elsif ($c == $sep) {
			if ($c == $lexer->yyGet()) {
				$found_escape = 1;
				next;
			} else {				
				$lexer->yyUnget();
			}
			
			my ($str, $end, $start);

			$str = $lexer->[LEXER_TOK_START] + 1;
			$end = $lexer->[LEXER_PTR] - 1;

			my $to;

			if (!$found_escape) {
				my $yytoklen = $end - $str;	# CHANGED
				if ($yytoklen > 0) {
					return substr($lexer->[LEXER_STRING], $str, $yytoklen);
				} else {
					return '';
				}
			} else {
				my $new_str = '';		# ADDED
				for ($to = $start; $str != $end; $str++) {
					if (
						(!($lexer->[LEXER_SQL_MODE] & MODE_NO_BACKSLASH_ESCAPES)) &&
						(substr($string, $str, 1) eq "\\") &&
						($str + 1 != $end)
					) {
						my $prev_str = substr($string, ++$str, 1);
						if ($prev_str eq 'n') {
							substr($new_str, $to++, 1) = "\n";
							next;
						} elsif ($prev_str eq 't') {
							substr($new_str, $to++, 1) = "\t";
							next;
						} elsif ($prev_str eq 'r') {
							substr($new_str, $to++, 1) = "\r";
							next;
						} elsif ($prev_str eq 'b') {
							substr($new_str, $to++, 1) = "\b";
							next;
						} elsif ($prev_str eq '0') {
							substr($new_str, $to++, 1) = "\0";
							next;
						} elsif ($prev_str eq 'Z') {
							substr($new_str, $to++, 1) = "\032";
							next;
						} elsif (
							($prev_str eq '_') ||
							($prev_str eq '%')
						) {
							substr($new_str, $to++, 1) = "\\";
							substr($new_str, $to++, 1) = $prev_str;	# Added
						} else {
							substr($new_str, $to++, 1) = $prev_str;
						}
					} elsif (substr($string, $str, 1) eq $sep) {
						substr($new_str, $to++, 1) = substr($string, $str++, 1);
					} else {
						substr($new_str, $to++, 1) = substr($string, $str, 1);
					}
				}
				return $new_str;
			}
			return substr($string, $start, ($to - $start));
		}
	}
	return undef;
}

sub get_token {
	my ($lexer, $length) = @_;
	$lexer->yyUnget();
	return substr($lexer->[LEXER_STRING], $lexer->[LEXER_TOK_START], $length);
}

use constant LONG_STR		=> "2147483647";
use constant LONG_LEN 		=> 10;
use constant SIGNED_LONG_STR	=> "-2147483648";
use constant LONGLONG_STR	=> "9223372036854775807";
use constant LONGLONG_LEN	=> 19;
use constant SIGNED_LONGLONG_STR => "-9223372036854775808";
use constant SIGNED_LONGLONG_LEN => 19;
use constant UNSIGNED_LONGLONG_STR => "18446744073709551615";
use constant UNSIGNED_LONGLONG_LEN => 20;

sub int_token {
	my ($lexer, $token) = @_;
	
	if (length($token) < LONG_LEN) {
		return ("NUM", $token);
	}

	my $neg = 0;

	if (substr($token, 0, 1) eq '+') {
		$token = substr($token, 1);
	} elsif (substr($token, 0, 1) eq '-') {
		$token = substr($token, 1);
		$neg = 1;
	}

	while (
		(substr($token, 0, 1) eq '0') &&
		(length($token) > 0)
	) {
		$token = substr($token, 1);
	}

	if (length($token) < LONG_LEN) {
		return ("NUM", $token);
	}

	my ($smaller, $bigger);
	my $cmp;

	if ($neg) {
		if (length($token) == LONG_LEN) {
			$cmp = SIGNED_LONG_STR + 1;
			$smaller = 'NUM';
			$bigger = 'LONG_NUM';
		} elsif (length($token) < SIGNED_LONGLONG_LEN) {
			return ('LONG_NUM', $token);
		} elsif (length($token) > SIGNED_LONGLONG_LEN) {
			return ('DECIMAL_SYM', $token);
		} else {
			$cmp = SIGNED_LONGLONG_STR + 1;
			$smaller = 'LONG_NUM';
			$bigger = 'DECIMAL_NUM';
		}
	} else {
		if (length($token) == LONGLONG_LEN) {
			$cmp = LONG_STR;
			$smaller = 'NUM';
			$bigger = 'LONG_NUM';
		} elsif (length($token) < LONGLONG_LEN) {
			return('LONG_NUM', $token);
		} elsif (length($token) > LONGLONG_LEN) {
			if (length($token) > UNSIGNED_LONGLONG_LEN) {
				return ('DECIMAL_NUM', $token);
			}
			$cmp = UNSIGNED_LONGLONG_STR;
			$smaller = 'ULONGLONG_NUM';
			$bigger = 'DECIMAL_NUM';
		} else {
			$cmp = LONGLONG_STR;
			$smaller = 'LONG_NUM';
			$bigger = 'ULONGLONG_NUM';
		}
	}
		
	return $token > $cmp ? ($bigger, $token) : ($smaller, $token);
}

sub find_keyword {
	my ($lexer, $length, $function) = @_;
	my $keyword = substr($lexer->[LEXER_STRING], $lexer->[LEXER_TOK_START], $length);

	my $symbol;
	if ($function) {
		$symbol = $DBIx::MyParsePP::Symbols::functions->{uc($keyword)};
		$symbol = $DBIx::MyParsePP::Symbols::symbols->{uc($keyword)} if not defined $symbol;
	} else {
		$symbol = $DBIx::MyParsePP::Symbols::symbols->{uc($keyword)};
	}

	return () if not defined $symbol;
	
	if (
		($symbol eq 'NOT_SYM') &&
		($lexer->[LEXER_SQL_MODE] & MODE_HIGH_NOT_PRECEDENCE)
	) {
		$symbol = 'NOT2_SYM';
	}

	if (
		($symbol eq 'OR_OR_SYM') &&
		($lexer->[LEXER_SQL_MODE] & MODE_PIPES_AS_CONCAT)
	) {
		$symbol = 'OR2_SYM';
	}

	return ($symbol, $keyword);
}

1;


__END__

=pod

=head1 NAME

DBIx::MyParsePP::Lexer - Pure-perl SQL lexer based on MySQL's source

=head1 SYNOPSIS

	use DBIx::MyParsePP::Lexer;
	use Data::Dumper;

	my $lexer = DBIx::MyParsePP::Lexer->new(
		string => $string
	);
	
	while ( my $token = $lexer->yylex() ) {

		print Dumper $token;
		
		last if $token->type() eq 'END_OF_INPUT';
		print $lexer->pos();
		print $lexer->line();
	
	}

=head1 DESCRIPTION

C<DBIx::MyParsePP::Lexer> is a translation of the lexer function from MySQL into pure Perl.

The goal of the translation was to closely follow the method of operation of the original lexer --
therefore performance is suffering at the expense of compatibility. For example, the original character set
definitions are used, rather than determining which letter is uppercase or lowercase using a Perl regular
expression.

=head1 CONSTRUCTOR

The following arguments are available for the constructor. They are passed from L<DBIx::MyParsePP>:

C<string> is the string being parsed.

C<charset> is the character set of the string. This is important when determining what is a number and what is a
separator in the string. The default value is C<'ascii'>, which is the only charset bundled with L<DBIx::MyParsePP>
by default. Please contact the author if you need support for other character sets.

C<version> is the MySQL version to be emulated. This only affects the processing of /*!##### sql_clause */ comments, where
##### is the minimum version required to process sql_clause. The grammar itself is taken from MySQL 5.0.45, which is the
default value of C<version>.

C<sql_mode> contains flags that influence the behavoir of the parser. Valid constants are C<MODE_PIPES_AS_CONCAT>,
C<MODE_ANSI_QUOTES>, C<MODE_IGNORE_SPACE>, C<MODE_NO_BACKSLASH_ESCAPES> and C<MODE_HIGH_NOT_PRECEDENCE>.
The flags can be combined with the C<|> operator. By default no flags are set.

C<client_capabilities> is flag reflecting the capabilities of the client that issued the query. Currently the only
flag accepted is C<CLIENT_MULTI_STATEMENTS>, which controls whether several SQL statements can be parsed at once.
By default no flags are set.

C<stmt_prepare_mode> controls whether the statement being parsed is a prepared statement. The default is C<0>, however
if this flag is set to C<1>, multiple SQL statements can not be parsed at once.

=head1 METHODS

C<pos()> and C<getPos()> return the current character position as counted from the start of the string

C<getLine()> and C<line()> return the current line number.

C<getTokens()> returns a reference to an array containing all tokens parsed so far.

=head1 LICENCE

This file contains code derived from code Copyright (C) 2000-2006 MySQL AB

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License in the file named LICENCE for more details.

=cut
