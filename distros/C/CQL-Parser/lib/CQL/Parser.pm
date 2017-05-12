package CQL::Parser;

use strict;
use warnings;
use CQL::Lexer;
use CQL::Relation;
use CQL::Token;
use CQL::TermNode;
use CQL::AndNode;
use CQL::OrNode;
use CQL::NotNode;
use CQL::PrefixNode;
use CQL::ProxNode;
use Carp qw( croak );

our $VERSION = '1.13';

my $lexer;
my $token;

=head1 NAME

CQL::Parser - compiles CQL strings into parse trees of Node subtypes.

=head1 SYNOPSIS

    use CQL::Parser;
    my $parser = CQL::Parser->new();
    my $root = $parser->parse( $cql );

=head1 DESCRIPTION

CQL::Parser provides a mechanism to parse Common Query Language (CQL)
statements. The best description of CQL comes from the CQL homepage
at the Library of Congress L<http://www.loc.gov/z3950/agency/zing/cql/>

CQL is a formal language for representing queries to information
retrieval systems such as web indexes, bibliographic catalogs and museum
collection information. The CQL design objective is that queries be
human readable and human writable, and that the language be intuitive
while maintaining the expressiveness of more complex languages.

A CQL statement can be as simple as a single keyword, or as complicated as a set
of compoenents indicating search indexes, relations, relational modifiers,
proximity clauses and boolean logic. CQL::Parser will parse CQL statements
and return the root node for a tree of nodes which describes the CQL statement.
This data structure can then be used by a client application to analyze the
statement, and possibly turn it into a query for a local repository.

Each CQL component in the tree inherits from L<CQL::Node> and can be one
of the following: L<CQL::AndNode>, L<CQL::NotNode>, L<CQL::OrNode>,
L<CQL::ProxNode>, L<CQL::TermNode>, L<CQL::PrefixNode>. See the
documentation for those modules for their respective APIs.

Here are some examples of CQL statements:

=over 4

=item * george

=item * dc.creator=george

=item * dc.creator="George Clinton"

=item * clinton and funk

=item * clinton and parliament and funk

=item * (clinton or bootsy) and funk

=item * dc.creator="clinton" and dc.date="1976"

=back

=head1 METHODS

=head2 new()

=cut

## for convenience the lexer is located at the package level
## just need to be sure to reinitialize it in very call to parse()

sub new {
    my ( $class, $debug ) = @_;
    $CQL::DEBUG = $debug ? 1 : 0;
    return bless { }, ref($class) || $class;
}

=head2 parse( $query )

Pass in a CQL query and you'll get back the root node for the CQL parse tree.
If the CQL is invalid an exception will be thrown.

=cut

sub parse {
    my ($self,$query) = @_;

    ## initialize lexer
    $lexer = CQL::Lexer->new();

    debug( "about to parse query: $query" ); 
    
    ## create the lexer and get the first token
    $lexer->tokenize( $query );
    $token = $lexer->nextToken();

    my $root = parseQuery( 'srw.ServerChoice', CQL::Relation->new( 'scr' ) );
    if ( $token->getType() != CQL_EOF ) { 
        croak( "junk after end ".$token->getString() );
    }
    
    return $root;
}

=head2 parseSafe( $query )

Pass in a CQL query and you'll get back the root node for the CQL parse tree.
If the CQL is invalid, an error code from the SRU Diagnostics List 
will be returned.

=cut

my @cql_errors = (
    { regex => qr/does not support relational modifiers/,   code => 20 },
    { regex => qr/expected boolean got /,                   code => 37 },
    { regex => qr/expected relation modifier got /,         code => 20 },
    { regex => qr/unknown first-class relation modifier: /, code => 20 },
    { regex => qr/missing term/,                            code => 27 },
    { regex => qr/expected proximity relation got /,        code => 40 },
    { regex => qr/expected proximity distance got /,        code => 41 },
    { regex => qr/expected proximity unit got/,             code => 42 },
    { regex => qr/expected proximity ordering got /,        code => 43 },
    { regex => qr/unknown first class relation: /,          code => 19 },
    { regex => qr/must supply name/,                        code => 15 },
    { regex => qr/must supply identifier/,                  code => 15 },
    { regex => qr/must supply subtree/,                     code => 15 },
    { regex => qr/must supply term parameter/,              code => 27 },
    { regex => qr/doesn\'t support relations other than/,   code => 20 },
);

sub parseSafe {
    my ($self,$query) = @_;

    my $root = eval { $self->parse( $query ); };

    if ( my $error = $@ ) {
        my $code = 10;
        for( @cql_errors ) {
            $code = $_->{ code } if $error =~ $_->{ regex };
        }
        return $code;
    }

    return $root;
}

sub parseQuery {
    my ( $qualifier, $relation ) = @_;
    debug( "in parseQuery() with term=" . $token->getString() );
    my $term = parseTerm( $qualifier, $relation );

    my $type = $token->getType();
    while ( $type != CQL_EOF and $type != CQL_RPAREN ) { 
        if ( $type == CQL_AND ) { 
            match($token);
            my $term2 = parseTerm( $qualifier, $relation );
            $term = CQL::AndNode->new( left=>$term, right=>$term2 );
        } 
        elsif ( $type == CQL_OR ) {
            match($token);
            my $term2 = parseTerm( $qualifier, $relation );
            $term = CQL::OrNode->new( left=>$term, right=>$term2 );
        }
        elsif ( $type == CQL_NOT ) { 
            match($token);
            my $term2 = parseTerm( $qualifier, $relation );
            $term = CQL::NotNode->new( left=>$term, right=>$term2 );
        }
        elsif ( $type == CQL_PROX ) { 
            match($token);
            my $proxNode = CQL::ProxNode->new( $term );
            gatherProxParameters( $proxNode );
            my $term2 = parseTerm( $qualifier, $relation );
            $proxNode->addSecondTerm( $term2 );
            $term = $proxNode;
        } 
        else {
            croak( "expected boolean got ".$token->getString() );
        }
        $type = $token->getType();
    }
    debug( "no more ops" );
    return( $term );
}

sub parseTerm {
    my ( $qualifier, $relation ) = @_;
    debug( "in parseTerm()" );
    my $word;
    while ( 1 ) { 
        if ( $token->getType() == CQL_LPAREN ) { 
            debug( "parenthesized term" );
            match( CQL::Token->new('(') );
            my $expr = parseQuery( $qualifier, $relation );
            match( CQL::Token->new(')') );
            return $expr;
        } 
        elsif ( $token->getType() == CQL_GT ) {
            match( $token );
            return parsePrefix( $qualifier, $relation );
        }

        debug( "non-parenthesised term" );
        $word = matchSymbol( "qualifier or term" );

        last if ! isBaseRelation();

        $qualifier = $word;
        debug( "creating relation with word=$word" );
        $relation = CQL::Relation->new( $token->getString() );
        match( $token );

        while ($token->getType() == CQL_MODIFIER ) {
            match( $token );
            if ( !isRelationModifier() ) {
                croak( "expected relation modifier got " . $token->getString() );
            }
            $relation->addModifier( $token->getString() );
            match( $token );
        }
    }

    debug( "qualifier=$qualifier relation=$relation term=$word" );
    croak( "missing term" ) if ! defined($word) or $word eq '';

    my $node = CQL::TermNode->new( 
        qualifier   => $qualifier, 
        relation    => $relation, 
        term        => $word 
    );
    debug( "made term node: ".$node->toCQL() );
    return $node;
}

sub parsePrefix {
    my ( $qualifier, $relation ) = @_;
    debug( "prefix mapping" );
    my $name = undef;
    my $identifier = matchSymbol( "prefix name" );
    if ( $token->getType() == CQL_EQ ) {
        match( $token );
        $name = $identifier;
        $identifier = matchSymbol( "prefix identifier" );
    }
    my $node = parseQuery( $qualifier, $relation );
    return CQL::PrefixNode->new(
        name        => $name,
        identifier  => $identifier,
        subtree     => $node 
    );
}

sub gatherProxParameters {
    my $node = shift;
    if (0) {	# CQL 1.0 (obsolete)
    for (my $i=0; $i<4; $i++ ) {
        if ( $token->getType() != CQL_MODIFIER ) { 
            ## end of proximity parameters 
            return;
        }
        match($token);
        if ( $token->getType() != CQL_MODIFIER ) { 
            if ( $i==0 ) { gatherProxRelation($node); }
            elsif ( $i==1 ) { gatherProxDistance($node); }
            elsif ( $i==2 ) { gatherProxUnit($node); }
            elsif ( $i==3 ) { gatherProxOrdering($node); }
        }
    }
    } else {
        while ( $token->getType() == CQL_MODIFIER ) {
	    match( $token );
	    if ( $token->getType() == CQL_DISTANCE ) {
		match( $token );
		gatherProxRelation( $node );
		gatherProxDistance( $node );
	    } elsif ( $token->getType() == CQL_UNIT ) {
		match( $token );
		if ( $token->getType() != CQL_EQ ) {
		    croak( "expected proximity unit parameter got ".$token->getString() );
		}
		match( $token );
		gatherProxUnit( $node );
	    } elsif ( $token->getType() == CQL_ORDERED
		      || $token->getType() == CQL_UNORDERED ) {
		gatherProxOrdering( $node );
	    } else {
		croak( "expected proximity parameter got ". $token->getString()  ."(". $token->getType() .")" );
	    }
        }
    }
}

sub gatherProxRelation {
    my $node = shift;
    if ( ! isProxRelation() ) { 
        croak( "expected proximity relation got ".$token->getString() );
    }
    $node->addModifier( "relation", $token->getString() );
    match( $token );
    debug( "gatherProxRelation matched ".$token->getString() );
}

sub gatherProxDistance {
    my $node = shift;
    if ( $token->getString() !~ /^\d+$/ ) { 
        croak( "expected proximity distance got ".$token->getString() );
    }
    $node->addModifier( "distance", $token->getString() );
    match( $token );
    debug( "gatherProxDistance matched ".$token->getString() );
}

sub gatherProxUnit {
    my $node = shift;
    my $type = $token->getType();
    if( $type != CQL_PWORD and $type != CQL_SENTENCE and $type != CQL_PARAGRAPH
        and $type != CQL_ELEMENT ) {
        croak( "expected proximity unit got ".$token->getString() );
    }
    $node->addModifier( "unit", $token->getString() );
    match( $token );
    debug( "gatherProxUnit matched ".$token->getString() );
}

sub gatherProxOrdering {
    my $node = shift;
    my $type = $token->getType();
    if ( $type != CQL_ORDERED and $type != CQL_UNORDERED ) {
        croak( "expected proximity ordering got ".$token->getString() );
    }
    $node->addModifier( "ordering", $token->getString() );
    match( $token );
}

sub isBaseRelation {
    debug( "inside base relation: checking ttype=".$token->getType()." sval=".
        $token->getString() );
    if( $token->getType() == CQL_WORD and $token->getString() !~ /\./ ) {
        croak( "unknown first class relation: ".$token->getString() );
    }
    my $type = $token->getType();
    return( isProxRelation() or $type==CQL_ANY or $type==CQL_ALL 
        or $type==CQL_EXACT or $type==CQL_SCR or $type==CQL_WORD 
        or $type==CQL_WITHIN or $type==CQL_ENCLOSES);
}

sub isProxRelation {
    debug( "isProxRelation: checking ttype=".$token->getType()." sval=".
        $token->getString() );
    my $type = $token->getType();
    return( $type==CQL_LT or $type==CQL_GT or $type==CQL_EQ or $type==CQL_LE
        or $type==CQL_GE or $type==CQL_NE );
}

sub isRelationModifier {
    my $type = $token->getType();
    if ($type == CQL_WORD) {
        return $token->getString() =~ /\./;
    }
    return ($type==CQL_RELEVANT or $type==CQL_FUZZY or $type==CQL_STEM
        or $type==CQL_PHONETIC or $type==CQL_PWORD or $type==CQL_STRING
        or $type==CQL_ISODATE or $type==CQL_NUMBER or $type==CQL_URI
        or $type==CQL_PARTIAL or $type==CQL_MASKED or $type==CQL_UNMASKED
        or $type==CQL_NWSE);
}

sub match {
    my $expected = shift;
    debug( "in match(".$expected->getString().")" );
    if ( $token->getType() != $expected->getType() ) {
        croak( "expected ".$expected->getString() . 
            " but got " . $token->getString() );
    }
    $token = $lexer->nextToken();
    debug( "got token type=".$token->getType()." string=".$token->getString() );
}

sub matchSymbol {
    debug( "in match symbol" );
    my $return = $token->getString();
    match( $token );
    return $return;
}

sub debug {
    return unless $CQL::DEBUG;
    print STDERR "CQL::Parser: ", shift, "\n";
}

=head1 XCQL 

CQL has an XML representation which you can generate from a CQL parse
tree. Just call the toXCQL() method on the root node you get back
from a call to parse().

=head1 ERRORS AND DIAGNOSTICS

As mentioned above, a CQL syntax error will result in an exception being 
thrown. So if you have any doubts about the CQL that you are parsing you
should wrap the call to parse() in an eval block, and check $@
afterwards to make sure everything went ok.

    eval {
        my $node = $parser->parse( $cql );
    };
    if ( $@ ) {
        print "uhoh, exception $@\n";
    }

If you'd like to see blow by blow details while your CQL is being parsed
set $CQL::DEBUG equal to 1, and you will get details on STDERR. This is
useful if the parse tree is incorrect and you want to locate where things
are going wrong. Hopefully this won't happen, but if it does please notify the
author.

=head1 TODO

=over 4

=item * toYourEngineHere() please feel free to add functionality and send in
patches!

=back

=head1 THANKYOUS 

CQL::Parser is essentially a Perl port of Mike Taylor's cql-java package 
http://zing.z3950.org/cql/java/. Mike and IndexData were kind enough
to allow the author to write this port, and to make it available under
the terms of the Artistic License. Thanks Mike!

The CQL::Lexer package relies heavily on Stevan Little's excellent
String::Tokenizer. Thanks Stevan!

CQL::Parser was developed as a component of the Ockham project,
which is funded by the National Science Foundation. See http://www.ockham.org
for more information about Ockham.

=head1 AUTHOR

=over 4

=item * Ed Summers - ehs at pobox dot com

=item * Brian Cassidy - bricas at cpan dot org

=item * Wilbert Hengst - W.Hengst at uva dot nl

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by Ed Summers

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
