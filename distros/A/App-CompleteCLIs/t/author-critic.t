#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/CompleteCLIs.pm','script/complete-acme-metasyntactic-meta-category','script/complete-acme-metasyntactic-meta-theme','script/complete-acme-metasyntactic-meta-theme-and-category','script/complete-array-elem','script/complete-chrome-profile-name','script/complete-country-code','script/complete-currency-code','script/complete-cwalitee-indicator','script/complete-dist','script/complete-dzil-bundle','script/complete-dzil-plugin','script/complete-dzil-role','script/complete-env','script/complete-env-elem','script/complete-file','script/complete-firefox-profile-name','script/complete-float','script/complete-gid','script/complete-group','script/complete-hash-key','script/complete-int','script/complete-kernel','script/complete-known-host','script/complete-known-mac','script/complete-language-code','script/complete-locale','script/complete-manpage','script/complete-manpage-section','script/complete-module','script/complete-path-env-elem','script/complete-perl-builtin-function','script/complete-perl-builtin-symbol','script/complete-perl-version','script/complete-perlmv-scriptlet','script/complete-pid','script/complete-pod','script/complete-ppr-subpattern','script/complete-proc-name','script/complete-program','script/complete-regexp-pattern-module','script/complete-regexp-pattern-pattern','script/complete-riap-url','script/complete-riap-url-clientless','script/complete-service-name','script/complete-service-port','script/complete-tz-name','script/complete-tz-offset','script/complete-uid','script/complete-user','script/complete-vivaldi-profile-name','script/complete-weaver-bundle','script/complete-weaver-plugin','script/complete-weaver-role','script/complete-weaver-section'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
