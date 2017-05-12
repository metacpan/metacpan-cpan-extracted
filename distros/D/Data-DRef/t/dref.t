#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 11, todo => [] }

use Data::DRef qw( :root_dref );

my $str = 'testing';
my $ary = [ '1', 'two', '3' ];
my $hash = { 'key' => 'value' };

set_value_for_root_dref('str', $str);
set_value_for_root_dref('ara', $ary);
set_value_for_root_dref('hash', $hash);

ok( get_value_for_root_dref('str') eq $str );

ok( get_value_for_root_dref('hash') eq $hash );
ok( get_value_for_root_dref('hash.key') eq $hash->{'key'} );

ok( get_value_for_root_dref('ara') eq $ary );
foreach ( 0 .. 2 ) {
  ok( get_value_for_root_dref("ara.$_") eq $ary->[$_] );
}

my $new_str = 'pokery';
set_value_for_root_dref('str', $new_str);
ok( get_value_for_root_dref('str') eq $new_str );

my $new_hashval = 'jiggery';
set_value_for_root_dref('hash.key', $new_hashval);
ok( get_value_for_root_dref('hash') eq $hash );
ok( get_value_for_root_dref('hash.key') eq $new_hashval );
ok( get_value_for_root_dref('hash.key') eq $hash->{'key'} );


__END__

print "- twiddling with the strings \n";

set_value_for_root_dref('wack', Wonky->new);
set_value_for_root_dref('wack.string', 'It\'s so wacky!');

print 'wack.string ', get_value_for_root_dref('wack.string') || '-none-', "\n";
print 'wack.magic ', get_value_for_root_dref('wack.magic') || '-none-', "\n";

package Wonky;

push @ISA, qw( Data::DRef::MethodBased );

sub new { bless {}; }

sub m_get_value_for_key ($$) {
  my $target = shift;
  my $dref = shift;
  return time() if ($dref eq 'magic');
  return Data::DRef::get($target, $dref);
}

__END__

# backslashed escapes don't work yet
# print joindref('escape', 'from', 'N.Y.C.') . "\n";
# print join(' - ', splitdref('escape.from.N\.Y\.C\.')) . "\n";

# print 'esca\\.pe ', get_value_for_root_dref('esca\\.pe'), "\n";

