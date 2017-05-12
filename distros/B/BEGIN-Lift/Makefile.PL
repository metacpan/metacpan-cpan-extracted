use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    'NAME'               => 'BEGIN::Lift',
    'VERSION'            => '0.04',
    'DISTNAME'           => 'BEGIN-Lift',
    'ABSTRACT'           => 'Lift subroutine calls into the BEGIN phase',
    'AUTHOR'             => 'Stevan Little',
    'BUILD_REQUIRES'     => {},
    'CONFIGURE_REQUIRES' => {
        'Devel::CallParser'   => '0',
        'ExtUtils::MakeMaker' => '6.30'
    },
    'EXE_FILES'          => [],
    'LICENSE'            => 'perl',
    'NORECURS'           => 1,
    'PREREQ_PM'  => {
        # cpan ....
        'Sub::Name'              => 0,
        'B::CompilerPhase::Hook' => 0,
        'Devel::CallParser'      => 0,
        'XSLoader'               => 0,
        # tests ..
        'Test::More'             => 0,
    },
    'clean'              => { FILES => 'cover_db/ nytprof/ callparser1.h' },
    'test'               => { RECURSIVE_TEST_FILES => 1 },
);

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

use File::Spec::Functions 'abs2rel';
use Devel::CallParser 'callparser1_h', 'callparser_linkable';
open my $fh, '>', 'callparser1.h' or die "Couldn't write to callparser1.h";
$fh->print(callparser1_h);
my @linkable = map { abs2rel($_) } callparser_linkable;
unshift @linkable, '$(BASEEXT)$(OBJ_EXT)' if @linkable;
$WriteMakefileArgs{OBJECT} = join(' ', @linkable) if @linkable;

WriteMakefile(%WriteMakefileArgs);
