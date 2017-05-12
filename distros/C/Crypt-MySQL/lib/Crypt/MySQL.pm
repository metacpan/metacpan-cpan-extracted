package Crypt::MySQL;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Digest::SHA1 qw(sha1 sha1_hex);

BEGIN {
    $VERSION = '0.04';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }
    require Exporter;
    push @ISA, 'Exporter';
    @EXPORT_OK = qw(password password41);
}

sub password41($) { "*".uc(sha1_hex(sha1($_[0]))); }

1;
__END__

=head1 NAME

Crypt::MySQL - emulate MySQL PASSWORD() function.

=head1 SYNOPSIS

  use Crypt::MySQL qw(password password41);

  my $encrypted = password("foobar"); # for MySQL 3.23, 4.0

  my $encrypted = password41("foobar"); # for MySQL 4.1 or later.

=head1 DESCRIPTION

Crypt::MySQL emulates MySQL PASSWORD() SQL function, without libmysqlclient.
You can compare encrypted passwords, without real MySQL environment.

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@shebang.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBD::mysql> L<Digest::SHA1>

=cut
