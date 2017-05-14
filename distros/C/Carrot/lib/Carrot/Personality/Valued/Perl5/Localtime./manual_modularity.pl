package Carrot::Personality::Valued::Perl5::Localtime;
use strict;
use warnings;

*RDX_LOCALTIME_SECOND = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_SECOND;
*RDX_LOCALTIME_MINUTE = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_MINUTE;
*RDX_LOCALTIME_HOUR = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_HOUR;
*RDX_LOCALTIME_DAY_OF_MONTH = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_DAY_OF_MONTH;
*RDX_LOCALTIME_MONTH = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_MONTH;
*RDX_LOCALTIME_YEAR = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_YEAR;
*RDX_LOCALTIME_WEEK_DAY = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_WEEK_DAY;
*RDX_LOCALTIME_YEAR_DAY = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_YEAR_DAY;
*RDX_LOCALTIME_IS_DST = \&Carrot::Modularity::Constant::Global::Result_Indices::Localtime::RDX_LOCALTIME_IS_DST;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(qw(
	::Diversity::Attribute_Type::One_Anonymous::Existing_Reference
	::Diversity::Attribute_Type::Many_Declared::Ordered));
return(1);
