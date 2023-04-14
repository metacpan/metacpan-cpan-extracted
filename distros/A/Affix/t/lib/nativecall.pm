package t::lib::nativecall {
    use strict;
    use warnings;
    use Test::More;
    use experimental 'signatures';
    use Path::Tiny;
    use Exporter 'import';
    our @EXPORT = qw[compile_test_lib compile_cpp_test_lib is_approx];
    use Config;
    #
    my $OS = $^O;
    my @cleanup;
    #
    #~ diag $Config{cc};
    #~ diag $Config{cccdlflags};
    #~ diag $Config{ccdlflags};
    #~ diag $Config{ccflags};
    #~ diag $Config{ccname};
    #~ diag $Config{ccsymbols};
    #
    sub compile_test_lib ( $name, $aggs = '' ) {
        my $c_file = path( grep { -f $_ } "t/src/$name.cxx", "t/src/$name.c" )->canonpath;
        my $o_file = path( "t/src/$name" . $Config{_o} )->canonpath;
        my $l_file = path( "t/src/$name." . $Config{so} )->canonpath;
        diag sprintf 'Building %s into %s', $c_file, $l_file;
        my @cmds = (
            $Config{cc} . " -Wall --shared -fPIC -DBUILD_LIB $aggs -o $l_file $c_file",

            #~ (
            #~ $OS eq 'MSWin32' ? "cl /LD /EHsc /Fe$l_file $c_file" :
            #~ "clang -stdlib=libc --shared -fPIC -o $l_file $c_file"
            #~ )
        );
        my ( @fails, $succeeded );
        my $ok;
        for my $cmd (@cmds) {
            diag $cmd;
            system $cmd;
            if ( $? == -1 ) {
                diag 'failed to execute: ' . $!;
            }
            elsif ( $? & 127 ) {
                diag sprintf "child died with signal %d, %s coredump\n", ( $? & 127 ),
                    ( $? & 128 ) ? 'with' : 'without';
            }
            else {
                # diag 'child exited with value ' . ( $? >> 8 );
                $ok++;
                last;
            }
        }
        plan skip_all => 'Failed to build test lib' if !-f $l_file;
        push @cleanup, $o_file, $l_file;
        $l_file;
    }

    END {
        for my $file ( grep {-f} @cleanup ) {
            diag 'Removing ' . $file;
            unlink $file;
        }
    }

    sub is_approx ( $actual, $expected, $desc ) {    # https://docs.raku.org/routine/is-approx
        ok abs( $actual - $expected ) < 1e-6, $desc;
    }
};
1;
