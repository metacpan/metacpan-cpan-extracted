#!/usr/bin/perl -w
use strict;
use Test::More tests=>15;  #qw(no_plan); #

BEGIN { use_ok( 'Class::DispatchToAll' ); }
require_ok( 'Class::DispatchToAll' );

=pod

Testing takes place using this complex class structure

              C
             /
   A    B  C::C
    \  / \ /
   A::A   D
       \ /
     testing

There are 6 methods, but not all are implemented in every class

=over

=item all

returns the Package Name

=item string

returns a string

=item hash

returns a HASHREF

=item array

returns an ARRAYREF

=item rand_num

returns a random number between 0 and 100

=item mulitply

returns the passed argument mulitplied by some hardcoded value

=cut



package A;

sub all { return __PACKAGE__ }
sub string { return "string" }
sub hash { return {foo=>'foo'} }
sub array { return ['a'] }
sub rand_num { return int(rand(100)) }


package A::A;
our @ISA=qw(A B);

sub all { return __PACKAGE__ }
sub multiply { return $_[1]*2 }
sub hash { return {foo=>'FOO'} }
sub array { return ['a::a'] }
sub rand_num { return int(rand(100)) }

package B;

sub all { return __PACKAGE__ }
sub string { return "another string" }
sub rand_num { return int(rand(100)) }
sub array { return ['b'] }

package C;

sub all { return __PACKAGE__ }
sub hash { return {bar=>'bar'} }
sub rand_num { return int(rand(100)) }
sub array { return ['c'] }

package C::C;
our @ISA=qw(C);

sub all { return __PACKAGE__ }
sub rand_num {  return int(rand(100)) }
sub array { return ['c::c'] }

package D;
our @ISA=qw(B C::C);

sub all { return __PACKAGE__ }
sub string { return "Cstring" }
sub mulitply { shift;return 10*shift; }
sub rand_num {  return int(rand(100)) }
sub array { return ['d'] }

package testing;
our @ISA=qw(A::A D);
use Class::DispatchToAll qw(dispatch_to_all);

sub new { return bless{},shift }
sub all { return __PACKAGE__ }
sub hash { return {base=>'class'} }
sub rand_num {  return int(rand(100)) }

package main;


my $t=testing->new;
ok(ref($t) eq "testing",'ref($t)');
$\="\n";
ok(join('',$t->dispatch_to_all('all')) eq "testingA::AABDBC::CC",'all');
ok(join(',',$t->dispatch_to_all('string')) eq "string,another string,Cstring,another string",'string');
ok($t->dispatch_to_all('multiply',undef,10)->[0]=20,'multiply 1');
ok($t->dispatch_to_all('multiply',undef,10)->[1]=20,'multiply 2');

# array merge
{
    my @v=$t->dispatch_to_all('array');
    my @array=();
    foreach (reverse @v) {
	push(@array,@$_);
    }
    ok($array[2] eq 'b','array merge 1');
    ok($array[4] eq 'b','array merge 2');
}
# array merge, no dups
{
    my @v=$t->dispatch_to_all('array');
    my @array=();
    my %seen;
    foreach (reverse @v) {
	next if $seen{join('',@$_)};
	$seen{join('',@$_)}=1;
	push(@array,@$_);
    }
    ok($array[2] eq 'b','array merge, no dups 1');
    ok($array[4] eq 'a','array merge, no dups 2');
}

# hash merge
{
    my @v=$t->dispatch_to_all('hash');
    my %hash=();
    foreach (reverse @v) {
	%hash=(%hash,%$_);
    }
    ok(keys %hash == 3,'hash merge 1');
    ok($hash{foo} eq "FOO",'hash merge 2');
}

# highest number, might fail because of rand
{
    my @nums=sort $t->dispatch_to_all('rand_num');
    ok(@nums == 8,'highest number 1');
    my $highest=pop(@nums);
    my $lowest=shift(@nums);
    ok($highest >= $lowest,'highest number 2');
}



