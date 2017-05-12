#!/usr/bin/perl

use strict;
use warnings;
use Carp qw/carp croak cluck confess longmess/;
use Test::More;
use Test::Warnings;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or confess "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
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

not_in_file_ok((-f 'README' ? 'README' : 'README.pod') =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

module_boilerplate_ok('lib/Data/Context.pm');
module_boilerplate_ok('lib/Data/Context/Actions.pm');
module_boilerplate_ok('lib/Data/Context/Finder.pm');
module_boilerplate_ok('lib/Data/Context/Finder/File.pm');
module_boilerplate_ok('lib/Data/Context/Instance.pm');
module_boilerplate_ok('lib/Data/Context/Loader.pm');
module_boilerplate_ok('lib/Data/Context/Loader/File.pm');
module_boilerplate_ok('lib/Data/Context/Loader/File/JS.pm');
module_boilerplate_ok('lib/Data/Context/Loader/File/JSON.pm');
module_boilerplate_ok('lib/Data/Context/Loader/File/XML.pm');
module_boilerplate_ok('lib/Data/Context/Loader/File/YAML.pm');
module_boilerplate_ok('lib/Data/Context/Log.pm');
module_boilerplate_ok('lib/Data/Context/Manual.pod');
module_boilerplate_ok('lib/Data/Context/Util.pm');
done_testing();
