#!/usr/bin/env perl
use warnings;
use strict;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Test::More tests => 4;
use YAML;

# from our test lib:
use Age;
use Unprepared;
use base 'Data::Comparable';
use constant SKIP_COMPARABLE_KEYS => ('rank');

sub prepare_comparable {
    my $self = shift;
    $self->SUPER::prepare_comparable(@_);
    $self->{prepared} = 1;
}
sub new { bless {}, shift }
my $age = Age->new;
$age->{age} = 22;
my $obj = main->new;
$obj->{firstname}  = 'Se-tol';
$obj->{lastname}   = 'Yi';
$obj->{rank}       = '9p';
$obj->{age}        = $age;
$obj->{a_hash}     = { foo => 1, bar => 2 };
$obj->{an_array}   = [ 3, 5, 8, 13 ];
$obj->{unprepared} = Unprepared->new;

# dump_comparable, default
my %expected = (
    firstname  => 'Se-tol',
    lastname   => 'Yi',
    prepared   => 1,
    age        => '22 years',
    a_hash     => { foo => 1, bar => 2 },
    an_array   => [ 3, 5, 8, 13 ],
    unprepared => Unprepared->new,
);
my $dump = $obj->dump_comparable;
$dump =~ s/^\$VAR1 = /\$restored = /;
my $restored;
eval $dump or die "can't undump:\n$dump";
is_deeply($restored, \%expected, 'dump_comparable');

# yaml_dump_comparable, default
$dump     = $obj->yaml_dump_comparable;
$restored = Load($dump);
is_deeply($restored, \%expected, 'yaml_dump_comparable');

# dump_comparable, skip bless
%expected = (
    firstname => 'Se-tol',
    lastname  => 'Yi',
    prepared  => 1,
    age       => '22 years',
    a_hash    => { foo => 1, bar => 2 },
    an_array  => [ 3, 5, 8, 13 ],
    unprepared => { value => 123 },
);
$dump = $obj->dump_comparable(1);
$dump =~ s/^\$VAR1 = /\$restored = /;
eval $dump or die "can't undump:\n$dump";
is_deeply($restored, \%expected, 'dump_comparable, skip bless');

# yaml_dump_comparable, skip_bless
$dump     = $obj->yaml_dump_comparable(1);
$restored = Load($dump);
is_deeply($restored, \%expected, 'yaml_dump_comparable, skip bless');
