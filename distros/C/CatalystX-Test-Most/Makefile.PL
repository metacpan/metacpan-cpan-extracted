use inc::Module::Install;

name "CatalystX-Test-Most";
all_from "lib/CatalystX/Test/Most.pm";
repository "git://github.com/pangyre/p5-catalystx-test-most";

requires "Catalyst" => 5.8;
requires "Catalyst::Action::RenderView" => undef;
requires "Catalyst::Test" => undef;
requires "Test::WWW::Mechanize::Catalyst" => undef;
requires "Test::More" => undef;
requires "HTTP::Request::Common" => undef;
requires "Test::Exception" => undef;
requires "strictures" => undef;

system("pod2text lib/CatalystX/Test/Most.pm > README") == 0
    or die "Couldn't update the README file"
    if $Module::Install::AUTHOR;

auto_install;
WriteAll;
