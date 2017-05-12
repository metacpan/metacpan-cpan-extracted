use strict;
use warnings;
use Test::More;
use Data::DigestPath;

{
    my $dp = Data::DigestPath->new;
    isa_ok $dp, 'Data::DigestPath';
    is $dp->salt, '';
    is $dp->depth, 4;
    is $dp->delim, '/';
    is $dp->make_path, 'd/4/1/d/d41d8cd98f00b204e9800998ecf8427e';
    is $dp->make_path('mahalo'), 'f/a/b/1/fab13d2100ac06e7a9ddc683db6ca1ff';
    $dp->depth(0);
    is $dp->make_path, 'd41d8cd98f00b204e9800998ecf8427e';
    $dp->depth(6);
    is $dp->make_path, 'd/4/1/d/8/c/d41d8cd98f00b204e9800998ecf8427e';
    $dp->salt("aloha");
    is $dp->make_path, 'd/3/4/b/6/c/d34b6c59ef0497d8ff246abd1049352e';
    is $dp->make_path('', 4), 'd/3/4/b/6/c/d34b';
    is $dp->make_path('mahalo', 4), '8/5/2/2/e/0/8522'; # with salt
    $dp->delim('-');
    is $dp->make_path, 'd-3-4-b-6-c-d34b6c59ef0497d8ff246abd1049352e';
    $dp->trancate(1);
    is $dp->make_path, 'd-3-4-b-6-c-59ef0497d8ff246abd1049352e';
    is $dp->make_path('', 5), 'd-3-4-b-6-c-59ef0';
    is $dp->make_path('pama', 6), 'd-e-2-4-f-e-275531';
}

done_testing;
