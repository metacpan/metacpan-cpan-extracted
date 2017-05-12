# ABSTRACT: Bubblegum Wrapper around Data Dumping
package Bubblegum::Wrapper::Dumper;

use 5.10.0;
use Bubblegum::Class;

use Data::Dumper ();

extends 'Bubblegum::Object::Instance';

our $VERSION = '0.45'; # VERSION

sub decode {
    my $self = shift;
    return eval $self->data;
}

sub encode {
    my $self = shift;
    return Data::Dumper->new([$self->data])
        ->Indent(0)->Sortkeys(1)->Terse(1)->Dump;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Wrapper::Dumper - Bubblegum Wrapper around Data Dumping

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use Bubblegum;

    my $data = {1..3,{4,{5,6,7,{8,9,10,11}}}};

    my $string  = $data->dumper->encode;
    my $hashref = $string->dumper->decode;

=head1 DESCRIPTION

L<Bubblegum::Wrapper::Dumper> is a Bubblegum wrapper which provides the ability
to endcode/decode Perl data structures. It is not necessary to use this module
as it is loaded automatically by the L<Bubblegum> class.

=head1 METHODS

=head2 decode

The decode method deserializes the stringified Perl data structure using the
L<Data::Dumper> module.

=head2 encode

The encode method serializes the Perl data structure using the L<Data::Dumper>
module with the following options; Indent=0, Sortkeys=1, and Terse=1.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
