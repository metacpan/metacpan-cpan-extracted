use v5.40;
use blib;
use Test2::V0 -no_srand => 1;
use Capture::Tiny qw[capture];

# Load the Unix platform module directly (works cross-platform for unit testing)
use Affix::Platform::Unix qw[find_library];
$|++;
#
subtest '_findLib_ld: safe command execution (C2)' => sub {

    # Normal call — may return error output on Windows (no /dev/null) or empty on
    # Unix without ld, but must not die
    my ( $out, $err, $exit ) = capture { Affix::Platform::Unix::_findLib_ld('m') };
    pass '_findLib_ld does not die on normal input';

    # Malicious input must not execute shell commands.
    # With list-form open, the entire string "-lm; echo INJECTED" is passed as a
    # single argument to ld — never interpreted by a shell.
    for my $evil ( 'm; echo INJECTED', 'm && touch /tmp/pwned', 'm | cat /etc/passwd', 'm $(id)', 'm`id`', ) {
        ( $out, $err, $exit ) = capture { Affix::Platform::Unix::_findLib_ld($evil) };
        my $combined = ( $out // '' ) . ( $err // '' );

        # The shell injection payload must NOT appear as executed output
        unlike $combined, qr/^INJECTED$/m, "No shell injection via ld: $evil";

        # On systems where ld exists, verify the malicious string is passed as a
        # single argument (ld will complain about "cannot find -l<entire string>")
        if ( $combined =~ /cannot find/ ) {
            like $combined, qr/\Q$evil\E/, "Malicious string passed as single arg to ld: $evil";
        }
    }
};
subtest '_findLib_gcc: safe command execution (C3)' => sub {

    # Normal call — may return empty without gcc, must not die
    my @result = eval { Affix::Platform::Unix::_findLib_gcc('m') };
    is ref \@result, 'ARRAY', '_findLib_gcc returns array';

    # Malicious input must not execute shell commands
    for my $evil ( 'm; echo INJECTED', 'm && touch /tmp/pwned', 'm | cat /etc/passwd', 'm $(id)', 'm`id`', ) {
        my @ret = eval { Affix::Platform::Unix::_findLib_gcc($evil) };
        ok !@ret, "Malicious gcc input rejected safely: $evil";
    }

    # lib prefix is stripped
    my @stripped = eval { Affix::Platform::Unix::_findLib_gcc('libfoo') };
    is ref \@stripped, 'ARRAY', 'lib prefix stripped without error';
};
subtest '_get_soname: safe command execution (C4)' => sub {

    # Nonexistent file returns undef
    my $result = eval { Affix::Platform::Unix::_get_soname('/nonexistent/file.so') };
    is $result, undef, '_get_soname returns undef for nonexistent file';

    # undef input returns undef
    $result = eval { Affix::Platform::Unix::_get_soname(undef) };
    is $result, undef, '_get_soname returns undef for undef input';

    # Empty string returns undef
    $result = eval { Affix::Platform::Unix::_get_soname('') };
    is $result, undef, '_get_soname returns undef for empty string';

    # Malicious input must not execute shell commands
    for my $evil ( '/tmp/fake; echo INJECTED', '/tmp/fake && touch /tmp/pwned', '/tmp/fake | cat /etc/passwd', '/tmp/fake $(id)', '/tmp/fake`id`', ) {
        $result = eval { Affix::Platform::Unix::_get_soname($evil) };
        is $result, undef, "Malicious soname input rejected safely: $evil";
    }
};
subtest 'find_library: graceful handling' => sub {

    # find_library with normal names must not die (returns undef on error)
    my $result = eval { find_library('m') };
    ok !defined $result || -f $result, 'find_library(m) returns undef or valid path';
    $result = eval { find_library('nonexistent_lib_xyz_12345') };
    is $result, undef, 'find_library returns undef for unknown lib';

    # Malicious input must not execute shell commands
    for my $evil ( 'm; echo INJECTED', 'm && touch /tmp/pwned', 'm | cat /etc/passwd', ) {
        $result = eval { find_library($evil) };
        is $result, undef, "Malicious find_library input rejected safely: $evil";
    }
};
subtest 'is_elf: binary detection' => sub {
    skip_all 'No /tmp on Windows' if $^O eq 'MSWin32';

    # Create a fake ELF file
    my $fake_elf = '/tmp/_test_fake_elf_' . $$;
    open( my $fh, '>', $fake_elf ) or die "Cannot create temp file: $!";
    print $fh "\x7fELF" . "\x00" x 20;
    close $fh;
    ok Affix::Platform::Unix::is_elf($fake_elf), 'is_elf detects ELF header';

    # Create a non-ELF file
    my $fake_txt = '/tmp/_test_fake_txt_' . $$;
    open( $fh, '>', $fake_txt ) or die "Cannot create temp file: $!";
    print $fh "This is not an ELF file";
    close $fh;
    ok !Affix::Platform::Unix::is_elf($fake_txt), 'is_elf rejects non-ELF';

    # Nonexistent file
    ok !Affix::Platform::Unix::is_elf('/nonexistent/file'), 'is_elf handles nonexistent file';
    unlink $fake_elf, $fake_txt;
};
done_testing();
