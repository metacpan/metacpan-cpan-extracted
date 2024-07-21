package App::PerlGzipScript v0.0.1;
use v5.40;
__END__

=encoding utf-8

=head1 NAME

App::PerlGzipScript - Gzip perl scripts to reduce their file size

=head1 SYNOPSIS

  $ perl-gzip-script script.pl > script.pl.gz

=head1 DESCRIPTION

App::PerlGzipScript compresses perl scripts to reduce their file size.

=head1 EXAMPLE

Applying perl-gzip-script to L<App::cpm>,
the size of cpm script is reduced from 731KB to 189KB.

  $ curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm > cpm

  $ perl-gzip-script cpm > cpm-gzip

  $ ls -alh cpm*
  -rw-r--r-- 1 skaji staff 731K Sep 30 06:48 cpm
  -rw-r--r-- 1 skaji staff 189K Sep 30 06:48 cpm-gzip

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
