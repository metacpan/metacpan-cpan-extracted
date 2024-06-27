#! /usr/bin/env perl

use 5.026;   # So we can use an indented heredoc below (otherwise would be: use 5.022)

use warnings;
use experimentals;

use DWIM::Block;

sub _____ () { say "\n_____\n" }

sub carp ($errmsg) {
    use Carp ();
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::carp do { DWIM { Please convert the following text to a haiku: $errmsg } },
                  "\n\n   GPT's commentary:\n      $errmsg";
}

carp "Bad argument to method left()";

_____;

sub autoinflect ($text) {
    DWIM {
        Please inflect the following text so that its grammar is correct
        and its nouns and verbs agree in number and person.
        Please return only the inflected sentence, without any commentary:

        $text
    }
}

say autoinflect "When you has did 6 impossible thing before breakfast...";

_____;

sub autoformat ($text, %opt) {
    $opt{width} //= 72;

    DWIM {
        Could you please reformat the following text quotation from an email,
        so that each line is no more than $opt{width} columns.
        Please preserve any leading email quoters, adding them back to the
        reformatted lines and, if the plaintext contains a list of numbered points,
        ensure that the point numbers are sequential and remain outdented
        from the reformatted text of each point.
        Please return only the reformatted plaintext, without any commentary:

        $text
    }
}

say autoformat <<~'END_AUSTEN', width => 42;
    > I often think about the opening lines of Jane Austen's "Pride and Prejudice",
    > and how they encapsulate the cultural milieu in which the subsequent novel
    > is set:
    >
    >> It is a truth universally acknowledged, that a single man in possession of a
    >> good fortune, must be in want of a wife. However little known the feelings or
    >> views of such a man may be on his first entering a neighbourhood, this truth
    >> is so well fixed in the minds of the surrounding families, that he is
    >> considered the rightful property of some one or other of their daughters.
    END_AUSTEN






