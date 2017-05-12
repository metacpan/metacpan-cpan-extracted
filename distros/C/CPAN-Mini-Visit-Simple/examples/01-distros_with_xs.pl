#!/usr/local/bin/perl

=head1 NAME

01-distros_with_xs.pl

=head1 SYNOPSIS

  perl 01-distros_with_xs.pl       # search all of minicpan

  perl 01-distros_with_xs.pl '/B'  # search only author directory 'authors/id/B/'

=head1 DESCRIPTION

This is an example of a program which uses CPAN::Mini::Visit::Simple.  It does
two things:

=over 4

=item 1

It traverses your minicpan repository (location as determined by your
F<.minicpanrc> file) and makes a list of the contents.  For future reuse, that
list is stored in a file, here called F<authors.txt>.  You may narrow the
search with an optional command-line argument consisting of a string starting
with a forward-slash (C</>) denoting a subdirectory of F<authors/id/>.

=item 2

It then uses the in-memory version of that list to re-traverse the minicpan
and visit each distribution in turn.  The action of the visit is to examine
the distribution's F<MANIFEST> and determine from that document whether the
distribution contains F<.xs> files.  If it does, a line is printed to STDOUT
in the following format:

  C/CH/CHM/OpenGL-0.62.tar.gz:OpenGL.xs   pgopogl.xs      ...

... I<i.e.>, the portion of the distribution's path below the F<authors/id>
directory, followed by a colon, followed by a tab-delimited list of the F<.xs>
files found in the distribution.

The list of distributions with XS may then be redirected to a file via the
command-line.

=back

David Golden recommended the use of C<quiet =E<gt> 1> option to C<visit()> to
hide warnings from distributions which fail to unpack properly.

On a vintage 2004 iBook G4, this program took 108 minutes to run, which the
user considered to be satisfactory.

=cut

use strict;
use warnings;
use feature qw( :5.10 );
use Carp;
use Cwd;
use File::Basename;
use CPAN::Mini::Visit::Simple;

my $author = q{};
if ( @ARGV == 1 and $ARGV[0] =~ m{^/} ) {
    $author = shift @ARGV;
}

my ($cwd, $start_time, $end_time);
$cwd = cwd();
$start_time = time();

my $self = CPAN::Mini::Visit::Simple->new({});
my $start_dir = $self->get_id_dir() . $author;
$self->identify_distros( { start_dir => $start_dir } );
my $primary_list = qq|$cwd/author.txt|;
$self->say_list( { file => $primary_list } );

my $rv = $self->visit( {
    quiet => 1,
    action => sub {
        my $distro = shift @_;
        return unless (-f 'MANIFEST');
        my @files_in_manifest;
        my @c_ish_files;
        open my $FH, '<', 'MANIFEST'
            or croak "Unable to read MANIFEST";
        while (my $l = <$FH>) {
            chomp $l;
            push @c_ish_files, $l
                if basename($l) =~ m/\.xs$/;
        }
        close $FH or croak "Unable to close";
        if (@c_ish_files) {
            say qq{$distro:} . join "\t" => @c_ish_files;
        }
    },
} );
$end_time = time();
my $runtime = $end_time - $start_time;
say STDERR "Elapsed time:  $runtime seconds";

