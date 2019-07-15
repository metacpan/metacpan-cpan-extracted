package Bio::MUST::Drivers::Roles::Hmmerable;
# ABSTRACT: HMMER model-related methods
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::MUST::Drivers::Roles::Hmmerable::VERSION = '0.191910';
use Moose::Role;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use File::Temp;
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);

use Bio::FastParsers;
use aliased 'Bio::MUST::Core::Ali::Stash';

use Bio::MUST::Drivers::Utils qw(stringify_args);


sub scan {                                  ## no critic (RequireArgUnpacking)
    return shift->_search('hmmscan',   @_);
}

sub search {                                ## no critic (RequireArgUnpacking)
    return shift->_search('hmmsearch', @_);
}

sub _search {
    my $self   = shift;
    my $pgm    = shift;
    my $target = shift;
    my $args   = shift // {};

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Hmmer')->new;
       $app->meet();

    # setup input/output files
    # Note: we handle both single models and model database...
    # ... as well as plain target filenames in addition to Ali-like objects
    my $model = $self->can('model') ? $self->model->filename : $self->filename;
    my $in = $target->can('filename') ?    $target->filename : $target;
    my $out = File::Temp->new(UNLINK => 0, EXLOCK => 0, SUFFIX => ".$pgm");

    # setup output file format and parser subclass
    my $parser_class;
    if (exists $args->{'--domtblout'} || $pgm eq 'hmmscan') {
        $args->{'--domtblout'} = $out->filename;
        $parser_class = 'Bio::FastParsers::Hmmer::DomTable';
    }
    elsif (exists $args->{'--tblout'} ) {
        $args->{'--tblout'}    = $out->filename;
        $parser_class = 'Bio::FastParsers::Hmmer::Table';
    }
    else {
        $args->{'--notextw'}   = undef;
        $args->{'-o'}          = $out->filename;
        $parser_class = 'Bio::FastParsers::Hmmer::Standard';
    }
    unless ($parser_class) {
        carp '[BMD] Warning: cannot set parser subclass;'
            . ' returning without parser!';
        return;
    }

    # create HMMER command
    my $args_str = stringify_args($args);
    my $cmd = "$pgm $args_str $model $in > /dev/null 2> /dev/null";
    #### $cmd

    # try to robustly execute HMMER
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command;"
            . ' returning without parser!';
        return;
    }

    return $parser_class->new( file => $out->filename );
}

sub emit {
	my $self = shift;
    my $args = shift // { '-C' => undef };

    # setup input/output files (outfile will be automatically unlinked)
    my $model = $self->model->filename;
    my $out = File::Temp->new(UNLINK => 1, EXLOCK => 0);
    # TODO: check if lifespan of $out temp file long enough for loading

    # create hmmemit command
    $args->{'-o'} = $out;
    my $args_str = stringify_args($args);
    my $pgm = 'hmmemit';
    my $cmd = "$pgm $args_str $model > /dev/null 2> /dev/null";
	# hmmemit -C -o hmmconsensus_GNTPAN12210.fasta test_emitGNT.hmm
    #### $cmd

    # try to robustly execute hmmemit
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command;"
            . ' returning without seqs!';
        return;
    }

    return Stash->load( $out->filename );
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Roles::Hmmerable - HMMER model-related methods

=head1 VERSION

version 0.191910

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
