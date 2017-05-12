package CGI::Untaint::CountyStateProvince::GB;

use warnings;
use strict;
use Locale::SubCountry;
use Carp;

# use base qw(CGI::Untaint::object CGI::Untaint::CountyStateProvince);
use base 'CGI::Untaint::object';

=head1 NAME

CGI::Untaint::CountyStateProvince::GB - Add British counties to CGI::Untaint::CountyStateProvince tables

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

our %counties = (
	'aberdeenshire' => 1,
	'anglesey' => 1,
	'angus' => 1,
	'avon' => 1,
	'ayrshire' => 1,
	'bedfordshire' => 1,
	'berkshire' => 1,
	'blaenau gwent' => 1,
	'brecknockshire' => 1,
	'bridgend' => 1,
	'buckinghamshire' => 1,
	'borders' => 1,
	'cardinganshire' => 1,
	'caerphilly' => 1,
	'cambridgeshire' => 1,
	'cardiff' => 1,
	'carmarthenshire' => 1,
	'ceredigion' => 1,
	'channel islands' => 1,
	'cheshire' => 1,
	'clackmannanshire' => 1,
	'clywd' => 1,
	'county durham' => 1,
	'county tyrone' => 1,
	'conwy' => 1,
	'cornwall' => 1,
	'cumbria' => 1,
	'derbyshire' => 1,
	'denbighshire' => 1,
	'devon' => 1,
	'dorset' => 1,
	'dumfries and galloway' => 1,
	'dyfed' => 1,
	'east lothian' => 1,
	'east sussex' => 1,
	'east yorkshire' => 1,
	'essex' => 1,
	'fife' => 1,
	'flintshire' => 1,
	'glamorgan' => 1,
	'gloucestershire' => 1,
	'grampian' => 1,
	'gwent' => 1,
	'gwynedd' => 1,
	'hampshire' => 1,
	'hertfordshire' => 1,
	'herefordshire' => 1,
	'isle of man' => 1,
	'isle of wight' => 1,
	'kent' => 1,
	'lancashire' => 1,
	'leicestershire' => 1,
	'lincolnshire' => 1,
	'london' => 1,
	'manchester' => 1,
	'merioneth' => 1,
	'merseyside' => 1,
	'mid lothian' => 1,
	'middlesex' => 1,	# Doesn't exist anymore, but people like it
	'monmouthshire' => 1,
	'montgomeryshire' => 1,
	'north yorkshire' => 1,
	'norfolk' => 1,
	'northamptonshire' => 1,
	'northern ireland' => 1,
	'northumberland' => 1,
	'nottinghamshire' => 1,
	'oxfordshire' => 1,
	'pembrokeshire' => 1,
	'powys' => 1,
	'radnorshire' => 1,
	'renfrewshire' => 1,
	'shropshire' => 1,
	'somerset' => 1,
	'south yorkshire' => 1,
	'staffordshire' => 1,
	'strathclyde' => 1,
	'suffolk' => 1,
	'surrey' => 1,
	'tayside' => 1,
	'teesside' => 1,
	'tyne and wear' => 1,
	'warwickshire' => 1,
	'west dunbartonshire' => 1,
	'west lothian' => 1,
	'west midlands' => 1,
	'west sussex' => 1,
	'west yorkshire' => 1,
	'wiltshire' => 1,
	'worcestershire' => 1,
);

our %abbreviations = (
	'beds' => 'bedfordshire',
	'cambs' => 'cambridgeshire',
	'cleveland' => 'teesside',
	'co durham' => 'county durham',
	'durham' => 'county durham',
	'east yorks' => 'east yorkshire',
	'glasgow' => 'west lothian',
	'gloucester' => 'gloucestershire',
	'greater london' => 'london',
	'hants' => 'hampshire',
	'herts' => 'hertfordshire',
	'lancs' => 'lancashire',
	'middx' => 'middlesex',
	'n yorkshire' => 'north yorkshire',
	'northants' => 'northamptonshire',
	'notts' => 'nottinghamshire',
	'oxon' => 'oxfordshire',
	'greater manchester' => 'manchester',
	's yorkshire' => 'south yorkshire',
	'westmidlands' => 'west midlands',
	'west mids' => 'west midlands',
	'west yorks' => 'west yorkshire',
);

=head1 SYNOPSIS

Adds a list of British counties to the list of counties/state/provinces
which are known by the CGI::Untaint::CountyStateProvince validator so that
an HTML form sent by CGI contains a valid county.

You must include CGI::Untaint::CountyStateProvince::GB after including
CGI::Untaint, otherwise it won't work.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::CountyStateProvince::GB;
    my $info = CGI::Info->new();
    my $u = CGI::Untaint->new($info->params());
    # Succeeds if state = 'Kent', fails if state = 'Queensland';
    $u->extract(-as_CountyStateProvince => 'state');
    # ...

=cut

=head1 SUBSOUTINES/METHODS

=head2 is_valid

Validates the data. See CGI::Untaint::is_valid.

=cut

sub is_valid {
	my $self = shift;

	my $value = lc($self->value);

	if($value =~ /([a-z\s]+)/) {
		$value = $1;
	} else {
		return 0;
	}

	if(exists($abbreviations{$value})) {
		return $abbreviations{$value};
	}

	# Try using Locale::SubCountry first, but be aware of RT77735 - some
	# counties are missing and some towns are listed as counties.
	unless($self->{_validator}) {
		$self->{_validator} = Locale::SubCountry->new('GB');
		unless($self->{_validator}) {
			carp 'Can\'t instantiate Locale::SubCountry';
		}
	}

	my $county = $self->{_validator}->code($value);
	if($county && ($county ne 'unknown')) {
		return $value;
	}

	return exists($counties{$value}) ? $value : 0;
}

=head2 value

Sets the raw data which is to be validated.  Called by the superclass, you
are unlikely to want to call it.

=cut

sub value {
	my ($self, $value) = @_;

	if(defined($value)) {
		$self->{value} = $value;
	}

	return $self->{value};
}

BEGIN {
	my $gb = CGI::Untaint::CountyStateProvince::GB->_new();

	push @CGI::Untaint::CountyStateProvince::countries, $gb;
};

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-untaint-csp-gb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-CountyStateProvince>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

CGI::Untaint::CountyStateProvince, CGI::Untaint

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc CGI::Untaint::CountyStateProvince::GB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-CountyStateProvince-GB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Untaint-CountyStateProvince-GB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Untaint-CountyStateProvince-GB>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Untaint-CountyStateProvince-GB>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nigel Horne.

This program is released under the following licence: GPL


=cut

1; # End of CGI::Untaint::CountyStateProvince::GB
