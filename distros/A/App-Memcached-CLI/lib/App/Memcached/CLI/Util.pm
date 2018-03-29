package App::Memcached::CLI::Util;

use strict;
use warnings;
use 5.008_001;

use Exporter 'import';
use POSIX 'strftime';
use Time::HiRes 'gettimeofday';

our @EXPORT_OK = qw(
    looks_like_addr
    create_addr
    is_unixsocket
    debug
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use App::Memcached::CLI;
use App::Memcached::CLI::Constants ':all';

use version; our $VERSION = 'v0.9.5';

sub looks_like_addr {
    my $string = shift;
    return $string if is_unixsocket($string);

    my $hostname = $string;
    if ($hostname =~ m/([^\s:]+):\d+/) {
        $hostname = $1;
    }
    return $string if gethostbyname($hostname);

    return;
}

sub create_addr {
    my $base_addr = shift;
    return DEFAULT_ADDR() unless $base_addr;
    return $base_addr if is_unixsocket($base_addr);
    return $base_addr if ($base_addr =~ m/([^\s:]+):\d+/);
    return join(qw{:}, $base_addr, DEFAULT_PORT());
}

sub debug {
    my $message = shift;
    return unless $App::Memcached::CLI::DEBUG;
    my ($sec, $usec) = gettimeofday;
    printf STDERR "%s.%03d [DEBUG] $message at %s line %d.\n",
        strftime('%F %T', localtime($sec)), $usec/1000, (caller)[1,2];
}

sub is_unixsocket {
    my $file = shift;
    return 1 if (-e $file && -S $file);
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::CLI::Util - Utility functions for memcached-cli

=head1 SYNOPSIS

    use App::Memcached::CLI::Util ':all';
    if (looks_like_addr($given)) {
        ...
    }
    my $addr = is_unixsocket($given) ? $given : create_addr($hostname);
    debug "foo";

=head1 DESCRIPTION

This module provides utility functions for other modules.

=head1 LICENSE

Copyright (C) IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=cut

