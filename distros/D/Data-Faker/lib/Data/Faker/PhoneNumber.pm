package Data::Faker::PhoneNumber;
use strict;
use warnings;
use vars qw($VERSION); $VERSION = '0.10';
use base 'Data::Faker';

=head1 NAME

Data::Faker::PhoneNumber - Data::Faker plugin

=head1 SYNOPSIS AND USAGE

See L<Data::Faker>

=head1 DATA PROVIDERS

=over 4

=item phone_number

Return a fake phone number.

=cut

__PACKAGE__->register_plugin(
	phone_number => [
		'###-###-####',
		'(###)###-####',
		'1-###-###-####',
		'###.###.####',
		'###-###-####',
		'(###)###-####',
		'1-###-###-####',
		'###.###.####',
		'###-###-#### x###',
		'(###)###-#### x###',
		'1-###-###-#### x###',
		'###.###.#### x###',
		'###-###-#### x####',
		'(###)###-#### x####',
		'1-###-###-#### x####',
		'###.###.#### x####',
		'###-###-#### x#####',
		'(###)###-#### x#####',
		'1-###-###-#### x#####',
		'###.###.#### x#####',
	],
);

=back

=head1 SEE ALSO

L<Data::Faker>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
