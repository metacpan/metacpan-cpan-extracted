# Perl bindings for the PAG functions in libkafs.
#
# This is the Perl boostrap file for the AFS::PAG module, nearly all of which
# is implemented in XS.  For the actual source, see PAG.xs.  This file
# contains the bootstrap and export code and the documentation.
#
# Written by Russ Allbery <rra@cpan.org>
# Copyright 2013
#     The Board of Trustees of the Leland Stanford Junior University
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

package AFS::PAG;

use 5.008;
use strict;
use warnings;

use base qw(DynaLoader);

use Exporter qw(import);

our (@EXPORT_OK, $VERSION);

# Set all import-related variables in a BEGIN block for robustness.
BEGIN {
    @EXPORT_OK = qw(hasafs haspag setpag unlog);
    $VERSION   = '1.02';
}

# Load the binary module.
bootstrap AFS::PAG $VERSION;

1;
__END__

=for stopwords
Allbery AFS PAG libkafs libkopenafs Kerberos aklog UID kdestroy

=head1 NAME

AFS::PAG - Perl bindings for AFS PAG manipulation

=head1 SYNOPSIS

    use AFS::PAG qw(hasafs setpag unlog);

    if (hasafs()) {
        setpag();
        system('aklog') == 0
          or die "cannot get tokens\n";
        do_afs_things();
        unlog();
    }

=head1 DESCRIPTION

AFS is a distributed file system allowing cross-platform sharing of files
among multiple computers.  It associates client credentials (called AFS
tokens) with a Process Authentication Group, or PAG.  AFS::PAG makes
available in Perl the PAG manipulation functions provided by the libkafs
or libkopenafs libraries.

With the functions provided by this module, a Perl program can detect
whether AFS is available on the local system (hasafs()) and whether it is
currently running inside a PAG (haspag()).  It can also create a new PAG
and put the current process in it (setpag()) and remove any AFS tokens in
the current PAG (unlog()).

Note that this module doesn't provide a direct way to obtain new AFS
tokens.  Programs that need AFS tokens should normally obtain Kerberos
tickets (via whatever means) and then run the program B<aklog>, which
comes with most AFS distributions.  This program will create AFS tokens
from the current Kerberos ticket cache and store them in the current PAG.
To isolate those credentials from the rest of the system, call setpag()
before running B<aklog>.

=head1 FUNCTIONS

This module provides the following functions, none of which are exported
by default:

=over 4

=item hasafs()

Returns true if the local host is running an AFS client and false
otherwise.

=item haspag()

Returns true if the current process is running inside a PAG and false
otherwise.  AFS tokens obtained outside of a PAG are visible to any
process on the system outside of a PAG running as the same UID.  AFS
tokens obtained inside a PAG are visible to any process in the same PAG,
regardless of UID.

=item setpag()

Creates a new, empty PAG and put the current process in it.  This should
normally be called before obtaining new AFS tokens to isolate those tokens
from other processes on the system.  Returns true on success and throws
an exception on failure.

=item unlog()

Deletes all AFS tokens in the current PAG, similar to the action of
B<kdestroy> on a Kerberos ticket cache.  Returns true on success and
throws an exception on failure.

=back

=head1 DIAGNOSTICS

=over 4

=item PAG creation failed: %s

setpag() failed.  The end of the error message will be a translation of
the system call error number.

=item Token deletion failed: %s

unlog() failed.  The end of the error message will be a translation of
the system call error number.

=back

=head1 RESTRICTIONS

This module currently doesn't provide the k_pioctl() or pioctl() function
to make lower-level AFS system calls.  It also doesn't provide the libkafs
functions to obtain AFS tokens from Kerberos tickets directly without using
an external ticket cache.  This prevents use of internal Kerberos ticket
caches (such as memory caches), since the Kerberos tickets used to generate
AFS tokens have to be visible to an external B<aklog> program.

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 SEE ALSO

aklog(1)

The current version of this module is always available from its web site
at L<http://www.eyrie.org/~eagle/software/afs-pag/>.

=cut
