package BioX::Wrapper;

use File::Find::Rule;
use File::Basename;
use File::Path qw(make_path remove_tree);
use File::Find::Rule;
use Cwd;
use DateTime;

use Moose;
use Moose::Util::TypeConstraints;
with 'MooseX::Getopt';
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';
with 'MooseX::SimpleConfig';

# For pretty man pages!
$ENV{TERM}='xterm-256color';

our $VERSION = '1.5';

=head1 BioX::Wrapper

Base class for BioX::Wrapper

=head2 Wrapper Options

=cut

=head3 example.yml

    ---
    indir: "/path/to/files"
    outdir: "path/to/testdir"

=cut

has '+configfile' => (
    required => 0,
    documentation => q{
If you get tired of putting all your options on the command line create a config file instead.
---
indir: "/path/to/files"
outdir: "path/to/testdir"
    }
);

=head3 comment_char

For a bash script a comment is "#", but is other characters for other languages

=cut

has 'comment_char' => (
     is => 'rw',
     isa => 'Str',
     default => '#',
);

=head2 print_opts

Print out the command line options

=cut

sub print_opts {
    my($self) = @_;

    my $now = DateTime->now();

    print "$self->{comment_char}\n";
    print "$self->{comment_char} Generated at: $now\n";
    print "$self->{comment_char} This file was generated with the following options\n";

    for(my $x=0; $x<=$#ARGV; $x++){
        next unless $ARGV[$x];
        print "$self->{comment_char}\t$ARGV[$x]\t";
        if($ARGV[$x+1]){
           print $ARGV[$x+1];
        }
        print "\n";
        $x++;
    }

    print "$self->{comment_char}\n\n";
}

=head3 indir

A path to your vcf files can be given, and using File::Find::Rule it will recursively search for vcf or vcf.gz

=cut

has 'indir' => (
    is => 'rw',
    isa => 'Str|Undef',
    required => 0,
);

=head3 outdir

Path to write out annotation files. It creates the structure

    outdir
        --annovar_interim
        --annovar_final
        --vcf-annotate_interim #If you choose to reannotate VCF file
        --vcf-annotate_final #If you choose to reannotate VCF file

A lot of interim files are created by annovar, and the only one that really matters unless you debugging a new database is the multianno file found in annovar_final

If not given the outdirectory is assumed to be the current working directory.

=cut

has 'outdir' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => sub { return getcwd() },
);

1;
__END__

=encoding utf-8

=head1 NAME

BioX::Wrapper - Base class for BioX::Wrappers

=head1 SYNOPSIS

  use BioX::Wrapper;

=head1 DESCRIPTION

BioX::Wrapper is

=head1 Acknowledgements

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015 - Weill Cornell Medical College in Qatar

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
