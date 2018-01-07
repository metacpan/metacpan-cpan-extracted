package Bio::FastParsers::Hmmer::Standard;
# ABSTRACT: front-end class for standard HMMER parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::Standard::VERSION = '0.173640';
use Moose;
use namespace::autoclean;

# TODO: check if autodie is actually needed here
use autodie;

use List::AllUtils qw(indexes firstidx mesh);

extends 'Bio::FastParsers::Base';

use Bio::FastParsers::Constants qw(:files);
use aliased 'Bio::FastParsers::Hmmer::Standard::Iteration';


# public attributes (inherited)


# private attributes

has '_iterations'  => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Bio::FastParsers::Hmmer::Standard::Iteration]',
    writer  => '_set_iterations',
    handles => {
         next_iteration  => 'shift',
          get_iteration  => 'get',
          all_iterations => 'elements',
        count_iterations => 'count',
    },
);

sub BUILD {
    my $self = shift;

    my $content = $self->file->slurp;           # includes autodie
    my @iter_blocks = $content =~ m{ ( ^Query: .+?  ^//$ ) }xmsg;
    my @iterations = map { Iteration->new($_) } @iter_blocks;
    $self->_set_iterations( \@iterations );

    return;
}


# aliases

sub next_query {
    return shift->next_iteration;
}

sub get_query {                             ## no critic (RequireArgUnpacking)
    return shift->get_iteration(@_);
}

sub all_queries {
    return shift->all_iterations;
}

sub count_queries {
    return shift->count_iterations;
}

# TODO: improve documentation of HMMER methods

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer::Standard - front-end class for standard HMMER parser

=head1 VERSION

version 0.173640

=head1 SYNOPSIS

    use aliased 'Bio::FastParsers::Hmmer::Standard';

    # open and parse hmmsearch output
    my $infile = 'test/hmmer.out';
    my $parser = Standard->new(file => $infile);
    say $parser->next_hit->fullseq_eval;

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to HMMER report file in standard format (--notextw) to be parsed

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Arnaud DI FRANCO

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
