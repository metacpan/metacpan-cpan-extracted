#!/usr/bin/perl -w

use File::Basename qw(basename dirname);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use strict;
use utf8;
use open qw(:std :utf8);


##======================================================================
## Command-line
our ($help);
our $name  = undef;
our $value = '';
our $dictfile = undef;
our $force = 0;
GetOptions('help|h'=>\$help,
 	   'name|n|label|l=s' => \$name,
	   'value|v=s' => \$value,
	   'dictfile|dict|d=s' => \$dictfile,
	   'force!' => \$force,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-exitval=>1, -verbose=>0, -msg=>"no PROJECT.con specified"}) if (!@ARGV);
pod2usage({-exitval=>1, -verbose=>0, -msg=>"no index name specified: use the -name option"}) if (!$name);

##-- sanity check(s)
die("$0: newlines not allowed in -value") if ($value =~ /\n/);

##======================================================================
## MAIN

##-- load dict
my (%dict);
if ($dictfile) {
  open(my $dictfh, "<$dictfile")
    or die("$0: open failed for dict-file $dictfile: $!");
  my ($docfile,$docval);
  while (defined($_=<$dictfh>)) {
    chomp;
    next if (/^(?:%%|\#)/ || /^\s*$/);
    ($docfile,$docval) = split(/\t/,$_,2);
    $dict{$docfile} = $docval;
  }
  close $dictfh;
}

##-- ye olde loope
foreach my $confile (@ARGV) {
  (my $project=$confile) =~ s/\._?con$//i;
  $confile .= ".con" if ($confile !~ /\._?con$/ && !-e $confile);

  ##-- check files
  my $stringfile = "${project}._bibl_${name}_strings";
  my $intfile    = "${project}._bibl_${name}_integers";
  if (!$force && (-e $stringfile || -e $intfile)) {
    die("$0: index file(s) ${project}._bibl_${name}_(strings|integers) already exist; specify --force to overwrite");
    next;
  }

  ##-- read con-file
  open(my $confh,"<:raw", $confile)
    or die("$0: open failed for project file $confile: $!");
  my (@con);
  my $fileid = 0;
  while (defined($_=<$confh>)) {
    chomp;
    next if ($.==1 && /^Dialing DWDS Concordance\b/);
    push(@con, {file=>$_,fileid=>++$fileid});
  }
  close $confh;

  ##-- get {value} and {valid} keys
  $_->{value} = ($dictfile ? ($dict{$_->{file}}//'') : $value) foreach (@con);
  my %val2i   = map {($_->{value}=>undef)} @con;
  my $valid   = 0;
  my @values  = sort keys %val2i;
  $val2i{$_}  = $valid++ foreach (@values);
  $_->{valid} = $val2i{$_->{value}} foreach (@con);

  ##-- write: string-file
  open(my $stringfh,">$stringfile")
    or die("$0: open failed for string file $stringfile: $!");
  foreach (@values) {
    print $stringfh $_, "\n";
  }
  close $stringfh;
  print STDERR "$0: wrote ", scalar(@values)," value(s) to $stringfile\n";

  ##-- write: integer-file
  open(my $intfh,">:raw", $intfile)
    or die("$0: open failed for integer file $intfile: $!");
  foreach (@con) {
    print $intfh pack('L',$_->{valid});
  }
  close $intfh;
  print STDERR "$0: wrote ", scalar(@con), " value(s) to $intfile\n";
}

##-- all done
print STDERR
  ("$0: finished (but don't forget to add the index \`${name}' to your *.opt file(s))\n",
   #"\tBibl string 0 ${name} //NONE\n\n",
   #"$0: finished\n",
  );


__END__

##======================================================================
## PODs

=pod

=head1 NAME

 ddc-make-bibl.perl : add a bibliographic attribute to an existing DDC project without re-indexing.

=head1 SYNOPSIS

 ddc-make-bibl.perl [OPTIONS] PROJECT.con ...
 
 Options:
  -h, -help		# this help message
  -n, -name NAME	# bibl attribute name (REQUIRED)
  -v, -value VALUE	# use constant value VALUE (obsolete for ddc>=v2.0.27)
  -d, -dict DICTFILE	# use values from dictionary file DICTFILE (TAB-separated)
  -force		# force overwrite existing files (default:don't)
 
 Caveats:
  Generated indices must still be added to your project's *.opt file(s), e.g.
 
    Bibl string 0 NAME /DUMMY
 
  will add an "invisible" field NAME.

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

