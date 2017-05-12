package Ambrosia::DataProvider::ResourceDriver;
use strict;
use warnings;

use Ambrosia::core::Nil;
use Ambrosia::Meta;
class
{
    extends   => [qw/Ambrosia::DataProvider::BaseDriver/],
    private   => [qw/__start/],
};

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->_cache = new Ambrosia::core::Nil();
}

our $VERSION = 0.010;

sub reset
{
    my $self = shift;
    $self->SUPER::reset();
    $self->__start = 0;
    return $self;
}

################################################################################

sub begin_transaction
{
}

sub save_transaction
{
}

sub cancel_transaction
{
}

################################################################################

sub predicate
{
    my $self = shift;
    my ($f, $op, $v) = @_;

    my $old = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE] || sub {1};
    $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE] = {
        '=' => sub {
            my $h = shift;
            $old->($h) && $h->{$f} eq $v
        },
        '<' => sub {
            my $h = shift;
            $old->($h) && $h->{$f} lt $v
        },
        '<=' => sub {
            my $h = shift;
            $old->($h) && $h->{$f} le $v
        },
        '>' => sub {
            my $h = shift;
            $old->($h) && $h->{$f} gt $v
        },
        '>=' => sub {
            my $h = shift;
            $old->($h) && $h->{$f} ge $v
        },
        '!=' => sub {
            my $h = shift;
            $old->($h) && $h->{$f} ne $v
        },
        'like' => sub {
            my $h = shift;
            $old->($h) && $h->{$f} =~ /$v/
        },
    }->{lc($op)};

    return $self;
}

sub next
{
    my $self = shift;

    my $table = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]->[-1];

    my $source = $self->handler->{$table};

    my @fields = @{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::WHAT]};
M1:
    if ( my $res = $source->[$self->__start++] )
    {
        if ( my $p = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE] )
        {
            goto M1 unless $p->($res);
        }
        return @fields ? {map {$_ => $res->{$_}} @fields} : $res;
    }
    return;
}

sub count
{
    my $table = $_[0]->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]->[-1];

    return scalar @{$_[0]->handler->{$table}};
}

sub limit
{
}

sub skip
{
}

sub insert
{
    die 'Cannot insert. Resource read only';
}

sub update
{
    die 'Cannot update. Resource read only';
}

sub delete
{
    die 'Cannot delete. Resource read only';
}

1;

__END__

=head1 NAME

Ambrosia::DataProvider::ResourceDriver - a class realize Ambrosia::DataProvider::BaseDriver and provide connection to resources storage.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::DataProvider;
    my $confDS = {
        Resource => [
            {
                engine_name => 'Resource::Hash',
                source_name  => 'application_name',
                engine_params => {
                    path => $PATH_ROOT . '/Application/Resource/Resources.pm'
                }
            },
        ]
    };

    instance Ambrosia::Storage(application_name => $confDS);
    Ambrosia::DataProvider::assign 'application_name';


=head1 DESCRIPTION

C<Ambrosia::DataProvider::DBIDriver> is a class realize Ambrosia::DataProvider::BaseDriver and provide connection to data bases throw DBI.

For more information see:

=over

=item L<Ambrosia::DataProvider::Engine::Resource::Hash>

=back

=head1 SUBROUTINES/METHODS

=head2 cache

Returns cache.

=head2 open_connection (Wraper. Translate request to engine.)

Opens a connection. Returns a handler.

=head2 close_connection (Wraper. Translate request to engine.)

Closes a connection and clears a cache.

=head2 begin_transaction (Wraper. Translate request to engine.)

Begins a transaction and initializes a cache

=head2 save_transaction (Wraper. Translate request to engine.)

Saves a transaction.

=head2 cancel_transaction (Wraper. Translate request to engine.)

Canceled a transaction (rollback) and clears a cache.

=head2 CQL

Returns an adapter for L<Ambrosia::QL> that can translate CQL to Resource request.

=cut

=head1 DEPENDENCIES

L<Ambrosia::CQL::toResource>;
L<Ambrosia::Util::Container>;

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
