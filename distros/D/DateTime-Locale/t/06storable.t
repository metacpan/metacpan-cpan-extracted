use strict;
use warnings;

use Test::Requires {
    Storable => '0',
};

use Test::More;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;
use File::Spec;
use File::Temp qw( tempdir );
use IPC::System::Simple qw( capturex );
use Storable;

my $dir = tempdir( CLEANUP => 1 );

{
    my $loc1   = DateTime::Locale->load('en-US');
    my $frozen = Storable::nfreeze($loc1);

    ok(
        length $frozen < 2000,
        'the serialized locale object should not be immense'
    );

    my $loc2 = Storable::thaw($frozen);

    is( $loc2->code, 'en-US', 'thaw frozen locale object' );

    my $loc3 = Storable::dclone($loc1);

    is( $loc3->code, 'en-US', 'dclone object' );

    my $file = File::Spec->catfile( $dir, 'dt-locale.storable' );

    open my $fh, '>', $file or die $!;
    print {$fh} $frozen or die $!;
    close $fh or die $!;
}

{
    my $pl_file   = File::Spec->catfile( $dir, 'storable-test.pl' );
    my $data_file = File::Spec->catfile( $dir, 'dt-locale.storable' );

    # We need to make sure that the object can be thawed in a process that has not
    # yet loaded DateTime::Locale. See
    # https://github.com/houseabsolute/DateTime-Locale/issues/18.
    my $code = <<'EOF';
use strict;
use warnings;

use Storable qw( thaw );

open my $fh, '<', shift or die $!;
my $loc = thaw( do { local $/; <$fh> });
print $loc->code . "\n";
EOF

    open my $fh, '>', $pl_file or die $!;
    print {$fh} $code or die $!;
    close $fh or die $!;

    my $id = capturex( $^X, $pl_file, $data_file );
    chomp $id;
    is(
        $id,
        'en-US',
        'can thaw a DateTime::Locale::FromData object in a process that has not loaded DateTime::Locale yet'
    );
}

done_testing();
