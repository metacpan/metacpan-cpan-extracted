use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use File::Temp qw[tempdir];
use Path::Tiny;
use Alien::Xrepo::MB;
my $dir = tempdir( CLEANUP => 1 );

sub make_mini_dist {
    my $root = path($dir)->child('Exotic-Foo');
    $root->child( 'lib', 'Exotic' )->mkpath;
    $root->child('Build.PL')->spew_utf8("use Alien::Xrepo::MB;\n");
    $root->child( 'lib', 'Exotic', 'Foo.pm' )->spew_utf8(<<'PM');
use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
class Exotic::Foo : isa(Alien::Xrepo::Runtime) {
    method recipe { return { name => 'Exotic-Foo', packages => ['zstd'] }; }
}
1;
PM
    return $root;
}

sub make_builder {
    my (%args) = @_;
    return Alien::Xrepo::MB->new(
        module_name   => 'Exotic::Foo',
        base_dir      => $args{root}->stringify,
        build_dir     => $args{root}->child('_b')->stringify,
        dist_abstract => 'x',
        dist_version  => 'v1.0.0',
        license       => 'artistic_2',
        ( defined $args{snapshot} ? ( xrepo_snapshot => $args{snapshot} ) : () ),
    );
}
subtest 'loads as a Module::Build subclass' => sub {
    my $b = Alien::Xrepo::MB->new( module_name => 'Exotic::Foo', base_dir => $dir, build_dir => $dir, dist_version => 'v1.0.0' );
    isa_ok $b, ['Module::Build'], 'isa Module::Build';
    is $b->xrepo_cache,     0,     'xrepo_cache defaults to 0';
    is $b->xrepo_snapshot,  undef, 'xrepo_snapshot defaults to undef (auto-derive)';
    is $b->xrepo_share_dir, undef, 'xrepo_share_dir defaults to undef (snapshot parent)';
};
subtest 'snapshot path derives from the module tail' => sub {
    my $root = make_mini_dist();
    my $b    = make_builder( root => $root );
    is $b->_xrepo_snapshot, path($root)->child( 'blib', 'lib', 'auto', 'share', 'dist', 'Exotic-Foo', 'xrepo-snapshot.json' )->stringify,
        'Exotic::Foo -> Exotic-Foo share dir';
};
subtest 'dist_name is module_name with :: -> -, nothing invented' => sub {
    use Alien::Xrepo::Build::Dist;
    my $d = sub { Alien::Xrepo::Build::Dist->new( module_name => $_[0] )->dist_name };
    is $d->('Alien::Foo'),                'Alien-Foo',              'Alien::Foo -> Alien-Foo';
    is $d->('Exotic::Zlib'),              'Exotic-Zlib',            'Exotic::Zlib -> Exotic-Zlib';
    is $d->('Sanko::Thing'),              'Sanko-Thing',            'Sanko::Thing -> Sanko-Thing';
    is $d->('Alien::Xrepo::Build::Dist'), 'Alien-Xrepo-Build-Dist', 'deep namespaces hyphenate fully';
};
subtest 'staleness keys on the dist recipe inputs and engine modules' => sub {
    my $root  = make_mini_dist();
    my $b     = make_builder( root => $root );
    my @input = $b->_xrepo_inputs;
    like join( ' ', @input ), qr/Build\.PL/,                            'Build.PL is an input';
    like join( ' ', @input ), qr/Foo\.pm/,                              'module file is an input';
    like join( ' ', @input ), qr/Alien[\\\/]Xrepo[\\\/](MB|Build)\.pm/, 'engine modules are inputs';
    my $snap = path( $b->_xrepo_snapshot );
    ok $b->_snapshot_stale($snap), 'stale when the snapshot is missing';
    $snap->parent->mkpath;
    $snap->spew_utf8('{}');
    my $t = time;
    utime( $t + 100, $t + 100, $snap );
    ok !$b->_snapshot_stale($snap), 'fresh when newer than the inputs';
};
subtest '_recipe loads lib/<class>.pm and forwards recipe()' => sub {
    my $root = make_mini_dist();
    my $b    = make_builder( root => $root );
    is $b->_recipe, { name => 'Exotic-Foo', packages => ['zstd'] }, 'recipe hashref from the class';
};
done_testing;
