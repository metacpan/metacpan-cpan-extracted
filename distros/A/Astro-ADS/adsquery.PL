#!/usr/bin/perl -w

use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
my $origdir = cwd;
chdir dirname($0);
my $file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{startperl}
    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
        if \$running_under_some_shell;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

=head1 NAME

 adsquery - tool to query ADS and print out the result

=head1 SYNOPSIS

  adsquery --author="Jenness,T."

=head1 DESCRIPTION

Command line interface to the C<Astro::ADS> classes.
Given some query parameters (such as author) a query is sent
to the ADS and the result is sent to standard output.

=head1 ARGUMENTS

The following arguments are recognized:

=over 4

=item B<--help>

Print a usage message.

=item B<--man>

List the full documentation.

=item B<--version>

The version number.

=item B<--author>

Specify the author to use for the query. Multiple authors can
be specified simply by using the option more than once.

  adsquery --author="Author1" --author="Author2"

=item B<--bibcode>

Specify a bibcode to use for the query. If a bibcode (or multiple
bibcodes) is specified then any authors supplied are ignored since
a bibcode is unique.

=item B<--bibfile>

Name of a file containing multiple bibcodes. One bibcode per line.
If the file can not be found the command aborts.

=item B<--count>

Simply counts the number of papers that match the query
and exits.

=item B<--useor>

Use OR logic with the author list. Default is to AND the authors
for the query.

=item B<--xml>

Output the results in XML where the element names are the
same as the query fields. The top level element is 
E<lt>ADSResultE<gt>. Default is to print a tabulated ASCII
result.

=item B<--debug>

Turn on debug messages. Default is off.

=back

=cut

use strict;

use Pod::Usage;
use Getopt::Long;

use Astro::ADS::Query;

use vars qw/ $VERSION /;
$VERSION = (qw$Revision: 1.1 $ )[1];

# Init options
my ($help, $man, $version, %opt);
$opt{author} = [];
$opt{bibcode} = [];
GetOptions( "help"     => \$help,
	    "man"      => \$man,
	    "version"  => \$version,
	    "author=s" => $opt{author},
	    "useor"    => \$opt{useor},
	    "xml"      => \$opt{xml},
	    "count"    => \$opt{count},
	    "debug"    => \$opt{debug},
	    "bibcode=s"  => $opt{bibcode},
	    "bibfile=s"  => \$opt{bibfile},
	  );

# deal with options that abort
pod2usage(-verbose => 1)  if ($help);
pod2usage(-verbose => 2)  if ($man);

if ($version) {
  print "adsquery Version $VERSION\n";
  exit;
}

# if we have been supplied with a file of bibcodes open it 
# and store the results into the bibcode array
if ($opt{bibfile}) {
  open BIB, $opt{bibfile}
    or die "Could not open bibfile $opt{bibfile}: $!\n";

  # Read each line from the file and remove the newline
  # We only want to store it if the remainder of the line matches
  # a non-space character
  @{$opt{bibcode}} = grep { chomp; /\w/ } <BIB>;

  close(BIB)
    or die "Strange error closing bibfile: $!\n";
}

# Now form the query - we are either doing a bibcode query or
# an author query. Currently multiple bibcodes must be
# sent as multiple queries
# Bibcodes override authors
my $query;
if (@{ $opt{bibcode} }) {

  print "Bibcode: ", $opt{bibcode}->[0], "\n" if $opt{debug};

  # For now just run the query on the first bibcode
  # this is for code symmetry since then the result object
  # can be used for the rest of the code.
  $query = new Astro::ADS::Query( Bibcode => $opt{bibcode}->[0] );

} elsif (@{ $opt{author} }) {
  $query = new Astro::ADS::Query( Authors => $opt{author} );

  # Set the author logic
  if ($opt{useor}) {
    $query->authorlogic("OR");
  } else {
    $query->authorlogic("AND");
  }

} else {
  die "No query specified\n";
}

# Run the query
print "Connecting to ADS\n" if $opt{debug};
my $result = $query->querydb();
my @papers = $result->papers;


print "Received ",scalar(@papers)," papers\n" if $opt{debug};

if ($opt{count}) {
  print scalar(@papers),"\n";
  exit;
}



# If we are using XML output print outer element
print "<ADSResult>\n" if $opt{xml};

# Print out each of the papers
if ($opt{xml}) {
  print $result->summary(format => "XML");
} else {
  print "$result";
}

=head1 BUGS

Currently only a single bibcode is used for a bib query even if multiple
values are supplied.

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Tim Jenness. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
