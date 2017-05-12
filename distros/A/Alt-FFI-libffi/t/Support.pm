package main;

use strict;
use warnings;

if ($^O eq 'MSWin32') {
    require Win32;
}
else {
    use Config;
    require DynaLoader;
}

# Convenience functions wrapping dynamic loading

sub load {
    my $name = shift;
    return if $name eq '-';
    return Win32::LoadLibrary($name) if $^O eq 'MSWin32';

    my $so = $name;
    -e $so or $so = DynaLoader::dl_findfile($name) || $name;
    return DynaLoader::dl_load_file($so, @_);
}

sub unload {
    if ($^O eq 'MSWin32') {
        Win32::FreeLibrary($_[0]);
    }
    else {
        DynaLoader::dl_free_file($_[0])
            if defined (&DynaLoader::dl_free_file);
    }
}

sub address {
    if ($^O eq 'MSWin32') {
        Win32::GetProcAddress($_[0], $_[1]);
    }
    elsif($_[0] eq '-') {
        DynaLoader::dl_find_symbol_anywhere($_[1]);
    }
    else {
        DynaLoader::dl_find_symbol($_[0], $_[1]);
    }
}

# Get the libc and libm libraries

our $libc;
our $libm;
if ($^O eq 'MSWin32') {
    $libc = load("MSVCRT80") || load("MSVCRT71") || load("MSVCRT70") ||
            load("MSVCRT60") || load("MSVCRT40") || load("MSVCRT20");
    $libm = $libc;
}
else {
    $libc = load($Config{'libc'} || "-lc");
    if (!$libc) {
        if ($^O =~ /linux/i) {
            # Some glibc versions install "libc.so" as a linker script,
            # unintelligible to dlopen().
            $libc = load("libc.so.6");
        }
        elsif ($^O eq "cygwin") {
          $libc = load("cygwin1.dll");
          $libm = $libc;
        }
        else {
          $libc = '-';
        }
    }
    if (!$libc) {
        die "Can't load -lc: ", DynaLoader::dl_error(), "\nGiving up.\n";
    }

    my $libm_arg = DynaLoader::dl_findfile("-lm");
    if (!$libm_arg) {
        $libm = $libc;
    } elsif ($libm_arg !~ /libm\.a$/) {
        $libm = load("-lm");
    }
    if (!$libm) {
        die "Can't load -lm: ", DynaLoader::dl_error(), "\nGiving up.\n";
    }
}

END {
    unload($libm);
    unload($libc);
}

1;
