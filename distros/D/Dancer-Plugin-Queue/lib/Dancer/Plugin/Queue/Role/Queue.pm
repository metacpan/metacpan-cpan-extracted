use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Queue::Role::Queue;
# ABSTRACT: Dancer::Plugin::Queue implementation API
our $VERSION = '0.002'; # VERSION

use Moo::Role;

requires 'add_msg';

requires 'get_msg';

requires 'remove_msg';

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding utf-8

=head1 NAME

Dancer::Plugin::Queue::Role::Queue - Dancer::Plugin::Queue implementation API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package Dancer::Plugin::Queue::MyBackend

    use Moo;
    with 'Dancer::Plugin::Queue::Role::Queue';

    sub add_msg    { ... }

    sub get_msg    { ... }

    sub remove_msg { ... }

=head1 DESCRIPTION

This role specifies the API required by queue backend implementations.
The following methods must be provided:

=over 4

=item *

add_msg

=item *

get_msg

=item *

remove_msg

=back

=for Pod::Coverage method_names_here

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
