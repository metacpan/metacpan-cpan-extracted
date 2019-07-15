package Bio::MUST::Drivers::Mafft;
# ABSTRACT: Bio::MUST driver for running the MAFFT program
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Drivers::Mafft::VERSION = '0.191910';
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
    return shift->_mafft('align_all', @_);
}

sub seqs2profile {                          ## no critic (RequireArgUnpacking)
    return shift->_mafft('seqs2profile', @_);
}

sub profile2profile {                       ## no critic (RequireArgUnpacking)
    my $out = shift->_mafft('profile2profile' , @_);
    return $out if $out;

    carp '[BMD] Warning: cannot align profiles; returning nothing!';
    return;
}

sub _mafft {
    my $self    = shift;
    my $mode    = shift;
    my $profile;            # conditional declaring is bad...
       $profile = shift unless $mode eq 'align_all';
    my $args    = shift // {};

    #### in _mafft

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Mafft')->new;
       $app->meet();

    # setup input/output files
    my $infile  = $self->filename;
    my $outfile = $infile . '.mafft';

    $args->{$profile} = undef if $profile;      # should come last (no --)
    my $args_str  = stringify_args($args);

    my %opt_for = (
        align_all       => q{},
        seqs2profile    => '--add',
        profile2profile => '--addprofile',
    );

    # create mafft command
    my $pgm = 'mafft';      # linsi, ginsi,... do not work
    my $cmd = "$pgm $opt_for{$mode} $infile $args_str > $outfile 2> /dev/null";
    #### $cmd

    # try to robustly execute mafft
    my $ret_code = system( [ 0, 1, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command; returning nothing!";
        return;
    }
    if ($ret_code == 1) {
        carp "[BMD] Warning: $pgm cannot align files; returning nothing!";
        file($outfile)->remove;                 # ugly but needed
        return;
    }
    # TODO: try to bypass shell (need for absolute path to executable then)

    my $out = Ali->load($outfile);

    # unlink temp files
    file($outfile)->remove;

    # return Ali
    return $out;
}



__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Mafft - Bio::MUST driver for running the MAFFT program

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
