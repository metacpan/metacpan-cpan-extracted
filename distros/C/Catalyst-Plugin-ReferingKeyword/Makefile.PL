use inc::Module::Install;

name            "Catalyst-Plugin-ReferingKeyword";
all_from        "lib/Catalyst/Plugin/ReferingKeyword.pm";

build_requires  "Class::Accessor::Fast" => 0;
build_requires  "Test::More"            => "0.42";
build_requires  "Catalyst::Runtime"     => "5.7";
build_requires  "URI"                   => 0;
build_requires  "URI::QueryParam"       => 0;

auto_install;
WriteAll;

__END__

