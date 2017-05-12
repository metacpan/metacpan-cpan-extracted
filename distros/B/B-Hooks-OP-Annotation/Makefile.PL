use 5.008000;

use strict;
use warnings;

use Config;
use ExtUtils::Depends;
use ExtUtils::MakeMaker;

our $OPTIMIZE;

if ($Config{gccversion}) {
    $OPTIMIZE = '-O3 -Wall -W';
    $OPTIMIZE .= ' -g -Wdeclaration-after-statement' if (-d 'dev');
} elsif ($Config{osname} eq 'MSWin32') {
    $OPTIMIZE = '-O2 -W4';
} else {
    $OPTIMIZE = $Config{optimize};
}

my $package = ExtUtils::Depends->new('B::Hooks::OP::Annotation');

$package->install('hook_op_annotation.h');
$package->add_xs('Annotation.xs');
$package->add_pm('lib/B/Hooks/OP/Annotation.pm' => '$(INST_LIB)/B/Hooks/OP/Annotation.pm');
$package->save_config('Files.pm');

our %MAKEFILE_VARS = $package->get_makefile_vars();

my $clean = $MAKEFILE_VARS{clean};

$clean->{FILES} .= ' Files.pm' if ($clean);

WriteMakefile(
    NAME          => 'B::Hooks::OP::Annotation',
    VERSION_FROM  => 'lib/B/Hooks/OP/Annotation.pm',
    PREREQ_PM     => { 'ExtUtils::Depends' => '0.304' },
    ABSTRACT_FROM => 'lib/B/Hooks/OP/Annotation.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    FUNCLIST => [
        qw(
          op_annotate
          op_annotation_new
          op_annotation_get
          op_annotation_delete
          op_annotation_group_new
          op_annotation_group_free
        )
    ],
    DL_FUNCS => { 'B::Hooks::OP::Annotation' => [] },
    OPTIMIZE => $OPTIMIZE,
    (eval($ExtUtils::MakeMaker::VERSION) >= 6.31 ? (LICENSE => 'perl') : ()),
    (eval($ExtUtils::MakeMaker::VERSION) >= 6.46 ?
        (META_MERGE => {
            configure_requires => { 'ExtUtils::Depends' => '0.304' },
            resources          => { repository => 'http://github.com/chocolateboy/B-Hooks-OP-Annotation' },
        }) :
        ()
    ),
    %MAKEFILE_VARS
);
