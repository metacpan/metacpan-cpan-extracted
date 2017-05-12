use strict;
use Test::More;

use_ok $_ for qw(
    Data::Generator::FromDDL
    Data::Generator::FromDDL::Builder
    Data::Generator::FromDDL::Builder::SerialOrder
    Data::Generator::FromDDL::Director
    Data::Generator::FromDDL::RecordSet
    Data::Generator::FromDDL::Formatter
    Data::Generator::FromDDL::CLI
    Data::Generator::FromDDL::Util
);

done_testing;
