[![Actions Status](https://github.com/sanko/App-dumpbin/workflows/windows/badge.svg)](https://github.com/sanko/App-dumpbin/actions) [![Actions Status](https://github.com/sanko/App-dumpbin/workflows/linux/badge.svg)](https://github.com/sanko/App-dumpbin/actions) [![Actions Status](https://github.com/sanko/App-dumpbin/workflows/macos/badge.svg)](https://github.com/sanko/App-dumpbin/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-dumpbin.svg)](https://metacpan.org/release/App-dumpbin)
# NAME

App::dumpbin - It's a PE Parser!

# SYNOPSIS

    use App::dumpbin;
    my $exports = App::dumpbin::exports( 'some.dll' );

# DESCRIPTION

App::dumpbin is a pure Perl PE parser with just enough functionality to make
[FFI::ExtractSymbols::Windows](https://metacpan.org/pod/FFI%3A%3AExtractSymbols%3A%3AWindows) work without installing Visual Studio for
`dumpbin`.

Both 32bit (PE32) and 64bit (PE32+) libraries are supported.

The functionality of this may grow in the future but my goal right now is very
narrow.

# See Also

- [https://docs.microsoft.com/en-us/windows/win32/debug/pe-format](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format)
- [Win32::PEFile](https://metacpan.org/pod/Win32%3A%3APEFile)
- [Win32::Exe](https://metacpan.org/pod/Win32%3A%3AExe)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
