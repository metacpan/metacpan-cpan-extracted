package AI::Prolog::Parser::PreProcessor::Math;
$REVISION = '$Id: Math.pm,v 1.3 2005/08/06 23:28:40 ovid Exp $';

$VERSION = '0.01';
use strict;
use warnings;
use Carp qw( croak );
use Regexp::Common;

my $var = qr/[[:upper:]][[:alnum:]_]*/;
my $num = $RE{num}{real};

# ** must be before *
my $op      = qr{(?:\*\*|[-+*/%])};
my $compare = qr/(?:(?:\\|=)?=|is|[<>]=?)/;
my $lparen  = qr/\(/;
my $rparen  = qr/\)/;

# Having a word boundary prior to $num breaks the regex
# when trying to match negative numbers
my $simple_math_term = qr/(?!\.(?![0-9]))(?:$num\b|\b$var\b)/;
my $simple_rhs       = qr/
    $simple_math_term
    (?:
        \s*
        $op 
        \s*
        $simple_math_term
    )*
/x;
my $simple_group_term = qr/$lparen\s*$simple_rhs\s*$rparen/;
my $math_term         = qr/(?:$simple_math_term|$simple_group_term)/;
my $complex_rhs       = qr/
    $math_term
    (?:
        \s*
        $op 
        \s*
        $math_term
    )*
/x;
my $complex_group_term = qr/$lparen\s*$complex_rhs\s*$rparen/;
my $final_math_term    = qr/(?:$math_term|$complex_group_term)/;
my $rhs                = qr/
    $final_math_term
    (?:
        \s*
        $op
        \s*
        $final_math_term
    )*
/x;

my $expression = qr/
    (
        ($simple_math_term)
        \s+
        ($compare)
        \s+
        ($rhs)
    )
    (?=[,.])
/x;

my %convert = (
    qw{
        is    is
        =     eq
        +     plus
        /     div
        -     minus
        %     mod
        *     mult
        **    pow
        <     lt
        <=    le
        >     gt
        >=    ge
        ==    eq
        \=    ne
        }
);

sub process {
    my ( $class, $prolog ) = @_;
    while ( $prolog =~ $expression ) {
        my ( $old_expression, $lhs, $comp, $rhs ) = ( $1, $2, $3, $4 );
        my $new_rhs        = $class->_parse( $class->_lex($rhs) );
        my $new_expression = sprintf
            "%s(%s, %s)" => $convert{$comp},
            $lhs, $new_rhs;
        $prolog =~ s/\Q$old_expression\E/$new_expression/g;
    }
    return $prolog;
}

sub _lex {
    my ( $class, $rhs ) = @_;
    my $lexer = _lexer($rhs);
    my @tokens;
    while ( my $token = $lexer->() ) {
        push @tokens => $token;
    }
    return \@tokens;
}

sub _lexer {
    my $rhs = shift;

   # the entire "$prev_op" thing is to allow the lexer to be aware of '7 + -3'
   # $op_ok is false on the first pass because it can never be first, but we
   # might have '-7 * (-2 + 3)'
    my $op_ok = 0;
    return sub {
    LEXER: {
            $op_ok = 0, return [ 'OP', $1 ]
                if $op_ok && $rhs =~ /\G ($op)               /gcx;
            $op_ok = 1, return [ 'ATOM', $1 ]
                if $rhs =~ /\G ($simple_math_term) /gcx;
            $op_ok = 0, return [ 'LPAREN', '(' ]
                if $rhs =~ /\G $lparen             /gcx;
            $op_ok = 1, return [ 'RPAREN', ')' ]
                if $rhs =~ /\G $rparen             /gcx;
            redo LEXER if $rhs =~ /\G \s+                 /gcx;
        }
    };
}

sub _parse {
    my ( $class, $tokens ) = @_;
    my $parens_left = 1;
REDUCE: while ($parens_left) {
        my ( $first, $last );
        for my $i ( 0 .. $#$tokens ) {
            my $token = $tokens->[$i];
            next unless $token;
            if ( "(" eq _as_string($token) ) {
                $first = $i;
            }
            if ( ")" eq _as_string($token) ) {
                unless ( defined $first ) {

                # XXX I should probably cache the string and show it.
                # XXX But it doesn't matter because that shouldn't happen here
                    croak(
                        "Parse error in math pre-processor.  Mismatched parens"
                    );
                }
                $last = $i;
                $tokens->[$first] = $class->_parse_group(
                    [ @{$tokens}[ $first + 1 .. $last - 1 ] ] );
                undef $tokens->[$_] for $first + 1 .. $last;
                @$tokens = grep $_ => @$tokens;
                undef $first;
                undef $last;
                redo REDUCE;
            }
        }
        $parens_left = 0 unless defined $first;
    }
    return _as_string( $class->_parse_group($tokens) );
}

sub _parse_group {
    my ( $class, $tokens ) = @_;
    foreach my $op_re ( qr{(?:\*\*|[*/])}, qr{[+-]}, qr/\%/ ) {
        for my $i ( 0 .. $#$tokens ) {
            my $token = $tokens->[$i];
            if ( ref $token && "@$token" =~ /OP ($op_re)/ ) {
                my $curr_op = $1;
                my $prev    = _prev_token( $tokens, $i );
                my $next    = _next_token( $tokens, $i );
                $tokens->[$i] = sprintf
                    "%s(%s, %s)" => $convert{$curr_op},
                    _as_string( $tokens->[$prev] ),
                    _as_string( $tokens->[$next] );
                undef $tokens->[$prev];
                undef $tokens->[$next];
            }
        }
        @$tokens = grep $_ => @$tokens;
    }

    #main::diag Dumper $tokens;
    return $tokens->[0];    # should never have more than on token left
}

sub _prev_token {
    my ( $tokens, $index ) = @_;
    for my $i ( reverse 0 .. $index - 1 ) {
        return $i if defined $tokens->[$i];
    }
}

sub _next_token {
    my ( $tokens, $index ) = @_;
    for my $i ( $index + 1 .. $#$tokens ) {
        return $i if defined $tokens->[$i];
    }
}

sub _as_string { ref $_[0] ? $_[0][1] : $_[0] }

sub match { shift; shift =~ $expression }

# The following are testing hooks

sub _compare            { shift; shift =~ /^$compare$/ }
sub _op                 { shift; shift =~ /^$op$/ }
sub _simple_rhs         { shift; shift =~ /^$simple_rhs$/ }
sub _simple_group_term  { shift; shift =~ /^$simple_group_term$/ }
sub _simple_math_term   { shift; shift =~ /^$simple_math_term$/ }
sub _math_term          { shift; shift =~ /^$math_term$/ }
sub _complex_rhs        { shift; shift =~ /^$complex_rhs$/ }
sub _complex_group_term { shift; shift =~ /^$complex_group_term$/ }

1;

__END__

=head1 NAME

AI::Prolog::Parser::PreProcessor::Math - The AI::Prolog math macro

=head1 SYNOPSIS

 my $program = AI::Prolog::Parser::PreProcessor::Math->process($prolog_text).

=head1 DESCRIPTION

This code reads in the Prolog text and rewrites it to a for that is suitable
for the L<AI::Prolog::Parser|AI::Prolog::Parser> to read.  Users of
L<AI::Prolog||AI::Prolog> should never need to know about this.

=head1 TODO

Constant folding for performance improvment.  No need to internally have
C<is(X, plus(3, 4))> when I can do C<is(X, 5)>.  It shouldn't be too hard.

Figure out how to preserve line number.

=head1 AUTHOR

Curtis "Ovid" Poe, E<lt>moc tod oohay ta eop_divo_sitrucE<gt>

Reverse the name to email me.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
