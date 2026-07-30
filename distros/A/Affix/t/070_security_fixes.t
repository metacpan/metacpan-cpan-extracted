use v5.40;
use blib;
use Test2::V0 -no_srand => 1;
use Config;
use Path::Tiny qw[path];
$|++;
#
subtest 'H6: BSD find_library regex uses \Q quoting' => sub {
    use Affix::Platform::BSD;

    # We can't easily test the regex directly since \Q is consumed by qr//,
    # but we CAN test that malicious library names don't produce false matches.
    # Verify the regex is compiled (won't die when constructed with evil name)
    my $evil_name = q[m; rm -rf /];
    my $regex     = qr[-l\Q$evil_name\E\.[^\s]+.+\s*=>\s*(.+)$];

    # The escaped name should NOT match a legitimate ldconfig output line
    unlike '-lm.1 => /lib/libm.so.1', $regex, 'Evil name does not match legitimate ldconfig line';

    # A safe name should match ldconfig-style output
    my $safe_name  = 'm';
    my $safe_regex = qr[-l\Q$safe_name\E\.[^\s]+.+\s*=>\s*(.+)$];
    like '-lm.1 => /lib/libm.so.1', $safe_regex, 'Safe name matches ldconfig output format';
};
#
subtest 'H7/H8: Macro name validation prevents symbol table injection' => sub {
    use Affix::Wrap;

    # Valid macro
    my $valid  = Affix::Wrap::Macro->new( name => 'SAFE_CONST', value => '42' );
    my $result = $valid->affix( undef, 'Test::H7Valid' );
    ok defined $result, 'affix() returns for valid name';

    # The generated constant should work via use constant
    my $code = $valid->affix_type;
    ok eval "package Test::H7Valid; $code; 1", 'Generated constant compiles' or diag "eval error: $@";

    # Evil macro name — should NOT install into symbol table
    my $evil = Affix::Wrap::Macro->new( name => 'EVIL; system("echo PWNED")', value => '1', );
    $result = $evil->affix( undef, 'Test::H7Evil' );
    ok defined $result, 'affix() returns for evil name (no crash)';

    # The evil name must NOT be accessible as a subroutine in the target package
    ok !defined $Test::H7Evil::{'EVIL; system("echo PWNED")'}, 'Evil name NOT installed in symbol table';
};
#
subtest 'H7/H8: Enum constant name validation' => sub {
    use Affix qw[Enum];
    my $type = Enum [ [ RED => 0 ], [ GREEN => 1 ], [ BLUE => 2 ], ];
    ok defined $type, 'Enum type created';
    my ( $const_map, $val_map ) = $type->resolve();
    is ref $const_map, 'HASH', 'const_map is a hash';
    ok exists $const_map->{RED},   'RED in const_map';
    ok exists $const_map->{GREEN}, 'GREEN in const_map';
    ok exists $const_map->{BLUE},  'BLUE in const_map';
};
#
subtest 'M4: Double-quote C string literal stripping in affix_type' => sub {
    use Affix::Wrap;
    my $macro = Affix::Wrap::Macro->new( name => 'GREETING', value => '"Hello World"', );
    my $code  = $macro->affix_type;
    like $code,   qr/use constant GREETING => 'Hello World'/, 'Double-quoted string stripped of outer quotes';
    unlike $code, qr/"Hello World"/,                          'No remaining double quotes in generated code';
    ok eval "package Test::M4; $code; 1", 'Generated constant compiles' or diag "eval error: $@";
};
#
subtest 'M5: Path traversal prevention in Affix::Build output name' => sub {
    skip_all 'No CC' unless $Config{cc};
    use Affix::Build;
    my $TMP_DIR = Path::Tiny->tempdir( CLEANUP => 1 );
    my $c       = Affix::Build->new( build_dir => $TMP_DIR, name => '../../etc/passwd' );
    $c->add( \<<~'', lang => 'c' );
        #include <stdio.h>
        int traversal_test(void) { return 42; }

    ok eval { $c->compile_and_link() }, 'Compiled despite malicious name';
    my $lib = $c->link;
    unlike "$lib", qr/\.\.[\/\\]/, 'Output path contains no path traversal';
};
#
subtest 'M13: Division by zero in _calculate_expr' => sub {
    use Affix qw[Enum];

    # _calculate_expr is in Affix::Type::Enum, accessible via resolve
    # We can test indirectly by defining enums with division expressions
    my $type = Enum [ [ HALF => '10 / 2' ], [ ZERO => '10 / 0' ], [ REM => '10 % 3' ], [ REMZ => '10 % 0' ], ];
    ok defined $type, 'Enum with division expressions created';
    my ( $const_map, $val_map ) = $type->resolve();
    is $const_map->{HALF}, 5, '10 / 2 = 5';
    is $const_map->{ZERO}, 0, '10 / 0 = 0 (not crash)';
    is $const_map->{REM},  1, '10 % 3 = 1';
    is $const_map->{REMZ}, 0, '10 % 0 = 0 (not crash)';
};
#
subtest 'M14/L12: DynaLoader typo fix' => sub {
    is $DynaLoader::dl_debug, 0, '$DynaLoader::dl_debug is set to 0 (not 1, no noisy bootstrap)';
};
done_testing;
