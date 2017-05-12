package Acme::FixIO;
$Acme::FixIO::VERSION = '0.02';
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw();

binmode(STDOUT, ':unix:encoding(utf8):crlf') or die "Can't binmode STDOUT because $!";
binmode(STDERR, ':unix:encoding(utf8):crlf') or die "Can't binmode STDERR because $!";

1;

__END__

=head1 NAME

Acme::FixIO - Workaround for Windows chcp 65001 UTF-8 output bug

=head1 SYNOPSIS

    use Acme::FixIO;

    print chr(300) x 3, chr(301), "UVW\n";

=head1 DESCRIPTION

This is the underlying problem:
The last octet is repeated when Perl outputs a UTF-8 encoded string in
cmd.exe, chcp 65001

Two StackOverflow articles with basically the same problem:
L<http://stackoverflow.com/questions/23416075> and
L<http://stackoverflow.com/questions/25585248>.

This is caused by a bug in Windows. When writing to a console set to code
page 65001, WriteFile() returns the number of characters written instead
of the number of bytes.

Workaround: Inject a binmode(STDOUT, ':unix:encoding(utf8):crlf') into the
perl program.

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
