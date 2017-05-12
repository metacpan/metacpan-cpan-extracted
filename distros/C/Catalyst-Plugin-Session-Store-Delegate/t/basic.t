#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use File::Temp;
use File::Spec;

use Test::More;

my %mocks;
my @mocks;

{
    package MockDelegate;
    use base qw/Class::Accessor::Fast/;
    BEGIN { __PACKAGE__->mk_accessors(qw/session expires flash/) };

    sub flush { $_[0]{flushed}++ }
}

use Catalyst::Plugin::Session::Test::Store (
    extra_tests => 4,
    backend     => "Delegate",
    config      => {
        model => 'Session',
        get_delegate => sub {
            my ( $model, $id ) = @_;
            
            if ( my $mock = $mocks{$id} ) {
                $mock->{reloaded}++;
                return $mock;
            } else {
                my $mock = MockDelegate->new({});
                push @mocks, $mock;
                return $mocks{$id} = $mock;
            }
        },
    },
);

is(
    (($_->{flushed}||0) - ($_->{reloaded}||0)),
    1,
    "object flushed an even number of times"
) for @mocks;
