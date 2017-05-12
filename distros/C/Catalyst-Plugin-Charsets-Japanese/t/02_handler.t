#!/usr/bin/perl -w
use strict;
use Test::More qw/no_plan/;
use Catalyst::Plugin::Charsets::Japanese;
my $handler = undef;
ok( $handler = Catalyst::Plugin::Charsets::Japanese::Handler->new );
isa_ok( $handler, "Catalyst::Plugin::Charsets::Japanese::Handler" );

my $inner = undef;

ok( $handler->set_inner("UTF-8") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "UTF-8");
is( $inner->abbreviation, "utf8");
is( $inner->method, "utf8");

ok( $handler->set_inner("EUC-JP") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "EUC-JP");
is( $inner->abbreviation, "euc");
is( $inner->method, "euc");

ok( $handler->set_inner("Shift_JIS") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "Shift_JIS");
is( $inner->abbreviation, "sjis");
is( $inner->method, "sjis");

ok( $handler->set_inner("utf-8") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "UTF-8");
is( $inner->abbreviation, "utf8");
is( $inner->method, "utf8");

ok( $handler->set_inner("euc-jp") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "EUC-JP");
is( $inner->abbreviation, "euc");
is( $inner->method, "euc");

ok( $handler->set_inner("shift_jis") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "Shift_JIS");
is( $inner->abbreviation, "sjis");
is( $inner->method, "sjis");

ok( $handler->set_inner("utf8") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "UTF-8");
is( $inner->abbreviation, "utf8");
is( $inner->method, "utf8");

ok( $handler->set_inner("euc") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "EUC-JP");
is( $inner->abbreviation, "euc");
is( $inner->method, "euc");

ok( $handler->set_inner("sjis") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "Shift_JIS");
is( $inner->abbreviation, "sjis");
is( $inner->method, "sjis");

ok( $handler->set_inner("sjis") );
ok( $inner = $handler->in );
isa_ok( $inner, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $inner->name, "Shift_JIS");
is( $inner->abbreviation, "sjis");
is( $inner->method, "sjis");

my $outer = undef;

ok( $handler->set_outer("UTF-8") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "UTF-8");
is( $outer->abbreviation, "utf8");
is( $outer->method, "utf8");

ok( $handler->set_outer("EUC-JP") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "EUC-JP");
is( $outer->abbreviation, "euc");
is( $outer->method, "euc");

ok( $handler->set_outer("Shift_JIS") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "Shift_JIS");
is( $outer->abbreviation, "sjis");
is( $outer->method, "sjis");

ok( $handler->set_outer("utf-8") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "UTF-8");
is( $outer->abbreviation, "utf8");
is( $outer->method, "utf8");

ok( $handler->set_outer("euc-jp") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "EUC-JP");
is( $outer->abbreviation, "euc");
is( $outer->method, "euc");

ok( $handler->set_outer("shift_jis") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "Shift_JIS");
is( $outer->abbreviation, "sjis");
is( $outer->method, "sjis");

ok( $handler->set_outer("utf8") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "UTF-8");
is( $outer->abbreviation, "utf8");
is( $outer->method, "utf8");

ok( $handler->set_outer("euc") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "EUC-JP");
is( $outer->abbreviation, "euc");
is( $outer->method, "euc");

ok( $handler->set_outer("sjis") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "Shift_JIS");
is( $outer->abbreviation, "sjis");
is( $outer->method, "sjis");

ok( $handler->set_outer("sjis") );
ok( $outer = $handler->out );
isa_ok( $outer, "Catalyst::Plugin::Charsets::Japanese::Charset" );
is( $outer->name, "Shift_JIS");
is( $outer->abbreviation, "sjis");
is( $outer->method, "sjis");

