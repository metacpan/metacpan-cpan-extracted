package Bio::FastParsers::Hmmer::Standard::Iteration;
# ABSTRACT: Front-end class for standard HMMER parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::Standard::Iteration::VERSION = '0.221230';
use Moose;
use namespace::autoclean;

use autodie;

use List::AllUtils qw(indexes firstidx mesh);

use Bio::FastParsers::Constants qw(:files);
use aliased 'Bio::FastParsers::Hmmer::Standard::Target';


# public attributes

has 'query' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'query_length' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'targets' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::FastParsers::Hmmer::Standard::Target]',
    required => 1,
    handles  => {
         next_target  => 'shift',
          get_target  => 'get',
          all_targets => 'elements',
        count_targets => 'count',
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

around BUILDARGS => sub {
    my ($orig, $class, $iter_block) = @_;

    my %outargs;
    my @hits;

    # Parse Iteration to separate header information (q, qlen), header hit
    # table (Hit) and main output information per target (Target).
    # Hit and Target are the same entity but Hit is close to what is retrieved
    # from a Hmmer::Table output. For now, we chose to conserve Target as
    # primary name since it is how it is called in the file.

    my @lines = split /\n/xms, $iter_block;

    LINE:
    for my $line (@lines) {

        # parse header
        if ($line =~ m/Query:/xms) {
            my @fields = split /\s+/xms, $line;
              $outargs{'query'}        = $fields[1];
            ( $outargs{'query_length'} = $fields[2] ) =~ s/\D//xmsg;
        }

        # parse Hit
        my @attrs = qw(
                     evalue            score           bias
            best_dom_evalue   best_dom_score  best_dom_bias
            exp  dom  query_name  target_description
        );

        if ($line =~ m/^\s+ (\d .*)/xms) {
            my @fields = split /\s+/xms, $1;

            # Fields
            #  0. full seq    - evalue
            #  1. full seq    - score
            #  2. full seq    - bias
            #  3. best domain - evalue
            #  4. best domain - score
            #  5. best domain - bias
            #  6. #domain     - exp
            #  7. #domain     - N
            #  8. sequence
            #  9. description

            # coerce numeric fields to numbers
            @fields[0..7] = map { 0 + $_      } @fields[0..7];

            # fixing description
            $fields[9] = join q{ }, @fields[9..$#fields];
            # set missing/empty field values to undef
            @fields[8..9] = map { $_ || undef } @fields[8..9];

            my @wanted = @fields[0..9];
            push @hits, { mesh @attrs, @wanted };
        }

        # process only header
        last LINE if $line =~ m/^\>\>/xms;
    }

    # split Targets (Hits)
    my @target_indexes = indexes { m/^\>\>/xms } @lines;
    my @targets;
    for (my $i = 0; $i < @target_indexes; $i++) {
        my @block = defined $target_indexes[$i+1]
                    ? @lines[ $target_indexes[$i] .. $target_indexes[$i+1] ]
                    : splice @lines, $target_indexes[$i]
        ;
        push @targets, Target->new( { raw => \@block, hit => $hits[$i] } );
    }
    $outargs{targets} = \@targets;

    # return expected constructor hash
    return $class->$orig(%outargs);
};


# aliases for Target/Hit

sub next_hit {
    return shift->next_target;
}

sub get_hit {                               ## no critic (RequireArgUnpacking)
    return shift->get_target(@_);
}

sub all_hits {
    return shift->all_targets;
}

sub count_hits {
    return shift->count_targets;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer::Standard::Iteration - Front-end class for standard HMMER parser

=head1 VERSION

version 0.221230

=head1 SYNOPSIS

    use aliased 'Bio::FastParsers::Hmmer::Standard';

    # open and parse hmmsearch output
    my $infile = 'test/hmmer.out';
    my $parser = Standard->new(file => $infile);

=head1 DESCRIPTION

    # TODO

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
