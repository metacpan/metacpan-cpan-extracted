use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Every module has a $VERSION, the distribution's, so a caller can ask
# for the version a module's feature came in, as
# `use DBIx::Squirrel::Tooling v4.0.0 qw(:all)`. minil prepare
# sets $VERSION in every module that declares one, so they stay in step
# as long as each declares one, for its own package, and no other
# package does (roadmap 2026-0049, as Ekorn-Pipeline's 2026-0053, D5).

use File::Find qw(find);
use File::Spec qw();
use DBIx::Squirrel;

my $want = DBIx::Squirrel->VERSION;

# The modules, by their files under the folder DBIx::Squirrel was loaded
# from, as installed or as here: DBIx/Squirrel.pm and those under
# DBIx/Squirrel, not other DBIx modules installed beside it.
my $lib
    = $INC{'DBIx/Squirrel.pm'} =~ s( [\/\\] DBIx [\/\\] Squirrel\.pm \z )()xr;
my @files = ("$lib/DBIx/Squirrel.pm");
find(
    sub { push @files, $File::Find::name if m( \.pm \z )x },
    "$lib/DBIx/Squirrel",
);

# Return the code of a module's file, before its POD.
sub code_of ($path) {
    open my $in, '<', $path or die "Can't read $path: $!";
    local $/ = undef;
    my $text = <$in>;
    close $in;
    return $text =~ s( ^ __END__ $ .* )()xmsr;
}

# Each file's path as require takes it, relative to the folder, with
# / between its parts, on any platform; and the module it holds.
my %relative_of = map {
    $_ => join '/', File::Spec->splitdir(File::Spec->abs2rel($_, $lib))
} @files;
my %module_of
    = map { $_ => $relative_of{$_} =~ s( \.pm \z )()xr =~ s( / )(::)xgr }
    @files;
my %is_module = map { $_ => 1 } values %module_of;

for my $path (sort @files) {
    my $module   = $module_of{$path};
    my $code     = code_of($path);
    my @versions = $code =~ m( ^ \s* our \s+ \$VERSION \b )xmg;
    is scalar @versions, 1, "$module declares one \$VERSION";
    require $relative_of{$path};
    is $module->VERSION, $want, "$module is at the distribution's version";
    # The packages it defines inside, which a $VERSION would stray to.
    for my $inner (grep { !$is_module{$_} }
        $code =~ m( ^ \s* package \s+ ([\w:]+) \s* \{ )xmg)
    {
        is $inner->VERSION, undef, "$inner, inside $module, has none";
    }
}

ok scalar @files >= 18, 'every module was found';

done_testing;
