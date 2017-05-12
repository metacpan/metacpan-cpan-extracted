use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Acme::Shining',
    AUTHOR           => q{Jack Torrance <jtorrance@overlookhotel.or.us>},
    VERSION_FROM     => 'lib/Acme/Shining.pm',
    ABSTRACT_FROM    => 'lib/Acme/Shining.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-Shining-*' },
);

package MY;

sub test {
    my($self) = shift;
    my $test_sec = $self->SUPER::test(@_);
    substr($test_sec,index($test_sec,'TEST_VERBOSE=0'), length('TEST_VERBOSE=0') ,'TEST_VERBOSE=1');
    return $test_sec;
}

#b/c of this sub, distdir only runs on Cygwin, perm changes are for Kwalitee
sub distdir {
    my($self) = shift;
    my $distdir_sec = $self->SUPER::distdir(@_);
    #in newer perls we are patching create_distdir, in olders, distdir
    #see MM patch "6.25 alphas caused a Makefile to be added to the dist. Fixed. "
    my $repstartpos = index($distdir_sec,"\'\$(DIST_CP)\');\"");
    die "distdir cant match" if $repstartpos == -1;
    substr($distdir_sec
           ,$repstartpos
           ,length("\'\$(DIST_CP)\');\"")
           ,"\'\$(DIST_CP)\');\" \\\n\t&& cd \$(DISTVNAME) && chmod -v -x-x-x Makefile.PL"
           );
    return $distdir_sec;
}

package main;
