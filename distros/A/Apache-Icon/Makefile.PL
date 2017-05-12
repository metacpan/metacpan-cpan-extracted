package Apache::Icon;

use strict;
use Apache::src ();
use ExtUtils::MakeMaker;

my $class = __PACKAGE__;
my $pm = "Icon.pm";
my $src = Apache::src->new;

WriteMakefile(
    'NAME'	=> $class,
    'VERSION_FROM' => $pm, 
    'INC'	=> $src->inc,
    'OBJECT' => 'Icon.o mod_icon.o',
    'TYPEMAPS' => $src->typemaps,
    'macro' => {
	CVSROOT => 'modperl.com:/local/cvs_repository',
    },
#    'DEFINE' => "-g -Wall",
);

sub MY::dist {
    system "pod2text $pm > README";
    shift->MM::dist;
}

sub MY::postamble {
    return <<'EOF';

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) .
	@echo update Icon.pm's VERSION now

EOF
}
