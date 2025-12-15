package Test2::Tools::Affix v0.12.0 {
    use v5.40;
    use blib;
    use Affix;
    use Test2::API qw[context run_subtest];
    use Test2::V0 -no_srand => 1, '!subtest';
    use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
    use Test2::Plugin::UTF8;
    use Test2::IPC;
    use Path::Tiny qw[path tempfile];
    use Exporter 'import';
    use Capture::Tiny ':all';
    our @CARP_NOT;
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT
                = qw[
                compile_ok affix_ok leaks
                plan todo skip skip_all done_testing diag note
                subtest ok isa_ok skip_all is isnt like
                pass
                lives dies try_ok warns warning
                U D T F DNE array string float number bool hash etc end
                refcount
                can_ok isa_ok
                capture imported_ok warns]
        ]
    );
    #
    my $OS  = $^O;
    my $Inc = path($0)->absolute;
    $Inc = $Inc->parent while !$Inc->child('t')->is_dir;
    $Inc = $Inc->child( 't', 'src' );
    my @cleanup;

    END {
        for my $file ( grep {-f} @cleanup ) {
            unlink $file;
        }
        for my $dir ( grep {-d} @cleanup ) {
            $dir->remove_tree;
        }
    }
    #
    sub compile_ok( $name, $aggs //= '', $keep //= 0 ) {
        my $c = context();

        #~ return $c->pass_and_release($name) if 1;
        #~ return $c->fail_and_release($name, @diag);
        my ($opt) = grep { -f $_ } "t/src/$name.cxx", "t/src/$name.c", "src/$name.cxx", "src/$name.c";
        if ($opt) {
            $opt = path($opt)->absolute;
        }
        else {
            $opt = tempfile(
                UNLINK => !$keep,
                SUFFIX => '_' . path( [ caller() ]->[1] )->basename . ( $name =~ m[^\s*//\s*ext:\s*\.c$]ms ? '.c' : '.cxx' )
            )->absolute;
            push @cleanup, $opt unless $keep;
            my ( $package, $filename, $line ) = caller;
            $filename = path($filename)->canonpath;
            $line++;
            $filename =~ s[\\][\\\\]g;    # Windows...
            $opt->spew_utf8(qq[#line $line "$filename"\r\n$name]);
        }
        if ( !$opt ) {
            $c->fail('Failed to locate test source');
            $c->release;
            return ();
        }
        my $compiler = Affix::Compiler->new( name => 'testing', version => '1.0', source => [ $opt->canonpath ], flags => { cflags => '-I' . $Inc } );
        $compiler->compile;
        push @cleanup, $opt->canonpath, $compiler->link unless $keep;
        $c->ok( 1, 'build lib: ' . $compiler->link );
        $c->release;
        $compiler->link;
    }

    sub affix_ok ( $lib, $name, $args, $ret ) {
        my $c = context;
        my $sub;
        diag __PACKAGE__;
        diag join ', ', caller;
        my $okay = run_subtest(
            'affix ' . $name . '( ... )',
            sub {
                ok lives {
                    $sub = affix( $lib, $name, $args, $ret )
                }, 'affix ' . $name . ' ...';
                isa_ok $sub, ['Affix'], $name;
            },
            { buffered => 0, no_fork => 1 }
        );
        $c->release;
        return $sub;
    }
    {
        my $supp;    # defined later
        my ( $test, $generate_suppressions, $count );
        my $valgrind = 0;
        my $file;

        sub init_valgrind {
            return if $valgrind;
            require Path::Tiny;
            $file     = Path::Tiny::path($0)->absolute;
            $valgrind = 1;
            return plan skip_all 'Capture::Tiny is not installed' unless eval 'require Capture::Tiny';
            return plan skip_all 'Path::Tiny is not installed'    unless eval 'require Path::Tiny';
            require Getopt::Long;
            Getopt::Long::GetOptions( 'test=s' => \$test, 'generate' => \$generate_suppressions, 'count=i' => \$count );
            Test2::API::test2_stack()->top->{count} = $count if defined $count;

            if ( defined $test ) {

                #~ Affix::set_destruct_level(3);
                #~ die 'I should be running a test named ' . $test;
            }
            elsif ( defined $generate_suppressions ) {
                no Test2::Plugin::ExitSummary;
                pass 'exiting...';
                done_testing;
                exit;
            }
            else {
                my ( $stdout, $stderr, $exit_code ) = Capture::Tiny::capture(
                    sub {
                        system('valgrind --version');
                    }
                );
                plan skip_all 'Valgrind is not installed' if $exit_code;
                diag 'Valgrind v', ( $stdout =~ m/valgrind-(.+)$/ ), ' found';
                diag 'Generating suppressions...';
                my @cmd = (
                    qw[valgrind --leak-check=full --show-reachable=yes --error-limit=no
                        --gen-suppressions=all --log-fd=1], $^X, '-e',
                    sprintf <<'', ( join ', ', map {"'$_'"} sort { length $a <=> length $b } map { path($_)->absolute->canonpath } @INC ) );
    use strict;
    use warnings;
    use lib %s;
    use Affix;
    no Test2::Plugin::ExitSummary;
    use Test2::V0;
    pass "generate valgrind suppressions";
    done_testing;


                #~ use Data::Dump;
                #~ ddx \@cmd;
                my ( $out, $err, @res ) = Capture::Tiny::capture(
                    sub {
                        system @cmd;
                    }
                );
                my ( $known, $dups ) = parse_suppression($out);

                #~ diag $out;
                #~ diag $err;
                diag scalar( keys %$known ) . ' suppressions found';
                diag $dups . ' duplicates have been filtered out';
                $known->{'BSD is trash'} = <<'';
{
    <insert_a_suppression_name_here>
    Memcheck:Free
    fun:~vector
}

                $known->{'chaotic access'} = <<'';
{
    <insert_a_suppression_name_here>
    Memcheck:Addr1
    fun:_DumpHex
}


                # https://bugs.kde.org/show_bug.cgi?id=453084
                # https://github.com/Perl/perl5/issues/19949
                # https://github.com/Perl/perl5/issues/20970
                $known->{'https://github.com/Perl/perl5/issues/19949'} = <<'';
{
   <insert_a_suppression_name_here>
   Memcheck:Overlap
   fun:__memcpy_chk
   fun:XS_Cwd_abs_path
   fun:Perl_pp_entersub
   fun:Perl_runops_standard
   fun:S_docatch
   fun:Perl_runops_standard
   fun:Perl_call_sv
}
{
   memmove overlapping source and destination
   Memcheck:Overlap
   fun:__memcpy_chk
}

                $supp = Path::Tiny::tempfile( { realpath => 1 }, 'valgrind_suppression_XXXXXXXXXX' );
                diag 'spewing to ' . $supp;
                diag $supp->spew( join "\n\n", values %$known );
                push @cleanup, $supp;
                Test2::API::test2_stack()->top->{count};

                #~ Test2::API::test2_stack()->top->{count}++;
            }
        }

        sub parse_suppression {
            my $dups  = 0;
            my $known = {};
            require Digest::MD5;
            my @in = split /\R/, shift;
            my $l  = 0;
            while ( $_ = shift @in ) {
                $l++;
                next unless (/^\{/);
                my $block = $_ . "\n";
                while ( $_ = shift @in ) {
                    $l++;
                    $block .= $_ . "\n";
                    last if /^\}/;
                }
                $block // last;
                if ( $block !~ /\}\n/ ) {
                    diag "Unterminated suppression at line $l";
                    last;
                }
                my $key = $block;
                $key =~ s/(\A\{[^\n]*\n)\s*[^\n]*\n/$1/;
                my $sum = Digest::MD5::md5_hex($key);
                $dups++ if exists $known->{$sum};
                $known->{$sum} = $block;
            }
            return ( $known, $dups );
        }

        sub dec_ent {
            return $1 if $_[0] =~ m/^<!\[CDATA\[\{(.*)}]]>$/smg;
            $_[0]              =~ s[&lt;][<]g;
            $_[0]              =~ s[&gt;][>]g;
            $_[0]              =~ s[&amp;][&]g;
            shift;
        }

        sub stacktrace($blah) {
            use Test2::Util::Table qw[table];
            $blah ?
                join "\n", table(
                max_width => 120,
                collapse  => 1,                                # Do not show empty columns
                header    => [ 'function', 'path', 'line' ],
                rows      => [
                    map { [ $_->{fn}, ( defined $_->{dir} && defined $_->{file} ) ? join '/', $_->{dir}, $_->{file} : '', $_->{line} // '' ] } @$blah
                ],
                ) :
                '';
        }

        sub parse_xml {
            my ($xml) = @_;
            my $hash  = {};
            my $re    = qr{<([^>]+)>\s*(.*?)\s*</\1>}sm;
            while ( $xml =~ m/$re/g ) {
                my ( $tag, $content ) = ( $1, $2 );
                $content = parse_xml($content) if $content =~ /$re/;
                $content = dec_ent($content) unless ref $content;
                if ( $tag eq 'error' ) {

                    # use Data::Dump;
                    # ddx $content;
                    diag $content->{what} // $content->{xwhat}{text};
                    if ( ref $content->{auxwhat} eq 'ARRAY' ) {
                        for my $i ( 0 .. scalar @{ $content->{stack} } ) {
                            note $content->{auxwhat}[$i] if $content->{auxwhat}[$i];
                            note stacktrace $content->{stack}[$i]{frame};
                        }
                    }
                    else {
                        note $content->{auxwhat};
                        for my $i ( 0 .. scalar @{ $content->{stack} } ) {
                            note stacktrace $content->{stack}[$i]{frame};
                        }
                    }
                }
                $hash->{$tag}
                    = defined $content ?
                    (
                    defined $hash->{$tag} ?
                        ref $hash->{$tag} eq 'ARRAY' ?
                            [ @{ $hash->{$tag} }, $content ] :
                            [ $hash->{$tag}, $content ] :
                        $tag =~ m/^(error|stack)$/ ? [$content] :
                        dec_ent($content) ) :
                    undef;
            }
            $hash;
        }

        # Function to run anonymous sub in a new process with valgrind
        sub leaks( $name, $code_ref ) {
            init_valgrind();
            #
            require B::Deparse;
            CORE::state $deparse //= B::Deparse->new(qw[-l]);
            my ( $package, $file, $line ) = caller;
            my $source = sprintf
                <<'', ( join ', ', map {"'$_'"} sort { length $a <=> length $b } grep {defined} map { my $dir = path($_); $dir->exists ? $dir->absolute->realpath : () } @INC, 't/lib' ), Test2::API::test2_stack()->top->{count}, $deparse->coderef2text($code_ref);
use lib %s;
use Test2::V0 -no_srand => 1, '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
no Test2::Plugin::ExitSummary; # I wish
use Test2::Tools::Affix;
# Test2::API::test2_stack()->top->{count} = %d;
$|++;
my $exit = sub {use Affix; Affix::set_destruct_level(3); %s;}->();
# Test2::API::test2_stack()->top->{count}++;
done_testing;
exit !$exit;

            my $report = Path::Tiny->tempfile( { realpath => 1 }, 'valgrind_report_XXXXXXXXXX' );
            push @cleanup, $report;
            my @cmd = (
                'valgrind',               '-q', '--suppressions=' . $supp->canonpath,
                '--leak-check=full',      '--show-leak-kinds=all', '--show-reachable=yes', '--demangle=yes', '--error-limit=no', '--xml=yes',
                '--gen-suppressions=all', '--xml-file=' . $report->stringify,
                $^X,                      '-e', $source
            );
            my ( $out, $err, $exit ) = Capture::Tiny::capture(
                sub {
                    system @cmd;
                }
            );

            # $out =~ s[# Seeded srand with seed .+$][]m;
            # $err =~ s[# Tests were run .+$][];
            if ( $out =~ m[\S] ) {
                $out =~ s[^((?:[ \t]*))(?=\S)][$1  ]gm;
                print $out;
            }
            if ( $err =~ m[\S] ) {
                $err =~ s[^((?:[ \t]*))(?=\S)][$1  ]gm;
                print STDERR $err;
            }
            my $parsed = parse_xml( $report->slurp_utf8 );

            # use Data::Dump;
            # ddx $parsed;
            # diag 'exit: '. $exit;
            # Test2::API::test2_stack()->top->{count}++;
            ok !$exit && !$parsed->{valgrindoutput}{errorcounts}, $name;
        }
    }

    END {
        for my $file ( grep {-f} @cleanup ) {

            #~ note 'Removing ' . $file;
            unlink $file;
        }
        for my $dir ( grep {-d} @cleanup ) {

            #~ note 'Removing ' . $dir;
            $dir->remove_tree;
        }
    }
};
1;
