BEGIN {
    use Class::Accessor::Fast::GXS;
    local $Class::Accessor::Fast::GXS::GENERATE_TO = "CAFGXS.xs";
    local $Class::Accessor::Fast::GXS::MODULE = "My::CAFGXS";
    require "lib/My/CAFGXS.pm";
};

use inc::Module::Install;
all_from 'lib/My/CAFGXS.pm';
WriteAll;

