package CGI::Untaint::CountyStateProvince;

use warnings;
use strict;
use Carp;

use base 'CGI::Untaint::object';

=head1 NAME

CGI::Untaint::CountyStateProvince - Validate a state, county or province in a
CGI script.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

our @countries;

=head1 SYNOPSIS

CGI::Untaint::CountyStateProvince is a subclass of CGI::Untaint used to
validate if the given user data is a valid county/state/province.

This class is not to be instantiated, instead a subclass must be
instantiated. For example L<CGI::Untaint::CountyStateProvince::GB> would
validate against a British county, L<CGI::Untaint::CountyStateProvince::US>
would validate against a US state, and so on.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::CountyStateProvince;
    # ...
    my $info = CGI::Info->new();
    my $params = $info->params();
    # ...
    # Country table(s) must be loaded after CGI::Untaint::CountyStateProvince
    if($params->{'country'} == 44) {
	require CGI::Untaint::CountyStateProvince::GB;

	CGI::Untaint::CountyStateProvince::GB->import();
    } elsif($params->{'country'} == 1) {
	require CGI::Untaint::CountyStateProvince::US;

	CGI::Untaint::CountyStateProvince::US->import();
    } else {
	die 'Unsupported country ', $params->{'country'};
    }
    my $u = CGI::Untaint->new($params);
    my $csp = $u->extract(-as_CountyStateProvince => 'state');
    # $csp will be lower case

=head1 SUBROUTINES/METHODS

=head2 is_valid

Validates the data.

=cut

sub _untaint_re {
	# Only allow letters and spaces
	return qr/^([a-zA-Z\s]+)$/;
}

sub is_valid {
	my $self = shift;

	unless(@countries) {
		carp 'You must specify at least one country';
		return 0;
	}

	my $value = $self->value();

	foreach my $country(@countries) {
		$country->value($value);

		if(my $new_value = $country->is_valid()) {
			$self->value($new_value) if $new_value ne $value;
		} else {
			return 0;
		}
	}

	return 1;
}


=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-untaint-countystateprovince at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-CountyStateProvince>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

CGI::Untaint

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Untaint::CountyStateProvince

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-CountyStateProvince>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Untaint-CountyStateProvince>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of CGI::Untaint::CountyStateProvince
