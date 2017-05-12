package Apache::DummyScoreboard;

use strict;
use warnings FATAL => 'all';

$Apache::DummyScoreboard::VERSION = '2.00';
require XSLoader;
XSLoader::load(__PACKAGE__, $Apache::DummyScoreboard::VERSION);

1;
__END__

=head1 NAME

Apache::DummyScoreboard - Perl interface to the Apache scoreboard structure outside mod_perl



=head1 DESCRIPTION

when loading C<Apache::Scoreboard>, C<Apache::DummyScoreboard> is used
internally if the code is not running under mod_perl. It has almost
the same functionality with some limitations. See the
C<Apache::Scoreboard> manpage for more info.

You shouldn't be using this module directly.




=head1 Limitations

=over

=item * C<image>

This method can't be used when not running under Apache/mod_perl. Use
C<Apache::Scoreboard-E<gt>fetch> instead.

=item * C<Apache::Const::SERVER_LIMIT> and C<Apache::Const::THREAD_LIMIT> 

At the moment the deprecated constants C<Apache::Const::SERVER_LIMIT>
and C<Apache::Const::THREAD_LIMIT> are hardwired to 0, since the
methods that provide this information are only accessible via a
running Apache (i.e. via C<Apache::Scoreboad> running under mod_perl).
However, you should be using
C<L<$image->server_limit|Apache::Scoreboard/C_server_limit_>> and
C<L<$image->thread_limit|Apache::Scoreboard/C_thread_limit_>>.

=back

=cut

