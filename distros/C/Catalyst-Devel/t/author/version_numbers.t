use strict;
use warnings;

use FindBin qw/$Bin/;
use File::Spec;
use File::Find ();
use ExtUtils::MakeMaker ();

use File::Find::Rule;
use Module::Info;

use Test::More;

my %versions;
File::Find::find({
    no_chdir => 1,
    wanted => sub {
        return
            if -d;
        return
            if !/\.pm\z/;

        my $version = MM->parse_version($_);
        $version = undef
            if $version && $version eq 'undef';

        ( my $stripped_file = $_ ) =~ s{.*lib/}{};

        $versions{$stripped_file} = $version;
    },
}, File::Spec->catdir($Bin, '..', '..', 'lib'));

my $ver = delete $versions{'Catalyst/Devel.pm'};
ok $ver;
ok scalar(keys %versions);

for my $module ( sort keys %versions ) {
    next unless $versions{$module};

    is( $versions{$module}, $ver,
        "version for $module is the same as in Catalyst/Devel.pm" );
}

done_testing;

