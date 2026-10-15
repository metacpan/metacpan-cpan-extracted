use v5.40;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../builder";
use File::Spec;
use Path::Tiny qw[path];
use Alien::Xmake::Builder;
#
chdir "$FindBin::Bin/.." or die "chdir to dist root: $!";
my $builder = Alien::Xmake::Builder->new;
my $name    = $builder->meta->name;
is $name, 'Alien-Xmake', 'dist name';

# Windows bundle layout: the binary lands at the root of share/.
my $windows = $builder->_generate_share_config( path('share')->absolute->child('xmake.exe'), 'v3.1.1' );
is $windows->{install_type}, 'share',                                 'Windows: install_type is share';
is $windows->{version},      'v3.1.1',                                'Windows: version is passed through';
is $windows->{bin},          "../../auto/share/dist/$name/xmake.exe", 'Windows: bin is relative to the ConfigData module';

# Unix `make install` layout: the binary lands in share/bin/.
my $unix = $builder->_generate_share_config( path('share')->absolute->child( 'bin', 'xmake' ), 'v3.1.1' );
is $unix->{install_type}, 'share',                                 'Unix: install_type is share';
is $unix->{version},      'v3.1.1',                                'Unix: version is passed through';
is $unix->{bin},          "../../auto/share/dist/$name/bin/xmake", 'Unix: bin is relative to the ConfigData module';
my $config_dir = path('blib/lib/Alien/Xmake')->absolute->stringify;

# Whatever the platform, the stored value must resolve, from the ConfigData module's own directory, to a path inside the dist sharedir not somewhere above the library tree.
for my $case ( [ Windows => $windows ], [ Unix => $unix ] ) {
    my ( $label, $cfg ) = @$case;
    my $resolved = File::Spec->rel2abs( $cfg->{bin}, $config_dir );
    my $sep      = qr{[/\\]};
    like $resolved,   qr{auto${sep}share${sep}dist${sep}\Q$name\E}, "$label: resolves inside auto/share/dist";
    unlike $resolved, qr{\.\.[/\\]\.\.[/\\]\.\.[/\\]\.\.},          "$label: does not escape four levels up";
}

# On the current platform the staged copy should be present after a build; when it is, the stored path must resolve to exactly that file.
my ($staged_rel) = $^O eq 'MSWin32' ? ('xmake.exe') : ('bin/xmake');
my ($current)    = $^O eq 'MSWin32' ? ($windows)    : ($unix);
my $staged       = "blib/lib/auto/share/dist/$name";
SKIP: {
    skip 'staged sharedir not present (run ./Build build first)', 1 unless -e "$staged/$staged_rel";
    my $resolved = File::Spec->rel2abs( $current->{bin}, $config_dir );
    is path($resolved)->realpath->stringify, path("$staged/$staged_rel")->realpath->stringify, 'resolves to the staged binary';
}
#
done_testing;
