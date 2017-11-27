# NAME

Bio::SeqHash - get one or more sequences from a FASTA file quickly.

# VERSION

version 0.1.4

# SYNOPSIS

    # use it in object-oriented way;
    
    use Bio::SeqHash;
    my $obj = Bio::SeqHash->new(file => "test.fa");
    my $hs = $obj->fa2hs; # get a HashRef coverted from the test.fa
    my $seq = $obj->get_seq("seq_id"); # get the sequence of "seq_id"(only the sequence)
    my $seq_fa = $obj->get_id_seq("seq_id"); # get the sequence of "seq_id"(in the FASTA format)
    $obj->get_seqs_batch('id_list.txt', 'output.fa');  # extract specified sequence to output file

    # use it in Common mode;

    use Bio::SeqHash "fa2hs";
    my $hs = fa2hs("in.fa");

# DESCRIPTION

Currently, there do have some modules that can operate the FASTA file such as Bio::SeqIO, 
But it only provide some basic operation to obtain the information about sequence. In my daily work,
I still have to write some repetitive code. So this module is write to perform a deeper wrapper for operating FASTA file
Notice: this module is not suitable for the FASTA file that is extremble big.

# METHODS

## fa2hs

    Convert a fasta file into a HashRef variable. If the C<file> parameter have been passed
    into during the process of new, here needs no parameter, otherwise you have to provide
    the path of a fasta file.

## get\_id\_seq

    get a sequence by a id in FASTA format

## get\_seq

    get a sequence by a id

## get\_seqs\_batch

    extract specified gene list from input file

# AUTHOR

Yan Xueqing <yanxueqing621@163.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
