#!/usr/bin/perl -w

use lib qw(.);
use Lingua::LTS::Gfsm;
use Encode qw(encode decode);
use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use IO::File;
use Pod::Usage;
use locale;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------

##-- analysis object
our $lts = Lingua::LTS::Gfsm->new(
				  check_symbols=>1,
				  tolower      =>1,
				  profile      =>0,
				 );

##-- analysis object: filenames
our $lts_labfile = undef;
our $lts_fstfile = undef;
our $lts_dictfile = undef;

##-- analysis options
our $queryenc = undef;

##-- program options
our $verbose = 1;
our $progname = basename($0);

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v!' => \$verbose,

	   ##-- Analysis Objects
	   'labels|labs|lab|l|symbols|syms|sym|s=s' => \$lts_labfile,
	   'fst|f|m=s' => \$lts_fstfile,
	   'dictionary|dict|d=s' => \$lts_dictfile,

	   ##-- Analysis Options
	   'label-encoding|labencoding|labenc|le=s' => \$lts->{labenc},
	   'query-encoding|queryenc|qenc|qe|q=s' => \$queryenc,
	   'check-symbols|check|c!' => \$lts->{check_symbols},
	   'tolower|lower|L=s' => \$lts->{tolower},
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-msg=>"No query specified!", -exitval=>1, -verbose=>0}) if (!@ARGV);


##------------------------------------------------------------------------------
## Subs: regexify
##------------------------------------------------------------------------------
sub regexify {
  my $str = shift;
  $str =~ s/([\[\]\+\*\.\^\$\(\)\:\?])/\\$1/g;
  return '/^'.$str.'$/';
}

##------------------------------------------------------------------------------
## MAIN
##------------------------------------------------------------------------------

##-- load: labels
$lts->loadLabels($lts_labfile)
  or die("$progname: load failed for labels '$lts_labfile': $!");

##-- load: fst
$lts->loadFst($lts_fstfile)
  or die("$progname: load failed for automaton '$lts_fstfile': $!");

##-- load: dict
if (defined($lts_dictfile)) {
  $lts->loadDict($lts_dictfile)
    or die("$progname: load failed for dictionary file '$lts_dictfile': $!");
}


##-- expand query
our $query = join(' ', @ARGV);
$query = decode($queryenc,$query) if ($queryenc);
$query =~ s/\$p\~([^\s\"\(\)\&\|]+)/'$p='.regexify($lts->analyze($1))/ge;
$query = encode($queryenc,$query) if ($queryenc);

print STDERR "$progname: $query\n" if ($verbose);

print $query, "\n";

__END__

##------------------------------------------------------------------------------
## PODS
##------------------------------------------------------------------------------
=pod

=head1 NAME

ddc-expand-lts-query.perl - LTS-savvy DDC-query expander

=head1 SYNOPSIS

 ddc-expand-lts-query.perl [OPTIONS] [QUERY...]

 General Options:
  -help

 LTS Analysis Objects:
  -fst  GFSMFILE         # LTS analysis FST
  -lab  LABFILE          # LTS analysis labels (default: basename(GFSMFILE).lab)
  -dict DICTFILE         # exception dictionary

 LTS Analysis Options:
  -labenc   ENCODING     # use ENCODING for labels
  -queryenc ENCODING     # use ENCODING for query
  -check   , -no-check   # do/don't check for unknown symbols (default=do)
  -tolower , -nolower    # do/don't force input to lower case (default=do)

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

not yet written

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

not yet written

=cut


##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut

