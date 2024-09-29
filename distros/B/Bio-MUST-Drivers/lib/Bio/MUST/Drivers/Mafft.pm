package Bio::MUST::Drivers::Mafft;
# ABSTRACT: Bio::MUST driver for running the MAFFT program
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Drivers::Mafft::VERSION = '0.242720';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments '###';

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

sub profile2profile {                       ## no critic (RequireArgUnpacking)
    my $out = shift->_mafft('profile2profile' , @_);
    return $out if $out;

    carp '[BMD] Warning: cannot align profiles; returning nothing!';
    return;
}

sub seqs2profile {
    my $self    = shift;
    my $profile = shift;
    my $args    = shift // {};

    # setup specialized options
    my $mode = 'seqs2profile';
    for my $suffix ( qw(long fragments) ) {
        my $opt = '--' . $suffix;
        if (exists $args->{$opt}) {
            $mode =~ s/seqs/$suffix/xms;
            delete $args->{$opt};
        }
    }
    #### $mode

    return $self->_mafft($mode, $profile, $args);
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

    # see https://mafft.cbrc.jp/alignment/server/add.html
    my %opt_for = (
        align_all         => q{},
        profile2profile   => '--addprofile',
        seqs2profile      => '--add',
        long2profile      => '--addlong',
        fragments2profile => '--addfragments',
    );

    # create mafft command
    my $pgm = 'mafft';      # linsi, ginsi,... do not work
    my $final_args = $mode eq 'align_all' ? "$args_str $infile" : "$infile $args_str";
    my $cmd = "$pgm $opt_for{$mode} $final_args > $outfile 2> /dev/null";
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

version 0.242720

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
