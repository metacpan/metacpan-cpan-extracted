#!/usr/bin/perl -w
use ExtUtils::MakeMaker;
unless (-f 'README') {
        require Pod::Text;
        my $parser = Pod::Text->new(sentence => 1, width => 78);
        $parser->parse_from_file('Spider.pm', 'README');
}

WriteMakefile(
    'NAME'		=> 'Acme::Spider',
    'VERSION_FROM'	=> 'Spider.pm',
    'PREREQ_PM'		=> {},
);
