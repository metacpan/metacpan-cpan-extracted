package ARGV::OrDATA;

use 5.006;
use strict;
use warnings;

=head1 NAME

ARGV::OrDATA - Let the diamond operator read from DATA if there's no ARGV

=head1 VERSION

Version 0.006

=cut

our $VERSION = '0.006';

sub import {
    my ($package) = $_[1] || caller;
    {   no strict 'refs';
        no warnings 'once';
        *ORIG = *ARGV;
        *ARGV = *{$package . '::DATA'} unless @ARGV || ! -t;
    }
}


sub unimport {
    my $package = shift;
    *ARGV = *ORIG;
    {   no strict 'refs';
        delete ${$package . '::'}{ORIG};
    }
    undef *ORIG;
}


sub is_using_argv {
    ! is_using_data()
}


sub is_using_data {
    my ($package) = caller;
    $package = caller 1 if 'ARGV::OrDATA' eq $package;
    return do {
        no strict 'refs';
        *ARGV eq *{$package . '::DATA' }
    }
}


=head1 SYNOPSIS

    use ARGV::OrDATA;

    while (<>) {
        print;
    }

    __DATA__
    You'll see this if you don't redirect something to the script's
    STDIN or you don't specify a filename on the command line.

=head1 DESCRIPTION

Tell your script it should use the DATA section if there's no input
coming from STDIN and there are no arguments.

You can also specify which package's DATA should be read instead of
the caller's:

    use My::Module;
    use ARGV::OrDATA 'My::Module';

    while (<>) {  # This reads from My/Module.pm's DATA section.
        print;
    }

To restore the old behaviour, you can call the C<unimport> method.

    use ARGV::OrDATA;

    my $from_data = <>;

    @ARGV = 'file1.txt';  # Ignored.

    'ARGV::OrDATA'->unimport;

    @ARGV = 'file2.txt';  # Works.

    my $from_file2 = <>;

Calling C<import> after C<unimport> would restore the DATA handle, but
B<wouldn't rewind it>, i.e. it would continue from where you stopped
(see t/04-unimport.t).

=head2 Why?

I use this technique when solving programming contests. The sample
input is usually small and I don't want to waste time by saving it
into a file.

=head1 EXPORT

Nothing. There are 2 subroutines you can call via their fully qualified names,
though:

=over 4

=item ARGV::OrDATA::is_using_argv()

Returns 0 when ARGV reads from DATA, 1 otherwise.

=item ARGV::OrDATA::is_using_data()

Returns 1 when ARGV reads from DATA, 0 otherwise.

=back

=head1 AUTHOR

E. Choroba, C<< <choroba at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub repository at
L<https://github.com/choroba/argv-ordata>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ARGV::OrDATA


You can also look for information at:

=over 4

=item * MetaCPAN

L<http://mcpan.org/pod/ARGV-OrDATA>

=item * GitHub

L<https://github.com/choroba/argv-ordata>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 E. Choroba.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__
