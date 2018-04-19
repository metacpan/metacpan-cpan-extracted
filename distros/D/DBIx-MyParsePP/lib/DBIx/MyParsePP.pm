package DBIx::MyParsePP;
use strict;

use DBIx::MyParsePP::Lexer;
use DBIx::MyParsePP::Parser;
use DBIx::MyParsePP::Query;


our $VERSION = '0.51';

use constant MYPARSEPP_YAPP			=> 0;
use constant MYPARSEPP_CHARSET			=> 1;
use constant MYPARSEPP_VERSION			=> 2;
use constant MYPARSEPP_SQL_MODE			=> 3;
use constant MYPARSEPP_CLIENT_CAPABILITIES	=> 4;
use constant MYPARSEPP_STMT_PREPARE_MODE	=> 5;

my %args = (
	charset		=> MYPARSEPP_CHARSET,
	version		=> MYPARSEPP_VERSION,
	sql_mode	=> MYPARSEPP_SQL_MODE,
	client_capabilities	=> MYPARSEPP_CLIENT_CAPABILITIES,
	stmt_prepare_mode	=> MYPARSEPP_STMT_PREPARE_MODE
);

1;

sub new {
	my $class = shift;
	my $parser = bless ([], $class );

        my $max_arg = (scalar(@_) / 2) - 1;

        foreach my $i (0..$max_arg) {
                if (exists $args{$_[$i * 2]}) {
                        $parser->[$args{$_[$i * 2]}] = $_[$i * 2 + 1];
                } else {
                        warn("Unkown argument '$_[$i * 2]' to DBIx::MyParsePP->new()");
                }
        }

	my $yapp = DBIx::MyParsePP::Parser->new();
	$parser->[MYPARSEPP_YAPP] = $yapp;
	return $parser;
}

sub parse {
	my ($parser, $string) = @_;

	my $lexer = DBIx::MyParsePP::Lexer->new(
		string => $string,
		charset => $parser->[MYPARSEPP_CHARSET],
		version	 => $parser->[MYPARSEPP_VERSION],
		sql_mode => $parser->[MYPARSEPP_SQL_MODE],
		client_capabilities => $parser->[MYPARSEPP_CLIENT_CAPABILITIES],
		stmt_prepare_mode => $parser->[MYPARSEPP_CLIENT_CAPABILITIES]
	);
		
	my $query = DBIx::MyParsePP::Query->new(
		lexer => $lexer
	);

	my $yapp = $parser->[MYPARSEPP_YAPP];
	my $result = $yapp->YYParse( yylex => sub { $lexer->yylex() }, yyerror => sub { $parser->error(@_, $query) } );

	if (defined $result) {
		$query->setRoot($result->[0]);
	}

	return $query;
}

sub error {
	my ($parser, $yapp, $query) = @_;
	$query->setActual($yapp->YYCurval);
	$query->setExpected($yapp->YYExpect);
}

1;

__END__

=head1 NAME

DBIx::MyParsePP - Pure-perl SQL parser based on MySQL grammar and lexer

=head1 SYNOPSIS

  use DBIx::MyParsePP;
  use Data::Dumper;

  my $parser = DBIx::MyParsePP->new();

  my $query = $parser->parse("SELECT 1");

  print Dumper $query;
  print $query->toString();

=head1 DESCRIPTION

C<DBIx::MyParsePP> is a pure-perl SQL parser that implements the MySQL grammar and lexer.
The grammar was automatically converted from the original C<sql_yacc.yy> file by removing all
the C code. The lexer comes from C<sql_lex.cc>, completely translated in Perl almost verbatim.

The grammar is converted into Perl form using L<Parse::Yapp>.

=head1 CONSTRUCTOR

C<charset>, C<version>, C<sql_mode>, C<client_capabilities> and C<stmt_prepare_mode> can be passed
as arguments to the constructor. Please C<use DBIx::MyParsePP::Lexer> to bring in the required constants
and see L<DBIx::MyParsePP::Lexer> for information.

=head1 METHODS

C<DBIx::MyParsePP> provides C<parse()> which takes the string to be parsed.
The result is a L<DBIx::MyParsePP::Query> object which contains the result from the parsing.

Queries can be reconstructed back into SQL by calling the C<toString()> method.

=head1 SPECIAL CONSIDERATIONS

The file containing the grammar C<lib/DBIx/MyParsePP/Parser.pm> is about 5 megabytes in size
and takes a while to load. Compex statements take a while to parse, e.g. the first Twins query
from the MySQL manual can only be parsed at a speed of few queries per second per 1GHz of CPU. If
you require a full-speed parsing solution, please take a look at L<DBIx::MyParse>, which requires
a GCC compiler and produces more concise parse trees.

The parse trees produced by C<DBIx::MyParsePP> contain one leaf for every grammar rule that has been
matched, even rules that serve no useful purpose. Therefore, parsing event simple statements such
as C<SELECT 1> produce trees dozens of levels deep. Please exercise caution when walking those trees
recursively. The L<DBIx::MyParsePP::Rule> module contains the C<extract()> and C<shrink()> methods
which are useful for dealing with the inherent complexity of the MySQL grammar.

=head1 USING GRAMMARS FROM OTHER MYSQL VERSIONS

The package by default parses strings using the grammar from MySQL version 5.0.45. If you wish to use
the grammar from a different version, you can use the C<bin/myconvpp.pl> script to prepare the grammar:

	$ perl bin/myconvpp.pl --

=head1 SEE ALSO

For Yacc grammars, please see the Bison manual at:

	http://www.gnu.org/software/bison

For generating Yacc parsers in Perl, please see:

	http://search.cpan.org/~fdesar

For a full-speed C++-based parser that generates nicer parse trees, please see L<DBIx::MyParse>

=head1 AUTHOR

Philip Stoev, E<lt>philip@stoev.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Philip Stoev

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public Licence as specified in
the README and LICENCE files.

Please note that this module contains code copyright by MySQL AB released under
the GNU General Public Licence, and not the GNU Lesser General Public Licence.
Using this code for commercial purposes may require purchasing a licence from MySQL AB.

=cut
