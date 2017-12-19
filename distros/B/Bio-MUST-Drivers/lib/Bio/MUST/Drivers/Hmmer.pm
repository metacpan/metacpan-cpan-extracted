package Bio::MUST::Drivers::Hmmer;
# ABSTRACT: Bio::MUST driver for running HMMER3 (mainly hmmbuild and hmmsearch)
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::MUST::Drivers::Hmmer::VERSION = '0.173510';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Modern::Perl;
use Carp;
use IPC::System::Simple qw(system $EXITVAL);
use File::Temp qw(tempfile); my $template = 'tmpfile_XXXX';
use Path::Class;

use Bio::FastParsers::Hmmer;

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::Ali';
use Bio::MUST::Drivers::Utils qw(stringify_args);

use Smart::Comments -ENV;
### [HMM] Value of env verbosity : scalar(split ' ', $ENV{Smart_Comments})

has 'ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
);

has 'model' => (
    is      => 'ro',
    isa     => 'Maybe[Bio::FastParsers::Hmmer::Model]',
    lazy    => 1,
    builder => '_build_model',
);

has 'consider_X' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

# TODO: check how to avoid this
# It allows to keep the temporary for debugging purpose
# How did you manage that with BLAST (linked to verbosity level?)
has 'debug_mode' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

# TODO: think about API here: do we really want this? maybe yes
# it gives more power to the end user and I think it is as relevant as for BLAST
has 'args' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_model {
    my $self = shift;

    my $ali = $self->ali;
    ##### N seqs in ali: $ali->count_seqs

    # skip model creation if empty Ali
    return unless $ali->count_seqs;

    # setup input/output files
    my ($tmpfasta_fh, $tmpfasta)  = tempfile( TEMPLATE => $template,
        SUFFIX => '_model.fasta', UNLINK => $self->debug_mode ? 0 : 1, EXLOCK => 0 );
    close($tmpfasta_fh);
    # TODO: check how to avoid this
    # Why? X are informative and keeping them or not influence the profile
    $ali->gapify_seqs( $self->consider_X ? 'X' : undef );
    $ali->store_fasta($tmpfasta);
    my ($hmmmodel_fh, $hmm_model) = tempfile( TEMPLATE => $template, SUFFIX => '.hmm',
        UNLINK => $self->debug_mode ? 0 : 1, EXLOCK => 0 );
    close($hmmmodel_fh);
    my ($hmmout_fh, $hmm_out)   = tempfile( TEMPLATE => $template, SUFFIX => '.out',
        UNLINK => $self->debug_mode ? 0 : 1, EXLOCK => 0 );
    close($hmmout_fh);

    my $args = $self->args;

    # TODO: check the comment below
    # seems to be not so reliable -> so it is returning 0 and failed dna
    $args->{ $ali->is_protein ? '--amino' : '--dna' } = undef;
    ###### [HMM] args : $args
    my $args_str = stringify_args($args);
    ###### [HMM] args_str : $args_str

    # WHAT THE HELL with IPC::SYSTEM
    # I have to set $ENV{PATH} or I'll get a error
    # the bug does not seem to occur anymore
    #~ $ENV{PATH} = '/usr/local/bin/';

    # create hmmbuild command
    my $pgm = 'hmmbuild';
    #~ my $cmd = "$pgm $args_str $hmm_model $tmpfasta";
    my $cmd = "$pgm $args_str $hmm_model $tmpfasta >> $hmm_out";
    #### [HMM] hmmbuild cmd : $cmd

    # try to robustly execute hmmbuild
    my $ret_code = system( [ 0..127 ], $cmd);
    if ($ret_code != 0) {
        carp "Cannot execute $pgm command; returning without HMM model!";
        return;
    }

    return Bio::FastParsers::Hmmer::Model->new( file => $hmm_model );
}

## use critic


sub search {
    my $self    = shift;
    my $targets = shift;
    my $args    = shift // {};

    # skip search if empty Ali (undefined model)
    return unless defined $self->model;

    # setup input/output files
    my $hmm_model = $self->model->file;
    my ($target_fh, $target) = tempfile($template, SUFFIX => '_target.fasta',
        UNLINK => $self->debug_mode ? 0 : 1, EXLOCK => 0 );
    close($target_fh);
    my $temp_ali = Ali->new( seqs => $targets );
    $temp_ali->store_fasta( $target, { degap => 1 } );
    my ($res_fh, $res)    = tempfile($template, SUFFIX => '.res',
        UNLINK => $self->debug_mode ? 0 : 1, EXLOCK => 0 );
    close($res_fh);
    my ($out_fh, $out)    = tempfile($template, SUFFIX => '.out',
        UNLINK => $self->debug_mode ? 0 : 1, EXLOCK => 0 );
    close($out_fh);

    # setup output file format and parser subclass
    my $parser_class;
    if (exists $args->{'--notextw'}) {
        $args->{'-o'} = $res;
        $parser_class = 'Bio::FastParsers::Hmmer::Standard';
    } elsif (exists $args->{'--domtblout'}) {
        $args->{'--domtblout'} = $res;
        $parser_class = 'Bio::FastParsers::Hmmer::DomTable';
    } elsif (exists $args->{'--tblout'}) {
        $args->{'--tblout'} = $res;
        $parser_class = 'Bio::FastParsers::Hmmer::Table';
    }
    return unless defined $parser_class;

    # create hmmsearch command
    my $args_str = stringify_args($args);
    my $pgm = 'hmmsearch';
    #~ my $cmd = "$pgm $args_str $hmm_model $target";
    my $cmd = "$pgm $args_str $hmm_model $target >> $out 2>> $out";
    # TODO: clarify the use of $out and of the appending mode
    # the appended output will always be the same as '-o' 
    # $out is only present to retrieve everything just in case
    #### [HMM] hmmsearch cmd : $cmd

    # try to robustly execute hmmsearch
    my $ret_code = system( [ 0..127 ], $cmd);
    if ($ret_code != 0) {
        carp 'Warning: cannot execute $pgm command; returning without parser!';
        return;
    }

    my $parser = $parser_class->new( file => file($res) );
    return $parser;
}

sub emit {
	# hmmemit -C -o hmmconsensus_GNTPAN12210.fasta test_emitGNT.hmm
	my $self    = shift;
    my $args    = shift // { '-C' => undef};
    
    my ($temp_fh, $temp) = tempfile($template, SUFFIX => '_consensus.fasta',
        UNLINK => $self->debug_mode ? 0 : 1, EXLOCK => 0 );
    close($temp_fh);
    $args->{'-o'} = $temp;
    
    my $hmm_model = $self->model->file;
    
    # create hmmemit command
    my $args_str = stringify_args($args);
    my $pgm = 'hmmemit';
    my $cmd = "$pgm $args_str $hmm_model";
    #### [HMM] hmmemit cmd : $cmd

    # try to robustly execute hmmsearch
    my $ret_code = system( [ 0..127 ], $cmd);
    if ($ret_code != 0) {
        carp 'Warning: cannot execute $pgm command; returning without Ali!';
        return;
    }
    
    my $consensus = Ali->load( file($temp) );
    return $consensus;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Hmmer - Bio::MUST driver for running HMMER3 (mainly hmmbuild and hmmsearch)

=head1 VERSION

version 0.173510

=head1 SYNOPSIS

    # TODO

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
