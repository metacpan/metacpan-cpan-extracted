#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

use Chorus::Frame;
use Chorus::Engine;
use Chorus::Expert;

my $version = $Chorus::Expert::VERSION;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains chorus text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no chorus text");
    }
}

sub module_chorus_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'chorus description'          => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}


TODO: {
  local $TODO = "Need to replace the chorus text";

#  not_in_file_ok(README =>
#    "The README is used..."       => qr/The README is used/,
#    "'version information here'"  => qr/to provide version information/,
#  );

#  not_in_file_ok(Changes =>
#    "placeholder date/time"       => qr(Date/time)
#  );

  module_chorus_ok('lib/Chorus/Expert.pm');
  module_chorus_ok('lib/Chorus/Engine.pm');
  module_chorus_ok('lib/Chorus/Frame.pm');
}

done_testing();
