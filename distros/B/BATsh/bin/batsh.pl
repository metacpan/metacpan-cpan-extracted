#!/usr/bin/env perl
######################################################################
#
# batsh.pl - command-line launcher for BATsh
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
#
# Installed via EXE_FILES so that "batsh.pl script.batsh" works after
# "make install" (ExtUtils::MakeMaker creates a .bat wrapper on Win32).
# The process exit code is the script's exit code.
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

# Prefer the sibling lib/ when run from an unpacked distribution
# (perl bin/batsh.pl ...); an installed BATsh is found via @INC as usual.
#
# The sibling directory is added only when the parent really is an
# unpacked BATsh distribution, which is what MANIFEST next to it means.
# An unconditional "use lib" would, once this script is installed into
# (say) /usr/local/bin, put /usr/local/lib at the head of @INC on every
# run; a stale or unrelated BATsh.pm left in that directory would then
# shadow the copy that was just installed.  Testing only for the module
# would not help, since that is exactly the case that goes wrong.
use FindBin ();
BEGIN {
    my $root   = "$FindBin::Bin/..";
    my $devlib = "$root/lib";
    if (-e "$root/MANIFEST" && -e "$devlib/BATsh.pm") {
        require lib;
        lib->import($devlib);
    }
}

use BATsh;

exit(BATsh->main(@ARGV));

__END__

=head1 NAME

batsh.pl - run a bilingual cmd.exe / bash .batsh script

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

  batsh.pl [--encoding=ENC] script.batsh [args...]
  batsh.pl [--encoding=ENC] -            # read the script from STDIN
  batsh.pl [--encoding=ENC] -e 'source'  # run inline source
  batsh.pl                               # interactive REPL
  batsh.pl --version
  batsh.pl --help

=head1 DESCRIPTION

Thin launcher around C<< BATsh->main(@ARGV) >>.  The process exit code is
the script's exit code: the argument of C<exit N> (SH mode) or
C<EXIT [/B] N> (CMD mode), or the status of the last executed command.

C<ENC> is one of C<cp932>, C<sjis>, C<gbk>, C<uhc>, C<big5>, C<utf8>,
C<none>, or C<auto> (the default).

=head1 SEE ALSO

L<BATsh>

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
