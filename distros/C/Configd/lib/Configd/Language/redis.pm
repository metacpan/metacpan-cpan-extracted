package Configd::Language::redis;
$Configd::Language::redis::VERSION = '0.005';
#ABSTRACT: redis.conf, which has no conf.d and a handful of directives you say more than once.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use parent qw{Configd::Syntax::Spaced};


# Everything redis takes more than once, meaning each of them.
my %REPEATS = map { $_ => 1 } qw{
  save
  client-output-buffer-limit
  rename-command
  module
  include
  bind
  replicaof
  slaveof
};

sub files {

    # 0640 root:redis as the package ships it, but configd keeps whatever it
    # finds; this is only what a file created from nothing would get.
    return ( { path => '/etc/redis/redis.conf', mode => 0o640, owner => 'root:redis' } );
}

sub units {
    return ('redis-server.service');
}

sub repeats {
    my ( $self, $key ) = @_;
    return $REPEATS{$key} // 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd::Language::redis - redis.conf, which has no conf.d and a handful of directives you say more than once.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Configd();

    Configd->adopt('redis');
    Configd->build('redis');

=head1 DESCRIPTION

Redis has an C<include> directive, which is not the same thing as a C<conf.d>:
the included file has to be named from the file doing the including, so adding
one still means editing C<redis.conf>.  Include order also decides precedence in
a way that surprises people -- a directive in the main file B<after> an include
wins over the included one.

So C<redis.conf> becomes generated, and a fragment is a file rather than a file
plus an edit.

=head1 NAME

Configd::Language::redis - redis.conf, which has no conf.d and a handful of
directives you say more than once.

=head1 REPEATED DIRECTIVES

Most of redis.conf is one value per directive: a second C<maxmemory> replaces
the first.  A few are not, and mean every occurrence:

=over 4

=item * C<save> -- one line per snapshot point, C<save 900 1> and C<save 300 10>
being two conditions rather than one overriding the other.

=item * C<client-output-buffer-limit> -- one line per client class.

=item * C<rename-command>, C<module>, C<include>, C<bind> when written as
several lines.

=back

Those are matched on everything they say, so two fragments both asking for
C<save 900 1> get one line and two asking for different snapshot points get
both.  That is what lets a fragment be written without checking whether somebody
else already asked for the same thing.

=head1 METHODS

=head2 files()

F</etc/redis/redis.conf>, 0640 root:redis if it has to be created.

=head2 units()

C<redis-server.service>.

=head2 repeats($key)

True for the directives listed above, each occurrence of which means something
of its own.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd|Configd>

=item *

L<Configd::Language>, L<Configd::Syntax::Spaced>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-configd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
