#!/usr/local/bin/perl

use Pod::Html;
$marker = shift;

print STDERR "Creating HTML documentation in docs...\n";

mkdir "docs",0755;
mkdir "docs/Ace",0755;
mkdir "docs/Ace/Sequence",0755;
mkdir "docs/Ace/Browser",0755;
mkdir "docs/Ace/Graphics",0755;
foreach $pod ('Ace.pm',<Ace/*.pm>,<Ace/*/*.pm>) {
  (my $out = $pod) =~ s/\.pm$/.html/;

  if (open(POD,"-|")) {
    open (OUT,">docs/$out");
    while (<POD>) {
      if (/<BODY>/) {
	print OUT <<END;
<BODY BGCOLOR="white">
<!--NAVBAR-->
<hr>
<a href="http://stein.cshl.org/AcePerl">AcePerl Main Page</a>
END
;
      } else {
	print OUT;
      }
    }
  } else {  # child process
    open STDERR,">/dev/null";
    pod2html(
	     $pod,
	     '--podroot=.',
	     '--podpath=.',
	     '--noindex',
	     '--htmlroot=/AcePerl/docs',
	     "--infile=$pod",
	     "--outfile=-"
	    );
    exit 0;
  }
}

system "touch $marker" if $marker;
print STDERR "            ....done!\n";
