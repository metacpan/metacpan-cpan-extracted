package Data::Faker::Country;
# ABSTRACT: Provides country and ISO country code generation

use strict;
use warnings;

=head1 NAME

Data::Faker::Country - provides country support for L<Data::Faker>

=head1 SYNOPSIS

 use Data::Faker;
 use feature qw(say);
 my $faker = Data::Faker->new;
 say "Example country:          " . $faker->country;
 say "Example ISO country code: " . $faker->country_code;

=head1 DESCRIPTION

Provides two methods in L<Data::Faker>:

=head1 METHODS

=head2 country

Returns a single scalar country name (in English) as a Unicode string.

=head2 country_code

Returns a single scalar 2-character ISO-3166 country code as a Unicode string.

=cut

our $VERSION = '0.001';

use parent qw(Data::Faker);

use Locale::Country;

__PACKAGE__->register_plugin(
    country => [ Locale::Country::all_country_names() ],
    country_code => [  Locale::Country::all_country_codes() ],
);

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2019. Licensed under the same terms as Perl itself.

