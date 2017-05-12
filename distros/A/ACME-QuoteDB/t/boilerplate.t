#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use File::Basename qw/dirname/;
use File::Spec;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    my $file = File::Spec->catfile((dirname(__FILE__), '..'), $filename);
    open( my $fh, '<', $file )
        or die "couldn't open $file for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$file contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$file contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

not_in_file_ok(README =>
  "The README is used..."       => qr/The README is used/,
  "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
  "placeholder date/time"       => qr(Date/time)
);

module_boilerplate_ok('lib/ACME/QuoteDB.pm');


