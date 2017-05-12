#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the Data::SExpression tokenizer

=cut

use Test::More qw(no_plan);
use Data::SExpression::Parser;


sub tokenize {
    my $parser = Data::SExpression::Parser->new;
    my $string = shift;

    $parser->set_input($string);

    my @tokens = ();
    my ($tok, $val);
    while(1) {
        ($tok, $val) = $parser->lexer();
        last unless $tok;
        push @tokens, [$tok, $val];
    }

#    use Data::Dumper;
#    warn "Tokenized $string to " . Dumper(\@tokens);

    return \@tokens;
}




is_deeply(tokenize('+ 5 4.3 2. .45 -6'),
          [[SYMBOL => '+'],
           [NUMBER => 5],
           [NUMBER => 4.3],
           [NUMBER => "2."],
           [NUMBER => '.45'],
           [NUMBER => '-6']]);

is_deeply(tokenize(q{(string-append "Hello " "\"" 'Dave "\"")}),
          [['('    => '('],
           [SYMBOL => 'string-append'],
           [STRING => "Hello "],
           [STRING => q{\"}],
           [QUOTE  => 'quote'],
           [SYMBOL => "Dave"],
           [STRING => q{\"}],
           [q{)}   => q{)}]]);

is_deeply(tokenize(q{a . b}),
          [[SYMBOL => 'a'],
           [q{.}   => q{.}],
           [SYMBOL => 'b']]);

is_deeply(tokenize(q{""}),
          [[STRING => '']]);

is_deeply(tokenize(q{("")}),
          [['('    => '('],
           [STRING => ''],
           [')'    => ')']]);

is_deeply(tokenize(q{("") ("")}),
          [['('    => '('],
           [STRING => ''],
           [')'    => ')'],
           ['('    => '('],
           [STRING => ''],
           [')'    => ')']]);

is_deeply(tokenize(q{("") (" ")}),
          [['('    => '('],
           [STRING => ''],
           [')'    => ')'],
           ['('    => '('],
           [STRING => ' '],
           [')'    => ')']]);

is_deeply(tokenize(q{("a") ("b")}),
          [['('    => '('],
           [STRING => 'a'],
           [')'    => ')'],
           ['('    => '('],
           [STRING => 'b'],
           [')'    => ')']]);


is_deeply(tokenize(qq{"\n"}),
          [[STRING => "\n"]]);

is_deeply(tokenize(qq{"aa\n"}),
          [[STRING => "aa\n"]]);

is_deeply(tokenize(qq{"\nbb"}),
          [[STRING => "\nbb"]]);

is_deeply(tokenize(qq{"aa\nbb"}),
          [[STRING => "aa\nbb"]]);

is_deeply(tokenize(qq{"aa\nbb\ncc\ndd\n"}),
          [[STRING => "aa\nbb\ncc\ndd\n"]]);
