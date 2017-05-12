use strict;
use warnings;

package ARGV::URL;
{
  $ARGV::URL::VERSION = '0.93';
}

sub import
{
    # Inspired from L<perlopentut>
    @ARGV = map { m#^[a-z]{2,}://# ? qq#lwp-request -m GET "$_" |# : $_ } @ARGV;
}

1;

=head1 NAME

ARGV::URL - Wrap URLs from @ARGV for fetching and content consumption with <>

=head1 SYNOPSIS

From one-liners:

    perl -MARGV::URL -E "... <> ... "  $file_or_url ...
    perl -MARGV::URL -nE "..." $file_or_uri ...
    perl -MARGV::URL -pE "..." $file_or_url ...

From a script:

    use ARG::URL;
    ...
    while (<>) {
       ...

From a script that takes command-line options that should not be processed by
C<ARGV::URL> :

    # Skipping import
    use ARGV::URL ();
    
    ... extract options from @ARGV ...
    
    # Prepare URLs: do import now
    ARGV::URL->import;

=head1 DESCRIPTION

This module adds some power to the diamond (<>) operator (see L<perlopentut>):
importing the module will transform URLs in C<@ARGV> so that their content is
fetched and fed to <> like what is done for filenames in the standard
behavior.

=head1 IMPLEMENTATION DETAILS

I<B<Note:> implementation details are specific to this release and may change
in a later release.>

Have a look at the code: this is a 3-lines module.

Fetching URLs is done using the following command:

    lwp-request -m GET "$url"

=head1 SEE ALSO

=over 4

=item *

About the diamond operator (C<<>>): L<perlopentut/Filters>, L<perlop/"I/O Operators">

=item *

Some other modules that adds magic to C<@ARGV>: L<ARGV::readonly>, L<Encode::Argv>

=back

=head1 AUTHOR

Olivier MenguE<eacute>, L<mailto:dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2011 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut

