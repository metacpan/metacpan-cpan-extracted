#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile catdir);
use File::Path            qw(mkpath);
use Cwd                   qw(getcwd);
use File::Spec;

# simple core-only check for qrencode in PATH
sub have_in_path {
    my ($prog) = @_;
    for my $dir ( File::Spec->path ) {
        my $full = File::Spec->catfile( $dir, $prog );
        return $full if -x $full;
    }
    return;
}

# Set plans
if ( !have_in_path('qrencode') ) {
    plan skip_all => 'qrencode not available in PATH';
}
else {
    plan tests => 7;    # keep your original count
}

# Start
my $exe   = catfile( 'bin', 'clarid-tools' );
my $inc   = join ' -I', '', @INC;    # prepend -I to each path in @INC
my $value = 'TCGA_AML-HomSap-LIV-NOR-RNA-I10-BSL-B01-05';

# 1) Prepare working dir & CSV
my $work = catdir( 't', 'tmp_qrcode' );
mkpath($work) unless -d $work;
my $csv = catfile( $work, 'in.csv' );
open my $fh, '>', $csv or die $!;
print $fh "clar_id\n$value\n";
close $fh;

# 2) Run the encode command
ok(
    system("$^X $inc $exe qrcode --action=encode --input=$csv --outdir=$work")
      == 0,
    "ran clarid-tools qrcode encode"
);

# 3) Check that the PNG exists and isn’t empty
my $png = catfile( $work, "$value.png" );
ok( -f $png && -s $png, "generated non‑empty file $png" );

# 4) Decode with zbarimg and verify the payload
chomp( my $decoded = `zbarimg --raw "$png" 2>/dev/null` );
is( $decoded, $value, "round‑trip decode yields '$value'" );

# 5) Run the decode with clarid-tools and verify the payload
my $out = catfile( $work, "$value.txt" );
ok( system("$^X $inc $exe qrcode --action=decode --input=$png > $out") == 0,
    "ran clarid-tools qrcode decode" );

$decoded = do {
    open my $fh, '<', $out or die "open: $!";
    local $/ = undef;
    <$fh>;
};
chomp $decoded;
is( $decoded, $value, "clarid-tools decode yields '$value'" );

# 6) Run the decode in directory mode
my $outbis = catfile( $work, "decoded.csv" );
ok(
    system(
        "$^X $inc $exe qrcode --action=decode --input=$work  --outfile=$outbis")
      == 0,
    "ran clarid-tools qrcode decode"
);
$decoded = do {
    open my $fh, '<', $outbis or die "open: $!";
    my $header = <$fh>;    # read & discard header
    local $/ = undef;
    <$fh>;
};
chomp $decoded;
is( $decoded, $value, "clarid-tools decode dir yields '$value'" );

# cleanup
unlink $png;
unlink $csv;
unlink $out;
unlink $outbis;
rmdir $work;

done_testing();

