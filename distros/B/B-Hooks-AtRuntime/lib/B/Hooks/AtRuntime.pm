package B::Hooks::AtRuntime;

use warnings;
use strict;

use XSLoader;
use Sub::Name       "subname";
use Carp;

use parent "Exporter::Tiny";
our @EXPORT     = qw/at_runtime/;
our @EXPORT_OK  = qw/at_runtime after_runtime lex_stuff/;

BEGIN {
    our $VERSION = "4";
    XSLoader::load __PACKAGE__, $VERSION;
}

use constant USE_FILTER =>
    defined $ENV{PERL_B_HOOKS_ATRUNTIME} 
        ? $ENV{PERL_B_HOOKS_ATRUNTIME} eq "filter"
        : not defined &lex_stuff;

if (USE_FILTER) {
    require Filter::Util::Call;

    # This isn't an exact replacement: it inserts the text at the start
    # of the next line, rather than immediately after the current BEGIN.
    #
    # In theory I could use B::Hooks::Parser, which aims to emulate
    # lex_stuff on older perls, but that uses a source filter to ensure
    # PL_linebuf has some extra space in it (since it can't be
    # reallocated without adjusting pointers we can't get to). This
    # means BHP::setup needs to be called at least one source line
    # before we want to insert any text (so the filter has a chance to
    # run), which makes it precisely useless for our purposes :(.

    no warnings "redefine";
    *lex_stuff = subname "lex_stuff", sub {
        my ($str) = @_;

        compiling_string_eval() and croak 
            "Can't stuff into a string eval";

        if (defined(my $extra = remaining_text())) {
            $extra =~ s/\n+\z//;
            carp "Extra text '$extra' after call to lex_stuff";
        }

        Filter::Util::Call::filter_add(sub {
            $_ = $str;
            Filter::Util::Call::filter_del();
            return 1;
        });
    };
}

my @Hooks;

sub replace_hooks {
    my ($new) = @_;

    # By deleting the stash entry we ensure the only ref to the glob is
    # through the optree it was compiled into. This means that if that
    # optree is ever freed, the glob will disappear along with anything
    # closed over by the user's callbacks.
    delete $B::Hooks::AtRuntime::{hooks};

    no strict "refs";
    $new and *{"hooks"} = $new;
}

sub clear {
    my ($depth) = @_;
    $Hooks[$depth] = undef;
    replace_hooks $Hooks[$depth - 1];
}

sub find_hooks {
    USE_FILTER and compiling_string_eval() and croak
        "Can't use at_runtime from a string eval";

    my $depth = count_BEGINs()
        or croak "You must call at_runtime at compile time";

    my $hk;
    unless ($hk = $Hooks[$depth]) {
        # Close over an array of callbacks so we don't need to keep
        # stuffing text into the buffer.
        my @hooks;
        $hk = $Hooks[$depth] = \@hooks;
        replace_hooks $hk;

        # This must be all on one line, so we don't mess up perl's idea
        # of the current line number.
        lex_stuff(q{B::Hooks::AtRuntime::run(@B::Hooks::AtRuntime::hooks);} .
            "BEGIN{B::Hooks::AtRuntime::clear($depth)}");
    }

    return $hk;
}

sub at_runtime (&) {
    my ($cv) = @_;
    my $hk = find_hooks;
    push @$hk, subname scalar(caller) . "::(at_runtime)", $cv;
}

sub after_runtime (&) {
    my ($cv) = @_;
    my $hk = find_hooks;
    push @$hk, \subname scalar(caller) . "::(after_runtime)", $cv;
}

1;

=head1 NAME

B::Hooks::AtRuntime - Lower blocks from compile time to runtime

=head1 SYNOPSIS

    # My::Module
    sub import {
        at_runtime { warn "TWO" };
    }

    # elsewhere
    warn "ONE";
    use My::Module;
    warn "THREE";

=head1 DESCRIPTION

This module allows code that runs at compile-time to do something at
runtime. A block passed to C<at_runtime> gets compiled into the code
that's currently compiling, and will be called when control reaches that
point at runtime. In the example in the SYNOPSIS, the warnings will
occur in order, and if that section of code runs more than once, so will
all three warnings.

=head2 at_runtime

    at_runtime { ... };

This sets up a block to be called at runtime. It must be called from
within a C<BEGIN> block or C<use>, otherwise there will be no compiling
code to insert into. The innermost enclosing C<BEGIN> block, which would
normally be invisible once the section of code it is in has been
compiled, will effectively leave behind a call to the given block. For
example, this

    BEGIN { warn "ONE" }    warn "one";
    BEGIN { warn "TWO";     at_runtime { warn "two" }; }

will warn "ONE TWO one two", with the last warning 'lowered' out of the
C<BEGIN> block and back into the runtime control flow.

This applies even if calls to other subs intervene between C<BEGIN> and
C<at_runtime>. The lowered block is always inserted at the innermost
point where perl is still compiling, so something like this

    # My::Module
    sub also_at_runtime { 
        my ($msg) = @_; 
        at_runtime { warn $msg };
    }

    sub import {
        my ($class, $one, $two) = @_;
        at_runtime { warn $one };
        also_at_runtime $two;
    }

    # 
    warn "one";
    BEGIN { at_runtime { warn "two" } }
    BEGIN { My::Module::also_at_runtime "three" }
    use My::Module "four", "five";

will still put the warnings in order.

=head2 after_runtime

    after_runtime { ... };

This arranges to call the block when runtime execution reaches the end
of the surrounding compiling scope. For example, this will warn in order:

    warn "one";
    {
        warn "two";
        BEGIN { 
            after_runtime { warn "five" };
            at_runtime { warn "three" };
        }
        warn "four";
    }
    warn "six";

No exception handling is done, so if the block throws an exception it
will propogate normally into the surrounding code. (This is different
from the way perl calls C<DESTROY> methods, which have their exceptions
converted into warnings.)

Note that the block will be called during stack unwind, so the package,
file and line information for C<caller 0> will be the point where the
surrounding scope was called. This is the same as a C<DESTROY> method.

=head2 Object lifetimes

C<at_runtime> and C<after_runtime> are careful to make sure the
anonymous sub passed to them doesn't live any longer than it has to.
That sub, and any lexicals it has closed over, will be destroyed when
the optree it has been compiled into is destroyed: for code outside any
sub, this is when the containing file or eval finishes executing; for
named subs, this is when the sub is un- or redefined; and for anonymous
subs, this is not until both the code containing the C<sub { }>
expression and all instances generated by that expression have been
destroyed.

=head2 lex_stuff
    
    lex_stuff $text;

This is the function underlying C<at_runtime>. Under perl 5.12 and
later, this is just a Perl wrapper for the core function
L<lex_stuff_sv|perlapi/lex_stuff_sv>. Under earlier versions it is
implemented with a source filter, with some limitations, see L</CAVEATS>
below.

This function pushes text into perl's line buffer, at the point perl is
currently compiling. You should probably not try to push too much at
once without giving perl a chance to compile it. If C<$text> contains
newlines, they will affect perl's idea of the current line number. You
probably shouldn't use this function at all.

=head2 Exports

B::Hooks::AtRuntime uses L<Exporter::Tiny>, so you can customise its
exports as described by that module's documentation. C<at_runtime> is
exported by default; C<after_runtime> and C<lex_stuff> can be exported
on request.

=head1 CAVEATS

=head2 Incompatible changes from version 1

Version 1 used a different implementation for C<at_runtime>, which left
an extra scope between the provided block and the code it was compiled
into. Version 2 has removed this.

=head2 Perls before 5.12

Versions of perl before 5.12.0 don't have the C<lex_stuff_sv> function,
and don't export enough for it to be possible to emulate it entirely.
(L<B::Hooks::Parser> gets as close as it can, and just exactly doesn't
quite do what we need for C<at_runtime>.) This means our C<lex_stuff>
has to fall back to using a source filter to insert the text, which has
a couple of important limitations.

=over 4

=item * You cannot stuff text into a string C<eval>.

String evals aren't affected by source filters, so the stuffed text
would end up getting inserted into the innermost compiling scope that
B<wasn't> a string eval. Since this would be rather confusing, and
different from what 5.12 does, C<lex_stuff> and C<at_runtime> will croak
if you try to use them to affect a string eval.

=item * Stuffed text appears at the start of the next line.

This, unfortunately, is rather annoying. With a filter, the earliest
point at which we can insert text is the start of the next line. This
means that if there is any text between the closing brace of the
C<BEGIN> block or the semicolon of the C<use> that caused the insertion,
and the end of the line, the insertion will certainly be in the wrong
place and probably cause a syntax error. 

C<lex_stuff> (and, therefore, C<at_runtime>) will issue a warning if
this is going to happen (specifically, if there are any non-space
non-comment characters between the point where we want to insert and the
point we're forced to settle for), but this may not be something you can
entirely control. If you are writing a module like the examples above
which calls C<at_runtime> from its C<import> method, what matters is
that B<users of your module> not put anything on a line after your
module's C<use> statement.

=back

If you want to use the filter implementation on perl 5.12 (for testing),
set C<PERL_B_HOOKS_ATRUNTIME=filter> in the environment. If the filter
implementation is in use, C<B::Hooks::AtRuntime::USE_FILTER> will be
true.

=head1 SEE ALSO

L<B::Hooks::Parser> will insert text 'here' in perls before 5.12, but
requires a setup step at least one source line in advance.

L<Hook::AfterRuntime> uses it to implement something somewhat similar to
this module.

L<Scope::OnExit> and L<B::Hooks::EndOfScope> provide hooks into
different points in the surrounding scope.

L<Filter::Util::Call> is the generic interface to the source filtering
mechanism.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

=head1 BUGS

Please report any bugs to <bug-B-Hooks-AtRuntime@rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Zefram's work on the core lexer API made this module enormously easier.

=head1 COPYRIGHT

Copyright 2015 Ben Morrow.

Released under the 2-clause BSD licence.

=cut
