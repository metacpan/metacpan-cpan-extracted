package Ambrosia::RPC::Service;
use strict;

use Ambrosia::Meta;
use Ambrosia::error::Exceptions;
use Ambrosia::core::ClassFactory;

class
{
    private => [qw/service/]
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    my %params = @_ == 1 ? %{$_[0]} : @_;
    my $serviceType = $params{service_type};
    delete $params{service_type};
    $self->service = Ambrosia::core::ClassFactory::create_object('Ambrosia::RPC::Service::' . $serviceType, \%params);
}

sub open_connection
{
    $_[0]->service->open_connection();
}

sub close_connection
{
    $_[0]->service->close_connection();
    $_[0]->service = undef;
    $_[0];
}
################################################################################

sub on_success
{
    goto $_[0]->service->on_success;
}

sub on_error
{
    goto $_[0]->service->on_error;
}

1;

__END__

=head1 NAME

Ambrosia::RPC::Service - a wrapper for concrete service.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::RPC::Service> is a wrapper for concrete service.

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
