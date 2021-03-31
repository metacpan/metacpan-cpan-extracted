requires "Date::Holidays::Super";
requires "DateTime";
requires "Exporter";
requires "base";
requires "constant";
requires "perl" => "5.008";
requires "strict";
requires "utf8";
requires "warnings";

on 'test' => sub {
    requires "ExtUtils::MakeMaker";
    requires "File::Spec::Functions";
    requires "Test::Fatal";
    requires "Test::More";
    requires "Test::Most";
    requires "Test::Time" => "0.07";
    requires "version";

    recommends "CPAN::Meta";
    recommends "CPAN::Meta::Requirements" => "2.120900";
};

on 'configure' => sub {
    requires "ExtUtils::MakeMaker"     => "6.17";
    requires "File::ShareDir::Install" => "0.03";
    requires "Module::Build::Tiny"     => "0.034";
};

on 'develop' => sub {
    requires "Cwd";
    requires "DateTime";
    requires "Dist::Milla";
    requires "Dist::Zilla::Plugin::MetaProvides::Package";
    requires "Dist::Zilla::Plugin::OurPkgVersion";
    requires "Dist::Zilla::Plugin::Test::MinimumVersion";
    requires "File::Spec";
    requires "File::Spec::Functions";
    requires "File::Temp";
    requires "JSON";
    requires "List::MoreUtils";
    requires "LWP::Simple";
    requires "Pod::Coverage::TrustPod";
    requires "Test::CPAN::Meta";
    requires "Test::More";
    requires "Test::Pod"           => "1.41";
    requires "Test::Pod::Coverage" => "1.08";
    requires "Time::Local";
};

