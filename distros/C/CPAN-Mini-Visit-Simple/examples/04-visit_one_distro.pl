#!/usr/local/bin/perl
use strict;
use warnings;
use feature qw( :5.10 );
use Carp;
use Cwd;
use File::Basename;
use File::Copy;
use File::Find;
use File::Temp qw( tempdir );
use CPAN::Mini::Visit::Simple;
use lib qw( lib );
use Helper qw(
    perform_comparison_builds
    perform_one_build
);

=head1 NAME

04-visit_one_distro.pl - Use the C<get_id_dir()>, C<identify_distros_from_derived_list()> and C<visit()> methods

=head1 SYNOPSIS

    perl 04-visit_one_distro.pl \
        'A/AD/ADAMK/Params-Util-1.00.tar.gz' \
        /path/to/alternate/extutils-parsexs/lib

=head1 DESCRIPTION

This program illustrates how to use the CPAN::Mini::Visit::Simple
C<get_id_dir()>, C<identify_distros_from_derived_list()> and C<visit()>
methods.

We want to conduct a visit to Adam Kennedy's Params-Util distribution.  The
first step is to put that distribution on the list of distributions to be
examined.  We do that with the C<identify_distros_from_derived_list()> method.

Params-Util contains XS code in the file F<List.xs>.  F<make> compiles that
code into first a C source code file F<List.c> and then into a C object file.
Internally, F<make> calls the Perl 5 core program F<xsubpp> to parse the XS
code.  F<xsubpp>, in turn, is a wrapper around a call to a subroutine in the
Perl 5 core module ExtUtils::ParseXS.  The actual use case was to test out
different versions of ExtUtils::ParseXS and to see whether they resulted in
different C source code files.

As you can see by reading the source code and inline comments, quite a bit of
hackery was needed to achieve this objective.  However, that hackery was
neatly encapsulated in the code reference which was the value for the
C<action> element in the hash passed by reference to the C<visit()> method.

=cut

my $self = CPAN::Mini::Visit::Simple->new();
my $id_dir = $self->get_id_dir();
croak "Must supply single distro and path to alternate ParseXS"
    unless ( @ARGV == 2
            and
        ( -f qq|$id_dir/$ARGV[0]| )
            and
        ( -d $ARGV[1] )
    );
my $path_to_single_distro = qq|$id_dir/$ARGV[0]|;
my $path_to_alternate_module = $ARGV[1];

my $rv = $self->identify_distros_from_derived_list( {
    list => [ $path_to_single_distro ],
} );

$rv = $self->visit( {
    quiet => 1,
    action => sub {
        my $distro = shift @_;
        my $exit_code = perform_comparison_builds($distro, $path_to_alternate_module);
    },
} );

