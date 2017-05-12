#!/usr/local/bin/perl

=head1 NAME

02-build_distros_with_xs.pl

=head1 SYNOPSIS

  perl 02-build_distros_with_xs.pl

  # Only visit portion of derived list starting with 'X'
  perl 02-build_distros_with_xs.pl X  

=head1 DESCRIPTION

This is an example of a program which uses CPAN::Mini::Visit::Simple.  In
companion program F<01-distros_with_xs.pl>, we used the C<say_list()> method
to store in a file a list of all CPAN distributions with XS code.  Here we
further modify that list and then use it as a I<derived list> which is input
to the C<identify_distros_from_derived_list()> method.  We then use the
C<visit()> method to perform an action upon each visit, I<viz>., we attempt to
build each distribution with F<make> or F<./Build.PL>.  We log successful and
failed builds to separate files.  Files listed as successful builds are then
available as the source of other derived lists in other programs in later
steps in our development process.

=head2 Limitation

In its current form, this program is not able to easily handle distributions
whose F<Makefile.PL> pauses to prompt the user to supply information STDIN.
Since the larger project of which this program is a part merely aims to get a
useful subset of CPAN as a sample used during testing, we only want to concern
ourselves with distributions whose F<perl Makefile.PL> and F<make> calls will
run in a completely automated way -- regardless of whether they ultimately
succeed or not.

So, in practice, this program had to be run repeatedly.  Each time a
distribution with a user-prompt was encountered, that distribution's name was
added to a list of distributions to be skipped over (see the C<__DATA__>
section of this program) and the program was rerun.  This led to the program
being designed to be run one letter of the alphabet at a time.

Do you have a better way to approach this problem?  Please contact the author.

=cut

use strict;
use warnings;
use feature qw( :5.10 );
use Carp;
use Cwd;
use IO::Zlib;
use CPAN::Mini::Visit::Simple;

my @args = @ARGV;
my $letter = q{};
if ($args[0] =~ m/^[A-Z]$/) {
    $letter = $args[0];
}

my ($cwd, $start_time, $end_time);
$cwd = cwd();
$start_time = time();

my $xs_distros_file = qq|$cwd/all_distros_with_xs.txt.gz|;

my @known_problem_distros = ();
while (my $problem = <DATA>) {
    next if $problem =~ /^(?:#|\s+$)/o;
    chomp $problem;
    $problem =~ s{/}{\/}g;
    push @known_problem_distros, $problem;
}
my $known_problem_string = join '|' => @known_problem_distros;
my $IN = IO::Zlib->new( $xs_distros_file, 'rb' );
croak unless defined $IN;
my @distros_with_xs = ();
while (my $d = <$IN>) {
    chomp $d;
    my @data = split /:/, $d;
    if ($letter) {
        next unless $data[0] =~ m/^$letter\//;
    }
#    push @distros_with_xs, qq|/Users/jimk/minicpan/authors/id/$data[0]|;
    unless ($data[0] =~ m/(?:$known_problem_string)/o) {
        push @distros_with_xs, qq|/Users/jimk/minicpan/authors/id/$data[0]|;
    }
}
$IN->close or croak "Unable to close $xs_distros_file after reading";

my $self = CPAN::Mini::Visit::Simple->new({});
$self->identify_distros_from_derived_list( { list => \@distros_with_xs } );

open my $SUCCESS, '>', qq|$cwd/successful/$letter.success|
    or croak "Unable to open for writing";
open my $FAILURE, '>', qq|$cwd/failed/$letter.failed|
    or croak "Unable to open for writing";

my $rv = $self->visit( {
    quiet => 1,
    action => sub {
        my $distro = shift @_;
        say STDERR "Studying $distro in " . cwd();
        return unless (-f 'Makefile.PL' or -f 'Build.PL');
        my ($bfile, $bprogram, $builder);
        if (-f 'Build.PL') {
            $bfile = q{Build.PL};
            $bprogram = q{./Build};
            $builder = q{MB};
        }
        else {
            $bfile = q{Makefile.PL};
            $bprogram = q{make};
            $builder = q{EUMM};
        }
        my $exit_code = system(qq{$^X $bfile && $bprogram});
        $exit_code ? say $FAILURE qq{$distro:$builder}
            : say $SUCCESS qq{$distro:$builder};
    },
} );
close $SUCCESS or croak;
close $FAILURE or croak;

$end_time = time();
my $runtime = $end_time - $start_time;
say STDERR "Elapsed time:  $runtime seconds";

__DATA__
A/AB/ABW/Template-Toolkit
A/AL/ALFW/AFS-Monitor
A/AL/ALIAN/Filesys-SmbClient
A/AL/ALVAROL/PerlCryptLib
A/AM/AMALTSEV/XAO-Indexer
A/AM/AMALTSEV/XAO-MySQL
A/AM/AMALTSEV/XAO-Web
A/AS/ASH/Cache-FastMmap-WithWin32
A/AS/ASH/TryCatch
A/AS/ASH/WWW-Mechanize-TreeBuilder
B/BM/BMAMES/Rinchi-CPlusPlus-Preprocessor
B/BO/BOWMANBS/Audio-Ecasound
B/BR/BRIANSKI/Proc-Exists
C/CL/CLAESJAC/JavaScript
C/CO/CODECHILD/XML-Bare-SAX-Parser
C/CR/CREIN/Net-DNS
D/DL/DLAND/Crypt-SSLeay
D/DM/DMAKI/Text-MeCab
D/DM/DMLLOYD/Async-Callback
D/DM/DMUEY/Authen-Libwrap
D/DM/DMARTIN/Unix-SavedIDs
D/DO/DOUGM/mod_perl
U/UL/ULPFR/WAIT
W/WY/WYANT/Mac-Pasteboard
X/XA/XAOINC/XAO-MySQL
Y/YA/YAMATO/QDBM_File
Y/YE/YEWEI/Jvm
Y/YV/YVES/Data-Dump-Streamer
