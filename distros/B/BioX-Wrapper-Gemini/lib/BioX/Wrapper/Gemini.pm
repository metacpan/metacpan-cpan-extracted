package BioX::Wrapper::Gemini;

use 5.008_005;

our $VERSION = '0.05';

use Moose;
use File::Find::Rule;
use File::Basename;
use File::Path qw(make_path remove_tree);
use File::Find::Rule;
use Cwd;
use Data::Dumper;
use List::Compare;

extends 'BioX::Wrapper';
#with 'MooseX::Getopt';
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

=head1 NAME

BioX::Wrapper::Gemini - A simple wrapper around the python Gemini library for annotating VCF files.

=head1 SYNOPSIS

=head2 Basic Usage

  gemini_wrapper.pl --indir /path/to/vcfs --outdir /location/we/can/write/to > commands.in

=head2 Customized workflow

For more involved usage please see L<BioX::Wrapper::Gemini::Example>

=head2 Using the API

BioX::Wrapper::Gemini is written using Moose and can be extended in all the usual fashions.

  use BioX::Wrapper::Gemini;

  after 'db_load' =>
  sub {
  my $self = shift;
    # Run some commands
    # SCIENCE!
  }

=head1 Description

A wrapper around Gemini for processing files.

Read more about Gemini here: http://gemini.readthedocs.org/en/latest/

The workflow described is taken straight from the documentation written by the
author of Gemini.

For more customization please see the attributes sections of the docs

=cut

=head2 Attributes

Moose Attributes

=head2 vcfs

VCF files can be given individually as well.

    #Option is an ArrayRef and can be given as either

    --vcfs 1.vcf,2.vcf,3.vcfs

    #or

    --vcfs 1.vcf --vcfs 2.vcf --vcfs 3.vcf

Don't mix the methods

    If these vcfs are uncompressed, they will be compressed in place. Please make sure either this location has read/write access, or create a symbolic link to someplace

    Everytime you leave genomics data uncompressed a kitten dies!

=cut

has 'vcfs' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 0,
    documentation => 'List of vcfs if not using --indir option. This --vcfs 1.vcf --vcfs 2.vcf --vcfs 3.vcf or this --vcfs 1.vcf,2.vcf,3.vcfs'
);

=head2 uncomvcfs

Vcfs that are uncompressed

=cut

has 'uncomvcfs' => (
    metaclass => 'NoGetopt',
    is => 'rw',
    isa => 'ArrayRef',
    required => 0,
    default => sub{[]},
);

=head2 ref

Supply a path to a reference genome

Default is to assume there is an environmental variable $REFGENOME

=cut

has 'ref' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => "\$REFGENOME",
    documentation => 'Path to reference genome. Assumes it is stored in an environmental variable \$REFGENOME'
);

=head2 snpeff

Base directory of snpeff

The default assumes there is an environmental variable of $SNPEFF, being the base directory of the snpeff installation.

=cut

# TODO
# Add documentation for bioinformatics modules using environment modules

has 'snpeff' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => "\$SNPEFF",
    documentation => 'Base directory of SnpEff. Assumes it is stored in an environmental variable \$SNPEFF'
);

=head2 snpeff_opt

Options to run snpeff with

Default is -c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75

=cut

has snpeff_opt => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => "-c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75 ",
    documentation => "Snpeff run parameters. Default -c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75",
);

=head2 ped

If all vcf files are being loaded into the gemini db with the same pedigree file, simply change the --db_load_opts to correspond to your file.

If each vcf file has its own pedigree, make sure the pedigree file matches the basename of the vcf.

Basenames are captured like so:

    my @gzipbase = map {  basename($_, ".vcf.gz") }  @gzipped ;
    my @notgzipbase = map {  basename($_, ".vcf") }  @notgzipped ;

With the extension being .vcf.gz/.vcf

Invoke this with --ped

Exact specifications should be found here:

http://gemini.readthedocs.org/en/latest/content/preprocessing.html#describing-samples-with-a-ped-file

=cut

has 'ped' => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
    documentation => 'Load gemini with pedigre option. Pedigree should be named in the same convention as the vcf files processed. Family01.vcf Family01.ped'
);

=head2 ped_dir

If using the --ped option you must specify this if your pedigree files are not in the same directory as the --indir option

=cut

has 'ped_dir' => (
  is => 'rw',
  isa => 'Str',
  required => 0,
  lazy => 1,
  default => '',
  documentation => 'You must specify this directory if your pedigree files are not in the same location as --indir',
);

=head2 db_load_opts

Options for loading VCF file into gemini sqlite db

Default is  -t snpEff

This used to be --skip_cadd -t snpeff, but by popular demand is now just -t snpEff

=cut

has db_load_opts => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => "-t snpEff"
);

=head2 Subroutines

Subroutines

=cut

=head2 check_files

Check to make sure either an indir or vcfs are supplied

=cut

sub check_files {
    my($self) = @_;

    my($t);

    die print "Must specificy an indirectory or vcfs!\n" if (!$self->indir && !$self->vcfs);

    if($self->indir){
        $t = $self->indir;
        $t =~ s/\/$//g;
        $self->indir($t);
    }

    $t = $self->outdir;
    $t =~ s/\/$//g;
    $t = $t."/gemini-wrapper";
    $self->outdir($t);

    #make the outdir
    make_path($self->outdir) if ! -d $self->outdir;
    make_path($self->outdir."/norm_annot_vcf") if ! -d $self->outdir."/norm_annot_vcf";
    make_path($self->outdir."/gemini_sqlite") if ! -d $self->outdir."/gemini_sqlite";
}

=head2 find_vcfs

Use File::Find::Rule to find the vcfs

Make sure they are all gzipped first. If there are any .vcf$ files without a corresponding .vcf.gz$, bgzip those

=cut

sub find_vcfs{
    my($self) = @_;

    return if $self->vcfs;
    $self->vcfs([]);

    my @gzipped = File::Find::Rule->file->name(qr/(\.vcf\.gz)$/)->in( $self->indir);
    my @notgzipped = File::Find::Rule->file->name(qr/(\.vcf)$/)->in( $self->indir);

    my @gzipbase = map {  basename($_, ".vcf.gz") }  @gzipped ;
    my @notgzipbase = map {  basename($_, ".vcf") }  @notgzipped ;

    my $lc = List::Compare->new(\@notgzipbase, \@gzipbase);

    my @gzipthese = $lc->get_Lonly;

    if(@gzipthese){
        foreach my $i (@gzipthese){
            push(@{$self->uncomvcfs}, $self->indir."/".$i.".vcf");
            #push(@{$self->vcfs}, $self->indir."/".$i.".vcf.gz");
            push(@{$self->vcfs}, $i);
        }
    }

    foreach my $i (@gzipbase){
        #push(@{$self->vcfs}, $self->indir."/".$i.".vcf.gz")
        push(@{$self->vcfs}, $i);
    }

    print "\n\n#######################################################################\n";
    print "# Starting Sample Info Section\n";
    print "#######################################################################\n\n";

    print "# ".join(", ", @{$self->vcfs})."\n";

    print "\n#######################################################################\n";
    print "# Ending Sample Info Section\n";
    print "#######################################################################\n";

    $self->bgzip();
    die print "No vcfs were found!\n" unless $self->vcfs;
}

=head2 bgzip

Run bgzip command on files found in find_vcfs

=cut

sub bgzip{
    my($self) = shift;

    return unless $self->uncomvcfs;

    print "\n\n#######################################################################\n";
    print "# Starting Bgzip Section\n";
    print "#######################################################################\n";
    print "# The following samples must be bgzipped before processing can begin\n";
    print "# ".join(", ", @{$self->uncomvcfs})."\n";
    print "#######################################################################\n\n";

    foreach my $i (@{$self->uncomvcfs}){
        print "bgzip $i && tabix $i.gz\n"
    }

    print "wait\n";
    print "\n\n#######################################################################\n";
    print "# Finished Bgzip Section\n";
    print "#######################################################################\n\n";
}

=head2 norml

normalize vcfs using vt and annotate using SNPEFF

=cut

# TODO
# Add in option for vep annotation

sub norml {
    my($self) = shift;

    print "#######################################################################\n";
    print "# Normalizing with VT and annotating with SNPEFF the following samples\n";
    print "# ".join(", ", @{$self->vcfs})."\n";
    print "#######################################################################\n\n";

    foreach my $vcf (@{$self->vcfs}){

        my $cmd .=<<EOF;
bcftools view $self->{indir}/$vcf.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' \\
    | vt decompose -s - \\
    | vt normalize -r $self->{ref} - \\
    | java -Xmx4G -jar $self->{snpeff}/snpEff.jar $self->{snpeff_opt} \\
    | bgzip -c > \\
    $self->{outdir}/norm_annot_vcf/$vcf.norm.snpeff.gz && tabix $self->{outdir}/norm_annot_vcf/$vcf.norm.snpeff.gz
EOF

        print $cmd."\n\n";
    }

    print "wait\n";
    print "\n\n#######################################################################\n";
    print "# Finished Normalize Annotate Section\n";
    print "#######################################################################\n\n";
}


=head2 db_load

Load DB into gemini

=cut

sub db_load {
    my($self) = @_;

    print "#######################################################################\n";
    print "# Gemini is loading the following samples\n";
    print "# ".join(", ", @{$self->vcfs})."\n";
    print "#######################################################################\n\n";

    if ($self->ped){
        $self->ped_dir($self->indir) unless $self->ped_dir;
    }

    foreach my $vcf (@{$self->vcfs}){

        my $cmd =<<EOF;
gemini load -v $self->{outdir}/norm_annot_vcf/$vcf.norm.snpeff.gz \\
    $self->{db_load_opts} \\
EOF
        if($self->ped){
            $cmd .=<<EOF;
    -p $self->{ped_dir}/$vcf.ped \\
EOF
        }

        $cmd .=<<EOF;
     $self->{outdir}/gemini_sqlite/$vcf.vcf.db
EOF

        print $cmd."\n\n";
    }

    print "wait\n";
    print "\n\n#######################################################################\n";
    print "# Finished Gemini Load Section\n";
    print "#######################################################################\n";
}

=head2 run

Subroutine that starts everything off

=cut

sub run {
    my($self) = @_;

    $self->print_opts;

    $self->check_files;
    $self->find_vcfs;
    $self->norml;
    $self->db_load;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf-8


=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 ACKNOWLEDGEMENTS

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.

=head1 COPYRIGHT

Copyright 2015- Weill Cornell Medical College in Qatar

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
