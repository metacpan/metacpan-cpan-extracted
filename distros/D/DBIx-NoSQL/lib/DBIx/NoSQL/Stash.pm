package DBIx::NoSQL::Stash;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::Stash::VERSION = '0.0021';
use strict;
use warnings;

use Moose;
use Carp qw/ cluck /;

has store => qw/ is ro required 1 weak_ref 1 /;

has model => qw/ is ro lazy_build 1 /;
sub _build_model {
    my $self = shift;
    my $model = $self->store->model( '__NoSQL_Stash__' );
    $model->searchable( 0 );
    return $model;
}

sub value {
    my $self = shift;
    my $key = shift;
    if ( @_ ) {
        my $value = shift;
        $self->model->set( $key, { value => $value } );
        return;
    }
    my $value = $self->model->get( $key );
    return unless $value;
    return $value->{ value };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::Stash

=head1 VERSION

version 0.0021

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
