require 5.6.0;

use strict;
use ExtUtils::MakeMaker;

my $params = {
    NAME          => 'DNS::ZoneEdit',
    ABSTRACT      => 'Update your ZoneEdit dynamic DNS records',
    AUTHOR        => 'Evan Giles <egiles@cpan.org>',
    LICENSE       => 'perl',
    PREREQ_PM     => { 'LWP::UserAgent' => 2.001 },
    VERSION_FROM  => 'lib/DNS/ZoneEdit.pm',
    dist          => { COMPRESS=>'gzip', SUFFIX=>'gz' },
    clean         => { FILES=>'DNS-ZoneEdit-*' },
};

if ( $ExtUtils::MakeMaker::VERSION gt "6.46" ) {
  my $url = 'git://github.com/egiles/dns-zoneedit.git';
  $params->{META_MERGE} = { resources => { repository  => $url } };
}

WriteMakefile(%$params);
