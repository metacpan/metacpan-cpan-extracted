#!/usr/local/bin/perl
use strict;
use warnings;
use feature qw( :5.10 );
use Data::Dumper;$Data::Dumper::Indent=1;
use Carp;
use Cwd;
use CPAN::Mini::Visit::Simple;
use lib qw( lib );
use Helper qw(
    successful_eumm_or_mb
);

=head1 NAME

03-refresh_success_list.pl - Use the C<refresh_list()> method

=head1 SYNOPSIS

    perl 03-refresh_success_list.pl /path/to/successful_builds_list.txt

=head1 DESCRIPTION

This program illustrates how to use the CPAN::Mini::Visit::Simple
C<refresh_list()> method.

Earlier programming created a file called F<success.builds.txt> which
consisted of records looking like this:

    C/CT/CTILMES/Proc-Wait3-0.03.tar.gz:EUMM
    C/CT/CTRONDLP/X11-GUITest-0.21.tar.gz:EUMM
    D/DA/DAGOLDEN/ExtUtils-ParseXS-2.2203.tar.gz:MB
    D/DA/DANIEL/Crypt-OpenSSL-PKCS12-0.5.tar.gz:EUMM
    D/DA/DANIEL/Crypt-OpenSSL-X509-1.0.tar.gz:EUMM

..., I<i.e.>, colon-delimited records where the first element is the part of a
particular CPAN distribution's path in the minicipan below the F<author/id/>
directory and the second element is a string consisting either of C<EUMM>
(ExtUtils::MakeMaker) or C<MB> (Module::Build).  Distributions were placed in
this list if they built both successfully and fully automatically, I<i.e.>,
without any requirement that a user enter information in response to a
command-line prompt.

Over time, the authors of these distributions will upload new versions to
CPAN, which will, in turn eventually be reflected in a users minicpan
repository on disk.  Having gone to the effort of identifying which CPAN
distributions we want to use in our research, we want to make sure we are
working with up-to-date versions thereof.

Enter:  C<refresh_list()>.

This program creates two lists, one for EUMM distributions and one for MB
distributions.  It then uses those lists as arguments to two separate calls to
C<refresh_list()>.  Since C<refresh_list()> expects absolute paths, we have to
prepend each record with the F<minicpan/author/id/> path.  Each call to
C<refresh_list()> returns an array reference holding a list of absolute paths
to distributions found in the updated minicpan repository.  This array ref is
suitable for passing on to other methods (not illustrated).

=cut

croak "Must specify path to file holding list of successful builds"
    unless (@ARGV == 1 and (-f $ARGV[0]));

my $builds_file = shift @ARGV;
my ($eumm_ref, $mb_ref) = successful_eumm_or_mb($builds_file);
say "EUMM:  ", sprintf "%5d" => scalar @{$eumm_ref};
say "MB:    ", sprintf "%5d" => scalar @{$mb_ref};

my $self = CPAN::Mini::Visit::Simple->new();
my $id_dir = $self->get_id_dir();
my $refreshed_eumm_list_ref = $self->refresh_list( {
    derived_list    => [ map { qq|$id_dir/$_| } @{$eumm_ref} ],
} );
my $refreshed_mb_list_ref = $self->refresh_list( {
    derived_list    => [ map { qq|$id_dir/$_| } @{$mb_ref} ],
} );
#say Dumper $refreshed_eumm_list_ref;
#say Dumper $refreshed_mb_list_ref;

foreach my $eumm_xs_current (@{$refreshed_eumm_list_ref}) {
    say $eumm_xs_current;
}

