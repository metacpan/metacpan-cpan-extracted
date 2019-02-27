package Data::Recursive::Encode;
use 5.008001;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.07';

use Encode ();
use Carp ();
use Scalar::Util qw(blessed refaddr);
use B;

our $DO_NOT_PROCESS_NUMERIC_VALUE = 0;

sub _apply {
    my $code = shift;
    my $seen = shift;

    my @retval;
    for my $arg (@_) {
        if(my $ref = ref $arg){
            my $refaddr = refaddr($arg);
            my $proto;

            if(defined($proto = $seen->{$refaddr})){
                 # noop
            }
            elsif($ref eq 'ARRAY'){
                $proto = $seen->{$refaddr} = [];
                @{$proto} = _apply($code, $seen, @{$arg});
            }
            elsif($ref eq 'HASH'){
                $proto = $seen->{$refaddr} = {};
                %{$proto} = _apply($code, $seen, %{$arg});
            }
            elsif($ref eq 'REF' or $ref eq 'SCALAR'){
                $proto = $seen->{$refaddr} = \do{ my $scalar };
                ${$proto} = _apply($code, $seen, ${$arg});
            }
            else{ # CODE, GLOB, IO, LVALUE etc.
                $proto = $seen->{$refaddr} = $arg;
            }

            push @retval, $proto;
        }
        else{
            push @retval, defined($arg) && (! $DO_NOT_PROCESS_NUMERIC_VALUE || ! _is_number($arg)) ? $code->($arg) : $arg;
        }
    }

    return wantarray ? @retval : $retval[0];
}

sub decode {
    my ($class, $encoding, $stuff, $check) = @_;
    $encoding = Encode::find_encoding($encoding)
        || Carp::croak("$class: unknown encoding '$encoding'");
    $check ||= 0;
    _apply(sub { $encoding->decode($_[0], $check) }, {}, $stuff);
}

sub encode {
    my ($class, $encoding, $stuff, $check) = @_;
    $encoding = Encode::find_encoding($encoding)
        || Carp::croak("$class: unknown encoding '$encoding'");
    $check ||= 0;
    _apply(sub { $encoding->encode($_[0], $check) }, {}, $stuff);
}

sub decode_utf8 {
    my ($class, $stuff, $check) = @_;
    my $cb = @_==3
        ? sub { Encode::decode_utf8($_[0], $check) }
        : sub { Encode::decode_utf8($_[0]) };
    _apply($cb, {}, $stuff);
}

sub encode_utf8 {
    my ($class, $stuff) = @_;
    _apply(\&Encode::encode_utf8, {}, $stuff);
}

sub from_to {
    my ($class, $stuff, $from_enc, $to_enc, $check) = @_;
    @_ >= 4 or Carp::croak("Usage: $class->from_to(OCTET, FROM_ENC, TO_ENC[, CHECK])");
    $from_enc = Encode::find_encoding($from_enc)
        || Carp::croak("$class: unknown encoding '$from_enc'");
    $to_enc = Encode::find_encoding($to_enc)
        || Carp::croak("$class: unknown encoding '$to_enc'");
    my $cb = @_==5
        ? sub { Encode::from_to($_[0], $from_enc, $to_enc, $check) }
        : sub { Encode::from_to($_[0], $from_enc, $to_enc) };
    _apply($cb, {}, $stuff);
    return $stuff;
}

sub _is_number {
    my $value = shift;
    return 0 unless defined $value;

    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;
    return $flags & ( B::SVp_IOK | B::SVp_NOK ) && !( $flags & B::SVp_POK ) ? 1 : 0;
}

1;
__END__

=encoding utf8

=head1 NAME

Data::Recursive::Encode - Encode/Decode Values In A Structure

=head1 SYNOPSIS

    use Data::Recursive::Encode;

    Data::Recursive::Encode->decode('euc-jp', $data);
    Data::Recursive::Encode->encode('euc-jp', $data);
    Data::Recursive::Encode->decode_utf8($data);
    Data::Recursive::Encode->encode_utf8($data);
    Data::Recursive::Encode->from_to($data, $from_enc, $to_enc[, $check]);

=head1 DESCRIPTION

Data::Recursive::Encode visits each node of a structure, and returns a new
structure with each node's encoding (or similar action). If you ever wished
to do a bulk encode/decode of the contents of a structure, then this
module may help you.

=head1 VALIABLES

=over 4

=item $Data::Recursive::Encode::DO_NOT_PROCESS_NUMERIC_VALUE

do not process numeric value.

    use JSON;
    use Data::Recursive::Encode;

    my $data = { int => 1 };

    is encode_json( Data::Recursive::Encode->encode_utf8($data) ); #=> '{"int":"1"}'

    local $Data::Recursive::Encode::DO_NOT_PROCESS_NUMERIC_VALUE = 1;
    is encode_json( Data::Recursive::Encode->encode_utf8($data) ); #=> '{"int":1}'

=back

=head1 METHODS

=over 4

=item decode

    my $ret = Data::Recursive::Encode->decode($encoding, $data, [CHECK]);

Returns a structure containing nodes which are decoded from the specified
encoding.

=item encode

    my $ret = Data::Recursive::Encode->encode($encoding, $data, [CHECK]);

Returns a structure containing nodes which are encoded to the specified
encoding.

=item decode_utf8

    my $ret = Data::Recursive::Encode->decode_utf8($data, [CHECK]);

Returns a structure containing nodes which have been processed through
decode_utf8.

=item encode_utf8

    my $ret = Data::Recursive::Encode->encode_utf8($data);

Returns a structure containing nodes which have been processed through
encode_utf8.

=item from_to

    my $ret = Data::Recursive::Encode->from_to($data, FROM_ENC, TO_ENC[, CHECK]);

Returns a structure containing nodes which have been processed through
from_to.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

gfx

=head1 SEE ALSO

This module is inspired from L<Data::Visitor::Encode>, but this module depended to too much modules.
I want to use this module in pure-perl, but L<Data::Visitor::Encode> depend to XS modules.

L<Unicode::RecursiveDowngrade> does not supports perl5's Unicode way correctly.

=head1 LICENSE

Copyright (C) 2010 Tokuhiro Matsuno All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
