#!/usr/bin/env perl
use inc::Module::Install;

name "Acme-Pi-Abrahamic";
all_from "lib/Acme/Pi/Abrahamic.pm";
repository "git://github.com/pangyre/p5-acme-pi-abrahamic-";

if ( $Module::Install::AUTHOR )
{
    system("pod2text lib/Acme/Pi/Abrahamic.pm > README") == 0
        or die "Couldn't update the README file";
}

auto_install;

WriteAll;

__END__
