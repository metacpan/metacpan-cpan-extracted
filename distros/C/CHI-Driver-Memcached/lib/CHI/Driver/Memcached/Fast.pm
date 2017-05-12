package CHI::Driver::Memcached::Fast;
$CHI::Driver::Memcached::Fast::VERSION = '0.16';
use Moose;
use strict;
use warnings;

extends 'CHI::Driver::Memcached::Base';

has '+memd_class' => ( default => 'Cache::Memcached::Fast' );

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

CHI::Driver::Memcached::Fast -- Distributed cache via Cache::Memcached::Fast

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use CHI;

    my $cache = CHI->new(
        driver => 'Memcached::Fast',
        namespace => 'products',
        servers => [ "10.0.0.15:11211", "10.0.0.15:11212", "/var/sock/memcached",
        "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
        debug => 0,
        compress_threshold => 10_000,
    );

=head1 DESCRIPTION

A CHI driver that uses L<Cache::Memcached::Fast|Cache::Memcached::Fast> to
store data in the specified memcached server(s). From the perspective of the
CHI API, the feature set is nearly identical to
L<CHI::Driver::Memcached|CHI::Driver::Memcached>.

=head1 AUTHOR

Jonathan Swartz

=head1 SEE ALSO

L<CHI|CHI>, L<Cache::Memcached::Fast|Cache::Memcached::Fast>,
L<CHI::Driver::Memcached>, L<CHI::Driver::Memcached::libmemcached>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007 Jonathan Swartz.

CHI::Driver::Memcached is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
