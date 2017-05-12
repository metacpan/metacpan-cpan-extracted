use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'}

!GROK!THIS!

print OUT <<'!NO!SUBS!';

package Options;

use strict;

use Getopt::Long;
use File::Basename;

#
# Build a Main object.
#  
# options - hash table that is a list of the options recognized by
#           Main and in the syntax used by the GetOptions function
#           see the mygetopt::Long package for more information.
# short_usage - hash table mapping option name to a short description,
#               something like '-noheuristics -heuristics'. Not really
#               a description.
# long_usage - hash table mapping option name to a human readable
#              explanation of the option.
# default - hash table mapping option name to the default value for the 
#           option. 
# order - a list of the options in order. The usage command use this
#         list to show the options in order.
# 
sub new {
    my($type) = shift;
    my($self) = {};

    bless($self, $type);

    $self->{'options'} = {};
    $self->{'short_usage'} = {};
    $self->{'long_usage'} = {};
    $self->{'default'} = {};
    $self->{'order'} = [];
    #
    # Set default options
    #
    $self->initoptions();
    #
    # Override with caller choice
    #
    $self->initialize(@_);
    #
    # Parse the collected options
    #
    $self->getopt();

    return $self;
}

#
# Set the options available to everyone
#
sub initoptions {
    my($self) = shift;

    $self->initialize(
      ['help', '-help', 'get usage message'],
      ['fake', '-fake', 'do not actually perform any actions'],
    );
}

#
# Build a usage string, display it and die.
#
sub usage {
    my($self, $message) = @_;
    my($command) = basename($0);

    my($short_usage);
    my($long_usage);
    my($order) = $self->{'order'};
    my($option);
    foreach $option (reverse(@$order)) {
	$short_usage .= "$self->{'short_usage'}->{$option}";
	$long_usage .= "$self->{'long_usage'}->{$option}";
    }

    die "$message\nusage: $command $short_usage\n$long_usage";
}

#
# Build a synopsis line for manual entries
#
sub synopsis {
    my($self, $message) = @_;
    my($command) = basename($0);

    my($synopsis);
    my($order) = $self->{'order'};
    my($option);
    foreach $option (reverse(@$order)) {
	$synopsis .= "$self->{'short_usage'}->{$option}";
    }

    return "$command $synopsis";
}

# Analyse the options in @ARGV according to the specifications in
# 'options' variable.
#
sub getopt {
    my($self) = shift;

    return if($self->{'getopt_done'});

    my($options) = $self->{'options'};

    if (!GetOptions($self->{'linkage'}, keys(%$options)) || $::opt_help) {
	$self->usage();
    }

    $self->{'getopt_done'} = 'yes';
}

#
# Analyze the options specs given in argument.
# The specs are a table with entries containing three fields:
#   . option description for GetOptions (see mygetopt::Long)
#   . short description
#   . long description
#
sub initialize {
    my($self) = shift;

    my($spec);
    my($order) = $self->{'order'};
    foreach $spec (@_) {
	my($option, $flags, $explain) = @$spec;
	my($name) = $option;
	$name =~ s/[=!].*//;
	my($var);
	eval "\$var = \\\$::opt_$name";
	$self->{'linkage'}->{$name} = $var;
	$self->{'options'}->{$option} = 1;
	$self->{'short_usage'}->{$option} = "[$flags] ";
	$self->{'long_usage'}->{$option} = "\t$flags\t$explain\n";
	$self->{'explain'}->{$option} = "$explain";
	push(@$order, $option) if(!grep($_ eq $option, @$order));
    }
}

#
# Build an arg string suitable for running a new command.
# Only the options of the package given in argument are analyzed.
# Only the options in @valid are returned.
#
sub options {
    my($self, $package, @valid) = @_;

    my($my_options) = "${package}::my_options";
    my(@options);
    my($options);
    foreach $options ($self->${my_options}(@valid)) {
#	print "options = $options\n";
	if(!grep($_ eq $options, @options)) {
	    push(@options, $options);
	}
    }
    return "@options";
}

#
# Each package should define this function to call extract_options
# in a given order.
#
sub my_options {
    my($self, @valid) = @_;

    return $self->extract_options('help', 'fake', @valid);
}

#
# Backbone of options. Make the string rebuilding the options given
# in @ARGV initialy.
#
sub extract_options {
    my($self, @valid) = @_;
    
    my($options) = $self->{'options'};
    my($option);
    my($tmp);
    foreach $option (keys(%$options)) {
	my($flag) = $option =~ /^(.+?)\b.*/;
	next if(!grep($_ eq $flag, @valid));
	my($var) = "::opt_$flag";
	
	if(defined($$var)) {
	    if($option =~ /!$/) {
		if($$var) {
		    $tmp .= "-$flag ";
		} else {
		    $tmp .= "-no$flag ";
		}
	    } elsif($option =~ /=[is]$/) {
		if($$var ne $self->{'default'}->{$flag}) {
		    $tmp .= "-$flag '$$var' ";
		}
	    } else {
		$tmp .= "-$flag ";
	    }
	}
    }
    return $tmp;
}

package main;

use strict;

my($product);
my($base);

sub main {
    $::opt_module = 'Catalog';
    my($main) = Options->new(
              ['contributor=s', '-contributor <name>', 'contributor name'],
              ['commit', '-commit', 'commit changes & ask for integration'],
              ['checkout', '-checkout', 'checkout latest branch'],
              ['diff', '-diff', 'diff since last change'],
              ['merge=s', '-merge <change>', 'merge contributor changes number <change>'],
              ['branch', '-branch', 'create contributor branch'],
              ['module', '-module <name>', 'use module <name> (default Catalog)'],
					  );

    $main->usage("missing -contributor <name>") if(!defined($::opt_contributor));

    $product = $::opt_module;
    $base = lc($::opt_module);

    my($maintainer) = 'senga@senga.org';

    if($::opt_merge || $::opt_branch) {
	pause("NOT ALLOWED TO CONTRIBUTORS return to proceed or ctrl-c to cancel ");
	if($::opt_merge) {
	    die "$product directory/file exists" if(-d $product || -f $product);
	    run("cvs checkout $product");
	    my($info) = cvsinfo('trunc');
	    my($branch) = "$base-$info->{'newest_version'}-$::opt_contributor";
	    my($from) = $::opt_merge;
	    my($to) = sprintf("%02d", $from + 1);
	    run("cvs update -ko -j $branch-$from -j $branch-$to");
	} elsif($::opt_branch) {
	    my($info) = cvsinfo('trunc');
	    my($trunc) = "$base-$info->{'trunc_major'}-$info->{'trunc_next_minor'}";
	    my($branch) = "$trunc-$::opt_contributor";
	    die "$branch already exists" if($branch eq $info->{'newest_branch'});
	    mkdir("cvstmp", 0777) or die "cannot mkdir cvstmp : $!";
	    chdir("cvstmp") or die "cannot chdir cvstmp : $!";
	    run("cvs rtag $trunc $product");
	    run("cvs rtag -b -r $trunc $branch $product");
	    run("cvs checkout -r $branch $product");
	    chdir("$product") or die "cannot chdir $product : $!";
	    run("cvs tag $branch-1");
	    chdir("../..") or die "cannot chdir ../.. : $!";
	    run("rm -fr cvstmp");
	    print "Mail $::opt_contributor that $branch is ready\n";
	}
    } else {
	my($info) = cvsinfo('contributor');
	my($cmd);
	if($::opt_commit) {
	    run("make clean realclean") if(-f 'Makefile');
	    run("cvs update");
	    run("cvs commit");
	    run("cvs tag -F $info->{'next_change'}");
	    print "Now send a mail to $maintainer to ask for integration of $info->{'next_change'}\n";
	} elsif($::opt_checkout) {
	    $cmd = ".." ; print "cd $cmd\n" ; chdir($cmd) || die "cannot chdir $cmd : $!";
	    if($info->{'newest_branch'} eq $info->{'current_branch'}) {
		print "You have already checked out the newest branch\n";
	    } else {
		my($backup) = "$product-$info->{'current_version'}";
		die "$product directory does not exist" if(! -d $product);
		die "$backup exists (regular file)" if(-f $backup);
		die "$backup exists (directory)" if(-d $backup);
		run("mv $product $backup");
		run("cvs checkout -r $info->{'newest_branch'} $product");
	    }
	} elsif($::opt_diff) {
	    run("cvs diff -c -r $info->{'current_change'} > ../$info->{'current_change'}.diff");
	}
    }
}

sub run {
    my($cmd) = @_;

    my($input) = pause("Press return to proceed, s to skip or ctrl-c to cancel\n$cmd ");
    if($input !~ /^s/io) {
	system($cmd);
    }
}

sub pause {
    my($msg) = @_;
    print $msg;
    my($input) = scalar(<>);
    chop($input);
    return $input;
}

sub cvsinfo {
    my($what) = @_;

    my(%info);

    die "must run in the directory containing the $product directory" if(! -f "$product/COPYING");
    print "cd $product\n" ; chdir($product) || die "cannot chdir $product : $!";

    if($what eq 'contributor') {
	my($file) = "CVS/Tag";
	open(FILE, "<$file") or die "cannot open $file for reading : $!";
	($info{'current_branch'}) = scalar(<FILE>) =~ /^T(.*)/;
	close(FILE);

	print "$info{'current_branch'}";
	die "$info{'current_branch'} does not contain $::opt_contributor" if($info{'current_branch'} !~ /-$::opt_contributor$/);

	($info{'current_version'}) = $info{'current_branch'} =~ /^$base-(\d+-\d+)-$::opt_contributor$/;

	die "could not extract current_version from $info{'current_branch'}" if(!defined($info{'current_version'}));
    }

    my($cmd) = "cvs log -h COPYING |";
    open(FILE, $cmd) or die "cannot open $cmd : $!";
    my($symbolic) = 0;
    while(<FILE>) {
	chop;
	if($symbolic && /^\t/) {
	    if(/^\t(.*-$::opt_contributor.*):/) {
		my($tag) = $1;
		if($tag =~ /^$base-\d+-\d+-$::opt_contributor$/) {
		    $info{'newest_branch'} = $tag if(!exists($info{'newest_branch'}));
		}
		if($tag =~ /^$info{'current_branch'}-\d+$/) {
		    if(!exists($info{'current_change'})) {
			$info{'current_change'} = $tag;
		    }
		}
		if($tag =~ /^$base-(\d+-\d+)-$::opt_contributor-(\d+)$/) {
		    if(!exists($info{'newest_change'})) {
			$info{'newest_version'} = $1;
			$info{'change_number'} = $2;
			$info{'newest_change'} = $tag;
		    }
		}
	    } elsif(/^\t$base-(\d+)-(\d+):/) {
		if(!exists($info{'trunc_major'})) {
		    $info{'trunc_major'} = $1;
		    $info{'trunc_minor'} = $2;
		    $info{'trunc_next_minor'} = sprintf("%02d", $2 + 1);
		}
	    }
	} else {
	    $symbolic = /^symbolic names/o;
	}
    }
    close(FILE);

    if($what eq 'contributor') {
	$info{'next_change'} = "$info{'current_branch'}-" . ($info{'change_number'} + 1);
    }

    die "could not find trunc for $product" if(!exists($info{'trunc_major'}));

    return \%info;
}

main();

!NO!SUBS!

# Local Variables: ***
# mode: perl ***
# End: ***
