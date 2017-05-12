# $Id$

package Test::Data::Visitor::Encode;
use strict;
use warnings;
use Data::Visitor::Callback;
use Encode qw(encode decode encode_utf8 decode_utf8 is_utf8 FB_CROAK);
use Test::More;
use Test::Exception;

sub import {
    my $caller = caller(1);

    foreach my $method qw(decode_ok encode_ok decode_utf8_ok encode_utf8_ok utf8_on_ok utf8_off_ok) {
        no strict 'refs';
        *{"${caller}::${method}"} = \&{$method};
    }
}

sub encode_ok {
    my ($enc, $data, $title) = @_;

    lives_ok {
        my $dve = Data::Visitor::Encode->new();
        $dve->encode($enc, $data);
    } "encode() doesn't croak";

    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        object => "visit_ref",
        plain_value => sub {
            my $caller;
            my $i = 1;
            do {
                $caller = caller($i++);
            } while ($caller =~ /Data::Visitor/);

            local $Test::Builder::Level = $Test::Builder::Level + $i;
            lives_ok { decode($enc, $_[1], &FB_CROAK) }
                encode_utf8("value '" . (eval { decode($enc, $_[1]) } || '(fail)') . "' encodes to '$enc' for '$title'")
            ;
        }
    )->visit($data);
}

sub decode_ok {
    my ($enc, $data, $title) = @_;
    my $dve = Data::Visitor::Encode->new();
    $dve->decode($enc, $data);

    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        object => "visit_ref",
        plain_value => sub {
            my $caller;
            my $i = 1;
            do {
                $caller = caller($i++);
            } while ($caller =~ /Data::Visitor/);

            local $Test::Builder::Level = $Test::Builder::Level + $i;
            lives_ok { encode($enc, $_[1], &FB_CROAK) }
                encode_utf8("value '$_[1]' decodes from '$enc' for '$title'")
            ;
        }
    )->visit($data);
}

sub encode_utf8_ok {
    my ($data, $title) = @_;

    lives_ok {
        my $dve = Data::Visitor::Encode->new();
        $dve->encode_utf8($data);
    } "encode_utf8 ok";

    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        object => "visit_ref",
        plain_value => sub {
            my $caller;
            my $i = 1;
            do {
                $caller = caller($i++);
            } while ($caller =~ /Data::Visitor/);

            local $Test::Builder::Level = $Test::Builder::Level + $i;
            ok(!is_utf8($_[1], 1), "value $_[1] is not utf8 for '$title'");
        }
    )->visit($data);
}

sub decode_utf8_ok {
    my ($data, $title) = @_;

    lives_ok {
        my $dve = Data::Visitor::Encode->new();
        $dve->decode_utf8($data);
    } "decode_utf8 ok";

    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        object => "visit_ref",
        plain_value => sub {
            my $caller;
            my $i = 1;
            do {
                $caller = caller($i++);
            } while ($caller =~ /Data::Visitor/);

            local $Test::Builder::Level = $Test::Builder::Level + $i;
            ok(is_utf8($_[1], 1), encode_utf8("value $_[1] is utf8 for '$title'"));
        }
    )->visit($data);
}

sub utf8_on_ok {
    my ($data, $title) = @_;

    lives_ok {
        my $dve = Data::Visitor::Encode->new();
        $dve->utf8_on($data);
    } "utf8_on ok";

    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        object => "visit_ref",
        plain_value => sub {
            my $caller;
            my $i = 1;
            do {
                $caller = caller($i++);
            } while ($caller =~ /Data::Visitor/);

            local $Test::Builder::Level = $Test::Builder::Level + $i;
            ok(is_utf8($_[1], 1), encode_utf8("value $_[1] is utf8 for '$title'"));
        }
    )->visit($data);
}

sub utf8_off_ok {
    my ($data, $title) = @_;

    lives_ok {
        my $dve = Data::Visitor::Encode->new();
        $dve->utf8_off($data);
    } "utf8_off ok";

    Data::Visitor::Callback->new(
        ignore_return_values => 1,
        object => "visit_ref",
        plain_value => sub {
            my $caller;
            my $i = 1;
            do {
                $caller = caller($i++);
            } while ($caller =~ /Data::Visitor/);

            local $Test::Builder::Level = $Test::Builder::Level + $i;
            ok(! is_utf8($_[1], 1), "value $_[1] is NOT utf8 for '$title'");
        }
    )->visit($data);
}

1;
