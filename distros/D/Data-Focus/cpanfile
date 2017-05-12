
requires "parent";
requires "Carp";
requires "Exporter";
requires "Scalar::Util";
requires "overload";
requires "Test::More" => "1.00";
requires "Scalar::Util";

on 'test' => sub {
    requires 'Test::More' => "0";
    requires 'Test::Fatal';
    requires 'Exporter';
    requires "Scalar::Util";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
