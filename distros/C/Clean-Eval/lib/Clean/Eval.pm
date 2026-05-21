package Clean::Eval;
use strict;
use warnings;

our $VERSION = '0.000002';

use Importer Importer => 'import';

our @EXPORT_OK = qw/clean_eval clean_string_eval last_error/;

use overload(
    'bool' => sub { $_[0]->{ok} ? 1 : 0 },
    '""'   => sub { defined($_[0]->{error}) ? $_[0]->{error} : "" },
);

sub ok        { $_[0]->{ok} }
sub out       { $_[0]->{out} }
sub error     { $_[0]->{error} }
sub to_string { defined $_[0]->{error} ? $_[0]->{error} : "" }

my $LAST_ERR;

sub last_error { $LAST_ERR }

sub clean_eval(&)        { goto &_clean_eval }
sub clean_string_eval($) { goto &_clean_eval }

sub _clean_eval {
    my $code = shift;
    local $@ = "";

    my ($pkg, $file, $line) = caller;

    my $self = bless { ok => 0, package => $pkg, file => $file, line => $line }, __PACKAGE__;

    if (ref($code) eq 'CODE') {
        my $out;
        if (eval { $out = $code->(); 1 }) {
            $self->{ok}  = 1;
            $self->{out} = $out;
            return $self;
        }
    }
    else {
        if (eval qq{#line $line "$file"\n$code; 1}) {
            $self->{ok} = 1;
            return $self;
        }
    }

    $self->{error} = $@;
    $LAST_ERR = $self;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clean::Eval - Run code under C<eval> without leaking C<$@> and get a rich
error object back on failure.

=head1 DESCRIPTION

Perl's built-in C<eval> is the standard way to trap exceptions, but it has two
long-standing ergonomic problems:

=over 4

=item *

It modifies the global C<$@>, which can be clobbered by destructors or other
code running during stack unwind, leading to lost or corrupted error messages.

=item *

The return value of C<eval> can be ambiguous: a successful eval that
legitimately returns a false value is indistinguishable from a failure unless
you check C<$@>.

=back

C<Clean::Eval> wraps C<eval> in a way that avoids both problems. It localizes
C<$@> so the caller's copy is never touched and always returns a blessed
result object that is overloaded for boolean and string context. The object
is true on success and false on failure regardless of what the wrapped code
returned, so a single C<if> check is enough to distinguish the two.

On success the block form also stashes the block's return value (taken in
scalar context) in an C<out> field on the object, so the typical pattern is:

    if (my $ev = clean_eval { get_message() }) {
        $msg = $ev->out;
    }
    else {
        die $ev;        # stringifies to the trapped error
    }

Both a block form (C<clean_eval { ... }>) and a string form
(C<clean_string_eval $code>) are provided. The string form rewrites C<#line>
information so that any error reports the file and line of the caller, not an
anonymous C<(eval N)>. The string form does B<not> capture a return value -
see L</clean_string_eval>.

=head1 SYNOPSIS

    use Clean::Eval qw/clean_eval clean_string_eval last_error/;

    # Block form - object is always returned; bool overload picks
    # success vs failure; on success ->out holds the block's scalar
    # return value.
    my $msg;
    if (my $ev = clean_eval { get_message() }) {
        $msg = $ev->out;
    }
    else {
        die $ev;        # stringifies to trapped error
    }

    # Or, branchless:
    my $ev = clean_eval { risky() };
    die "Failed: $ev\n  at $ev->{file} line $ev->{line}\n" unless $ev;
    my $result = $ev->out;

    # String form - same overloaded object, but no ->out is ever set
    # (see "clean_string_eval" below). No need to add a trailing "; 1"
    # - it is appended for you.
    my $ev = clean_string_eval 'use SomeOptionalModule';
    warn "Optional dep missing: $ev\n" unless $ev;

    # Retrieve the most recent failure from anywhere
    my $last = last_error();

=head1 EXPORTS

Nothing is exported by default. The three functions below may be imported
individually using L<Importer>-style syntax:

    use Clean::Eval qw/clean_eval clean_string_eval last_error/;

=over 4

=item $ev = clean_eval { BLOCK }

Run C<BLOCK> under C<eval>. Always returns a C<Clean::Eval> result object
(see L</"RESULT OBJECT">). C<$@> in the caller's scope is not touched.

On success the block's return value is captured B<in scalar context> and
stored in the object's C<out> field. Scalar context is forced because the
object is a scalar-context-only carrier - capturing a list there would
require API choices (arrayref? flatten?) that would surprise callers. If
you need list-context results, assign to an outer C<my @list> from inside
the block:

    my @rows;
    my $ev = clean_eval { @rows = fetch_rows() };
    die $ev unless $ev;

On failure the C<out> key is B<not present> on the object and the C<error>,
C<package>, C<file>, and C<line> keys are populated instead.

The prototype is C<(&)>, so the block form works without a leading C<sub>.

=item $ev = clean_string_eval $STRING

Run C<$STRING> as Perl code under C<eval>. Always returns a C<Clean::Eval>
result object. C<$@> in the caller's scope is not touched.

B<Unlike the block form, the string form never captures a return value.>
The C<out> field is always absent on the result object, even on success.
This is because the body of a string eval is not necessarily a value-
producing expression: it might be defining a subroutine, opening a
C<BEGIN>/C<INIT>/C<END> block, declaring a package, loading a module via
C<use>, or otherwise producing something that has no meaningful "scalar
return value" to record. Trying to capture and stash a result in those
cases would just be misleading. If you need a value out of string eval'd
code, write to an outer C<our> package variable from inside the string,
or use C<clean_eval { eval $string }> and capture the result yourself.

A C<#line> directive is prepended to C<$STRING> using the caller's filename
and line number, so any error or warning produced by the eval'd code refers
to the source location of the C<clean_string_eval> call rather than to an
anonymous eval string.

A trailing C<; 1> is also appended to C<$STRING>, so you do not need to
remember the usual C<eval "...; 1"> success guard - success is recorded on
the result object regardless of what the final statement in C<$STRING>
evaluates to. Including the C<; 1> yourself is harmless.

The prototype is C<($)>, so a single scalar argument is taken.

=item $err = last_error()

Return the result object of the most recent B<failure> produced by
C<clean_eval> or C<clean_string_eval> anywhere in the program, or C<undef>
if no failure has been recorded yet. Successful calls do B<not> reset this
slot. Useful for code paths that discarded the result object or want to
inspect a previous failure after the fact.

B<Caveat:> C<last_error> is a global slot and is subject to the same class
of bug that makes raw C<$@> fragile. If a C<DESTROY> method (or anything
else running during stack unwind) calls C<clean_eval> or
C<clean_string_eval> and that inner call fails, it will overwrite the
global and the error you actually cared about will be lost. C<last_error>
is a convenience, not a guarantee - the only robust way to inspect a
particular failure is to capture the result object of
C<clean_eval>/C<clean_string_eval> directly at the call site and keep it
in a lexical of your own.

=back

=head1 RESULT OBJECT

Both C<clean_eval> and C<clean_string_eval> always return a blessed hashref
of class C<Clean::Eval>. It overloads boolean and stringification context:

=over 4

=item *

Boolean context: true on success, false on failure. This is computed from
the C<ok> field, so a successful eval whose block legitimately returned a
false value is still distinguishable from a failure.

=item *

String context: the trapped error message on failure (the value C<$@> had
inside the eval), or the empty string on success. This lets you write
C<die $ev> on a failure without having to dig out a field.

=back

The object is a plain hashref with the following keys. Which keys are
present depends on whether the eval succeeded:

=over 4

=item ok

Always present. C<1> on success, C<0> on failure.

=item out

B<Present only on success, and only for the block form.> Holds the block's
return value, taken in scalar context. Absent (the key does not C<exists>
at all) on failure, and absent for C<clean_string_eval> in all cases.

=item error

B<Present only on failure.> The trapped error message (string or object,
whatever was C<die>'d).

=item package

The package the call was made from. Always present.

=item file

The file the call was made from. Always present.

=item line

The line the call was made from. Always present.

=back

Convenience accessors C<ok>, C<out>, and C<error> return the corresponding
fields. C<to_string> returns the same string the C<""> overload yields.

=head1 WHY NOT JUST USE C<eval>?

You can, but you have to be careful. The idiomatic safe pattern looks like:

    my $ok = eval { ...; 1 };
    if (!$ok) {
        my $err = $@;
        ...
    }

This is correct but verbose, and the C<; 1> trailer is easy to forget. The
C<$@> variable is also famously fragile: destructors that run during stack
unwind can call C<eval> themselves and reset it before you read it. Localizing
C<$@> the way C<Clean::Eval> does avoids that class of bug entirely.

=head1 PITFALLS

=head2 C<my $ev = clean_eval { ... } or die "$ev"> does not work

This looks natural but contains a subtle bug. A lexical introduced by
C<my> is B<not> in scope until the statement that declared it has
finished, so the C<$ev> referenced by C<die "$ev"> is a different,
package-global C<$ev> (which is C<undef>):

    use Clean::Eval qw/clean_eval/;

    # WRONG - $ev inside the die is the package global, not the lexical;
    # the die fires (clean_eval returned a false-overloaded object) but
    # with an empty message.
    my $ev = clean_eval { die "foo" } or die "$ev";

Declare the lexical on its own statement first so it is in scope by the
time the C<or die> runs:

    use Clean::Eval qw/clean_eval/;

    # CORRECT - $ev refers to the lexical in both spots
    my $ev;
    $ev = clean_eval { die "foo" } or die "$ev";

Or split the check off into its own statement, which has the same effect:

    use Clean::Eval qw/clean_eval/;

    my $ev = clean_eval { die "foo" };
    die "$ev" unless $ev;

The reliable rule: do not reference a C<my>-declared variable in the same
statement that declares it. Running with C<use warnings> will diagnose
this with C<"Name main::ev used only once: possible typo">.

=head2 The block's return value is taken in scalar context

C<clean_eval> stashes the block's return value in C<< $ev->out >>, but
it does so in B<scalar context>. A block that returns a list will be
collapsed to the last element (or to the list count, depending on the
expression):

    use Clean::Eval qw/clean_eval/;

    my $ev = clean_eval { (1, 2, 3) };
    # $ev->out is 3, not [1, 2, 3]

If you need a list result, write to an outer lexical from inside the
block:

    my @rows;
    my $ev = clean_eval { @rows = fetch_rows() };
    die $ev unless $ev;
    # use @rows here

Scalar context is forced deliberately - the C<out> field is a single
scalar slot, and silently picking a list-handling convention would
surprise callers.

=head2 C<clean_string_eval> never sets C<out>

The string form never records a return value, even on success. A string
eval may be defining subs, opening C<BEGIN>/C<END> blocks, loading
modules, or otherwise doing things with no meaningful scalar result. If
you need a value back from a string eval, write to an C<our> package
variable from inside the string, or wrap a real C<eval $str> inside a
C<clean_eval> block and capture from there.

=head2 C<clean_string_eval> does not see the caller's lexicals

With a raw C<eval $string>, the eval'd code can see any C<my> variables
in the surrounding scope. C<clean_string_eval> cannot: the string is
eval'd inside this module, so the caller's lexicals are out of reach.
Only package globals are visible.

    use Clean::Eval qw/clean_string_eval/;

    my $x = 42;
    my $ret = clean_string_eval 'print $x';
    # $ret is an error: "Global symbol $x requires explicit package name"
    # (or, without strict, $x is just an unrelated undef global)

    our $y = 42;
    clean_string_eval 'print $y';   # prints 42 - $y is a package global

If you need to feed values in, pass them through globals you control or
through the environment, or build a closure and use C<clean_eval> with a
block instead.

=head2 C<return> inside the block returns from the block, not the caller

The block passed to C<clean_eval> is an anonymous subroutine. A C<return>
inside it returns from that anonymous subroutine - not from the
enclosing named sub - and C<clean_eval> still gets control back and
returns C<1> for success.

    sub do_work {
        my $ok = clean_eval {
            return if $skip;     # returns from the block only
            risky_thing();
        };
        return 0 unless $ok;
        ...
    }

This matches the behavior of plain C<eval { ... }>.

=head2 Cannot pass a coderef variable with block syntax

The C<(&)> prototype makes C<clean_eval> parse a literal block; it will
not accept a coderef in scalar variable form:

    my $cref = sub { die "foo" };
    clean_eval $cref;          # syntax error / wrong parse

Workarounds:

    clean_eval(\&named_sub);   # named sub via \&
    clean_eval { $cref->() };  # wrap in a literal block
    &Clean::Eval::clean_eval($cref);   # bypass the prototype

=head1 SEE ALSO

L<Try::Tiny>, L<Syntax::Keyword::Try>, L<Feature::Compat::Try>.

=head1 SOURCE

The source code repository for Clean-Eval can be found at
F<https://github.com/exodist/Clean-Eval/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2026 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
