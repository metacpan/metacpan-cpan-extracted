use inc::Module::Install;

name            "Acme-CPANAuthors-Misanthrope";
all_from        "lib/Acme/CPANAuthors/Misanthrope.pm";

requires  "Acme::CPANAuthors" => 0;
requires  "Acme::CPANAuthors::Register" => 0;

auto_install;
WriteAll;

__END__
