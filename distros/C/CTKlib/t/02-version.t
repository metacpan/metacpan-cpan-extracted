#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-version.t 192 2017-04-28 20:40:38Z minus $
#
#########################################################################
use strict;
use warnings;

use Test::More;
use File::Spec;
use YAML;

use CTK;
#$OPT{debug} = 1;
my $MSWIN = $^O =~ /mswin/i ? 1 : 0;

plan skip_all => "Currently a NO developer test" if -d '.svn' || -d ".git";
plan skip_all => 'Test only for MSWin32' unless $MSWIN;
plan tests => 10;

# Go!

my $c = new CTK;
my $ctk_version = $c->VERSION || '';
ok($ctk_version, "CTK version \"$ctk_version\"");


# Reading my files
my @myinc = @INC;
unshift @myinc, File::Spec->rel2abs('..');
unshift @myinc, File::Spec->rel2abs('../lib');
unshift @myinc, map { File::Spec->rel2abs($_) } @myinc;

# Reading CTK.pm File
my $filectk = _find('CTK.pm');
ok $filectk, "CTK.pm file: \"$filectk\"";
my $ctkcontent = CTK::fload($filectk);
my $vsec;
$vsec = $1 if $ctkcontent =~ /version\:?\s*([0-9.]+)/is;
ok $vsec, "Version from section VERSION";
is $vsec+0, $ctk_version+0, "CTK Version";
#CTK::debug "VSEC: $vsec";

# Reading README File
my $filereadme = _find('README');
ok $filereadme, "README file: \"$filereadme\"";
my $readmecontent = CTK::fload($filereadme);
my $vsecreadme;
$vsecreadme = $1 if $readmecontent =~ /version\:?\s*([0-9.]+)/is;
ok $vsecreadme, "Version from README";
is $vsecreadme+0, $ctk_version+0, "README Version";

# Reading META.yml
my $filemeta = _find('META.yml');
ok $filemeta, "META.yml file: \"$filemeta\"";
my $META = YAML::LoadFile($filemeta);
my $vmeta = '';
if ($META && ref($META) eq 'HASH') {
    foreach my $k (keys %$META) {
        $vmeta = $META->{$k} if $k =~ /^version$/i
    }
}
ok $vmeta, "Version from META.yml";
is $vmeta+0, $ctk_version+0, "META.yml Version";

done_testing();

sub _find {
    my $file = shift || '';
    foreach (@myinc) {
        my $f = CTK::catfile($_,$file);
        if ($_ && (-e $f) && -f _) {
            return $f;
        }
    }
    return '';
}
