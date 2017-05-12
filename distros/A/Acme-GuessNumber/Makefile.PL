#! /usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

use vars qw($eummver %sign %license);
$eummver = $ExtUtils::MakeMaker::VERSION;
$eummver =~ s/_//;
# SIGN is only availabe since ExtUtils::MakeMaker 6.18
%sign = qw();
%sign = (SIGN => 1) if $eummver > 6.17;
# LICENSE is only availabe since ExtUtils::MakeMaker 6.30_01
%license = qw();
%license = (LICENSE => "perl") if $eummver > 6.30;

WriteMakefile(
    NAME        => "Acme-GuessNumber",
    VERSION     => "0.04",
    ABSTRACT    => "Automatic number guessing game robot",
    AUTHOR      => "imacat <imacat\@mail.imacat.idv.tw>",
    PREREQ_PM   => { },
    PL_FILES    => { },
    %sign,
    %license,
    
    dist        => {
        COMPRESS    => "gzip -9",
        SUFFIX      => ".gz",
    },
);

__END__
