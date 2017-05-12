package ACME::MSDN::SPUtility;

use warnings;
use strict;

use Perl6::Say;

=encoding utf8

=head1 NAME

ACME::MSDN::SPUtility - SPUtility.HideTaiwan Method (Microsoft.SharePoint.Utilities)

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This is a Implementation of part of MSDN SPUtility.
L<http://msdn.microsoft.com/en-us/library/ms441219.aspx>

This module does the following things:
Checks whether the Taiwan calendar is hidden based on the specified Web site and locale ID.
Checks if the China Gov really Lost Their Brain based on the specified Web site and locale ID.
Checks if Bill-GAY$ and his 'Stuffz' lost thier Balls at Halloween based on the specified Web site and locale ID.


	use ACME::MSDN::SPUtility;

	my $fool = ACME::MSDN::SPUtility->new( $SPWeb, int $localeId);
	say 'Hello, Taiwan!' if not $fool->HideTaiwan;
	STDERR->say("I can't speak well if I don't have a brain!") if $fool->HideChina;
	say STDERR 'Plz find my balls for me and give it back to me. I lost all of them!' if $fool->HideMicroSoft;

=head1 FUNCTIONS

=head2 new

Get a SPUtility object.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	#$self->initialize();
	return $self;
}

=head2 HideTaiwan

Checks whether the Taiwan calendar is hidden based on the specified Web site and locale ID.

=cut

sub HideTaiwan {
	my $self = shift;
	my ($spWeb, $localeId) = @_;
	
	print "Taiwan is definitely a Contry already, and should never hide. Is china scared by this?";
	return undef;
};

=head2 HideChina

Checks if the China Gov really Lost Their Brain based on the specified Web site and locale ID.

=cut

sub HideChina {
	my $self = shift;
	my ($spWeb, $localeId) = @_;
	
	print "fsck the dumb China gov";
	return 1;
}

=head2 HideMicroSoft

Checks if Bill-GAY$ and his 'Stuffz' lost thier Balls at Halloween based on the specified Web site and locale ID.

=cut

sub HideMicroSoft {
	my $self = shift;
	my ($spWeb, $localeId) = @_;
	
	print 'Bill-Gay$ and Micro$oft Stuff$ lost their Ballz, did you see them?';
	return 1;
}

=head1 AUTHOR

BlueT - Matthew Lien - 練喆明, C<< <BlueT at BlueT.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-msdn-sputility at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ACME-MSDN-SPUtility>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ACME::MSDN::SPUtility


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ACME-MSDN-SPUtility>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ACME-MSDN-SPUtility>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ACME-MSDN-SPUtility>

=item * Search CPAN

L<http://search.cpan.org/dist/ACME-MSDN-SPUtility>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 BlueT - Matthew Lien - 練喆明, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ACME::MSDN::SPUtility
