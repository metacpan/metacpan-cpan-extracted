package Catalyst::Model::Redis;

use strict;
use warnings;
use base 'Catalyst::Model';

our $VERSION = "0.02";
$VERSION = eval $VERSION;

use MRO::Compat;
use mro 'c3';
use RedisDB;

=head1 NAME

Catalyst::Model::Redis - Redis Model Class

=head1 VERSION

0.01

=head1 SYNOPSIS

    # use helper to add model
    create model Redis Redis server port password

    # lib/MyApp/Model/Redis.pm
    package MyApp::Model::Redis;
    use parent "Catalyst::Model::Redis";

    __PACKAGE__->config(
        host     => 'localhost',
        port     => 6379,
        database => 3,
        password => 'secret',
    );

    1;

    # in controller
    my $redis = $c->model('Redis')->redis;

=head1 DESCRIPTION

This module implements Redis model class for Catalyst.

=head1 METHODS

=cut

=head2 $self->new

Initializes L<RedisDB> object

=cut

sub new {
    my $self = shift->next::method(@_);
    my $c = shift;
    $self->{redis} = RedisDB->new(
        map { $_ => $self->{$_} } qw(host port path database password lazy timeout utf8),
    );
    return $self;
}

=head2 $self->redis

Returns the L<RedisDB> object

=cut

sub redis {
    shift->{redis};
}

1;

__END__

=head1 SEE ALSO

L<Catalyst>, L<RedisDB>

=head1 BUGS

Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/trinitum/perl-Catalyst-Model-Redis/issues>.

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
