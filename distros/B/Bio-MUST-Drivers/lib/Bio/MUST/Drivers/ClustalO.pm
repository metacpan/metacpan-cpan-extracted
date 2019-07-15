package Bio::MUST::Drivers::ClustalO;
# ABSTRACT: Bio::MUST driver for running the Clustal Omega program
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Drivers::ClustalO::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::MUST::Core;
extends 'Bio::FastParsers::Base';

use Bio::MUST::Drivers::Utils qw(stringify_args);
use aliased 'Bio::MUST::Core::Ali';


sub align_all {                             ## no critic (RequireArgUnpacking)
    #### in align_all
    return shift->_clustalo('align_all', @_);
}

sub seqs2profile {                          ## no critic (RequireArgUnpacking)
    #### in seqs2profile
    my $self = shift;

    carp '[BMD] Warning: align seqs before aligning on profile!'
        unless Ali->load( $self->file )->is_aligned;
    return $self->_clustalo('seqs2profile', @_);
}

sub profile2profile {                       ## no critic (RequireArgUnpacking)
    #### in profile2profile
    return shift->_clustalo('profile2profile', @_);
}

sub _clustalo {
    #### in _clustalo

    my $self    = shift;
    my $mode    = shift;
    my $profile;            # conditional declaring is bad...
       $profile = shift unless $mode eq 'align_all';
    my $args    = shift // {};

    # provision executable
    my $app = use_module('Bio::MUST::Provision::ClustalO')->new;
       $app->meet();

    # setup input/output files
    my $infile  = $self->filename;
    my $outfile = $infile . '.clustalo';

    $args->{-o} = $outfile;
    $args->{ $mode eq 'profile2profile' ? '--p1' : '-i'   } = $infile;
    $args->{ $mode eq 'profile2profile' ? '--p2' : '--p1' } = $profile
        if $profile;

    my $args_str = stringify_args($args);

    # create clustalo command
    my $pgm = 'clustalo';
    my $cmd = join q{ }, $pgm, $args_str, '2> /dev/null';
    #### $cmd

    # try to robustly execute clustalo
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command; returning nothing!";
        return;
    }

    my $out = Ali->load($outfile);
    # TODO: try to bypass shell (need for absolute path to executable then)

    # unlink temp file
    file($outfile)->remove;

    # return Ali
    return $out;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::ClustalO - Bio::MUST driver for running the Clustal Omega program

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
