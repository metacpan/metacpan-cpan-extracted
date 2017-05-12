#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use File::Spec::Functions qw(:ALL);

BEGIN { use_ok('Audio::FLAC::Header') };

#########################

{
        # Always test pure perl
        my @constructors = ('_new_PP');

        # Only test XS if built
        SKIP: {
                eval { Audio::FLAC::Header->_new_XS(catdir('data', 'md5.flac')) };
                skip "Not built with XS", 1 if $@;

                push @constructors, '_new_XS';
        }

        # Be sure to test both code paths.
        for my $constructor (@constructors) {

		my $flac = Audio::FLAC::Header->$constructor(catdir('data', 'md5.flac'));

		my $info = $flac->info();
		ok($flac->info('MD5CHECKSUM') eq '00428198e1ae27ad16754f75ff068752', "md5");
       }

}

__END__
