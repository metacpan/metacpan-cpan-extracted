package Bio::MUST::Drivers::Blast::Database::Temporary;
# ABSTRACT: Internal class for BLAST driver
$Bio::MUST::Drivers::Blast::Database::Temporary::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);
use Path::Class qw(file);

extends 'Bio::MUST::Core::Ali::Temporary';

with 'Bio::MUST::Drivers::Roles::Blastable';


# overload equivalent attribute in plain Database
sub remote {
    return 0;
}

sub BUILD {
    my $self = shift;

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Blast')->new;
       $app->meet();

    my $in = $self->filename;
    my $dbtype = $self->type;

    # create makeblastdb command
    my $pgm = file($ENV{BMD_BLAST_BINDIR}, 'makeblastdb');
    my $cmd = "$pgm -in $in -dbtype $dbtype > /dev/null 2> /dev/null";

    # try to robustly execute makeblastdb
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        # TODO: do something to abort construction
        carp "[BMD] Warning: cannot execute $pgm command; returning!";
        return;
    }

    return;
}

sub DEMOLISH {
    my $self = shift;

    # unlink temp files
    my $basename = $self->filename;
    my @suffices = $self->type eq 'prot' ? qw(phr pin psq) : qw(nhr nin nsq);
    file($_)->remove for map { "$basename.$_" } @suffices;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Blast::Database::Temporary - Internal class for BLAST driver

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
