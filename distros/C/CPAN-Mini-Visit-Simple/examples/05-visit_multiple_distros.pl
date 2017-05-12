#!/usr/local/bin/perl
use strict;
use warnings;
use feature qw( :5.10 );
use Data::Dumper;$Data::Dumper::Indent=1;
use Carp;
use Cwd;
use File::Basename;
use File::Copy;
use File::Find;
use File::Temp qw( tempdir );
use CPAN::Mini::Visit::Simple;
use Scalar::Util qw( looks_like_number );
use Tie::File;
use lib qw( lib );
use Helper qw(
    prepare_list_of_random_distros
    perform_comparison_builds
);


=head1 NAME

05-visit_multiple_distros.pl

=head1 SYNOPSIS

    perl 05-visit_multiple_distros.pl \
        /path/to/eumm_xs_current.txt \
        5 \
        /path/to/alternate/extutils-parsexs/lib

=head1 DESCRIPTION

Specify a file holding a list of distributions with XS that build successfully
with ExtUtils::MakeMaker; the number of distributions to test; and a path to
the alternate version of ExtUtils::ParseXS.  The program will select that
number of distributions in a pseudo-random manner and test them with both old
and new ParseXS.

=cut

croak "Will need 3 command-line arguments" unless @ARGV == 3;
croak "Must supply path to list of files with XS that build successfully with EUMM"
    unless (-f $ARGV[0]);
my $eumm_file = shift @ARGV;
croak "Must supply number of distributions to be visited"
    unless (
        looks_like_number($ARGV[0])
            or
        $ARGV[0] eq 'all'
    );

my $count  = shift @ARGV;
croak "Must path to alternate ParseXS"
    unless (-d $ARGV[0]);
my $path_to_alternate_module = $ARGV[0];

my $selected_distros_ref = prepare_list_of_random_distros($eumm_file, $count);

my $self = CPAN::Mini::Visit::Simple->new();
my $id_dir = $self->get_id_dir();

my $rv = $self->identify_distros_from_derived_list( {
    list => $selected_distros_ref,
} );

$rv = $self->visit( {
    quiet => 1,
    action => sub {
        my $distro = shift @_;
        my $exit_code = perform_comparison_builds($distro, $path_to_alternate_module);
    },
} );

