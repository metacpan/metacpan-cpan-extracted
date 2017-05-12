use 5.005;
use strict;
use warnings;

package ARGV::Abs;
{
  $ARGV::Abs::VERSION = '1.01';
}

use File::Spec;


sub import
{
    # Base directory for resolving paths
    my $base = $_[1];
    unless (defined $base) {
        require Cwd;
        $base = Cwd::getcwd();
    }
    @ARGV = map { File::Spec->rel2abs($_, $base) } @ARGV;
}

1;

=head1 NAME

ARGV::Abs - Transform paths in @ARGV to absolute paths

=head1 VERSION

version 1.01

=head1 SYNOPSIS

From one-liners (see L<perlrun>):

    perl -MARGV::Abs -E "..." foo.txt bar.txt ...

From a script where B<all> arguments are expected to be filenames:

    use ARG::Abs;
    ...

From a script that takes command-line options that should not be processed by
C<ARGV::Abs> :

    # Skipping import
    use ARGV::Abs ();
    
    ... extract options from @ARGV ...
    
    # Transform paths: do import now
    ARGV::Abs->import;

Resolve relative paths using base directory F</tmp>:

    perl -MARGV::Abs=/tmp -E "..." foo.txt bar.txt ...

    use ARGV::Abs '/tmp';

=head1 DESCRIPTION

This module transform all elements of C<@ARGV> into absolute pathnames.

Relative paths are resolved by default relative to the current directory.
To use another base directory, pass it as the argument for import.

=head1 SEE ALSO

Some other modules that add magic to C<@ARGV>: L<ARGV::URL>, L<ARGV::readonly>, L<Encode::Argv>.

=head1 AUTHOR

Olivier MenguE<eacute>, L<mailto:dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2011 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut
