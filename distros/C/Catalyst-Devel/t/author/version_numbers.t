use strict;
use warnings;

use FindBin qw/$Bin/;
use File::Spec;
use File::Find::Rule;
use Module::Info;

use Test::More;

my %versions;
for my $pm_file ( File::Find::Rule->file->name( qr/\.pm$/ )->in(File::Spec->catdir($Bin, '..', '..', 'lib') ) ) {
    my $mod = Module::Info->new_from_file($pm_file);

    ( my $stripped_file = $pm_file ) =~ s{.*lib/}{};

    $versions{$stripped_file} = $mod->version;
}

my $ver = delete $versions{'Catalyst/Devel.pm'};
ok $ver;
ok scalar(keys %versions);

for my $module ( sort keys %versions ) {
    next unless $versions{$module};

    is( $versions{$module}, $ver,
        "version for $module is the same as in Catalyst/Devel.pm" );
}

done_testing;

