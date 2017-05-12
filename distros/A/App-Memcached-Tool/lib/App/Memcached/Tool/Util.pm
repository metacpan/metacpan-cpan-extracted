package App::Memcached::Tool::Util;

use strict;
use warnings;
use 5.008_001;

use Exporter 'import';
use List::Util qw(first);
use POSIX 'strftime';
use Time::HiRes 'gettimeofday';

our @EXPORT_OK = qw(
    looks_like_addr
    create_addr
    is_unixsocket
    debug
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use App::Memcached::Tool;
use App::Memcached::Tool::Constants ':all';

use version; our $VERSION = 'v0.9.4';

sub looks_like_addr {
    my $string = shift;
    return $string if is_unixsocket($string);

    my $hostname = $string;
    if (first { $_ eq $string } MODES()) {
        return;
    }
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
    return unless $App::Memcached::Tool::DEBUG;
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

App::Memcached::Tool::Util - Utility function set

=head1 SYNOPSIS

    use App::Memcached::Tool::Util ':all';
    if (looks_like_addr($given)) {
        ...
    }
    my $addr = is_unixsocket($given) ? $given : create_addr($hostname);
    debug "foo";

=head1 DESCRIPTION

App::Memcached::Tool::Util provides utility functions for other modules.

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

