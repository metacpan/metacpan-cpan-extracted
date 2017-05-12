package Ambrosia::RPC;
use strict;

use Ambrosia::error::Exceptions;
use Ambrosia::RPC::Service;
require Ambrosia::core::Object;

use Ambrosia::Meta;

class {
    extends   => [qw/Exporter/],
    protected => [qw/_list/],
};

our @EXPORT = qw/rpc/;

our $VERSION = 0.010;

our %PROCESS_MAP = ();
our %RPC = ();

sub import
{
    my $pkg = shift;
    my %prm = @_;
    assign($prm{assign}) if $prm{assign};

    __PACKAGE__->export_to_level(1, @EXPORT);
}

sub assign
{
    $PROCESS_MAP{$$} = shift;
}

{
    sub new : Private
    {
        return shift->SUPER::new(@_);
    }

    sub instance
    {
        my $package = shift;
        my $key = shift;

        unless ( $RPC{$key} )
        {
            my %params = @_ == 1 ? %{$_[0]} : @_;
            my %list = ();
            foreach my $serviceType ( keys %params )
            {
                foreach my $p ( ref $params{$serviceType} eq 'ARRAY' ? @{$params{$serviceType}} : $params{$serviceType} )
                {
                    my $name = $p->{name};
                    delete $p->{name};
                    $list{$serviceType}->{$name}
                        = Ambrosia::RPC::Service->new(service_type => $serviceType, %$p);
                }
            }
            $RPC{$key} = $package->new(_list => \%list);
        }

        return $RPC{$key};
    }

    sub rpc
    {
        return __PACKAGE__->instance(shift || $PROCESS_MAP{$$} || throw Ambrosia::error::Exception::BadUsage("First access to Ambrosia::RPC without assign to RPC."));
    }

    sub destroy
    {
        %RPC = ();
    }
}

sub service #(serviceType, name)
{
    my $self = shift;
    my $serviceType = shift;
    my $name = shift;

#!!TODO!! вызывать исключение вместо undef
    if ( $serviceType && $name )
    {
        return $self->_list->{$serviceType}->{$name} || undef;
    }
    return undef;
}

1;

__END__

=head1 NAME

Ambrosia::RPC - a container for engines, that implement service calls.

=head1 VERSION

version 0.010

=head1 SYNOPSIS


=head1 DESCRIPTION

C<Ambrosia::RPC> is a container for engines, that implement service calls.

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
