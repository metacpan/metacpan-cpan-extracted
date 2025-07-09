package Data::CEFACT::Unit;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.15 qw(check_required check_strings);
use Readonly;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @STATUSES => ('D', 'X', decode_utf8('¦'));

our $VERSION = 0.01;

has common_code => (
	is => 'ro',
);

has conversion_factor => (
	is => 'ro',
);

has description => (
	is => 'ro',
);

has level_category => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has status => (
	is => 'ro',
);

has symbol => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'common_code'.
	check_required($self, 'common_code');

	# Check 'level_category'.
	check_required($self, 'level_category');

	# Check 'name'.
	check_required($self, 'name');

	# Check 'status'.
	## Undefined status means valid item.
	check_strings($self, 'status', \@STATUSES);

	return;
}

1;

=pod

=encoding utf8

=head1 NAME

Data::CEFACT::Unit - Data object for CEFACT unit.

=head1 SYNOPSIS

 use Data::CEFACT::Unit;

 my $obj = Data::CEFACT::Unit->new(%params);
 my $common_code = $obj->common_code;
 my $conversion_factor = $obj->conversion_factor;
 my $description = $obj->description;
 my $level_category = $obj->level_category;
 my $name = $obj->name;
 my $status = $obj->status;
 my $symbol = $obj->symbol;

=head1 METHODS

=head2 C<new>

 my $obj = Data::CEFACT::Unit->new(%params);

Constructor.

=over 8

=item * C<common_code>

Common code of unit.

It's required.

Default value is undef.

=item * C<conversion_factor>

Conversion factor of unit.

It's optional.

Default value is undef.

=item * C<description>

Unit description.

It's optional.

Default value is undef.

=item * C<level_category>

Unit level/category.

It's required.

Default value is undef.

=item * C<name>

Unit name.

It's required.

Default value is undef.

=item * C<status>

Unit status,

Possible statuses are undef as valid, 'D' as deprecated, 'X' as invalid and '¦'
as new.

It's optional, default value is valid status.

Default value is undef.

=item * C<symbol>

Unit symbol.

It's optional.

Default value is undef.

=back

Returns instance of object.

=head2 C<common_code>

 my $common_code = $obj->common_code;

Get unit common code.

Returns string.

=head2 C<conversion_factor>

 my $conversion_factor = $obj->conversion_factor;

Get unit conversion factor.

Returns string.

=head2 C<description>

 my $description = $obj->description;

Get unit description.

Returns string.

=head2 C<level_category>

 my $level_category = $obj->level_category;

Get unit level/category.

Returns string.

=head2 C<name>

 my $name = $obj->name;

Get unit name.

Returns string.

=head2 C<status>

 my $status = $obj->status;

Get unit status.

Returns string or undef.

=head2 C<symbol>

 my $symbol = $obj->symbol;

Get unit symbol.

Returns string.

=head1 EXAMPLE

=for comment filename=create_and_print_unit_kilogram.pl

 use strict;
 use warnings;

 use Data::CEFACT::Unit;

 my $obj = Data::CEFACT::Unit->new(
         'common_code' => 'KGM',
         'conversion_factor' => 'kg',
         'description' => 'A unit of mass equal to one thousand grams.',
         'level_category' => 1,
         'name' => 'kilogram',
         'symbol' => 'kg',
 );

 # Print out.
 print 'Name: '.$obj->name."\n";
 print 'Description: '.$obj->description."\n";
 print 'Common code: '.$obj->common_code."\n";
 print 'Status: '.(! defined $obj->status ? 'valid' : $obj->status)."\n";
 print 'Symbol: '.$obj->symbol."\n";
 print 'Level/Category: '.$obj->level_category."\n";
 print 'Conversion factor: '.$obj->conversion_factor."\n";

 # Output:
 # Name: kilogram
 # Description: A unit of mass equal to one thousand grams.
 # Common code: KGM
 # Status: valid
 # Symbol: kg
 # Level/Category: 1
 # Conversion factor: kg

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.
L<Readonly>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-CEFACT-Unit>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
