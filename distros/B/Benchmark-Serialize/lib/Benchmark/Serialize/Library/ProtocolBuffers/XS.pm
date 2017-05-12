package Benchmark::Serialize::Library::ProtocolBuffers::XS;

use strict;
use warnings;

use Benchmark::Serialize::Library;
use Scalar::Util qw(blessed);

=head1 NAME

Benchmark::Serialize::Library::ProtocolBuffers::XS - Protobuf/XS benchmarks

=head1 SYNOPSIS

    # Register tests on use time
    use Benchmark::Serializer::Library::ProtocolBuffers::XS qw(Person);

    # Register tests on run time
    Benchmark::Serializer::Library::ProtocolBuffers::XS->register('Person');
    

=head1 DESCRIPTION

This module adds benchmarks to L<Benchmark::Serialize> for serializers created
with L<Protocol Buffers for Perl/XS|http://code.google.com/p/protobuf-perlxs/>.

=head1 Benchmark tags

All benchmarks created by this module will have the benchmark tag
C<:ProtocolBuffers>

=cut 

sub import {
    my $pkg     = shift;
    my @imports = @_;

    for my $class (@imports) {
        Benchmark::Serialize::Library->register(
            $class => {
                deflate         => sub { $class->new($_[0])->pack },
                inflate         => sub { $class->new($_[0])->to_hashref },
                ProtocolBuffers => 1,
            }
        );
    }
}

sub register {
    my $pkg = shift;

    $pkg->import( @_ );
}

=head1 SEE ALSO

L<http://code.google.com/p/protobuf-perlxs/>

=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-serialize at
rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Serialize>.  I will
be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Peter Makholm.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1;
