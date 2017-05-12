#!perl

use strict;
use warnings;

use Test::More tests => 25;

use CPANPLUS::Dist::Gentoo::Atom;

sub A () { 'CPANPLUS::Dist::Gentoo::Atom' }

my $no_info        = qr/^Not enough information/;
my $no_category    = qr/^Category unspecified/;
my $range_no_ver   = qr/^Range atoms require a valid version/;
my $cant_parse_ver = qr/^Couldn't parse version string/;

sub inv { qr/^Invalid \Q$_[0]\E/ }

my $a0 = { category => 'test',  name => 'a' };
my $a1 = { category => 'test',  name => 'a',   version => '1.0' };
my $a2 = { category => 'test+', name => 'a+b', version => '1.2.3' };

my $v0 = bless { }, 'CPANPLUS::Dist::Gentoo::Test::FakeVersion';
my $v1 = CPANPLUS::Dist::Gentoo::Version->new('0.1.2-r3');

my @tests = (
 [ { }                     => $no_info ],
 [ { category => 'test' }  => $no_info ],
 [ { name => 'a'  }        => $no_category ],

 [ { category => '',      name => 'a'  } => inv('category') ],
 [ { category => 'test$', name => 'a'  } => inv('category') ],
 [ { category => 'test',  name => ''   } => inv('name')     ],
 [ { category => 'test',  name => 'a$' } => inv('name')     ],

 [ $a0                     => $a0 ],
 [ { %$a0, range => ''   } => { %$a0, range => '' } ],
 [ { %$a0, range => '<=' } => $range_no_ver ],

 [ $a1                      => { %$a1, range => '>=' } ],
 [ { %$a1, version => $v0 } => $cant_parse_ver ],
 [ { %$a1, version => $v1 } => { %$a1, range => '>=', version => '0.1.2-r3' } ],
 [ { %$a1, range => '<>' }  => inv('range'), ],
 [ { %$a1, range => '<=' }  => { %$a1, range => '<=' } ],

 [ { atom => 'test/a' }       => $a0 ],
 [ { atom => 'test/a-1.0' }   => { %$a1, range => '>=' } ],
 [ { atom => '=test/a-1.0' }  => { %$a1, range => '=' } ],
 [ { atom => '=<test/a-1.0' } => inv('atom') ],
 [ { atom => '>=test/a' }     => $range_no_ver ],

 [ { ebuild => undef }                      => inv('ebuild') ],
 [ { ebuild => '/wat/test/a/a.ebuild' }     => inv('ebuild') ],
 [ { ebuild => '/wat/test/a/a-1.0.ebuild' } => { %$a1, range => '>=' } ],
 [ { ebuild => '/wat/test/a/b-1.0.ebuild' } => inv('ebuild') ],
 [ { ebuild => '/wat/test+/a+b/a+b-1.2.3.ebuild' } => { %$a2, range => '>=' } ],
);

my @fields = qw<range category name version ebuild>;

for my $t (@tests) {
 my ($args, $exp) = @$t;

 my ($meth, @args);
 if (exists $args->{ebuild}) {
  $meth = 'new_from_ebuild';
  @args = ($args->{ebuild});
 } else {
  $meth = 'new';
  @args = %$args;
 }

 my $atom = eval { A->$meth(@args) };
 my $err  = $@;

 if (ref $exp eq 'Regexp') {
  like $err, $exp;
 } elsif ($err) {
  fail $err;
 } else {
  $exp = { %$exp };
  for (@fields) {
   next if exists $exp->{$_};
   $exp->{$_} = ($_ eq 'ebuild' and exists $args->{ebuild})
                ? $args->{ebuild}
                : undef;
  }
  is_deeply {
   map { my $val = $atom->$_; $_ => (defined $val ? "$val" : undef) } @fields
  }, $exp;
 }
}
