#!/usr/bin/perl

use File::Spec;

my $image_dir = File::Spec->catdir('images');

open(my $fh, ">lib/Catalyst/Helper/Graphics/Files.pm");
print $fh qq|package #\n\tCatalyst::Helper::Graphics::Files;

1;

__DATA__

|;

opendir(my $dir, $image_dir);
foreach my $file ( readdir($dir) ) {
    next if $file =~ /^\./;
    open(my $image_fh, "$image_dir/$file")
        or die "Can't open $image_dir/$file: $!\n";
    my $image = unpack "H*", join('', <$image_fh>);
    close($image_fh);

    print $fh qq|__${file}__
$image
|;

}

close($fh);
