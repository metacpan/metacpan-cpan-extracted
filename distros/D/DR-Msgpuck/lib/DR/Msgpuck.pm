use 5.014002;
use strict;
use warnings;

package DR::Msgpuck;
use DR::Msgpuck::Bool;
require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(msgpack msgunpack msgunpack_utf8 msgunpack_check);
our @EXPORT = @EXPORT_OK;
our $VERSION = '0.04';

require XSLoader;
XSLoader::load('DR::Msgpuck', $VERSION);

1;
__END__

=head1 NAME

DR::Msgpuck - Perl bindings for
L<msgpuck|https://github.com/tarantool/msgpuck>.

=head1 SYNOPSIS

    use DR::Msgpuck;
    my $blob = msgpack { a => 'b', c => 'd' };
    my $object = msgunpack $blob;

    # all $object's string are utf8
    my $object = msgunpack_utf8 $blob;

    # length of the first msgpack object in your buffer
    if (my $len = msgunpack_check $buffer) {
        my $o = msgunpack $buffer;
        substr $buffer, 0, $len, '';
        ...
    }

=head1 DESCRIPTION


L<msgpuck|https://github.com/tarantool/msgpuck> is a simple
and efficient L<msgpack|https://github.com/msgpack/msgpack/blob/master/spec.md>
binary serialization library in a self-contained header file.

=head2 Boolean

Msgpack protocol provides C<true>/C<false> values.
They are unpacks to L<DR::Msgpuck::True> and L<DR::Msgpuck::False> instances.

=head2 Injections

If You have an object that can msgpack by itself, provide method C<TO_MSGPACK>
in it. Example:

    package MyExt;
    sub new {
        my ($class, $value) = @_;
        bless \$value => ref($class) || $class;
    }

    sub TO_MSGPACK {
        my ($self) = @_;
        pack 'CC', 0xA1, substr $$self, 0, 1;
    }


    package main;
    use MyStr;

    my $object = {
        a   => 'b',
        c   => 'd',
        e   => MyExt->new('f')
    };
    my $blob = msgpack($object);
    ...

=head1 METHODS

=head2 msgpack

Packs perl object and returns msgpack's blob.
    
=head3 example

    use DR::Msgpuck;
    my $blob = msgpack { a => 'b', c => 'd' };

=head2 msgunpack

Unpacks perl object (croaks if input buffer is invalid).


=head3 example

    use DR::Msgpuck;
    my $object = msgunpack $blob;


=head2 msgunpack_utf8

Unpacks perl object. All strings will be encoded to C<utf-8>.
    
=head3 example

    use DR::Msgpuck;

    # all $object's string are utf8
    my $object = msgunpack_utf8 $blob;

=head2 msgunpack_check

Checks input buffer, returns length of the first msgpack object in the buffer.
    
=head3 example

    use DR::Msgpuck;

    # length of the first msgpack object in your buffer
    if (my $len = msgunpack_check $buffer) {
        my $o = msgunpack $buffer;
        substr $buffer, 0, $len, '';
        ...
    }

=head1 BENCHMARKS

    Packing benchmark
			 Rate data-messagepack       dr-msgpuck
    data-messagepack 211416/s               --             -31%
    dr-msgpuck       306279/s              45%               --

    Unpacking benchmark 
			 Rate       dr-msgpuck data-messagepack
    dr-msgpuck       191681/s               --              -7%
    data-messagepack 206313/s               8%               --


=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
