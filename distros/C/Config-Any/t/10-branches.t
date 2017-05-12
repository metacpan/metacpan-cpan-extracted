use strict;
use warnings;
no warnings 'once';

# use Test::Without::Module qw(YAML YAML::Syck Config::General XML::Simple JSON JSON::Syck Config::Tiny );
use Test::More tests => 9;

use Config::Any;
use Config::Any::YAML;


{
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    Config::Any->load_files();
    like(
        shift @warnings,
        qr/^No files specified!/,
        "load_files expects args"
    );

    Config::Any->load_files( {} );
    like(
        shift @warnings,
        qr/^No files specified!/,
        "load_files expects files"
    );

    Config::Any->load_stems();
    like(
        shift @warnings,
        qr/^No stems specified!/,
        "load_stems expects args"
    );

    Config::Any->load_stems( {} );
    like(
        shift @warnings,
        qr/^No stems specified!/,
        "load_stems expects stems"
    );
}

my @files = glob( "t/supported/conf.*" );
{
    require Config::Any::General;
    local $SIG{ __WARN__ } = sub { }
        if Config::Any::General->is_supported;
    ok( Config::Any->load_files( { files => \@files, use_ext => 0 } ),
        "use_ext 0 works" );
}

my $filter = sub { return };
ok( Config::Any->load_files( { files => \@files, use_ext => 1 } ),
    "use_ext 1 works" );

ok( Config::Any->load_files(
        { files => \@files, use_ext => 1, filter => \&$filter }
    ),
    "filter works"
);
eval {
    Config::Any->load_files(
        {   files   => \@files,
            use_ext => 1,
            filter  => sub { die "reject" }
        }
    );
};
like $@, qr/reject/, "filter breaks";

my @stems = qw(t/supported/conf);
ok( Config::Any->load_stems( { stems => \@stems, use_ext => 1 } ),
    "load_stems with stems works" );
