use strict;
use warnings;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );

my %config = (
    NAME          => 'Acme::LAUTER::DEUTSCHER',
    AUTHOR        => 'Ian Langworth <ian@cpan.org>',
    VERSION_FROM  => 'lib/Acme/LAUTER/DEUTSCHER.pm',
    ABSTRACT_FROM => 'lib/Acme/LAUTER/DEUTSCHER.pm',
    PREREQ_PM     => {
        'Test::More'        => '0.54',
        'Lingua::Translate' => '0.08',
        'PerlIO::via'       => '0.02',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Acme-LAUTER-DEUTSCHER-*' },
);

my @patterns = qw( t/*.t );

my $answer = prompt(
    "Some tests require a network connection.\n"
        . "Would you like to run these tests?",
    'y'
);

if ( $answer =~ m/^y/i ) {
    print "I'm going to run the network tests.\n";
    push @patterns, 't/NETZ/*.t';
}
else {
    print "Skipping network tests.\n";
}

$config{test} = { TESTS => join ' ', map {glob} @patterns };

WriteMakefile(%config);

