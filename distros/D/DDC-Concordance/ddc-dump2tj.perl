#!/usr/bin/perl -w

use JSON;
use File::Basename qw(basename dirname);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use strict;

##======================================================================
## Comman-line
my ($help);
my $outfile = '-';
my $text_index_name = '';
my $sent_break_name = '';
my @only_indices = qw();
my @only_breaks  = qw();
GetOptions('help|h' => \$help,
	   'output|out|o=s' => \$outfile,
	   'text|token|t|word|w=s' => \$text_index_name,
	   'sentence|sent|s=s' => \$sent_break_name,
	   'indices|index|i=s' => \@only_indices,
	   'breaks|break|b=s'  => \@only_breaks,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##======================================================================
## MAIN

my $json = JSON->new->allow_nonref(1)->utf8(0)->pretty(0)->relaxed(1)->canonical(1);

##-- process user request
my %only_indices = map {($_=>undef)} grep {($_//'') ne ''} map {split(/[\s\,]+/,$_)} @only_indices;
my %only_breaks  = map {($_=>undef)} grep {($_//'') ne ''} map {split(/[\s\,]+/,$_)} @only_breaks;

open(my $outfh, ">$outfile")
     or die("$0: open failed for output file '$outfile': $!");

push(@ARGV,'-') if (!@ARGV);
foreach my $infile (@ARGV) {
  my ($dump);
  {
    local $/ = undef;
    open(my $fh, "<:raw", $infile)
      or die("$0: open failed for '$infile' $!");
    my $buf = <$fh>;
    close($fh)
      or die("$0: failed to close $infile: $!");
    $dump = $json->decode($buf)
      or die("$0: failed to decode dump data from $infile: $!");
  }

  ##-- get basic doc properties
  my ($tbegin,$tend) = @{$dump->{tokids}}{qw(begin end)};
  my ($breaks,$pages,$indices) = @$dump{qw(breaks pages indices)};
  @$breaks  = grep {!%only_breaks || exists($only_breaks{$_->{shortname}}) || exists($only_breaks{$_->{longname}})} @$breaks;
  @$indices = grep {!%only_indices || exists($only_indices{$_->{shortname}}) || exists($only_indices{$_->{longname}})} @$indices;
  my %name2break = (map {($_->{shortname}=>$_,$_->{longname}=>$_)} @$breaks);
  my %name2index = (map {($_->{shortname}=>$_,$_->{longname}=>$_)} @$indices);
  my ($textindex,$sentbreak);
  $textindex  = ($text_index_name ? $name2index{$text_index_name} : $indices->[0])
    or warn("$0: could not find token-text index '$text_index_name', using ", ($textindex=$indices->[0])->{longname});
  $sentbreak  = ($sent_break_name ? $name2break{$sent_break_name} : $breaks->[0])
    or warn("$0: could not find sentence break '$sent_break_name', using ", ($sentbreak=$breaks->[0])->{longname});
  my $off_max    = 2**32-1;

  ##-- decode & dump: document attrrs
  my $tjdoc = {
	       base    => basename($dump->{meta}{file_}),
	       indices => {map {($_->{shortname}=>$_->{longname})} @$indices},
	       breaks  => {map {($_->{shortname}=>$_->{longname})} @$breaks},
	       meta    => $dump->{meta},
	      };
  print $outfh "%%\$TJ:DOC=", $json->encode($tjdoc), "\n";

  @$breaks      = ((grep {$_ ne ($sentbreak//'')} @$breaks), ($sentbreak ? ($sentbreak) : qw())); ##-- ensure sentence-breaks are processed last
  $_->{cur}     = 0 foreach (@$breaks);
  my $curpage   = $dump->{meta}{page_};
  my ($brki,$battrs);
  my %sattrs = map {($_->{longname}=>'')} grep {($_->{longname} ne $_->{shortname})} @$breaks[0..($#$breaks-1)];
  my %wattrs = qw();
  my (@breakbuf,$wtext);

  ##-- ye olde loope
  for (my $toki=$tbegin; $toki < $tend; $toki++) {

    ##-- check for page-breaks
    push(@breakbuf, "%%\$TJ:PAGE=".$json->encode($curpage=$pages->{$toki})."\n") if (exists($pages->{$toki}));

    ##-- check for breaks
    foreach (@$breaks) {
      while (($_->{offsets}[$_->{cur}]//$off_max)<=$toki) {
	$battrs = {id=>$_->{shortname}.($_->{offsets}[$_->{cur}]//$off_max), type=>$_->{longname}};
	if ($_ ne ($sentbreak//'')) {
	  push(@breakbuf, "%%\$TJ:BREAK=".$json->encode($battrs)."\n");
	  $sattrs{$_->{longname}} = $battrs->{id};
	} else {
	  $sattrs{id} = $battrs->{id};
	  push(@breakbuf, "%%\$TJ:SENT=",$json->encode(\%sattrs)."\n");
	  unshift(@breakbuf,"\n") if ($toki > $tbegin);
	}
	++$_->{cur};
      }
    }
    do {print $outfh @breakbuf; @breakbuf=qw();} if (@breakbuf);

    ##-- dump token
    %wattrs = (id=>"w$toki", map {($_->{shortname}=>$_->{values}[$toki-$tbegin])} @$indices);
    $wattrs{page_} = $curpage if (defined($curpage) && !exists($wattrs{page_}));
    $wtext  = $wattrs{$textindex->{shortname}}//'';
    print $outfh $wtext, "\t", $json->encode(\%wattrs), "\n";
  }
}

__END__

##======================================================================
## PODs

=pod

=head1 NAME

 ddc-dump2tj.perl : convert ddc_dump document data to flat (text+json) format

=head1 SYNOPSIS

 ddc-dump2tj.perl [OPTIONS] [DDC_JSON_DUMPFILE(s)...]
 
 Options:
  -h, -help		# this help message
  -o, -output OUTFILE	# set output file (default=- (stdout))
  -t, -text INDEX	# use INDEX values for tj text column (default:(first))
  -s, -sentence BREAK	# use BREAK values for tj sentence breaks (default:(first))
  -i, -index INDEX...	# only include specified indices (default:all)
  -b, -break BREAK...	# only include specified breaks (default:all)

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

