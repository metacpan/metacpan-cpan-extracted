package Bio::MUST::Drivers::Hmmer::Model::Temporary;
# ABSTRACT: Internal class for HMMER3 driver
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::MUST::Drivers::Hmmer::Model::Temporary::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use File::Temp qw(tempfile);
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);
use Path::Class;

extends 'Bio::MUST::Core::Ali::Temporary';

use aliased 'Bio::FastParsers::Hmmer::Model';
use Bio::MUST::Drivers::Utils qw(stringify_args);


has 'model_args' => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
);

has 'model' => (
    is       => 'ro',
    isa      => 'Maybe[Bio::FastParsers::Hmmer::Model]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_model',
);

with 'Bio::MUST::Drivers::Roles::Hmmerable' => {
    -excludes => [ qw(scan) ]
};

## no critic (ProhibitUnusedPrivateSubroutines)

# overload Ali::Temporary default builder
sub _build_args {
    return { clean => 1, degap => 0 };
}

sub _build_model {
    my $self = shift;

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Hmmer')->new;
       $app->meet();

    # skip model creation if no seqs
    unless ($self->count_seqs) {
        carp '[BMD] Warning: no sequence provided; returning without model!';
        return;
    }

    # setup input/output files
    my $in = $self->filename;
    my $out = File::Temp->new(UNLINK => 0, EXLOCK => 0, SUFFIX => '.hmm');

    # format hmmbuild (optional) arguments
    my $args = $self->model_args;
    $args->{ $self->is_protein ? '--amino' : '--dna' } = undef;
    my $args_str = stringify_args($args);

    # create hmmbuild command
    my $pgm = 'hmmbuild';
    my $cmd = "$pgm $args_str $out $in > /dev/null 2> /dev/null";

    # try to robustly execute hmmbuild
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command;"
            . ' returning without model!';
        return;
    }

    return Model->new( file => $out->filename );
}

## use critic

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Hmmer::Model::Temporary - Internal class for HMMER3 driver

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
