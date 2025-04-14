# NAME

Common::Log::Parser - Parse the common log format lines used by Apache

# VERSION

version v0.2.0

# SYNOPSIS

```perl
use Common::Log::Parser qw( split_log_line );

my $columns = split_log_line($line);
```

# DESCRIPTION

This module provides a simple function to parse common log format lines, such as those used by Apache.

# EXPORTS

None by default.

## split\_log\_line

```perl
my $columns = split_log_line($line);
```

This function simply parses the log file and returns an array reference of the different columns.

It does not attempt to parse or unescape the contents. Surrounding brackets or quotes are not removed.

# SEE ALSO

- [Apache::Log::Parser](https://metacpan.org/pod/Apache%3A%3ALog%3A%3AParser)
- [Apache::ParseLog](https://metacpan.org/pod/Apache%3A%3AParseLog)
- [ApacheLog::Parser](https://metacpan.org/pod/ApacheLog%3A%3AParser)
- [Regexp::Log::Common](https://metacpan.org/pod/Regexp%3A%3ALog%3A%3ACommon)

# SUPPORT FOR OLDER PERL VERSIONS

Since v0.2.0, the this module requires Perl v5.20 or later.

Future releases may only support Perl versions released in the last ten years.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl5-Common-Log-Parser](https://github.com/robrwo/perl5-Common-Log-Parser)
and may be cloned from [git://github.com/robrwo/perl5-Common-Log-Parser.git](git://github.com/robrwo/perl5-Common-Log-Parser.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl5-Common-Log-Parser/issues](https://github.com/robrwo/perl5-Common-Log-Parser/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was partially supported by Science Photo Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
