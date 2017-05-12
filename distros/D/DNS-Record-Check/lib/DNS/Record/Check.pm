package DNS::Record::Check;

use warnings;
use strict;

=head1 NAME

DNS::Record::Check - Provides checks for some common DNS records.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use DNS::Record::Check;
    
    my $dnsrc=DNS::Record::Check->new;
    
    if($dnsrc->A($recordValue)){
        warn($recordValue.' is not a valid a record');
    }

=head1 SUBROUTINES/METHODS

=head2 new

This initiates the object.

    $dnsrc=DNS::Record::Check->new;

=cut

sub new{
	my $self={};
	bless $self;

	return $self;
}

=head2 A

Checks if a A record value is valid.

    my $return=$dnsrc->A($value);

=head3 Return Values

=head4 0

Valid.

=head4 1

Not defined.

=head4 2

Contains non-numeric or period characters.

=head4 3

It has less than four numbers.

=head4 4

It has more than four numbers.

=head4 5

The number is 0.

=head4 6

One of the numbers is greater than 255.

=head4 7

The fourth number is zero.

=cut

sub A{
	my $record=$_[1];

	#makes sure the record is defined
	if (!defined($record)) {
		return 1;
	}

	#make sure it does no
	if (!($record =~ /^[0123456789\.]*$/)) {
		return 2;
	}
	
	#checks each byte
	my @recordSplit=split(/\./, $record);
	my $int=0;
	while (defined($recordSplit[$int])) {

		#if we are at 4, it means there are 5 bytes
		if ($recordSplit[$int] == 4) {
			return 4;
		}

		#check if the first byte is equal to zero
		if ($int == 0) {
			if ($recordSplit[$int] == 0) {
				return 5;
			}
		}

		#makes sure the byde is not larger than 255
		if ($recordSplit[$int] > 255) {
			return 6;
		}

		#check if the last number is zero
		if ($int == 3) {
			if ($recordSplit[$int] == 0) {
				return 7;
			}
		}

		$int++;
	}

	if ($int < 4) {
		return 3;
	}

	return 0;
}

=head2 AAAA

Checks if a AAAA record value is valid.

    my $return=$dnsrc->AAAA($value);

=head3 Return Values

=head4 0

Valid.

=head4 1

Not defined.

=head4 2

Found characters that do not match a AAAA record.

=head4 3

Matched more than two semi-colons in a row.

=cut

sub AAAA{
	my $record=$_[1];

	#makes sure the record is defined
	if (!defined($record)) {
		return 1;
	}

	#make sure it does no
	if (!($record =~ /^[0123456789AaBbCcDdEeFf\:]*$/)) {
		return 2;
	}

	#make sure it does not have more than two : in a row
	if ($record =~ /\:\:\:/) {
		return 3;
	}

	return 0;
}

=head2 CNAME

Checks if a CNAME record value is valid.

    my $return=$dnsrc->CNAME($value);

=head3 Return Values

=head4 0

Valid.

=head4 1

Not defined.

=head4 2

Non-alphanumeric/period characters found.

=head4 3

The host name begins with a period.

=cut

sub CNAME{
	my $record=$_[1];

	#makes sure the record is defined
	if (!defined($record)) {
		return 1;
	}

	#makes sure no Non-alphanumeric/period characters found.
	if (!($record=~/^[[:alnum:]\.]*$/)) {
		return 2;
	}

	#makes sure it does not begin with a period
	if ($record =~ /^\./) {
		return 3;
	}

	return 0;
}

=head2 HINFO

Check a HINFO record value.

    my $return=$dnsrc->HINFO($value);

=head3 Return Values

=head4 0

Valid.

=head4 1

Undefined.

=head4 2

Does not start with a leter.

=head4 3

Contains values outside of capital letters, numbers, forwdward
slash, or a hyphen.

=head4 4

Does not end in either a capital letter or number.

=cut

sub HINFO{
	my $record=$_[1];

	#makes sure the record is defined
	if (!defined($record)) {
		return 1;
	}

	#make sure it starts with a capital letter
	if (!($record =~ /^[A-Z]/)) {
		return 2;
	}

	#makes sure it only contains the required characters
	if (!($record =~ /^[A-Z0-1\-\/]$/)) {
		return 3;
	}

	#makes sure it ends in either a number or letter
	if (!($record =~ /[A-Z0-1]$/)) {
		return 4;
	}	

	return 0;
}

=head2 MX

The MX value is not valid.

    my $return=$dnsrc->MX($value);

=head3 Return Values

=head4 0

Valid.

=head4 1

Undefined.

=head4 2

Non-numeric priority.

=head4 3

No hostname.

=head4 4

The hostname is not a valid domain name.

=head4 5

Additional information was found after a third space.

=cut

sub MX{
	my $record=$_[1];

	#makes sure the record is defined
	if (!defined($record)) {
		return 1;
	}

	#splits the record
	my @recordSplit=split(/\ /, $record);

	#the priority is not numeric
	if (!($recordSplit[0] =~ /^[[:digit:]]$/)) {
		return 2;
	}

	#no host name
	if (!defined($recordSplit[1])) {
		return 3;
	}

	#the CNAME check just checks if it is a valid host name or not
	if ($_[0]->CNAME($recordSplit[1])) {
		return 4;
	}

	#has extra info
	if (defined($recordSplit[2])) {
		return 5;
	}

	return 0;
}

=head2 NS

Checks if a NS record value is valid.

    my $return=$dnsrc->NS($value);

=head3 Return Values

See the return value listing for CNAME.

=cut

sub NS{
	my $record=$_[1];

	return $_[0]->CNAME($record);
}

=head2 PTR

Checks if a PTR record value is valid.

    my $return=$dnsrc->PTR($value);

=head3 Return Values

See the return value listing for CNAME.

=cut

sub PTR{
	my $record=$_[1];

	return $_[0]->CNAME($record);
}

=head2 RP

Checks if a RP record value is valid.

    my $return=$dnsrc->RP($value);

=head3 Return Values

=head4 0

Valid.

=head4 1

Undefined.

=head4 2

Invalid email address.

=head4 3

Invalid hostname in email address.

=cut

sub RP{
	my $record=$_[1];

	if (!defined($record)) {
		return 1;
	}

	my @recordSplit=split(/\@/, $record);

	if (defined($recordSplit[2])) {
		return 2;
	}

	if (!defined($recordSplit[1])) {
		return 2;
	}

	if ($recordSplit[0] =~ /[\!\#\$\%\^\&\*\(\)\;\:\<\>\[\]]/) {
		return 2;
	}

	if (!$_[0]->CNAME($recordSplit[1])) {
		return 3;
	}

	return 0;
}


=head2 TXT

Checks if a TXT record value is valid.

    my $return=$dnsrc->TXT($value);

=head3 Return Values

=head4 0

Valid.

=head4 1

Undefined.

=cut

sub TXT{
	my $record=$_[1];

	if (!defined($record)) {
		return 1;
	}

	return 0;
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dns-record-check at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DNS-Record-Check>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DNS::Record::Check


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DNS-Record-Check>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DNS-Record-Check>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DNS-Record-Check>

=item * Search CPAN

L<http://search.cpan.org/dist/DNS-Record-Check/>

=item * SVN Repo

L<http://eesdp.org/svnweb/index.cgi/pubsvn/browse/Perl/DNS%3A%3ARecord%3A%3ACheck>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Zane C. Bowers.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DNS::Record::Check
