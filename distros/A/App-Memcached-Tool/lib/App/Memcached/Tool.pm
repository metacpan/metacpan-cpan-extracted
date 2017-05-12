package App::Memcached::Tool;
use 5.008_001;
use strict;
use warnings;

use version; our $VERSION = 'v0.9.4';

our $DEBUG; # set by option

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::Tool - A porting of L<memcached/memcached-tool|https://github.com/memcached/memcached/blob/master/scripts/memcached-tool>

=head1 SYNOPSIS

    use App::Memcached::Tool;

=head1 DESCRIPTION

This package provides the same feature with
L<memcached/memcached-tool|https://github.com/memcached/memcached/blob/master/scripts/memcached-tool>.

A common commandline tool for B<memcached>.

See L<memcached-tool> for more information.

=head1 SEE ALSO

L<memcached-tool>,
L<http://www.memcached.org/>

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

