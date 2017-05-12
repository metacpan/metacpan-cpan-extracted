package App::Memcached::Tool::Constants;

use strict;
use warnings;
use 5.008_001;

use Exporter 'import';

our @EXPORT_OK = qw(
    DEFAULT_PORT
    DEFAULT_ADDR
    MODES
    DEFAULT_MODE
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use version; our $VERSION = 'v0.9.4';

my $DEFAULT_PORT = 11211;

sub DEFAULT_PORT { $DEFAULT_PORT }
sub DEFAULT_ADDR { '127.0.0.1:' . $DEFAULT_PORT }

my @MODES = qw(display dump stats settings sizes help man);
sub MODES { @MODES }
sub DEFAULT_MODE { $MODES[0] }

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::Tool::Constants - Provides constants

=head1 SYNOPSIS

    use App::Memcached::Tool::Constants ':all';
    my $addr = DEFAULT_ADDR();
    my $addr = $hostname . ':' . $DEFAULT_PORT;

=head1 DESCRIPTION

Provides constants for other modules.

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

