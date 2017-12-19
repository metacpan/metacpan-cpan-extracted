package Bio::MUST::Drivers::Blast::Database;
# ABSTRACT: internal class for BLAST driver
$Bio::MUST::Drivers::Blast::Database::VERSION = '0.173510';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use File::Temp;
use IPC::System::Simple qw(system);

use Bio::FastParsers;
extends 'Bio::FastParsers::Base';

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Ali';
use Bio::MUST::Drivers::Utils qw(stringify_args);

# TODO: probably move to role...
# TODO: warn user that we need to build db with -parse_seqids

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    writer   => '_set_type',
);

has 'remote' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);


# TODO: complete this with list of NCBI databases
# http://ncbiinsights.ncbi.nlm.nih.gov/2013/03/19/\
# blastdbinfo-api-access-to-a-database-of-blast-databases/
my %type_for = (            # cannot be made constant to allow undefined keys
    nt => 'nucl',
    nr => 'prot',
);

sub BUILD {
    my $self = shift;

    my $basename = $self->filename;

    # check for existence of BLAST database and set its type (nucl or prot)
    if ($self->remote) {
        $self->_set_type( $type_for{$basename} );
    }
    elsif (-e "$basename.psq") {
        $self->_set_type('prot');
    }
    elsif (-e "$basename.nsq") {
        $self->_set_type('nucl');
    }
    else {
        croak "Error: BLAST database not found at $basename; aborting!";
    }

    return;
}


sub blastdbcmd {
    my $self = shift;
    my $ids  = shift;
    my $args = shift // {};

    # setup temporary input/output files (will be automatically unlinked)
    my $in  = File::Temp->new(UNLINK => 1, EXLOCK => 0);
    my $out = File::Temp->new(UNLINK => 1, EXLOCK => 0);

    # write id list for -entry_batch
    say {$in} join "\n", @{$ids};
    $in->flush;                     # for robustness ; might be not needed

    # format blastdbcmd (optional) arguments
    $args->{-db}          = $self->filename;
    $args->{-entry_batch} =   $in->filename;
    $args->{-out}         =  $out->filename;
    my $args_str = stringify_args($args);

    # create blastdbcmd command
    my $pgm = 'blastdbcmd';
    my $cmd = join q{ }, $pgm, $args_str;
    ### $cmd

    # try to robustly execute blastdbcmd
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "Warning: cannot execute $pgm command; returning without seqs!";
        return;
    }

    # TODO: return Stash instead?
    return Ali->load($out->filename, guessing => 0);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Blast::Database - internal class for BLAST driver

=head1 VERSION

version 0.173510

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
