#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
    use_ok( 'App::TemplateCMD'                    );
    use_ok( 'App::TemplateCMD::Command'           );
    use_ok( 'App::TemplateCMD::Command::Build'    );
    use_ok( 'App::TemplateCMD::Command::Cat'      );
    use_ok( 'App::TemplateCMD::Command::Conf'     );
    use_ok( 'App::TemplateCMD::Command::Describe' );
    use_ok( 'App::TemplateCMD::Command::Help'     );
    use_ok( 'App::TemplateCMD::Command::List'     );
    use_ok( 'App::TemplateCMD::Command::Print'    );
}

diag( "Testing App::TemplateCMD $App::TemplateCMD::VERSION, Perl $], $^X" );
