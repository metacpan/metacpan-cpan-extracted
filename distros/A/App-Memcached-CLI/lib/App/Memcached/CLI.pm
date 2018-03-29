package App::Memcached::CLI;

use strict;
use warnings;
use 5.008_001;

use version; our $VERSION = 'v0.9.5';

our $DEBUG; # set by option

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::CLI - Interactive/Batch CLI for Memcached

=head1 SYNOPSIS

    use App::Memcached::CLI::Main;
    my $params = App::Memcached::CLI::Main->parse_args;
    App::Memcached::CLI::Main->new(%$params)->run;

=head1 DESCRIPTION

This package provides utility CLI for Memcached.

The CLI can be both interactive one or batch script.

See L<memcached-cli> for details.

=head1 SEE ALSO

L<memcached-cli>,
L<App::Memcached::CLI::Main>,
L<http://www.memcached.org/>

=head1 LICENSE

Copyright (C) IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=cut

