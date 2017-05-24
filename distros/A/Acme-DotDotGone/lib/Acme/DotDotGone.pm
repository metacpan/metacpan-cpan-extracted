package Acme::DotDotGone;

use 5.006;
use strict;
use warnings;

=head1 NAME

Acme::DotDotGone - The great new Acme::DotDotGone!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our %dots;
BEGIN {
 	%dots = (
		toDots => sub {
			join ' ', map { $dots{$_}() } split '', unpack "b*", shift;
		},
		fromDots => sub {
			pack "b*", join '', map { $dots{$_}() } split ' ', shift;
		},
		'.' => sub { 0 },
		'..' => sub { 1 },
		0 => sub { '.' },
		1 => sub { '..' },
		stderr => sub { print @_ }
	);
	close STDERR; # *\o/*
}

sub import {
	open FH, "<$0" or print "Cannot read '$0'\n" and exit;

	my $reg = $_[1] 
		? qr/(.*)\1^\s*use\s+Acme::DotDotGone\s+($_[1]);\n/
		: qr/.*^\s*use\s+Acme::DotDotGone;\n/;

	($_[2] = (join '', <FH>)) =~ s/$reg//sm;
	$_[2] = $1 . $_[2] if $1;

	close FH;

	($_[2], $_[3], $_[4]) = (($2) 
		? ($2 eq 'dot') 
			? sub { 
				$_[1] = $dots{toDots}($_[0]);
				$_[0], $_[1], $_[1]; 
			}
			: sub { 
				$_[1] = $dots{fromDots}($_[0]); 
				$_[1], $_[0], $_[1]; 
			}
		: ($_[2] =~ m/[a-zA-Z]/)
			? sub { 
				undef			
			}
			: sub { 
				$_[1] = $dots{fromDots}($_[0]);
				$_[1], $_[0];
			}
	)->($_[2]);

	if ($_[4]) {
		open FH, ">$0" or print "Cannot encode. '$0'\n" and exit;
		print FH "use Acme::DotDotGone;\n";
		print FH $_[4];
		close FH;
	}

	do { eval "$_[2]"; $dots{stderr}($@); } if $_[2];
}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

vim worldEnding.pl

    use Acme::DotDotGone dot;

	use feature 'say';
	say 'The world is about to end';

	1;

perl worldEnding.pl

	The world is about to end

cat worldEnding.pl

	use Acme::DotDotGone;
	. .. . .. . . . . .. . .. . .. .. .. . .. .. . . .. .. .. . .. . .. . . .. .. . . . . . . .. . . . .. .. . . .. .. . .. . .. . . .. .. . .. . . . . .. .. . . . .. . .. .. .. . .. . .. . .. .. .. . . .. . . .. .. .. . .. . .. . . .. .. . . . . . . .. . . .. .. .. . . .. . . .. .. . . .. .. .. . .. . . . . .. .. . .. . . .. .. .. .. . .. .. .. . . .. . . .. .. . .. .. .. . . . .. . .. . . . . .. .. . . .. .. .. . .. . . . . .. .. . .. . . .. .. .. .. . . . . . . .. . . .. .. .. . . .. . . . . .. . .. . .. . . . . .. . .. .. . .. . .. . . .. .. . . . . . . .. . . .. .. .. . .. .. .. . .. .. .. .. . .. .. . . .. . . .. .. .. . . . .. .. . .. .. . . . .. . . .. .. . . . . . . .. . . .. . . .. . .. .. . .. .. . . .. .. .. . . . . . . .. . . .. . . . . .. .. . . .. . . . .. .. . .. .. .. .. . .. .. . .. . .. . .. .. .. . . . .. . .. .. .. . . . . . . .. . . . . .. . .. .. .. . .. .. .. .. . .. .. . . . . . . .. . . .. . .. . . .. .. . . .. .. .. . .. .. . . . .. . . .. .. . .. .. .. . . .. . . .. .. . .. .. .. . . . .. . .. . . . . . .. . .. . . . . .. . . . .. .. . . .. .. . .. .. .. . . . .. . .. . . . .

perl worldEnding.pl

	The World is about to end

vim worldEnding.pl
	
	use Acme::DotDotGone panic;
	. .. . .. . . . . .. . .. . .. .. .. . .. .. . . .. .. .. . .. . .. . . .. .. . . . . . . .. . . . .. .. . . .. .. . .. . .. . . .. .. . .. . . . . .. .. . . . .. . .. .. .. . .. . .. . .. .. .. . . .. . . .. .. .. . .. . .. . . .. .. . . . . . . .. . . .. .. .. . . .. . . .. .. . . .. .. .. . .. . . . . .. .. . .. . . .. .. .. .. . .. .. .. . . .. . . .. .. . .. .. .. . . . .. . .. . . . . .. .. . . .. .. .. . .. . . . . .. .. . .. . . .. .. .. .. . . . . . . .. . . .. .. .. . . .. . . . . .. . .. . .. . . . . .. . .. .. . .. . .. . . .. .. . . . . . . .. . . .. .. .. . .. .. .. . .. .. .. .. . .. .. . . .. . . .. .. .. . . . .. .. . .. .. . . . .. . . .. .. . . . . . . .. . . .. . . .. . .. .. . .. .. . . .. .. .. . . . . . . .. . . .. . . . . .. .. . . .. . . . .. .. . .. .. .. .. . .. .. . .. . .. . .. .. .. . . . .. . .. .. .. . . . . . . .. . . . . .. . .. .. .. . .. .. .. .. . .. .. . . . . . . .. . . .. . .. . . .. .. . . .. .. .. . .. .. . . . .. . . .. .. . .. .. .. . . .. . . .. .. . .. .. .. . . . .. . .. . . . . . .. . .. . . . . .. . . . .. .. . . .. .. . .. .. .. . . . .. . .. . . . .

perl worldEnding.pl

	The World is about to end

less worldEnding.pl

    use Acme::DotDotGone;

	use feature 'say';
	say 'The world is about to end';

	1

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-dotdotgone at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-DotDotGone>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::DotDotGone


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-DotDotGone>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-DotDotGone>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-DotDotGone>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-DotDotGone/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

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

1; # End of Acme::DotDotGone
