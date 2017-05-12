package Data::Munge;

use strict;
use warnings;
use base qw(Exporter);

sub _eval { eval $_[0] }  # empty lexical scope

our $VERSION = '0.097';
our @EXPORT = qw(
    byval
    elem
    eval_string
    list2re
    mapval
    rec
    replace
    slurp
    submatches
    trim
);

sub byval (&$) {
    my ($f, $x) = @_;
    local *_ = \$x;
    $f->($_);
    $x
}

sub elem {
    my ($k, $xs) = @_;
    if (ref $k) {
        for my $x (@$xs) {
            return 1 if ref $x && $k == $x;
        }
    } elsif (defined $k) {
        for my $x (@$xs) {
            return 1 if defined $x && !ref $x && $k eq $x;
        }
    } else {
        for my $x (@$xs) {
            return 1 if !defined $x;
        }
    }
    !1
}

sub eval_string {
    my ($code) = @_;
    my ($package, $file, $line) = caller;
    local $Data::Munge::_err = $@;
    $code = qq{\$\@ = \$Data::Munge::_err; package $package; # eval_string()\n#line $line "$file"\n$code};
    my @r = wantarray ? _eval $code : scalar _eval $code;
    die $@ if $@;
    $@ = $Data::Munge::_err;
    wantarray ? @r : $r[0]
}

sub list2re {
    @_ or return qr/(?!)/;
    my $re = join '|', map quotemeta, sort {length $b <=> length $a || $a cmp $b } @_;
    $re eq '' and $re = '(?#)';
    qr/$re/
}

sub mapval (&@) {
    my $f = shift;
    my @xs = @_;
    map { $f->($_); $_ } @xs
}

if ($] >= 5.016) {
    eval_string <<'EOT';
use v5.16;
sub rec (&) {
    my ($f) = @_;
    sub { $f->(__SUB__, @_) }
}
EOT
} elsif (eval { require Scalar::Util } && defined &Scalar::Util::weaken) {
    *rec = sub (&) {
        my ($f) = @_;
        my $w;
        my $r = $w = sub { $f->($w, @_) };
        Scalar::Util::weaken($w);
        $r
    };
} else {
    # slow but always works
    *rec = sub (&) {
        my ($f) = @_;
        sub { $f->(&rec($f), @_) }
    };
}

sub replace {
    my ($str, $re, $x, $g) = @_;
    my $f = ref $x ? $x : sub {
        my $r = $x;
        $r =~ s{\$([\$&`'0-9]|\{([0-9]+)\})}{
            $+ eq '$' ? '$' :
            $+ eq '&' ? $_[0] :
            $+ eq '`' ? substr($_[-1], 0, $_[-2]) :
            $+ eq "'" ? substr($_[-1], $_[-2] + length $_[0]) :
            $_[$+]
        }eg;
        $r
    };
    if ($g) {
        $str =~ s{$re}{ $f->(substr($str, $-[0], $+[0] - $-[0]), submatches(), $-[0], $str) }eg;
    } else {
        $str =~ s{$re}{ $f->(substr($str, $-[0], $+[0] - $-[0]), submatches(), $-[0], $str) }e;
    }
    $str
}

sub slurp {
    local $/;
    scalar readline $_[0]
}

sub submatches {
    no strict 'refs';
    map $$_, 1 .. $#+
}

sub trim {
    my ($s) = @_;
    return undef if !defined $s;
    $s =~ s/^\s+//;
    $s =~ s/\s+\z//;
    $s
}

'ok'

__END__

=head1 NAME

Data::Munge - various utility functions

=head1 SYNOPSIS

 use Data::Munge;
 
 my $re = list2re qw/f ba foo bar baz/;
 # $re = qr/bar|baz|foo|ba|f/;
 
 print byval { s/foo/bar/ } $text;
 # print do { my $tmp = $text; $tmp =~ s/foo/bar/; $tmp };
 
 foo(mapval { chomp } @lines);
 # foo(map { my $tmp = $_; chomp $tmp; $tmp } @lines);
 
 print replace('Apples are round, and apples are juicy.', qr/apples/i, 'oranges', 'g');
 # "oranges are round, and oranges are juicy."
 print replace('John Smith', qr/(\w+)\s+(\w+)/, '$2, $1');
 # "Smith, John"
 
 my $trimmed = trim "  a b c "; # "a b c"
 
 my $x = 'bar';
 if (elem $x, [qw(foo bar baz)]) { ... }
 
 my $contents = slurp $fh;  # or: slurp *STDIN
 
 eval_string('print "hello world\\n"');  # says hello
 eval_string('die');  # dies
 eval_string('{');    # throws a syntax error
 
 my $fac = rec {
   my ($rec, $n) = @_;
   $n < 2 ? 1 : $n * $rec->($n - 1)
 };
 print $fac->(5);  # 120
 
 if ("hello, world!" =~ /(\w+), (\w+)/) {
   my @captured = submatches;
   # @captured = ("hello", "world")
 }

=head1 DESCRIPTION

This module defines a few generally useful utility functions. I got tired of
redefining or working around them, so I wrote this module.

=head2 Functions

=over

=item list2re LIST

Converts a list of strings to a regex that matches any of the strings.
Especially useful in combination with C<keys>. Example:

 my $re = list2re keys %hash;
 $str =~ s/($re)/$hash{$1}/g;

This function takes special care to get several edge cases right:

=over

=item *

Empty list: An empty argument list results in a regex that doesn't match
anything.

=item *

Empty string: An argument list consisting of a single empty string results in a
regex that matches the empty string (and nothing else).

=item *

Prefixes: The input strings are sorted by descending length to ensure longer
matches are tried before shorter matches. Otherwise C<list2re('ab', 'abcd')>
would generate C<qr/ab|abcd/>, which (on its own) can never match C<abcd>
(because C<ab> is tried first, and it always succeeds where C<abcd> could).

=back

=item byval BLOCK SCALAR

Takes a code block and a value, runs the block with C<$_> set to that value,
and returns the final value of C<$_>. The global value of C<$_> is not
affected. C<$_> isn't aliased to the input value either, so modifying C<$_>
in the block will not affect the passed in value. Example:

 foo(byval { s/!/?/g } $str);
 # Calls foo() with the value of $str, but all '!' have been replaced by '?'.
 # $str itself is not modified.

Since perl 5.14 you can also use the C</r> flag:

 foo($str =~ s/!/?/gr);

But C<byval> works on all versions of perl and is not limited to C<s///>.

=item mapval BLOCK LIST

Works like a combination of C<map> and C<byval>; i.e. it behaves like
C<map>, but C<$_> is a copy, not aliased to the current element, and the return
value is taken from C<$_> again (it ignores the value returned by the
block). Example:

 my @foo = mapval { chomp } @bar;
 # @foo contains a copy of @bar where all elements have been chomp'd.
 # This could also be written as chomp(my @foo = @bar); but that's not
 # always possible.

=item submatches

Returns a list of the strings captured by the last successful pattern match.
Normally you don't need this function because this is exactly what C<m//>
returns in list context. However, C<submatches> also works in other contexts
such as the RHS of C<s//.../e>.

=item replace STRING, REGEX, REPLACEMENT, FLAG

=item replace STRING, REGEX, REPLACEMENT

A clone of javascript's C<String.prototype.replace>. It works almost the same
as C<byval { s/REGEX/REPLACEMENT/FLAG } STRING>, but with a few important
differences. REGEX can be a string or a compiled C<qr//> object. REPLACEMENT
can be a string or a subroutine reference. If it's a string, it can contain the
following replacement patterns:

=over

=item $$

Inserts a '$'.

=item $&

Inserts the matched substring.

=item $`

Inserts the substring preceding the match.

=item $'

Inserts the substring following the match.

=item $N  (where N is a digit)

Inserts the substring matched by the Nth capturing group.

=item ${N}  (where N is one or more digits)

Inserts the substring matched by the Nth capturing group.

=back

Note that these aren't variables; they're character sequences interpreted by
C<replace>.

If REPLACEMENT is a subroutine reference, it's called with the following
arguments: First the matched substring (like C<$&> above), then the contents of
the capture buffers (as returned by C<submatches>), then the offset where the
pattern matched (like C<$-[0]>, see L<perlvar/@->), then the STRING. The return
value will be inserted in place of the matched substring.

Normally only the first occurrence of REGEX is replaced. If FLAG is present, it
must be C<'g'> and causes all occurrences to be replaced.

=item trim STRING

Returns I<STRING> with all leading and trailing whitespace removed. Like
L<C<length>|perlfunc/length-EXPR> it returns C<undef> if the input is C<undef>.

=item elem SCALAR, ARRAYREF

Returns a boolean value telling you whether I<SCALAR> is an element of
I<ARRAYREF> or not. Two scalars are considered equal if they're both C<undef>,
if they're both references to the same thing, or if they're both not references
and C<eq> to each other.

This is implemented as a linear search through I<ARRAYREF> that terminates
early if a match is found (i.e. C<elem 'A', ['A', 1 .. 9999]> won't even look
at elements C<1 .. 9999>).

=item eval_string STRING

Evals I<STRING> just like C<eval> but doesn't catch exceptions. Caveat: Unlike
with C<eval> the code runs in an empty lexical scope:

 my $foo = "Hello, world!\n";
 eval_string 'print $foo';
 # Dies: Global symbol "$foo" requires explicit package name

That is, the eval'd code can't see variables from the scope of the
C<eval_string> call.

=item slurp FILEHANDLE

Reads and returns all remaining data from I<FILEHANDLE> as a string, or
C<undef> if it hits end-of-file. (Interaction with non-blocking filehandles is
currently not well defined.)

C<slurp $handle> is equivalent to C<do { local $/; scalar readline $handle }>.

=item rec BLOCK

Creates an anonymous sub as C<sub BLOCK> would, but supplies the called sub
with an extra argument that can be used to recurse:

 my $code = rec {
   my ($rec, $n) = @_;
   $rec->($n - 1) if $n > 0;
   print $n, "\n";
 };
 $code->(4);

That is, when the sub is called, an implicit first argument is passed in
C<$_[0]> (all normal arguments are moved one up). This first argument is a
reference to the sub itself. This reference could be used to recurse directly
or to register the sub as a handler in an event system, for example.

A note on defining recursive anonymous functions: Doing this right is more
complicated than it may at first appear. The most straightforward solution
using a lexical variable and a closure leaks memory because it creates a
reference cycle. Starting with perl 5.16 there is a C<__SUB__> constant that is
equivalent to C<$rec> above, and this is indeed what this module uses (if
available).

However, this module works even on older perls by falling back to either weak
references (if available) or a "fake recursion" scheme that dynamically
instantiates a new sub for each call instead of creating a cycle. This last
resort is slower than weak references but works everywhere.

=back

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011, 2013-2015 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
