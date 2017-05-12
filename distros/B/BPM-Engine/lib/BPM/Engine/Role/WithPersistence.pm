package BPM::Engine::Role::WithPersistence;
BEGIN {
    $BPM::Engine::Role::WithPersistence::VERSION   = '0.01';
    $BPM::Engine::Role::WithPersistence::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Types qw/ConnectInfo Schema/;
use BPM::Engine::Store;
use BPM::Engine::Exceptions qw/throw_param/;

has schema => (
    isa        => Schema['BPM::Engine::Store'],
    is         => 'ro',
    lazy_build => 1,
    predicate  => 'has_schema',
    );

has 'connect_info' => (
    is        => 'ro',
    isa       => ConnectInfo,
    coerce    => 1,
    required  => 0,
    predicate => 'has_connect_info',
    );

sub _build_schema {
    my $self = shift;
    return BPM::Engine::Store->connect($self->connect_info)
        or die("Could not connect to Store");
    }

sub BUILD {}
after BUILD => sub {
    my $self = shift;

    confess "Invalid connection arguments - "
        . "either 'connect_info' or 'schema' must be supplied"
        unless ($self->has_connect_info || $self->has_schema);

    return;
    };

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $args = $orig->(@_);

    throw_param error => "Invalid connection arguments - "
        . "either 'connect_info' or 'schema' must be supplied"
        unless ($args->{connect_info} || $args->{schema});

    return $args;
    };

no Moose::Role;

1;
__END__

=pod

=head1 NAME

BPM::Engine::Role::WithPersistence - Engine role that provides DBIC schema

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This role provides the backend DBIC schema to BPM::Engine.

=head1 ATTRIBUTES

=head2 schema

=head2 connect_info

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
