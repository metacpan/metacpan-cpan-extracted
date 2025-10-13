package Arthas::Defaults::536;

use v5.36;
use warnings FATAL => 'all';
no warnings 'uninitialized';
use utf8;
use feature();
use feature 'try';
no warnings 'experimental::try';
use version;
use Carp qw/carp croak confess cluck/;

require Exporter;
our @ISA       = ('Exporter');
our @EXPORT    = qw/
    carp croak confess cluck
    try catch finally
/;

sub import {
    feature->import(':5.36');
    strict->import();
    warnings->import(FATAL => 'all');
    warnings->unimport('uninitialized');
    utf8->import();

    experimental->import('try');

    # Export all @EXPORT
    Arthas::Defaults::536->export_to_level(1, @_);
}

sub unimport {
    feature->unimport();
    strict->unimport();
    warnings->unimport();
    utf8->unimport();

    experimental->unimport('try');
}

1;

__END__

=head1 NAME

Arthas::Defaults::536 - Defaults for coding with perl 5.36 - Do not use if you're not Arthas

=head1 SYNOPSIS

    use Arthas::Defaults;

=head1 DESCRIPTION

It's like saying:

    use v5.36;
    use utf8;
    use warnings;
    no warnings 'uninitialized';
    use experimental 'signatures';
    use Carp qw/carp croak confess cluck/;
    use Try::Tiny;

Might change without notice, at any time. DO NOT USE!

=over

=item C<use v5.36>

This is actually C<use feature ':5.36'>. It imports some perl 5.10 -> 5.36
semantics, such as strict, given-when syntax, Unicode strings, signatures, ... See
L<feature> documentation and source code for more information.

=item C<use utf8>

This is NOT related to handling UTF-8 strings or input/output (see
C<use feature 'unicode_strings'> imported with C<use v5.20> for
something more related to that).

C<use utf8> is imported in order to allow UTF-8 characters inside the source
code: while using UTF-8 in the source is not standard procedure, it
happens to me every now and then. Also, enabling this feature does
no harm if you're using a recent version of perl, so why not enable it?

=item C<use warnings FATAL =E<gt> 'all'>

Warnings are useful, who wouldn't want them?

However, if they are not treated as fatal errors, they are often
ignored, making them pointless. So, be fatal!

=item C<no warnings 'uninitialized'>

Well, I<most> warnings are useful. The ones regarding uninitialized (undef)
variables are a bit of a pain. Writing a code such as this:

    my $str;
    
    if ( $str eq 'maya' ) {
        say 'Maya!';
    }

would emit a warning, thus forcing you to write:

    my $str;
    
    if ( defined $str && $str eq 'maya' ) {
        say 'Maya!';
    }

which is boring enough to justify suppressing these warnings.

=item C<use Carp qw/carp croak confess cluck/>

These functions are very useful to show error details better
than that of C<die()> and C<warn()>.

=item C<use experimental 'try'>

Try - catch - finaly... finally!

=back

=head1 WARNING

The 5.36 version of this module is not compatible with the previous one,
bcause it replaces L<Try::Tiny> with Perl's own new Try/Catch syntax,
and discards the obsoleted C<postderef> syntax.

=head1 AUTHOR

Michele Beltrame, C<arthas@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

