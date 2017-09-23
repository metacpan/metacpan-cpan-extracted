package CGI::BrowserDetect;

use 5.006;
use strict;
use warnings;

use base qw/HTTP::BrowserDetect/;

=head1 NAME

CGI::BrowserDetect - The great new CGI::BrowserDetect!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

sub new {
	my $pkg = shift;
	my $count = scalar @_;
	
	my %args = $count == 2 
			? (HTTP_USER_AGENT => shift, HTTP_ACCEPT_LANGUAGE => shift) 
			: $count == 1 
				? (HTTP_USER_AGENT => shift)
					: @_;

	my $self = $pkg->SUPER::new($args{HTTP_USER_AGENT});
	
	if ($args{HTTP_ACCEPT_LANGUAGE}) {
		$self->{accept_language} = $args{HTTP_ACCEPT_LANGUAGE};
		($self->{_lang}, $self->{_cnty}) = $self->{accept_language} =~ /([a-z]{2})\-([A-Z]{2})/;
	}
	return $self;
}

sub detect {
	my ($self, @want) = @_;
	my %provide;

	$self->$_ && do { $provide{$_} = $self->$_ } for @want;

	return wantarray ? %provide : \%provide;
}

sub device_type {
	my ($self) = @_;
	
	return $self->mobile
		? 'mobile'
		: $self->tablet
			? 'tablet'
			: 'computer';
}

sub lang {
	my ($self) = @_;

	return $self->language if $self->language;
	return $self->{_lang};
}

sub cnty {
	my ($self) = @_;

	return $self->country if $self->country;
	return $self->{_cnty};
}

1;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use CGI::BrowserDetect;

	my $ua = CGI::BrowserDetect->new($ENV{HTTP_USER_AGENT}, $ENV{HTTP_ACCEPT_LANGUAGE});
    ...

	my $hash = $ua->detect(qw/os browser type lang cnty/);


=head1 SUBROUTINES/METHODS

=head2 detect

pass in keys and returns a hash or reference.

=head2 device_type

return the type of device

=head2 lang

return the language if not found in HTTP_USER_AGENT using HTTP_ACCEPT_LANGUAGE 

=head2 cnty

returns the country IF NOT FOUND IN HTTP_USER_AGENT using HTTP_ACCEPT_LANGUAGE

=head2

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-browserdetect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-BrowserDetect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::BrowserDetect


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-BrowserDetect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-BrowserDetect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-BrowserDetect>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-BrowserDetect/>

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

1; # End of CGI::BrowserDetect
