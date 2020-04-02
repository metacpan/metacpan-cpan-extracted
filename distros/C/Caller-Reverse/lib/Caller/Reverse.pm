package Caller::Reverse;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use base 'Import::Export';

our %EX = (
	caller_first => [qw/all/],
	callr => [qw/all/],
);

sub caller_first {
	return callr(0, $_[0]);
}

sub callr {
	my ($n, @caller) = 0;
	while (my @l = (caller($n))) {
		unshift @caller, \@l unless 
			$l[0] =~ m/Caller\:\:Reverse/
			or 
			!$_[1] && $l[0] =~ m/main/;
		$n++;
	}
	return wantarray ? @{$caller[$_[0]]} : $caller[$_[0]][0];
}

=head1 NAME

Caller::Reverse - reverse the caller stack.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Caller::Reverse qw/callr caller_first/;

	my @caller = caller_first();

	my @callr = callr(2);

=head1 DESCRIPTION

This is a quick module to return that reverses the caller stack. 

=cut

=head1 EXPORT

A list of functions that can be exported.  

=head2 caller_first

Returns the first caller from the stack. In scalar context this will return the package name and in list context you will get the full caller response. See L<https://perldoc.perl.org/functions/caller.html> for more information. 

	my $package = caller_first();
	my @caller = caller_first(); 

=cut

=head2 callr 

The reverse order of caller.

=cut

=head1 AUTHOR

LNATION, C<< <lnation at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-caller-reverse at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Caller-Reverse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Caller::Reverse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Caller-Reverse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Caller-Reverse>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Caller-Reverse>

=item * Search CPAN

L<https://metacpan.org/release/Caller-Reverse>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Caller::Reverse
