package Ambrosia::DataProvider::Resource::Hash;
use strict;
use warnings;

use Ambrosia::Meta;
class sealed
{
    extends => [qw/Ambrosia::DataProvider::ResourceDriver/],
    private => [qw/__data/]
};

our $VERSION = 0.010;

sub open_connection
{
    my $self = shift;

    unless ( $self->__data )
    {
        my $path = $self->catalog . '/' . $self->schema;
        $path .= '.pm' unless $path =~ /\.pm$/;
        $self->__data ||= ( do $path or die($@ ? "$@ : $path" : "$! : $path") );
    }
    return $self->__data;
}

sub close_connection
{
    $_[0]->__data = undef;
}

1;

__END__

=head1 NAME

Ambrosia::DataProvider::Resource::Hash - a data source based on hash data.

=head1 VERSION

version 0.010

=head1 SYNOPSIS


=head1 DESCRIPTION

C<Ambrosia::DataProvider::Resource::Hash> is a data source based on hash data.

=head1 CONSTRUCTOR

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
