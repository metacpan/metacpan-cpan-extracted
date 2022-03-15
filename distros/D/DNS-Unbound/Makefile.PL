use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;

my $pkgconfig_name = 'libunbound';

my ($cflags, $ldflags, $libdir);

use Config;
use File::Temp;
use File::Spec;
use JSON::PP;

my $ccpath = $ENV{'CC'} || $Config::Config{'cc'};
print "Your C compiler appears to be: $ccpath\n";

if ( eval { require ExtUtils::PkgConfig } ) {
    print "Oh good! You have ExtUtils::PkgConfig. :)\n";

    # These can fail because older libunbound versions (e.g., 1.4.22)
    # didn’t include a pkg-config file.
    $cflags = ExtUtils::PkgConfig->cflags($pkgconfig_name);
    $ldflags = ExtUtils::PkgConfig->libs($pkgconfig_name);
    $libdir = ExtUtils::PkgConfig->libs_only_L($pkgconfig_name);
}
else {
    print "Hmm. You don’t seem to have ExtUtils::PkgConfig.\n";
    print "I’ll try running `pkg-config` directly …\n";

    my $cmd = "pkg-config --cflags $pkgconfig_name";

    $cflags = `$cmd`;
    if ($?) {
        warn "`$cmd` failed (CHILD_ERROR=$?)\n";
    }
    else {
        print "Cool. It looks like pkg-config works.\n";

        $ldflags = `pkg-config --libs $pkgconfig_name`;
        $libdir = `pkg-config --libs-only-L $pkgconfig_name`;
    }

    $_ && chomp for $cflags, $ldflags, $libdir;
}

$libdir =~ s<\A-L><>;

# In case pkg-config didn’t give us anything.
if (!$ldflags) {
    warn "I didn’t find libunbound via pkg-config. :(\n";
    warn "Now I’ll look for libunbound via ExtUtils::Liblist …\n";

    my ($xtralibs, $bsloadlibs, $ldloadlibs, $ld_run_path, $where_ar) = ExtUtils::Liblist->ext('-lunbound', 0, 1);

    if (@$where_ar) {
        print "Libunbound found at: @$where_ar\n";

        my @pieces = File::Spec->splitdir($where_ar->[0]);
        pop @pieces;
        $libdir = File::Spec->catdir(@pieces);

        $ldflags = "-L$libdir -lunbound";

        if (!$cflags) {
            print "Looking for unbound.h …$/";

            require Config;
            my @incdirs = (
                $Config::Config{'usrinc'},
                map { split m<\s+> } (
                    $Config::Config{'incpth'},
                    $Config::Config{'locincpth'},
                ),
            );

            while (@pieces > 1) {
                pop @pieces;
                push @incdirs, File::Spec->catdir(@pieces, "include"),
            }

            my %checked;

            for my $dir (@incdirs) {
                next if !$dir;

                next if $checked{$dir};
                $checked{$dir}++;

                print "Checking $dir …$/";

                if (-s File::Spec->catdir($dir, 'unbound.h')) {
                    print "Found it!$/";
                    $cflags = "-I$dir";
                    last;
                }
                else {
                    print "… nope. :($/";
                }
            }

            if (!$cflags) {
                print "I didn’t find unbound.h, but maybe your compiler can?$/";
            }
        }
    }
    else {

        # Useful for Travis CI. Not sure if it’s relevant in production …

        warn "That didn’t work, either. This doesn’t look good. :-/\n";
        warn "As a last resort, let’s just try compiling with libunbound …\n";

        my ($tfh, $tpath) = File::Temp::tempfile( CLEANUP => 1 );
        print {$tfh} "#include <unbound.h>\nint main() { return 0; }\n";
        close $tfh;

        my $cmd = "$ccpath $cflags -xc -lunbound $tpath";
        print "Trying: `$cmd`\n";

        my $out = `$cmd`;
        if ($?) {
            die "$ccpath failed to use libunbound (CHILD_ERROR=$?): $out";
        }
        else {
            print "Huh, weird … the compiler can use and link libunbound.\n";
            print "Maybe there’s a bug in ExtUtils::Liblist?\n";
            print "Anyway, let’s get on with our business …\n";
        }
    }

    $ldflags ||= '-lunbound';
}

print "CFLAGS: [$cflags]\n";
print "LDFLAGS: [$ldflags]\n";

# There has to be something better …

my (
    $HAS_UB_VERSION,
    $HAS_UB_CANCEL,
    $HAS_UB_CTX_ADD_TA_AUTR,
    $HAS_WHY_BOGUS,
    $HAS_TTL,
    $HAS_UB_CONSTANTS,
);

my @checks = (
    {
        label => 'sanity',
        c => join(
            $/,
            '#include <unbound.h>',
            'int main() {',
            '   struct ub_result myresult;',
            '   (void)(myresult);',
            '   return 0;',
            '}',
        ),
        perl => sub {
            if (!shift) {
                die "libunbound didn’t compile! (CHILD_ERROR=$?)";
            }
        },
    },
    {
        label => 'ub_version()',
        c => join(
            $/,
            '#include <stdio.h>',
            '#include <unbound.h>',
            'int main() {',
            '    fprintf(stdout, "%s", ub_version());',
            '    return 0;',
            '}',
        ),
        perl => sub {
            $HAS_UB_VERSION = shift;
        },
    },
    {
        label => 'ub_result.ttl',
        c => join(
            $/,
            '#include <unbound.h>',
            'int main() {',
            '   struct ub_result myresult;',
            '   myresult.ttl = 0;',
            '   return myresult.ttl;',
            '}',
        ),
        perl => sub {
            $HAS_TTL = shift;
        },
    },
    {
        label => 'UB_* constants',
        c => join(
            $/,
            '#include <unbound.h>',
            'int main() {',
            '   int foo = UB_NOERROR;',
            '   (void)(foo);',
            '   return 0;',
            '}',
        ),
        perl => sub {
            $HAS_UB_CONSTANTS = shift;
        },
    },
    {
        label => 'ub_result.why_bogus',
        c => join(
            $/,
            '#include <unbound.h>',
            '#include <stdio.h>',
            'int main() {',
            '   struct ub_result myresult;',
            '   myresult.why_bogus = "123";',
            '   fprintf(stdout, "%s", myresult.why_bogus);',
            '   return 0;',
            '}',
        ),
        perl => sub {
            $HAS_WHY_BOGUS = shift;
        },
    },
    {
        label => 'ub_cancel()',
        c => join(
            $/,
            '#include <unbound.h>',
            'int main() {',
            '   struct ub_ctx* myctx = ub_ctx_create();',
            '   ub_cancel(myctx, 0);',
            '   return 0;',
            '}',
        ),
        perl => sub {
            $HAS_UB_CANCEL = shift;
        },
    },
    {
        label => 'ub_ctx_add_ta_autr()',
        c => join(
            $/,
            '#include <unbound.h>',
            'int main() {',
            '   struct ub_ctx* myctx = ub_ctx_create();',
            '   ub_ctx_add_ta_autr(myctx, "/faux");',
            '   return 0;',
            '}',
        ),
        perl => sub {
            $HAS_UB_CTX_ADD_TA_AUTR = shift;
        },
    },
);

for my $check (@checks) {
    print "Checking: $check->{label} … $/";

    my $tdir = File::Temp::tempdir( CLEANUP => 1 );
    my $cpath = File::Spec->catdir( $tdir, 'check.c' );
    my $progpath = File::Spec->catdir( $tdir, 'check' );

    open my $wfh, '>', $cpath;
    print {$wfh} $check->{c};
    close $wfh;

    # Some compilers care about order here:
    #   compile flags, compile source, linker flags, then linker source.
    my $cmd = "$ccpath $Config{'ccflags'} $cflags $cpath -o $progpath $Config{ccdlflags} $ldflags";

    print "Compiling test program: `$cmd`\n";
    system($cmd);

    my $success = -s $progpath ? 1 : 0;
    printf "  $check->{label}: %s$/", ($success ? 'yes' : 'no');

    $check->{'perl'}->($success);
}

_generate_includes();

my @extra_makefile_args;
if ($libdir) {
    push @extra_makefile_args, LDDLFLAGS => "-Wl,-rpath,$libdir $Config{lddlflags}",
}

WriteMakefile(
    NAME           => 'DNS::Unbound',
    VERSION_FROM   => 'lib/DNS/Unbound.pm',
    ABSTRACT_FROM  => 'lib/DNS/Unbound.pm',
    AUTHOR         => 'Felipe Gasper (FELIPE)',
    CCFLAGS        => join(
        q< >,
        $Config{'ccflags'},
        $cflags,
        '-Wall',
        '-std=c99',
        "-DHAS_UB_VERSION=$HAS_UB_VERSION",
        "-DHAS_UB_CANCEL=$HAS_UB_CANCEL",
        "-DHAS_UB_CTX_ADD_TA_AUTR=$HAS_UB_CTX_ADD_TA_AUTR",
        "-DHAS_WHY_BOGUS=$HAS_WHY_BOGUS",
        "-DHAS_TTL=$HAS_TTL",
        "-DHAS_UB_CONSTANTS=$HAS_UB_CONSTANTS",
    ),

    @extra_makefile_args,

    LIBS           => [ $ldflags ],
    LICENSE        => 'perl',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/FGasper/p5-DNS-Unbound/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-DNS-Unbound.git',
                web  => 'https://github.com/FGasper/p5-DNS-Unbound',
            },
        },
    },
);

#----------------------------------------------------------------------

sub _generate_includes {
    open my $fh, '<', 'errcodes.jsonc' or die "open: $!";
    my $jsonc = do { local $/; <$fh> };

    my $err_value_ar = JSON::PP->new()->relaxed()->decode($jsonc);

    {
        open my $define_fh, '>', 'errcodes_define.inc';
        print {$define_fh} "#if !HAS_UB_CONSTANTS\n";
        print {$define_fh} "#   define @$_\n" for @$err_value_ar;
        print {$define_fh} "#endif\n";
    }

    {
        my @names = map { $_->[0] } @$err_value_ar;

        my $pkg_gv = qq<gv_stashpv("\$Package", FALSE)>;

        open my $boot_fh, '>', 'errcodes_boot.inc';
        print {$boot_fh} "BOOT:\n";
        print {$boot_fh} qq<    newCONSTSUB( $pkg_gv, "_ERROR_NAMES_STR", newSVpvs("@names") );\n>;
        print {$boot_fh} qq/    newCONSTSUB( $pkg_gv, "$_", newSViv($_) );\n/ for @names;
    }
}
