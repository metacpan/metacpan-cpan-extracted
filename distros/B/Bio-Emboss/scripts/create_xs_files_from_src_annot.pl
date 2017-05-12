#!/usr/bin/perl

use FileHandle;
use Data::Dumper;
use Getopt::Long;

use strict;

my $path = $0;
$path =~ s:/[^/]+$::;

my $olddir;
GetOptions("olddir=s", => \$olddir);


my $file;
foreach $file (@ARGV) {
    my $outfile = $file;
    $outfile =~ s:.*/::;

    $outfile =~ s/\.c$//;
    my $infile = $outfile;

    $outfile =~ s/^aj//;

    my $core = "Emboss_$outfile";

    $outfile = "$core.xs";

    my ($forder, $fcont, $fidx);
    ($forder, $fcont, $fidx) = get_func_order ("$olddir/$outfile") if -f "$olddir/$outfile";

    my $outfh  = open_xs_file ($outfile, $infile, $core);
    my $deprfh = open_xs_file ("deprecated_$outfile", $infile, $core . "_deprecated");
    my $depcntr = 0;

    my ($outarr, $outhash, $obshash) = create_xs_code_from_doc ($file);

    # --- print in old order
    foreach (@$forder) {
	my $idx = $outhash->{$_};
	if (defined ($idx)) {
	    print $outfh $outarr->[$idx];
	    $outarr->[$idx] = undef; # don't print again
	} elsif (exists($obshash->{$_})) {
	    #warn "$_ is considered obsolete in $file\n";
	    print $deprfh $fcont->[$fidx->{$_}];
	    ++$depcntr;
	} else {
	    warn "don't have information for $_ (removing it)\n";
	}
    }
    # --- print the rest
   foreach (@$outarr) {
       next unless defined $_;
       print $outfh $_;
    }
    
    close $outfh;
    close $deprfh;
    unlink "deprecated_$outfile" if $depcntr == 0;
}


sub get_func_order {
    my ($ofname) = @_;

    my @order;
    my @content = ("");
    my %bodyidx;

    open (FILE, $ofname);
    while (<FILE>) {
	if (/^(\w+)\s+\(/) {
	    push (@order, $1);
	    $bodyidx{$1} = $#content;
	}
	$content[-1] .= $_;
	if (/^\s*$/) {
	    push (@content, "");
	}
    }

    return (\@order, \@content, \%bodyidx);
}
    
sub create_xs_code_from_doc {
    my ($infile) = @_;

    my (%out, @out);
    my (%obsolete);

    open (FILE, $infile);
    while (<FILE>) {
	if ( /\/\* \@func (\w+)/) { # inside @func ... @@ block
	    my $funcname = $1;
	    my @params = ();
	    my $return = "void"; #undef;
	    while (<FILE>) {
		last if /\*\* \@\@/ or /\*\//; # end of @@ block
		if (/\*\* \@param +\[(\w+)\] +(\w+) *\[(.+?)\](?: |$)/) { # a @param line
		    my $hash = {
			name => $2,
			type => $3,
			rw   => $1};
		    push (@params, $hash);
	        }
	        elsif (/\*\* \@return +(?:\[\] +)?\[(.+?)\](?: |$)/) {
		    $return = $1;
		}
	    }

    	    if ( grep {$_->{rw} =~ /[vf]/ or $_->{type} =~ /\[\]/} @params) {
    	    	# --- ignore functions with varargs
    	    	# --- ignore functions with function-ptr arguments
		# --- ignore functions with [], e.g. char* const[]
    	    	next;
    	    }

	    my $l1 = join (", ",
		       map {$_->{name}} @params);
	    #$l1 = "void" unless $l1;

	    my $l2 = join ("\n       ",
			    map { type_to_prototype ($_, $infile) } @params);


	    $l2 = "       $l2\n" if $l2;

	    my @output = map {$_->{name}} 
	                   grep { $_->{isout} } @params;

	    #foreach (@params) { 
	    #	if ($_->{isout} and !($_->{rw} =~ /[wd]/))  {
	    #	    warn  "added to OUTPUT because of update: " . Dumper($_) . " $infile\n"
	    #	}
	    #};

	    unshift (@output, "RETVAL") unless $return eq "void";

	    my $output = "";
	    if (@output) {
	        $output = "    OUTPUT:\n       " .
	    	join ("\n       ", @output) . "\n";
	    }
	

	    #print $outfh "$return\n$funcname ($l1)\n$l2$output\n";
	    push (@out, "$return\n$funcname ($l1)\n$l2$output\n");
	    $out{$funcname} = $#out;

	} # end if  inside @func .
        elsif ( /\/\* \@obsolete (\w+)/) {
	    $obsolete{$1} = $1;
	} # end if  @obsolete
    } # end while
    return (\@out, \%out, \%obsolete);
}


sub type_to_prototype {
    my ($h, $infile) = @_;
    my $type = $h->{type};
    my $rw   = $h->{rw};
    my $name = $h->{name};

    unless ($type =~ /void *\*\*/) {
	if ($type =~ s/void *\*/char\*/) { # handle void* as char*, but not void**
	    ## warn "replaced void* => char* in " . Dumper($h) . " $infile\n";
	}
    }
    $type =~ s/^CONST +//;       # remove CAPITAL CONST

    # const won't work because of typedef instead of #define
    my @noconsttypes = qw(
			  AjPPStr
			  AjPResidue
			  );
    foreach my $t (@noconsttypes) {
	last if $type =~ s/const +$t/$t/;
    }

    if ($rw =~ /r/ ) {
	# do nothing

    } elsif ($rw =~ /u/ ) {
	if ($type =~ /\bchar\*$/) {
	    $h->{isout} = 1;
	} elsif ($type =~ /\bFILE/) {
	    # do nothing
	} else {
	    my $ok = $type =~ s/\*$/\&/;

	    $h->{isout} = 1 if $ok;
	    warn "\$rw =~ /u/ but no out because of missing \& in parameter: " . Dumper($h) . " $infile\n" unless $ok;
	}

    } elsif ($rw =~ /[wd]/ ) {
	$h->{isout} = 1; # is always output
	my $ok = $type =~ s/\*$/\&/;
	$ok ||= $type =~ /\bAjP/; # -- warn disabled for AjP.. types
        warn "problem with [$rw] $type $name $infile" unless $ok;

    } else {
	warn "unknown rw-status [$rw] $infile";
    }
    return $type . " " . $name;
}


sub open_xs_file {
    my ($outfile, $infile, $core) = @_;

    my $outfh = new FileHandle;
    open ($outfh, ">$outfile");
    print $outfh <<END_OF_OUT;
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::$core		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ${infile}.c: automatically generated

END_OF_OUT

   return $outfh;
}
