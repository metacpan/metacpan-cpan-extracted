# ABSTRACT: General Purpose Exception Class for Bubblegum
package Bubblegum::Exception;

use 5.10.0;

use Moo;

extends 'Throwable::Error';

use Data::Dumper ();
use Scalar::Util ();

our $VERSION = '0.45'; # VERSION

sub rethrow {
    die shift;
}

sub dumper {
    local $Data::Dumper::Terse = 1;
    return Data::Dumper::Dumper(shift);
}

sub caught {
    my($class, $e) = @_;
    return if ref $class;
    return unless Scalar::Util::blessed($e)
        && UNIVERSAL::isa($e, $class);
    return $e;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Exception - General Purpose Exception Class for Bubblegum

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    Bubblegum::Exception->throw('oh nooo!!!');

=head1 DESCRIPTION

Bubblegum::Exception provides a general purpose exception object to be thrown
and caught and rethrow. Bubblegum::Exception extends L<Throwable::Error>, please
review its documentation for addition usage information. B<Note: This is an
early release available for testing and feedback and as such is subject to
change.>

    try {
        Bubblegum::Exception->throw(
            message => 'you broke something',
        );
    }
    catch ($exception) {
        if (Bubblegum::Exception->caught($exception)) {
            # you belong to me
            $exception->rethrow;
        }
    };

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
