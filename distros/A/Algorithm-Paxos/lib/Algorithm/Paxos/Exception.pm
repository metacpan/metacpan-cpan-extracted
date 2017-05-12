package Algorithm::Paxos::Exception;
{
  $Algorithm::Paxos::Exception::VERSION = '0.001';
}
use Moose;

# ABSTRACT: Simple Sugar for Throwable::Error

use Sub::Exporter::Util ();
use Sub::Exporter -setup =>
    { exports => [ throw => Sub::Exporter::Util::curry_method('throw'), ], };

extends qw(Throwable::Error);

sub throw {
    my $class = shift;
    return $class->new(@_);
}

1;


=pod

=head1 NAME

Algorithm::Paxos::Exception - Simple Sugar for Throwable::Error

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Algorithm::Paxos::Exception;
    ...
    
    throw "Something failed";

=head1 DESCRIPTION

This is a very thin sugar wrapper around L<Throwable::Error>.

=head1 FUNCTIONS

=head2 throw ( $message )

Throw a new exception 

=head1 SEE ALSO

=over 4

=item *

L<Throwable>

=back

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

