package DBIx::MyParsePP::Query;
use strict;

use DBIx::MyParsePP::Lexer;
use DBIx::MyParsePP::Rule;

use constant MYPARSE_QUERY_LEXER		=> 0;
use constant MYPARSE_QUERY_ROOT			=> 1;
use constant MYPARSE_QUERY_EXPECTED		=> 2;
use constant MYPARSE_QUERY_ACTUAL		=> 3;

my %args = (
	lexer		=> MYPARSE_QUERY_LEXER,
	root		=> MYPARSE_QUERY_ROOT
);

1;

sub new {
	my $class = shift;

	my $query = bless([], $class);
	my $max_arg = (scalar(@_) / 2) - 1;

        foreach my $i (0..$max_arg) {
		if (exists $args{$_[$i * 2]}) {
			$query->[$args{$_[$i * 2]}] = $_[$i * 2 + 1];
		} else {
			warn("Unkown argument '$_[$i * 2]' to DBIx::MyParsePP::Query->new()");
		}
	}

	return $query;
}

sub getLexer {
	return $_[0]->[MYPARSE_QUERY_LEXER];
}

sub setRoot {
	$_[0]->[MYPARSE_QUERY_ROOT] = $_[1];
}	

sub getRoot {
	return $_[0]->[MYPARSE_QUERY_ROOT];
}

sub root {
	return $_[0]->[MYPARSE_QUERY_ROOT];
}

sub setExpected {
	my $query = shift;
	$query->[MYPARSE_QUERY_EXPECTED] = \@_;
}

sub getExpected {
	return $_[0]->[MYPARSE_QUERY_EXPECTED];
}

sub expected {
	return $_[0]->[MYPARSE_QUERY_EXPECTED];
}

sub setActual {
	$_[0]->[MYPARSE_QUERY_ACTUAL] = $_[1];
}

sub getActual {
	return $_[0]->[MYPARSE_QUERY_ACTUAL];
}

sub actual {
	return $_[0]->[MYPARSE_QUERY_ACTUAL];
}

sub line {
	$_[0]->getLine();
}
	
sub getLine {
	my $query = shift;
	my $lexer = $query->getLexer();
	return $lexer->getLine();
}

sub pos {
	$_[0]->getPos();
}
sub getPos {
	my $query = shift;
	my $lexer = $query->getLexer();
	return $lexer->getPos();
}

sub tokens {
	$_[0]->getTokens();
}

sub getTokens {
	my $query = shift;
	my $lexer = $query->getLexer();
	return $lexer->getTokens();	
}

sub toString() {
	my $query = shift;
	my $root = $query->root();
	return defined $root ? $root->toString() : undef;
}

sub print {
	return $_[0]->toString();
}

sub extract {
	my $query = shift;
	my $root = $query->root();
	return defined $root ? $root->extract(@_) : undef;
}

sub shrink {
	my $query = shift;
	my $root = $query->root();
	return defined $root ? $root->shrink() : undef;
}

sub getWhere {
	return $_[0]->extract('where_clause');
}

sub getGroupBy {
	return $_[0]->extract('group_clause');
}

sub getOrderBy {
	return $_[0]->extract('order_clause');
}

sub getLimit {
	return $_[0]->extract('limit_clause');
}

sub getFrom {
	return $_[0]->extract('table_factor','join_table','derived_table_list','select_from');
}

sub getSelectItems {
	return $_[0]->extract('select_item_list','select_part2','select_init');
}

sub getFields {
	my $root = $_[0]->root();
	return defined $root ? $root->getFields() : undef;
}

sub getTables {
	my $root = $_[0]->root();
	return defined $root ? $root->getTables() : undef;
}

1;

__END__

=pod

=head1 NAME

DBIx::MyParsePP::Query - Query produced by DBIx::MyParsePP

=head1 SYNOPSIS

	use DBIx::MyParsePP;

	my $parser = DBIx::MyParsePP->new();

	my $query = $parser->parse("SELECT 1");

	if (not defined $query->root()) {
		print "Error at pos ".$query->pos()", line ".$pos->line()."\n";
	} else {
		print "Query was ".$query->toString();
	}

=head1 METHODS

C<getLexer()> returns the L<DBIx::MyParsePP::Lexer> object for the string

C<getRoot()> returns a L<DBIx::MYParsePP::Rule> object representing the root of the parse tree

C<toString()> walks the parse tree reconstructs the query using the individual tokens.

C<tokens()> and C<getTokens()> returns a reference to an array containing all tokens parsed as L<DBIx::MyParsePP::Token>
objects. If the parsing failed, the list contains all tokens up to the failure point.

=head1 ERROR HANDLING

On error, C<getRoot()> will return C<undef>. You can call the following methods to determine the error:

C<getExpected()> returns a list of tokens the parser expected to find, whereas C<getActual()> returns the
actual token name that was encountered which caused the error. Please note that C<getActual()> returns a
L<DBIx::MyParsePP::Token> object, whereas C<getExpected()> returns a list of strings, containing
just the token types.

C<getLine()> returns the line number where the error occured. C<getPos()> returns the character position where the
error occured, counting from the beginning of the string, not the begining of the line.

C<getTokens()> can be used to reconstruct the query as it was up to the failure point.

=head1 UTILITY FUNCTIONS

C<getSelectItems()>, C<getFrom()>, C<getWhere()>, C<getGroupBy()>, C<getOrderBy()>, C<getHaving()> return the
respective parts of the parse tree as a L<DBIx::MyParsePP::Rule> object. Depending on the query, the part of the
tree that is being returned may look differently, e.g. C<getFrom()> will return widely different things depending
on how many tables are in the C<FROM> clause, whether there are joins or subqueries. You can then use C<shrink()> and
C<extract()> on the return value to further narrow down on the part of the query you are interested in.

=cut
