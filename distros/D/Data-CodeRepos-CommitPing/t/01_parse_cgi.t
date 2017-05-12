use strict;
use warnings;
use Test::Base;
use File::Spec;
use YAML;

use Data::CodeRepos::CommitPing;

plan tests => 1*blocks;

filters {
    input    => [qw/get_revision/],
    expected => [qw/exfilt/],
};

sub exfilt { '['.$_[0].']' }

sub get_revision {
    my $path = File::Spec->catfile('t', 'revs', shift);
    open my $fh, '<', $path or die $!;
    my $hash = bless {
        yaml => do { local $/; <$fh> },
    }, __PACKAGE__;
    my $ret = Data::CodeRepos::CommitPing->new($hash)->revision;
    return "[$ret]";
}

sub param { $_[0]->{$_[1]} }

run_is input => 'expected';

__END__

===
--- input: 9734.txt
--- expected: 9734

===
--- input: 9741.txt
--- expected: 9741

===
--- input: 9749.txt
--- expected: 9749

===
--- input: 9754.txt
--- expected: 9754

===
--- input: 9879.txt
--- expected: 9879

===
--- input: 9895.txt
--- expected: 9895
