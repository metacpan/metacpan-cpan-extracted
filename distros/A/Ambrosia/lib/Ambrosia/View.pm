package Ambrosia::View;
use strict;
use warnings;

use Ambrosia::Meta;

class abstract
{
    public => [qw/charset template data/],
};

our $VERSION = 0.010;

sub render
{
    my $self = shift;
    $self->template = shift;
    $self->data = shift;
    return $self->process;
}

sub process : Abstract
{
}

1;

__END__

=head1 NAME

Ambrosia::View - a base class for implemented view in MVC.

=head1 VERSION

version 0.010

=head1 SYNOPSIS


=head1 DESCRIPTION

C<Ambrosia::View> is a base class for implemented view in MVC..

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
