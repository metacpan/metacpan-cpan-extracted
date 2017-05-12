use strict;
use warnings;
use App::EUMM::Upgrade qw/convert_url_to_public convert_url_to_web/;
use Test::More 0.88;

is(convert_url_to_public('https://chorny@bitbucket.org/shlomif/fc-solve.git'), 'https://bitbucket.org/shlomif/fc-solve.git');

is(convert_url_to_web('git://github.com/aanari/MooseX-Modern.git'), 'https://github.com/aanari/MooseX-Modern');
is(convert_url_to_web('https://github.com/aanari/MooseX-Modern.git'), 'https://github.com/aanari/MooseX-Modern');
is(convert_url_to_web('http://bitbucket.org/kzys/test-apache2'), 'https://bitbucket.org/kzys/test-apache2');
is(convert_url_to_web('https://bitbucket.org/shlomif/perl-error.pm'), 'https://bitbucket.org/shlomif/perl-error.pm');
is(convert_url_to_web('https://bitbucket.org/shlomif/fc-solve.git'), 'https://bitbucket.org/shlomif/fc-solve');


#ssh://hg@bitbucket.org/shlomif/perl-App-ManiacDownloader
#https://chorny@bitbucket.org/shlomif/fc-solve.git

#is(convert_url_to_web(''), '');

done_testing;
