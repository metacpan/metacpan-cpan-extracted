#!/usr/bin/env perl
use 5.012;
use feature 'say';
use Clone();
use Benchmark qw/timethis timethese/;
use Clone::XS qw/clone fclone/;
use JSON::XS qw/encode_json decode_json/;
use Storable qw/dclone/;

say "START";

*cclone = *Clone::clone;

bench_clone();

sub bench_clone {
    my $prim1 = 1000;
    my $prim2 = 1.5;
    my $prim3 = "abcd";
    my $prim4 = "abcd" x 100000;
    
    my $arr_small = [1,2,3];
    my $arr_big   = [(1) x 10000];
    
    my $hash_small = {a => 1, b => 2.5, c => 3};
    my $hash_big   = {map {("abc$_" => $_)} 1..1000};
    
    my $mix_small = {a => 1, b => 2.5, c => [1,2,3], d => [1, {a => 1, b => 2}]};
    my $mix_big   = {map { ("abc$_" => $mix_small) } 1..1000};
    
    my $js = JSON::XS->new->utf8->allow_nonref;
    
    timethis(-1, sub { clone($mix_small) });
    
    timethese(-1, {
        state_json => sub { state $a = encode_json($mix_small); decode_json($a) },
        clone_xs   => sub { clone($mix_small) },
    });
    
    say "Clone::XS::clone";
    timethese(-1, {
        prim1 => sub { clone($prim1) },
        prim2 => sub { clone($prim2) },
        prim3 => sub { clone($prim3) },
        prim4 => sub { clone($prim4) },
        arrsm => sub { clone($arr_small) },
        arrbg => sub { clone($arr_big) },
        hashs => sub { clone($hash_small) },
        hashb => sub { clone($hash_big) },
        mixsm => sub { clone($mix_small) },
        mixbg => sub { clone($mix_big) },
    });
    
    
    say "Clone::XS::fclone";
    timethese(-1, {
        prim1 => sub { fclone($prim1) },
        prim2 => sub { fclone($prim2) },
        prim3 => sub { fclone($prim3) },
        prim4 => sub { fclone($prim4) },
        arrsm => sub { fclone($arr_small) },
        arrbg => sub { fclone($arr_big) },
        hashs => sub { fclone($hash_small) },
        hashb => sub { fclone($hash_big) },
        mixsm => sub { fclone($mix_small) },
        mixbg => sub { fclone($mix_big) },
    });
    
    say "Clone::clone";
    timethese(-1, {
        prim1 => sub { cclone([$prim1]) },
        prim2 => sub { cclone([$prim2]) },
        prim3 => sub { cclone([$prim3]) },
        prim4 => sub { cclone([$prim4]) },
        arrsm => sub { cclone($arr_small) },
        arrbg => sub { cclone($arr_big) },
        hashs => sub { cclone($hash_small) },
        hashb => sub { cclone($hash_big) },
        mixsm => sub { cclone($mix_small) },
        mixbg => sub { cclone($mix_big) },
    });
    
    say "Storable::dclone";
    timethese(-1, {
        prim1 => sub { dclone([$prim1]) },
        prim2 => sub { dclone([$prim2]) },
        prim3 => sub { dclone([$prim3]) },
        prim4 => sub { dclone([$prim4]) },
        arrsm => sub { dclone($arr_small) },
        arrbg => sub { dclone($arr_big) },
        hashs => sub { dclone($hash_small) },
        hashb => sub { dclone($hash_big) },
        mixsm => sub { dclone($mix_small) },
        mixbg => sub { dclone($mix_big) },
    });
    
    say "JSON::XS::encode/decode";
    timethese(-1, {
        prim1 => sub { $js->decode($js->encode($prim1)) },
        prim2 => sub { $js->decode($js->encode($prim2)) },
        prim3 => sub { $js->decode($js->encode($prim3)) },
        prim4 => sub { $js->decode($js->encode($prim4)) },
        arrsm => sub { decode_json(encode_json($arr_small)) },
        arrbg => sub { decode_json(encode_json($arr_big)) },
        hashs => sub { decode_json(encode_json($hash_small)) },
        hashb => sub { decode_json(encode_json($hash_big)) },
        mixsm => sub { decode_json(encode_json($mix_small)) },
        mixbg => sub { decode_json(encode_json($mix_big)) },
    });
    
    exit();
}

say "END";
