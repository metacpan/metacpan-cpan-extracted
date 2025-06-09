package DBIx::QuickORM::Role::STH;
use strict;
use warnings;

our $VERSION = '0.000013';

use Carp qw/croak/;

use Role::Tiny;

requires qw{
    connection
    source
    dialect
    only_one
    got_result
    result
    ready
    done
    set_done
    clear
    next
};

sub cancel_supported { 0 }

sub cancel { croak "cancel() is not supported" }

1;
