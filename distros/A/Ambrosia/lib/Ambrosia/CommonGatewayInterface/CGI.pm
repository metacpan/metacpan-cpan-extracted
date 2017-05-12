package Ambrosia::CommonGatewayInterface::CGI;
use strict;
use warnings;

use CGI ();

use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::CommonGatewayInterface/],
    public  => [qw/header_params/],
};

our $VERSION = 0.010;

sub open
{
    my $self = shift;
    my $params = shift;

    $self->_handler ||= new CGI;
    if ( $params )
    {
        $self->delete_all;
        foreach ( keys %$params)
        {
            $self->_handler->param($_, $params->{$_});
        }
    }
    $self->SUPER::open();
    return $self->_handler;
}

################################################################################

sub input_data
{
    shift->_handler->param(@_);
}

sub output_data
{
    my $self = shift;
    my %p = @_;

    my %h = %{$self->header_params};
    foreach (keys %p)
    {
        $h{$_} = $p{$_};
    }

    if ( $self->IS_OK )
    {
        return $self->_handler->header(map { $_ => ref $h{$_} eq 'CODE' ? ($h{$_}->()||undef) : $h{$_} } keys %h);
    }
    elsif( $self->IS_REDIRECT )
    {
        return $self->_handler->redirect(map { $_ => ref $h{$_} eq 'CODE' ? ($h{$_}->()||undef) : $h{$_} } keys %h);
    }
    elsif( $self->IS_ERROR )
    {
    }
}

1;

__END__

=head1 NAME

Ambrosia::CommonGatewayInterface::CGI - 

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::CommonGatewayInterface::CGI> .

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
