use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use t::Util;

use App::envfile;

sub test_parse_envfile {
    my %specs = @_;
    my ($input, $expects, $desc) = @specs{qw/input expects desc/};

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    runtest $desc => sub {
        my $tempfile = write_envfile($input);
        my $envf = App::envfile->new;
        my $got = $envf->parse_envfile($tempfile);
        is_deeply $got, $expects, 'parse ok';
    };
}

sub write_envfile {
    my $input = shift;
    my (undef, $filename) = tempfile DIR => tempdir CLEANUP => 1;
    open my $fh, '>', $filename or die "$filename: $!"; 
    print $fh $input;
    close $fh;
    return $filename;
}

test_parse_envfile(
    expects => { FOO => 'bar' },
    desc    => 'simple',
    input   => << 'ENV');
FOO=bar
ENV

test_parse_envfile(
    expects => { FOO => 'bar', HOGE => 'fuga' },
    desc    => 'multi',
    input   => << 'ENV');
FOO=bar
HOGE=fuga
ENV

test_parse_envfile(
    expects => { FOO => 'bar=baz' },
    desc    => 'contains split charctor',
    input   => << 'ENV');
FOO=bar=baz
ENV

test_parse_envfile(
    expects => { 'HOGE FUGA' => 'piyo' },
    desc    => 'key contains space',
    input   => << 'ENV');
HOGE FUGA=piyo
ENV

test_parse_envfile(
    expects => { 'FOO' => 'bar baz' },
    desc    => 'value contains space',
    input   => << 'ENV');
FOO=bar baz
ENV

test_parse_envfile(
    expects => { 'FOO' => 'bar baz' },
    desc    => 'spaces',
    input   => << 'ENV');
 FOO = bar baz  
ENV

test_parse_envfile(
    expects => { 'FOO' => 'bar' },
    desc    => 'skip comment',
    input   => << 'ENV');
# here is comment
FOO = bar 
ENV

test_parse_envfile(
    expects => { 'FOO' => 'bar' },
    desc    => 'skip white line',
    input   => << 'ENV');

FOO = bar 

ENV

runtest 'file not found' => sub {
    eval { App::envfile->new->parse_envfile('foo.bar') };
    ok $@, 'throw error';
};

done_testing;
