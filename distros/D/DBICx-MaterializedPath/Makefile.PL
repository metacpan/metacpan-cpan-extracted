use inc::Module::Install;

name "DBICx-MaterializedPath";
all_from "lib/DBICx/MaterializedPath.pm";
author 'Ashley Pond V <ashley@cpan.org>';

requires "parent" => "0.2";
requires "DBIx::Class" => "0.081";

build_requires "Test::More" => "0.42";
build_requires "DBICx::TestDatabase";

if ( $Module::Install::AUTHOR )
{
    system("pod2text lib/DBICx/MaterializedPath.pm > README") == 0
        or die "Couldn't update the README file";
}

auto_install;
repository 'http://github.com/pangyre/p5-dbicx-materializedpath';
WriteAll;

__END__
