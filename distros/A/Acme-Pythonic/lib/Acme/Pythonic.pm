package Acme::Pythonic;

# Please, if you tested it in some earlier version of Perl and works let
# me know! The versions of Filter::Simple, Text::Tabs, and Test::More
# would be useful as well.
use 5.006_001;
use strict;
use warnings;

our ($VERSION, $DEBUG, $CALLER);
$VERSION = '0.47';

use Text::Tabs;

sub import {
    my ($package, %cfg) = @_;
    $DEBUG = $cfg{debug};
    $CALLER = caller() # to be able to check sub prototypes
}


use Filter::Simple;
FILTER_ONLY code => sub {
    unpythonize();
    cuddle_elses_and_friends();
    if ($DEBUG) {
        s/$Filter::Simple::placeholder/BLANKED_OUT/g;
        print;
        $_ = '1;';
    }
};


# This regexp matches a 7-bit ASCII identifier. We use atomic grouping
# because an identifier cannot be backtracked.
my $id = qr/(?>[_a-zA-Z](?:[_a-zA-Z0-9']|::)*)/;

# Shorthand to put an eventual trailing comment in some regexps.
my $tc = qr/(?<!\$)#.*/;


# Tries its best at converting Pythonic code to Perl.
sub unpythonize {
    # Sometimes Filter::Simple adds newlines blanking out stuff, which
    # interferes with Pythonic conventions.
    my %bos = (); # BlanketOutS
    my $count = 0;
    s<$Filter::Simple::placeholder>
     <my $bo = "$;BLANKED_OUT_".$count++."$;";
      $bos{$bo} = $&;
      $bo>geo;

    # In addition, we can now normalize newlines without breaking
    # Filter::Simple's identifiers.
    normalize_newlines();
    my @lines = split /\n/;
    return unless @lines;

    # If unsure about the ending indentation level, add an extra
    # non-indented line to ensure the stack gets emptied.
    push @lines, '1; # added by Acme::Pythonic' if $lines[-1] =~ /^(?:\s|\s*#)/;

    my ($comment,             # comment in the current line, if any
        $indent,              # indentation of the current logical line
        $id_at_sob,           # identifier at StartOfBlock, for instance "else", or "eval"
        $prev_line_with_code, # previous line with code
        $might_be_modifier,   # flag: current logical line might be a modifier
        $line_with_modifier,  # physical line which started the current modifier
        $joining,             # flag: are we joining lines?
        $unbalanced_paren,    # flag: we opened a paren that remains to be closed
        @stack,               # keeps track of indentation stuff
    );

    @stack = ();
    foreach my $line (@lines) {
        # We remove any trailing comment so that we can assert stuff
        # easily about the end of the code in this line. It is later
        # appended back in the continue block below.
        $comment = $line =~ s/(\s*$tc)//o ? $1 : '';
        next if $line =~ /^\s*$/;

        if (!$joining) {
            $unbalanced_paren = left_parenthesize($line);
            $might_be_modifier = $line =~ /^\s*(?:if|unless|while|until|for|foreach)\b/;
            $line_with_modifier = \$line if $might_be_modifier;
            ($indent) = $line =~ /^(\s*)/;
            $indent = length(expand($indent));
        }

        if ($line =~ /(?:,|=>)\s*$/ || $line =~ s/\\\s*$//) {
            ++$joining;
            next if $joining > 1; # if 1 we need yet to handle indentation
        } else {
            $joining = 0;
        }

        # Handle trailing colons, which can be Pythonic, mark a labeled
        # block, mean some map, or &-sub call, etc.
        #
        # We check the parity of the number of ending colons to try to
        # avoid breaking things like
        #
        #    print for keys %main::
        #
        my $bracket_opened_by = '';
        if ($line =~ /(:+)$/ && length($1) % 2) {
            $might_be_modifier = 0;
            # We perform some checks because labels have to keep their colon.
            if ($line !~ /^\s*$id:$/o ||
                $line =~ /[[:lower:]]/ || # labels are not allowed to have lower-case letters
                $line =~ /^\s*(?:BEGIN|CHECK|INIT|END):$/) {
                chop $line;
                if ($unbalanced_paren) {
                    $line .= ")";
                    $unbalanced_paren = 0;
                } else {
                    ($bracket_opened_by) = $line =~ /($id)\s*$/o;
                }
            }
        } elsif (!$joining) {
            $$line_with_modifier =~ s/\(// if $might_be_modifier;
            $unbalanced_paren = 0;
            $line .= ';';
        }

        # Handle indentation. Language::Pythonesque was the basis of
        # this code.
        my $prev_indent = @stack ? $stack[-1]{indent} : 0;
        if ($prev_indent < $indent) {
            push @stack, {indent => $indent, id_at_sob => $id_at_sob};
            $$prev_line_with_code .= " {" unless $$prev_line_with_code =~ s/(?=\s*$tc)/ {/o;
        } elsif ($prev_indent > $indent) {
            do {
                my $prev_id_at_sob = $stack[-1]{id_at_sob};
                pop @stack;
                $prev_indent = @stack ? $stack[-1]{indent} : 0;
                $$prev_line_with_code .= "\n" . ((' ' x $prev_indent) . "}");
                $$prev_line_with_code .= ";" if needs_semicolon($prev_id_at_sob);
            } while $prev_indent > $indent;
            $$prev_line_with_code =~ s/;$/ / if $might_be_modifier;
        }
        $id_at_sob = $bracket_opened_by;
    } continue {
        $line =~ s/^\s*pass;?\s*$//;
        $prev_line_with_code = \$line if !$joining && $line =~ /\S/;
        $line .= $comment;
    }

    $_ = join "\n", @lines;
    s/$;BLANKED_OUT_\d+$;/$bos{$&}/go;
}


# In the trials I've done seems like the Python interpreter understands
# any of the three conventions, even if they are not the ones in the
# platform, and even if they are mixed in the same file.
#
# In addition, it guarantees make test works no matter the platform.
sub normalize_newlines {
    s/\015\012/\n/g;
    tr/\015/\n/ unless "\n" eq "\015";
    tr/\012/\n/ unless "\n" eq "\012";
}


# Put an opening paren in the places we forgive parens. It will be later
# closed or removed as needed in the main subroutine.
sub left_parenthesize {
    $_[0] =~ s/^(\s*\b(?:if|elsif|unless)\b\s*)/$1(/                                      ||
    $_[0] =~ s/^(\s*(?:$id\s*:)?\s*\b(?:while|until)\b(\s*))/$2 eq '' ? "$1 (" : "$1("/eo ||
    $_[0] =~ s/^(\s*(?:$id\s*:\s*)?\bfor(?:each)?\b\s*)(.*)/fortype_guesser($1,$2)/oxe
}


# Tries its best at guessing a for(each) type or, at least, where to put
# the opening paren.
#
# Returns a string which is a copy of the original with the paren
# inserted.
sub fortype_guesser {
    my ($for, $rest) = @_;
    my $guess = "";

    # Try to match "for VAR in LIST", and "for VAR LIST"
    if ($rest =~ m/^((?:my|our)? \s* \$ $id\s+) in\s* ((?: (?:[\$\@%&\\]) | (?:\b\w) ) .*)$/ox ||
        $rest =~ m/^((?:my|our)? \s* \$ $id\s*)       ((?: (?:[\$\@%&\\]) | (?:\b\w) ) .*)$/ox) {
        $guess = "$for$1($2";
    } else {
        # We are not sure whether this is a for or a foreach, but it is
        # very likely that putting parens around gets it right.
        $rest =~ s/^\s*in\b//; # fixes "foreach in LIST"
        $guess = "$for($rest";
    }

    return $guess;
}


# Guesses whether a block started by $id_at_sob needs a semicolon after the
# ending bracket.
sub needs_semicolon {
    my $id_at_sob = shift;
    return 0 if !$id_at_sob;
    return 1 if $id_at_sob =~ /^(do|sub|eval)$/;

    my $proto = $id_at_sob =~ /::/ ? prototype($id_at_sob) : prototype("${CALLER}::$id_at_sob");
    return 0 if not defined $proto;
    return $proto =~ /^;?&$/;
}


# We follow perlstyle here, as we did until now.
sub cuddle_elses_and_friends {
    s/^([ \t]*})\s*(?=(?:elsif|else|continue)\b)/$1 /gm;
    s/^([ \t]*})\s*(?=(?:if|unless|while|until|for|foreach)\b(?!.*{$tc?$))/$1 /gm;
}

1;


__END__

=head1 NAME

Acme::Pythonic - Python whitespace conventions for Perl

=head1 SYNOPSIS

 use Acme::Pythonic; # this semicolon yet needed

 sub delete_edges:
     my $G = shift
     while my ($u, $v) = splice(@_, 0, 2):
         if defined $v:
             $G->delete_edge($u, $v)
         else:
             my @e = $G->edges($u)
             while ($u, $v) = splice(@e, 0, 2):
                 $G->delete_edge($u, $v)


=head1 DESCRIPTION

Acme::Pythonic brings Python whitespace conventions to Perl. Just C<use>
it and Pythonic code will become valid on the fly. No file is generated,
no file is modified.

This module is thought for those who embrace contradictions. A humble
contribution for walkers of the Whitespace Matters Way in their pursuit
of highest realization, only attained with L<SuperPython>.

=head1 OVERVIEW

Acme::Pythonic provides I<grosso modo> these conventions:

=over 4

=item * Blocks are marked by indentation and an opening colon instead of
braces.

=item * Simple statements are separated by newlines instead of
semicolons.

=item * EXPRs in control flow structures do not need parentheses around.

=back

Additionally, the filter understands the keywords C<pass> and C<in>.

    for my $n in 1..100:
        while $n != 1:
            if $n % 2:
                $n = 3*$n + 1
            else:
                $n /= 2

=head1 DETAILS

=head2 Labels

The syntax this module provides introduces an ambiguity: Given

    if $flag:
        do_this()
    else:
        do_that()

there's no way to know whether that is meant to be

    if ($flag) {
        do_this();
    } else {
        do_that();
    }

or rather

    if ($flag) {
        do_this();
    }
    else: {
        do_that();
    }

The former is a regular if/else, whereas the latter consists of an if and a
labeled block, so C<do_that()> is unconditionally executed.

To solve this B<labels in Pythonic code have to be in upper case>.

In addition, to be able to write BEGIN blocks and friends this way:

    BEGIN:
        $foo = 3

C<BEGIN>, C<CHECK>, C<INIT>, C<END> cannot be used as labels.

Let's see some examples. This is the Pythonic version of the snippet in L<perlsyn>:

    OUTER: for my $wid in @ary1:
        INNER: for my $jet in @ary2:
            next OUTER if $wid > $jet
            $wid += $jet

And here we have a labeled block:

    my $k = 7
    FOO:
        --$k
        last FOO if $k < 0
        redo FOO

Note that if we put a label in the line before in a control structure
indentation matters, because that's what marks blocks. For instance, this
would be a non-equivalent reformat of the example above:

    OUTER:
        for my $wid in @ary1:               # NOT WHAT WE WANT
            INNER:
            for my $jet in @ary2:           # GOOD, ALIGNED
                next OUTER if $wid > $jet
                $wid += $jet

Since the first C<for> is indented with respect to the label C<OUTER:> we get a
labeled block containing a C<for> loop, instead of a labeled C<for>. This is
the interpretation in regular Perl:

    OUTER: {
        for my $wid (@ary1) {               # NOT WHAT WE WANT
            INNER:
            for my $jet (@ary2) {           # GOOD, ALIGNED
                next OUTER if $wid > $jet;
                $wid += $jet;
            }
        }
    }

The consequence is that C<next OUTER> goes outside the outer for loop and thus
it is restarted, instead of continued.

=head2 C<do/while>-like constructs

Acme::Pythonic tries to detect statement modifiers after a C<do BLOCK>. Thus

    do:
        do_something()
        do_something_else()
    while $condition

is seen as a do/while, whereas

    do:
        do_something()
        do_something_else()
    while $condition:
        handle_some_stuff()

is not.

=head2 New Keywords

=head3 pass

C<pass> is a NO-OP, it is meant to explicit empty blocks:

    sub abstract_method:
        pass

=head3 in

This works:

    foreach my $foo @array:
        do_something_with $foo

Nevertheless, C<in> can be inserted there as in Python in case you find
the following more readable:

    foreach my $foo in @array:
        do_something_with $foo

This keyword can be used if there's no variable to its left too, which
means we are dealing with C<$_> as usual:

    foreach in @array:
        s/foo/bar/

but can't be used when the loop acts as a modifier:

    print foreach in @array # ERROR

This keyword is not supported as sequence membership operator.

=head2 &-Prototyped subroutines

C<&>-prototyped subroutines can be used like this:

    sub mygrep (&@):
        my $code = shift
        my @result
        foreach @_:
            push @result, $_ if &$code
        return @result

    @array = mygrep:
        my $aux = $_
        $aux *= 3
        $aux += 1
        $aux % 2
    reverse 0..5

If the prototype is exactly C<&>, however, Acme::Pythonic needs to know
it in advance. Thus, if any module defines such a subroutine C<use()> it
I<before> Acme::Pythonic:

    use Thread 'async';
    use Acme::Pythonic; # now Acme::Pythonic knows async() has prototype "&"

    async:
        do_this()
        do_that()

If such a subroutine is defined in the very code being filtered we need to
declare it before Acme::Pythonic is C<use()>d:

    sub twice (&);      # declaration
    use Acme::Pythonic; # now Acme::Pythonic knows twice() has prototype "&"

    # the definition itself can be Pythonic
    sub twice (&):
         my $code = shift
         $code->() for 1..2

    twice:
         do_this_twice()

Nevertheless, the module is not smart enough to handle optional arguments as in
a subroutine with prototype C<&;$>.


=head2 Line joining

As in Python, you can break a logical line in several physical lines
using a backslash at the end:

    my $total = total_products() + \
                total_delivery() + \
                total_taxes()

and in that case the indentation of those additional lines is irrelevant.

Unlike Python, backslashes in a line with a comment are allowed

    my $foo = 1 + \  # comment, no problem
        2

If a line ends in a comma or arrow (C<< => >>) it is conceptually joined
with the following as well:

    my %authors = (Perl   => "Larry Wall",
                   Python => "Guido van Rossum")

As in Python, comments can be intermixed there:

    my %hello = (Catalan => 'Hola',   # my mother tongue
                 English => 'Hello',)


Acme::Pythonic munges a source that has already been processed by L<Filter::Simple>. In particular, L<Filter::Simple> blanks out quotelikes whose content is not even seen by Acme::Pythonic so backslashes in C<qw//> and friends won't be removed:

    # Do not put backslashes here because qw// is bypassed
    my @colors = qw(Red
                    Blue
                    Green)


=head1 CAVEATS

Although this module makes possible some Python-like syntax in Perl,
there are some remarkable limitations in the current implementation:

=over 4

=item * Compound statement bodies are not recognized in header
lines. This would be valid according to Python syntax:

    if $n % 2: $n = 3*$n + 1
    else: $n /= 2

but it does not work in Acme::Pythonic. The reason for this is that it
would be hard to identify the colon that closes the expression without
parsing Perl, consider for instance:

    if keys %foo::bar ? keys %main:: : keys %foo::: print "foo\n"

=item * In Python statements may span lines if they're enclosed in
C<()>, C<{}>, or C<[]> pairs. Acme::Pythonic does not support this rule,
however, though it understands the common case where you break the line
in a comma in list literals, subroutine calls, etc.

=back

Remember that source filters do not work if they are called at runtime,
for instance via C<require> or C<eval EXPR>. The source code was already
consumed in the compilation phase by then.


=head1 DEBUG

L<Filter::ExtractSource> can be used to inspect the source code
generated by Acme::Pythonic:

    perl -c -MFilter::ExtractSource pythonic_script.pl

Acme::Pythonic itself has a C<debug> flag though:

    use Acme::Pythonic debug => 1;

In debug mode the module prints to standard output the code it has
generated, and passes just a dummy C<1;> to L<Filter::Simple>.

This happens I<before> L<Filter::Simple> undoes the blanking out of
PODs, strings, and regexps. Those parts are marked with the label
C<BLANKED_OUT> for easy identification.

Acme::Pythonic generates human readable Perl following L<perlstyle>, and
tries meticulously to be respectful with the original source code.
Blank lines and comments are preserved.


=head1 BUGS

This module uses a regexp approach and the superb help of
Filter::Simple. The regexp part of this means it is broken from the
start, though I've tried hard to make it as robust as I could. Bug
reports will be very welcome, just drop me a line!


=head1 THANKS

Damian Conway gave his full blessing if I wanted to write a module like
this based on his unpublished Language::Pythonesque. The code that
handles indentation is inspired by his.

Also, Dr. Conway is the author of L<Filter::Simple>, which aids a lot
blanking out PODs, strings, etc. so you can munge the source with
certain confidence. Without Filter::Simple this module would be
infinitely more broken.

Esteve Fernandez helped testing the module under 5.6.1 and contributed
a Sieve of Eratosthenes for F<t/algorithms.t>. Thank you dude!

=head1 SEE ALSO

L<perlfilter>, L<Filter::Simple>, L<Filter::ExtractSource>, L<SuperPython>, L<Acme::Dot>.


=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2012 by Xavier Noria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
