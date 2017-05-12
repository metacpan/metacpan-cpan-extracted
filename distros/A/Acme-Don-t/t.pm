package Acme::Don::t;

$VERSION = '1.01';

sub don't (&) {}

1;
__END__

=head1 NAME

Acme::Don't - The opposite of C<do>

=head1 VERSION

This document describes version 1.01 of Acme::Don::t,
released May  3, 2002.

=head1 SYNOPSIS

    use Acme::Don't;

    don't { print "This won't be printed\n" };    # NO-OP

=head1 DESCRIPTION

The Acme::Don't module provides a C<don't> command, which is the 
opposite of Perl's built-in C<do>.

It is used exactly like the C<do BLOCK> function except that,
instead of executing the block it controls, it...well...doesn't.

Regardless of the contents of the block, C<don't> returns C<undef>.

You can even write:

    don't {
        # code here
    } while condition();

And, yes, in strict analogy to the semantics of Perl's magical
C<do...while>, the C<don't...while> block is I<unconditionally>
not done once before the test. ;-)

Note that the code in the C<don't> block must be syntactically valid
Perl.  This is an important feature: you get the accelerated
performance of not actually executing the code, without sacrificing
the security of compile-time syntax checking.

=head1 LIMITATIONS

=over

=item *

Doesn't (yet) implement the opposite of C<do STRING>. 
The current workaround is to use:

    don't {"filename"};

=item *

The construct:

    don't { don't { ... } }

isn't (yet) equivalent to:

    do { ... }

because the outer C<don't> prevents the inner C<don't> from being executed,
before the inner C<don't> gets the chance to discover that it actually
I<should> execute.

This is an issue of semantics. C<don't...> doesn't mean C<do the opposite of...>; it means C<do nothing with...>.

In other words, doin nothing about doing nothing does...nothing.

=item * 

You can't (yet) use a:

    don't { ... } unless condition();

as a substitute for:

    do { ... } if condition();

Again, it's an issue of semantics. C<don't...unless...> doesn't mean C<do the opposite of...if...>; it means C<do nothing with...if not...>.

=back

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BLAME

Luke Palmer really should be I<far> more careful what he idly wishes for.

=head1 BUGS

Unlikely, since it doesn't actually do anything.
However, bug reports and other feedback are most welcome.

=head1 COPYRIGHT

Copyright (c) 2002, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
