use strict;
use warnings;
use Test::More;

BEGIN {
    # Remove all relevant env variables to avoid accidental fail
    foreach my $name ( grep { m{^(CATALYST)} } keys %ENV ) {
        delete $ENV{ $name };
    }
}

{
    package QX;
    use strict;
    use warnings;

    use base 'Catalyst::Plugin::ConfigLoader';

    sub config { {} }
    sub path_to { shift; '/home/foo/QX-0.9.5/' . shift; }
}

my $app = bless {}, 'QX';
my ($path, $extension) = $app->get_config_path;
is $path, '/home/foo/QX-0.9.5/qx';
is $extension, undef;

done_testing;

