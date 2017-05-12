#!perl

# Test that the example in the POD is actually correct

use Test::More;
use strict;
use warnings;

if ( $] < 5.008 ) {
    plan skip_all => 'test requires Perl 5.8';
    exit;
}

plan tests => 10;

my %saved_bits;

use Data::Iterator::Hierarchical;

{
    package Data::Iterator::Hierarchical::Test::Pod::Parser;
    use base 'Pod::Parser';

    my $save_bit;

    sub command {
	my ($parser, $command, $paragraph, $line_num) = @_;
	my ($arg) = $paragraph =~ /(.*?)\s*$/m;
	$save_bit = "$command $arg";
    }

    sub verbatim {
	my ($parser, $paragraph, $line_num) = @_;
	push@{$saved_bits{$save_bit}} => $paragraph;
    }

    sub textblock {
	my ($parser, $paragraph, $line_num) = @_;
    }
}

my $module = $INC{'Data/Iterator/Hierarchical.pm'};

my $can_read = -r $module;

ok($can_read,'Can read module');

die unless $can_read;

{
    my $parser = Data::Iterator::Hierarchical::Test::Pod::Parser->new;
    $parser->parse_from_file($module);
}

ok(%saved_bits,'Found some POD sections in the module');

#use Data::Dumper; die Dumper \%saved_bits;

my $input = $saved_bits{'head2 input'}[0];

ok($input,'Found the input');

my $synopsis = $saved_bits{'head1 SYNOPSIS'};
ok($synopsis,'Found the SYNOPSIS');


my $expected = $saved_bits{'head2 output'}[0];

ok($expected,'Found expected output (in the POD)');

die unless $expected && $synopsis && $input;

my $code = "1";
for ( reverse @$synopsis ) {
    last if /->execute/;
    $code = "$_$code";
}

my $sth = [ map { my @r = /(\w+)/g; for (@r) { undef $_ if $_ eq 'NULL' }; @r ? \@r : () } split /\n/, $input ];

shift @$sth; # Remove header row


for ( $expected ) {
    ok(my ($indent) = /(\s+)/,'Got an indent on first line of expected output');
    tr/\r//d; # Ugly DOS encoded file on Unix?
    s/\n+\Z/\n/;
    ok(s/^//mg == s/^$indent//mg,'Removed indent from from expected output');
}

open my $output_fh, '>', \my $output or die $!;
select $output_fh;
eval $code or die $@;
select *STDOUT;
close $output_fh;
pass('Code executed');

ok($output,'Got some output');

# Uncomment this to get something to paste into POD
# print "---8<---\n$output---8<---\n";

is_deeply([$output =~ /^(.*)/mg],[$expected =~ /^(.*)/mg],'Got expected output');
