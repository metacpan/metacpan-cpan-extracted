package CGI::Untaint::CountyStateProvince::US;

use warnings;
use strict;
use Locale::SubCountry;

# use base qw(CGI::Untaint::object CGI::Untaint::CountyStateProvince);
use base 'CGI::Untaint::object';

=head1 NAME

CGI::Untaint::CountyStateProvince::US - Add U.S. states to CGI::Untaint::CountyStateProvince tables

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Adds a list of U.S. states to the list of counties/state/provinces
which are known by the CGI::Untaint::CountyStateProvince validator so that
an HTML form sent by CGI contains a valid U.S. state.

You must include CGI::Untaint::CountyStateProvince::US after including
CGI::Untaint, otherwise it won't work.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::CountyStateProvince::US;
    my $info = CGI::Info->new();
    my $u = CGI::Untaint->new($info->params());
    # Succeeds if state = 'MD' or 'Maryland', fails if state = 'Queensland';
    $u->extract(-as_CountyStateProvince => 'state');
    # ...

=cut

=head1 SUBSOUTINES/METHODS

=head2 is_valid

Validates the data, setting the data to be the two letter abbreviation for the
given state.  See CGI::Untaint::is_valid.

=cut

sub is_valid {
	my $self = shift;

	my $value = uc($self->value);

	if($value =~ /([A-Z\s]+)/) {
		$value = $1;
	} else {
		return 0;
	}

	unless($self->{_validator}) {
		$self->{_validator} = Locale::SubCountry->new('US');
	}

	unless($self->{_validator}) {
		return 0;
	}

	my $state = $self->{_validator}->code($value);
	if($state && ($state ne 'unknown')) {
		# Detaintify
		if($state =~ /(^[A-Z]{2}$)/) {
			return $1;
		}
	}

	$state = $self->{_validator}->full_name($value);
	if($state && ($state ne 'unknown')) {
		return $value;
	}

	return 0;
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
	my $gb = CGI::Untaint::CountyStateProvince::US->_new();

	push @CGI::Untaint::CountyStateProvince::countries, $gb;
};

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Only two letter abbreviations are allowable, so 'Mass' won't work for
Massachusetts.

Please report any bugs or feature requests to C<bug-cgi-untaint-csp-gb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-CountyStateProvince>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

CGI::Untaint::CountyStateProvince, CGI::Untaint

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Untaint::CountyStateProvince::US


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-CountyStateProvince-US>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Untaint-CountyStateProvince-US>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Untaint-CountyStateProvince-US>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Untaint-CountyStateProvince-US>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nigel Horne.

This program is released under the following licence: GPL


=cut

1; # End of CGI::Untaint::CountyStateProvince::US
