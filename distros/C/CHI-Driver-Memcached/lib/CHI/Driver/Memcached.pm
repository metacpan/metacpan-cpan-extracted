package CHI::Driver::Memcached;
$CHI::Driver::Memcached::VERSION = '0.16';
use Moose;
use strict;
use warnings;

extends 'CHI::Driver::Memcached::Base';

has '+memd_class' => ( default => 'Cache::Memcached' );

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

CHI::Driver::Memcached -- Distributed cache via memcached (memory cache daemon)

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use CHI;

    my $cache = CHI->new(
        driver => 'Memcached',   # or 'Memcached::Fast', or 'Memcached::libmemcached'
        namespace => 'products',
        servers => [ "10.0.0.15:11211", "10.0.0.15:11212", "/var/sock/memcached",
        "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
        debug => 0,
        compress_threshold => 10_000,
    );

=head1 DESCRIPTION

A CHI driver that uses Cache::Memcached to store data in the specified
memcached server(s).

L<CHI::Driver::Memcached::Fast> and L<CHI::Driver::Memcached::libmemcached> are
also available as part of this distribution. They work with other Memcached
clients and support a similar feature set. Documentation for all three modules
is presented below.

=head1 CONSTRUCTOR OPTIONS

Namespace, appended with ":", is passed along to the Cached::Memcached::*
constructor, along with any constructor options L<not recognized by
CHI|CHI/constructor> - for example I<servers>, I<compress_threshold> and
I<debug>.

If you need more control over the options passed to Cache::Memcached::*, you
may specify a hash directly in C<memd_params>.

=head1 METHODS

Besides the standard CHI methods:

=over

=item memd

Returns a handle to the underlying Cache::Memcached::* object. You can use this
to call memcached-specific methods that are not supported by the general API,
e.g.

    $self->memd->incr("key");
    my $stats = $self->memd->stats();

=back

=head1 UNSUPPORTED METHODS

These standard CHI methods cannot currently be supported by memcached, chiefly
because there is no way to get a list of stored keys.

=over

=item dump_as_hash

=item clear

=item get_keys

=item get_namespaces

=item is_empty

=item purge

=back

=head1 SUPPORT AND DOCUMENTATION

Questions and feedback are welcome, and should be directed to the perl-cache
mailing list:

    http://groups.google.com/group/perl-cache-discuss

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-Memcached

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-chi-driver-memcached/tree/master
    git clone git://github.com/jonswar/perl-chi-driver-memcached.git

=head1 AUTHOR

Jonathan Swartz

=head1 SEE ALSO

L<CHI|CHI>, L<Cache::Memcached|Cache::Memcached>,
L<CHI::Driver::Memcached::Fast>, L<CHI::Driver::Memcached::libmemcached>

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
