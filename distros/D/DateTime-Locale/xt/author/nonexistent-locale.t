use strict;
use warnings;
use utf8;

use Test2::V0;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale::Data;
use File::ShareDir qw( dist_dir );

skip_all 'This test requires chmod support'
    if $^O eq 'MSWin32';

my $file
    = File::Spec->catfile( dist_dir('DateTime-Locale'), 'unreadable.pl' );
open my $fh, '>', $file or die $!;
print {$fh} "some content\n" or die $!;
close $fh                    or die $!;

chmod 0000, $file or die $!;

like(
    dies { DateTime::Locale::Data::locale_data('unreadable') },
    qr/No read permission/,
    'got an exception trying to read an unreadable file',
);

done_testing();
