# runs through basic options

use strict;
use warnings;
use v5.10;
use Test::More tests => 14;
use FindBin;
use File::Spec;
use IPC::Run qw(run);
use File::Temp qw(tempdir);

my ( $rv, @files );

$rv = tfind('--help');
ok $rv->{out}, '--help returned something to stdout';

$rv = tfind('--nonexistent-option');
ok !$rv->{out}, '--nonexistent-option sends nothing to stdout';
ok $rv->{err}, '--nonexistent-option sends error to stderr';
like $rv->{err}, qr/Unknown/, 'error says option is unknown';

$rv = tfind( '--perl', 'Test/More.pm' );
ok $rv->{out}, 'returned some results when finding Test::More with --perl';
like $rv->{out}, qr{\bMore\.pm$}, 'found file path ending in More.pm';

$rv = tfind('Test/More.pm');
ok !$rv->{out}, 'cannot find Test/More.pm without --perl option';

my $dir = tempdir;
push @files, $dir;
make_file( '.hidden', 'something' );

$rv = tfind( '//*[@f]', $dir );
ok !$rv->{out}, 'does not find hidden files';

$rv = tfind( '--all', '//*[@f]', $dir );
ok $rv->{out}, 'finds hidden files when --all is specified';

make_file( 'A', 'something else' );

$rv = tfind( '//a', $dir );
ok !$rv->{out}, 'does not find A with //a when case sensitive';
$rv = tfind( '-i', '//a', $dir );
ok $rv->{out}, 'finds A with //a when case insensitive';

make_file( 'b', 'still more' );

$rv = tfind( '-i', '//~a|b~[1]', $dir );
my $rv2 = tfind( '-io', '//~a|b~[1]', $dir );
ok $rv->{out},  'zero-based [1] index found file';
ok $rv2->{out}, 'one-based [1] index found file';
ok $rv->{out} && $rv2->{out} && $rv->{out} ne $rv2->{out},
  'one-based indexation selects different file';

unlink @files;

done_testing();

# captures results of tfind
sub tfind {
    my @args = @_;
    state $base = [
        $^X,
        ( map { '-I' . File::Spec->rel2abs($_) } @INC ),
        File::Spec->catfile( $FindBin::Bin, '..', 'bin', 'tfind' )
    ];
    my @cmd = ( @$base, @args );
    my ( $stdout, $stderr );
    run \@cmd, \undef, \$stdout, \$stderr;
    return { out => $stdout, err => $stderr };
}

sub make_file {
    my ( $name, $text ) = @_;
    my $f = File::Spec->catfile( $dir, $name );
    open my $fh, '>', $f;
    print $fh $text;
    close $fh;
    return $f;
    push @files, $f;
}
