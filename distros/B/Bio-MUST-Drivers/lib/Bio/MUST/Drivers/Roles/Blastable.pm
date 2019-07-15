package Bio::MUST::Drivers::Roles::Blastable;
# ABSTRACT: BLAST database-related methods
$Bio::MUST::Drivers::Roles::Blastable::VERSION = '0.191910';
use 5.018;                      # to avoid a crash due to call to "can" below
use Moose::Role;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use File::Temp;
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);
use Path::Class;

use aliased 'Bio::MUST::Core::Ali::Stash';
use aliased 'Bio::FastParsers::Blast::Table';
use aliased 'Bio::FastParsers::Blast::Xml';

use Bio::MUST::Drivers::Utils qw(stringify_args);


# TODO: avoid hard-coded convenience methods?

sub blastn {                                ## no critic (RequireArgUnpacking)
    return shift->_blast( 'blastn', @_);
}

sub blastp {                                ## no critic (RequireArgUnpacking)
    return shift->_blast( 'blastp', @_);
}

sub blastx {                                ## no critic (RequireArgUnpacking)
    return shift->_blast( 'blastx', @_);
}

sub tblastn {                               ## no critic (RequireArgUnpacking)
    return shift->_blast('tblastn', @_);
}

sub tblastx {                               ## no critic (RequireArgUnpacking)
    return shift->_blast('tblastx', @_);
}

my %pgm_for = (             # cannot be made constant to allow undefined keys
	'nucl:nucl' =>  'blastn',
	'nucl:prot' =>  'blastx',
	'prot:prot' =>  'blastp',
	'prot:nucl' => 'tblastn',
);

sub blast {                                 ## no critic (RequireArgUnpacking)
    my $self  = shift;
    my $query = shift;

    # abort if no Ali::Temporary-like object
    # this seems to work both with Path::Class::File and plain filenames
    # however, the can construct here requires perl-5.18 (cannot find why)
    croak "[BMD] Error: Cannot autoselect BLAST program for $query; aborting!\n"
        . 'Use Ali::Temporary to autodetect query sequence type.'
        unless $query->can('type') && $query->can('filename');

    # auto-select BLAST program based on query/database type
    my $pgm = $pgm_for{ $query->type . ':' . $self->type };

    return $self->_blast($pgm, $query->filename, @_);
}

sub _blast {
    my $self  = shift;
    my $pgm   = shift;
    my $query = shift;
    my $args  = shift // {};

    ### $pgm
    ### $args

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Blast')->new;
       $app->meet();

    # setup output file and output format
    # Note: only tabular, XML and HTML outputs are allowed
    # if specified -html takes precedence on -outfmt
    my $suffix = ".$pgm";
    if (exists $args->{-html}) {
        $suffix .= '.html';
        delete $args->{-outfmt};            # enforce precedence policy
    }
    else {
        unless (defined $args->{-outfmt} && $args->{-outfmt} =~ m/[567]/xms) {
            carp '[BMD] Warning: no valid -outfmt specified;'
                . ' defaulting to tabular!';
            $args->{-outfmt} = 6;
        }
    }
    my $out = File::Temp->new(UNLINK => 0, EXLOCK => 0, SUFFIX => $suffix);

    # automatically setup remote BLAST based on database "class"
    $args->{-remote} = undef if $self->remote;

    # format BLAST (optional) arguments
    $args->{-query} = $query->can('filename') ? $query->filename : $query;
    $args->{-db}    =  $self->filename;     # handle query plain filenames too
    $args->{-out}   =   $out->filename;
    my $args_str = stringify_args($args);

    # create BLAST command
    $pgm = file($ENV{BMD_BLAST_BINDIR}, $pgm);
    my $cmd = join q{ }, $pgm, $args_str, '> /dev/null 2> /dev/null';
    ### $cmd

    # try to robustly execute BLAST
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command;"
            . ' returning without parser!';
        return;
    }

    # return Bio::FastParsers::Blast of the right subclass
    # depending on the output format (XML or tabular)
    # or the Path::Class::File of the report for HTML output
    return exists $args->{-html} ?                    $out->filename  :
           $args->{-outfmt} == 5 ?   Xml->new(file => $out->filename) :
                                   Table->new(file => $out->filename)
    ;

    # TODO: devise a way to unlink report without affecting parsing
    # should be an option of the FastParsers?
}

sub blastdbcmd {
    my $self = shift;
    my $ids  = shift;
    my $args = shift // {};

    # setup temporary input/output files (will be automatically unlinked)
    my $in  = File::Temp->new(UNLINK => 1, EXLOCK => 0);
    my $out = File::Temp->new(UNLINK => 1, EXLOCK => 0);
    # TODO: check if lifespan of $out temp file long enough for loading

    # write id list for -entry_batch
    say {$in} join "\n", @{$ids};
    $in->flush;                     # for robustness ; might be not needed

    # format blastdbcmd (optional) arguments
    $args->{-db}          = $self->filename;
    $args->{-entry_batch} =   $in->filename;
    $args->{-out}         =  $out->filename;
    my $args_str = stringify_args($args);

    # create blastdbcmd command
    my $pgm = file($ENV{BMD_BLAST_BINDIR}, 'blastdbcmd');
    my $cmd = join q{ }, $pgm, $args_str;
    ### $cmd

    # try to robustly execute blastdbcmd
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

Bio::MUST::Drivers::Roles::Blastable - BLAST database-related methods

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
