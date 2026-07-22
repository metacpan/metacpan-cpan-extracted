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
use FindBin ();
use lib "$FindBin::Bin/../lib";

use BATsh;

exit(BATsh->main(@ARGV));

__END__

=head1 NAME

batsh.pl - run a bilingual cmd.exe / bash .batsh script

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
