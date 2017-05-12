#!/usr/bin/env perl

use Test::More tests => 9;
use Test::Exception;

use strict;
use warnings;

use App::CmdDispatch::Table;

throws_ok { App::CmdDispatch::Table->new }          qr/Command definition is not a hashref/, 'No args';
throws_ok { App::CmdDispatch::Table->new( 'foo' ) } qr/Command definition is not a hashref/, 'Non-hashref arg';
throws_ok { App::CmdDispatch::Table->new( {} ) } qr/No commands specified/, 'Empty command hash';
throws_ok { App::CmdDispatch::Table->new( { noop => { code => sub {} } }, 'foo' ) } qr/Aliases .* not a hashref/, 'Non-hashref options';

# Bad commands
throws_ok { App::CmdDispatch::Table->new( { foo => 'aa' } ) }
    qr/'foo' is an invalid/, 'Command description not a hash';
throws_ok { App::CmdDispatch::Table->new( { foo => {} } ) }
    qr/'foo' has no handler/, 'No handler for foo';
throws_ok { App::CmdDispatch::Table->new( { foo => { code => 'ddd' } } ) }
    qr/'foo' has no handler/, 'Handler for foo is not code';

# Bad aliases
throws_ok { App::CmdDispatch::Table->new( { foo => { code => sub {} } }, { 'bar' => {} } ) }
    qr/'bar' mapping is not a string/, 'Alias points to a hash';
throws_ok { App::CmdDispatch::Table->new( { foo => { code => sub {} } }, { 'bar' => [] } ) }
    qr/'bar' mapping is not a string/, 'Alias points to an array';
