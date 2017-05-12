#!/usr/bin/env perl

use Test::More tests => 5;
use Test::Exception;

use strict;
use warnings;

use App::CmdDispatch::Help;

# Mock the creation of the dispatch object.
my $app = bless {}, 'App::CmdDispatch';

throws_ok { App::CmdDispatch::Help->new( $app, 'commands' ); } qr/not a hashref/,
    'commands not hash';

throws_ok { App::CmdDispatch::Help->new( $app, undef ); } qr/not a hashref/,
    'commands undef';

throws_ok { App::CmdDispatch::Help->new( $app, {} ); } qr/No commands/,
    'empty commands hash';

throws_ok { App::CmdDispatch::Help->new( $app, { noop => { code => sub {} } }, 'config' ); } qr/Config .* not a hashref/,
    'config not hash';

throws_ok { App::CmdDispatch::Help->new( {}, { noop => { code => sub {} } } ); } qr/Invalid owner object/,
    'Owner object wrong type';
