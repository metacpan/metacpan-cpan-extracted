use 5.006002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'AI::NeuralNet::FastSOM',
    VERSION_FROM  => 'lib/AI/NeuralNet/FastSOM.pm',
    ABSTRACT_FROM => 'lib/AI/NeuralNet/FastSOM.pm',
    AUTHOR        => 'Rick Myers <jrm@cpan.org>',
    LICENSE       => 'perl',
    PREREQ_PM     => { Storable => 0 },
    TYPEMAPS      => [ $] < 5.008000 ? 'typemap.v1' : 'typemap.v2' ],
    test          => { TESTS => 't/*.t t/orig/*.t' },
    clean         => { FILES => 't/*.bin typemap' },
);

#
# everything below is a work-around for some sort of bug in ExtUtils::ParseXS
# not picking up typemap files unless named "typemap" in perl5.6.2
#
# note however that the TYPEMAPS entry above is still needed for 5.6.2's still
# using the old xsubpp
#

package MY;

sub xs_c {
    my $t = shift->SUPER::xs_c(@_);
    $t =~ s/:/:\n	\$(MAKE) typemap/;
    $t;
}

sub test {
    my $t = shift->SUPER::test(@_);
    $t =~ s/(PERL_DL_NONLAZY=)/HARNESS_OPTIONS=j1 $1/g;
    $t;
}

sub postamble {
    my $out = <<'README';
readme:
	pod2text lib/AI/NeuralNet/FastSOM.pm README
	perl -i -pe's{\\*(\\S+)\\*}{\\1}g' README

README

    if ( $] < 5.008000 ) {
        $out .= <<'EOP';
typemap:
	$(CP) typemap.v1 typemap
EOP
    }

    else {
        $out .= <<'EOP';
typemap:
	$(CP) typemap.v2 typemap
EOP
    }

    return $out;
}

exit 0;

