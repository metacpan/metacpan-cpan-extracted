package Ambrosia::CommonGatewayInterface;
use strict;
use warnings;

use Ambrosia::core::Nil;
use Ambrosia::error::Exceptions;
use Ambrosia::Utils::Enumeration property => __state  => START => 1, PROCESS => 2, COMPLETE => 3, BREAK => 4;
use Ambrosia::Utils::Enumeration property => __status => OK => 1, REDIRECT => 2, ERROR => 4;
use Ambrosia::Meta;

class abstract
{
    protected => [qw/_handler/],
    private => [qw/__state __status/],
};

our $VERSION = 0.010;

sub open
{
    $_[0]->SET_START;
    $_[0]->SET_OK;
    return $_[0]->_handler;
}

sub close
{
    $_[0]->_handler = undef;
    $_[0]->SET_COMPLETE;
}

sub abort
{
    $_[0]->_handler = undef;
    $_[0]->SET_BREAK;
    $_[0]->SET_ERROR;
}

sub handler
{
    $_[0]->_handler or $_[0]->open();
}

sub error
{
    return 'error in ' . __PACKAGE__;
}

sub input_data  :Abstract {}
sub output_data :Abstract {}

1;

__END__

=head1 NAME

Ambrosia::CommonGatewayInterface - a common gateway interface for IO.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::CommonGatewayInterface> is a common gateway interface for IO.

=head1 METHODS

=head2 open

This method initialise a handler.

=head2 close

This method destroy a handler.

=head2 abort

You must call this method on error.

=head2 handler

Returns initialise handler.

=head2 error

Returns error message. This method may be overriding in concrete classes.

=head2 input_data

C<input_data> is abstract method. This method are overriding in concrete classes.

=head2 output_data

C<output_data> is abstract method. This method are overriding in concrete classes.

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 SEE ALSO

L<Ambrosia>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
