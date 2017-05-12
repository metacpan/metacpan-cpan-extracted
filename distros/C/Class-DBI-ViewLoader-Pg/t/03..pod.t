use strict;
use warnings;

our @modules;
BEGIN {
    @modules = qw(
        Class::DBI::ViewLoader::Pg
    );
}

use File::Spec::Functions qw( catfile );

use Test::More tests => @modules * 2;

SKIP: {
    eval {
        require Test::Pod;
        import Test::Pod;
    };

    skip "Test::Pod not installed", scalar @modules if $@;

    for my $module (@modules) {
        my @path = ('lib', split('::', $module));
        $path[-1] .= '.pm';
        
        pod_file_ok(catfile(@path), "$module pod ok");
    }
}

SKIP: {
    eval {
        require Test::Pod::Coverage;
        import Test::Pod::Coverage;
    };

    skip "Test::Pod::Coverage not installed", scalar @modules if $@;

    for my $module (@modules) {
        pod_coverage_ok(
            $module,
            "$module pod coverage ok"
        );
    }
}

__END__

vim: ft=perl
