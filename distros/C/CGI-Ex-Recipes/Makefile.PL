use strict;
use warnings;
use lib qw( erecipes/perl/lib );
use ExtUtils::MakeMaker;
use Cwd;
$main::RECIPES_LIB = 'erecipes/perl/lib';
$main::RECIPES_PREFIX = ExtUtils::MakeMaker::prompt(
    hello()
    .'Where the example application should be installed?',
    "$ENV{HOME}/recipes"
);

WriteMakefile(
    NAME                => 'CGI::Ex::Recipes',
    AUTHOR              => 'Красимир Беров <k.berov@gmail.org>',
    VERSION_FROM        => 'erecipes/perl/lib/CGI/Ex/Recipes.pm',
    ABSTRACT_FROM       => 'erecipes/perl/lib/CGI/Ex/Recipes.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'CGI::Ex'       => '2.18',
        'DBI'           => 0,
        'DBD::SQLite'   => 0,
        'SQL::Abstract' => 0,
        'YAML'          => '0.65',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Ex-Recipes-*' },
    test				=> {TESTS => 'erecipes/perl/t/*.t'}
);

sub hello {
<<HELLO;

CGI-Ex-Recipes - A usage example for CGI::Ex::App!

This small but relatively complete application was inspired 
by the examples, given by Paul in his documentation. 
You are encouraged to play with it or/and use it as a starting point  
for far more complex and customized applications.

INSTALLATION
Just place 'erecipes' into some viewable 
by the server dir with option 'AllowOverride All'.
Fire up the server and point the browser to
http:yourhost/your/destination/path/index.cgi.

NOTE
At any later time you can also run:
perl erecipes/install.pl src=erecipes dest=/your/destination/path

HELLO
}
#------------------------------------------------------------------------ 
# build options and write Makefile
#------------------------------------------------------------------------
package MY;

sub postamble {
 my $amble =<<'EOF';
recipes_install ::
	@$(PERL)  -I$(RECIPES_LIB) erecipes/install.pl src=erecipes dest=$(RECIPES_PREFIX)
EOF

    return $amble;
}

sub install {
    my $class = shift;
    my $basic = $class->SUPER::install(@_);
    #add this target to the default 'make install'
    my $add = 'recipes_install';
    $basic =~ s/^(install\s+::\s+.*)$/$1 $add/m;
    $basic;
}

sub constants {
    my $class = shift;
    my $basic = $class->SUPER::constants(@_);
    #Add some needed constants to the Makefile
    $basic = "RECIPES_LIB = $main::RECIPES_LIB\n"
        ."RECIPES_PREFIX = $main::RECIPES_PREFIX\n$basic"
	if $main::RECIPES_PREFIX;#this is dummy paste :DDD
    $basic;
}
