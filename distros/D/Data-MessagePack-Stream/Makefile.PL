use strict;
use warnings;

BEGIN {
    my @devmods = qw(
        Module::Install::AuthorTests
        Module::Install::ReadmeFromPod
        Module::Install::Repository
        Module::Install::XSUtil
    );
    my @not_available;

    eval qq{use inc::Module::Install; 1;} or push @not_available, 'inc::Module::Install';
    for my $mod (@devmods) {
        eval qq{require $mod} or push @not_available, $mod;
    }
    if (@not_available) {
        print qq{# The following modules are not available.\n};
        print qq{# `$^X $0 | cpanm` will install them:\n};
        print $_, "\n" for @not_available;
        print "\n";
        exit -1;
    }
}

use inc::Module::Install;

name 'Data-MessagePack-Stream';
all_from 'lib/Data/MessagePack/Stream.pm';

use_ppport 3.19;
cc_src_paths 'src';
cc_include_paths 'msgpack-1.4.2/include';
cc_warnings;

test_requires 'Data::MessagePack';

my ($amd64) = qx{ $^X -V } =~ /(amd64|x86_64)/i;
my $opt = '--disable-shared';
$opt .= ' --with-pic' if $amd64;

makemaker_args->{MYEXTLIB} = 'msgpack-1.4.2/src/.libs/libmsgpackc$(LIB_EXT)';

{
    package MY;
    sub postamble {
        <<"__EOF__";
\$(MYEXTLIB):
	cd msgpack-1.4.2 && ./configure $opt && \$(MAKE)

__EOF__
    }
}

readme_from 'lib/Data/MessagePack/Stream.pm';
author_tests 'xt';
auto_set_repository;

WriteAll;
