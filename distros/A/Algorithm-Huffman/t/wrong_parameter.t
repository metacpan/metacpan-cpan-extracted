#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::Huffman;
use Test::Exception;
use Test::More tests => 10;

throws_ok {
    Algorithm::Huffman->new();    
} qr/undefined counting hash/i,
  "->new()";
  
throws_ok {
    Algorithm::Huffman->new(undef); 
} qr/undefined counting hash/i,
  "->new(undef)";
  
throws_ok {
    Algorithm::Huffman->new(\undef);    
} qr/not (a )?hash ref/i,
  "->new(\\undef)";
  
throws_ok {
    Algorithm::Huffman->new([]);    
} qr/not (a )?hash ref/i,
  "->new([])";

throws_ok {
    Algorithm::Huffman->new({});
} qr/counting hash must have at least (two|2) keys/i,
  "->new({})";

throws_ok {
    Algorithm::Huffman->new({a => 1});
} qr/counting hash must have at least (two|2) keys/i,
  "->new({a => 1})";
  
lives_ok {
    Algorithm::Huffman->new({a => 1, b => 1});    
} "->new({a => 1, b => 1})";

throws_ok {
    Algorithm::Huffman->new({a => 1, b => 1, c => 'one'})
} qr/number/i,
  "->new({a => 1, b => 1, c => one})";
  
lives_ok {
    Algorithm::Huffman->new({a => 1, b => 1, c => 0})
} "->new({a => 1, b => 1, c => 0})";  

throws_ok {
    Algorithm::Huffman->new({a => 1, b => 1, c => -1})
} qr/positive/i,
  "->new({a => 1, b => 1, c => -1})";
