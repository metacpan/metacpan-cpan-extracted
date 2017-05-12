package Ambrosia::View::JSON;
use strict;
use warnings;
use Carp;

use JSON::XS ();

use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::View/],
};

our $VERSION = 0.010;

sub process
{
    my $self = shift;

    return $self->as_json;
}

sub as_json
{
    my $self = shift;

    my $json = JSON::XS->new;
    $json->utf8(0);
    $json->latin1(1);

    my $str = '';
    eval
    {
        $json->convert_blessed(1);
        $str = $self->data ? $json->encode($self->data) : '{}';
warn "$str\n";
    };
    if ( $@ )
    {
        carp "ERROR: $@";
    }

    return $str;
}

1;

__END__

=head1 NAME

Ambrosia::View::JSON - it is VIEW in MVC.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::View::JSON> - it is VIEW in MVC.
Returns result in JSON.

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
