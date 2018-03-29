package App::Memcached::CLI::Constants;

use strict;
use warnings;
use 5.008_001;

use Exporter 'import';

our @EXPORT_OK = qw(
    DEFAULT_PORT
    DEFAULT_ADDR
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use version; our $VERSION = 'v0.9.5';

my $DEFAULT_PORT = 11211;

sub DEFAULT_PORT { $DEFAULT_PORT }
sub DEFAULT_ADDR { '127.0.0.1:' . $DEFAULT_PORT }

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::CLI::Constants - Provides constants

=head1 SYNOPSIS

    use App::Memcached::CLI::Constants ':all';
    my $addr = DEFAULT_ADDR();
    my $addr = $hostname . ':' . $DEFAULT_PORT;

=head1 DESCRIPTION

This module provides constants for other modules.

=head1 LICENSE

Copyright (C) IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=cut

