use Test::More;
use Module::Load;
use File::Basename;
use File::Spec;

use Alien::UDUNITS2;
use Test::Number::Delta;

SKIP: {
	eval { load 'Inline::C' } or do {
		my $error = $@;
		skip "Inline::C not installed", 1 if $error;
	};

	plan tests => 1;


	Inline->import( with => qw(Alien::UDUNITS2) );
	Inline->bind( C => q{
		double convert_inch_to_metre(const char* path_to_xml, double inch_value) {

			ut_system* sys = ut_read_xml(path_to_xml);

			ut_unit* from_in_unit = ut_get_unit_by_name(sys, "inch" );
			ut_unit* to_m_unit    = ut_get_unit_by_name(sys, "metre");

			cv_converter* converter = ut_get_converter(from_in_unit, to_m_unit);

			double m_value = cv_convert_double(converter, inch_value);

			cv_free(converter);
			ut_free_system(sys);

			return m_value;
		}
	},
		ENABLE => AUTOWRAP => @inc_built );
	my $built_unitsdb = Alien::UDUNITS2->new->units_xml;

	# 100 inches is 2.54 metres
	my $eps = 1e-10;
	delta_within( convert_inch_to_metre($built_unitsdb, 100), 2.54, $eps, 'covert 100 inches to metres');
}

done_testing;
