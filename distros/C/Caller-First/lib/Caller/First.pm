package Caller::First;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.01';

use base 'Import::Export';

our %EX = (
	caller_first => [qw/all/]
);

sub caller_first {
	my ($n, @last) = (0);
	while (my @l = (caller($n))) {
		!$_[0] && $l[0] eq 'main' ? last : do {
			@last = @l;
			$n++;
		};
	}
	return wantarray ? @last : shift @last;
}

# If you know how to do this beter then please raise a ticket
# I was hoping for something like caller(-1).

=head1 NAME

Caller::First - first|last caller from the stack.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Caller::First qw/caller_first/;

	my @caller = caller_first();

=head1 DESCRIPTION

This is a quick module to return the first caller from the stack. 

=cut

=head1 EXPORT

A list of functions that can be exported.  

=head2 caller_first

Returns the first caller from the stack. In scalar context this will return the package name and in list context you will get the full caller response. See L<https://perldoc.perl.org/functions/caller.html> for more information. 

	my $package = caller_first();
	my @caller = caller_first(); 

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-caller-first at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Caller-First>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Caller::First


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Caller-First>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Caller-First>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Caller-First>

=item * Search CPAN

L<https://metacpan.org/release/Caller-First>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Caller::First
