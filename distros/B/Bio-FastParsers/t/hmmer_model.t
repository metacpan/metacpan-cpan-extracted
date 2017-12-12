#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::FastParsers;

my $class = 'Bio::FastParsers::Hmmer::Model';

check_model(
    file('test', 'hmmer_model_amino.hmm'),
    'amino',
    [qw(tmpfile_m0Dw_model 155 amino no no yes no yes 24 24.000000 1835300390)],
);

check_model(
    file('test', 'hmmer_model_nuc.hmm'),
    'nuc',
    [qw(tmpfile_ZRfE_model 471 612 DNA no no yes no yes 9 4.029785 3750044850)],
);

# NAME  tmpfile_m0Dw_model
# LENG  155
# ALPH  amino
# RF    no
# MM    no
# CONS  yes
# CS    no
# MAP   yes
# DATE  Mon Aug  8 16:49:55 2016
# NSEQ  24
# EFFN  24.000000
# CKSUM 1835300390
# STATS LOCAL MSV      -11.0100  0.71703
# STATS LOCAL VITERBI  -13.6896  0.71703
# STATS LOCAL FORWARD   -2.8011  0.71703

# NAME  tmpfile_ZRfE_model
# LENG  471
# MAXL  612
# ALPH  DNA
# RF    no
# MM    no
# CONS  yes
# CS    no
# MAP   yes
# DATE  Mon Aug  8 16:51:37 2016
# NSEQ  9
# EFFN  4.029785
# CKSUM 3750044850
# STATS LOCAL MSV      -11.2786  0.69993
# STATS LOCAL VITERBI  -17.9217  0.69993
# STATS LOCAL FORWARD   -4.4070  0.69993

sub check_model {
    my $infile      = shift;
    my $model_type  = shift;
    my $exp_model   = shift;

    ok my $model = $class->new( file => $infile ),
       'Hmmer::Model constructor';
    isa_ok $model, $class, $infile;

    my @model_attrs_amino   = qw(
            name    leng    alph    rf
                mm      cons    cs
            map     nseq    effn    cksum
    );

    my @model_attrs_nuc     = qw(
            name    leng    maxl    alph    rf
                mm      cons    cs
            map     nseq    effn    cksum
    );

    my @model_attrs = ($model_type eq 'amino') ? @model_attrs_amino : @model_attrs_nuc;
    cmp_deeply [ map { $model->$_ } @model_attrs ], $exp_model,
        'got exp values for all methods for model'
    ;

    return;
}

done_testing;
