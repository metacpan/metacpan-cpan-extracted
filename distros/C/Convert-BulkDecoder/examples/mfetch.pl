#!/usr/bin/perl -w

my $RCS_Id = '$Id: mfetch,v 1.7 2003-03-31 12:11:54+02 jv Exp $ ';

# Author          : Johan Vromans
# Created On      : Fri Jan 17 20:18:22 2003
# Last Modified By: Johan Vromans
# Last Modified On: Mon Mar 31 12:10:12 2003
# Update Count    : 138
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
# Tack '*' if it is not checked in into RCS.
$my_version .= '*' if length('$Locker:  $ ') > 12;

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $verbose = 0;		# verbose processing
my $delay = 0;			# wait between fetches
my $destdir = "";
my $rawfetch = 0;		# just fetch
my $dry_run = 0;		# don't

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();
exit if $dry_run;

# Post-processing.
$trace |= ($debug || $test);

$destdir .= "/" if $destdir;

################ Presets ################

use FindBin;
use lib $FindBin::Bin;

################ The Process ################

use Net::NNTP;
use Convert::BulkDecoder 0.03;

my $nntp;
my $server;
my $group = shift;
my @a = split(':',$group);
app_usage(1) if @a > 2 || @a == 0;
if ( @a > 1 ) {
    $server = shift(@a);
    $group = pop(@a);
}
$server ||= $ENV{NNTPSERVER} || $ENV{NEWSHOST} || "news";
&connect($server, $group);

my @alist = split(/:/, join(":",@ARGV));
my @art;
my $inx = "00";
my $cnt = @alist;
my $tag = "";

my $st = time;			# elapsed time
my $sz = 0;			# total size

foreach my $id ( @alist ) {
    $inx++;
    $tag = sprintf("%s %s", $id, $nntp->xhdr("subject",$id)->{$id});
    my $rtag = $tag;
    $rtag =~ s/^(\d+)/$id  ($inx\/$cnt)/;
    my $a = $nntp->article($id);
    unless ( $a ) {
	xwarn ("? $tag\n");
	# Retry 1.
	sleep(3);
	$a = $nntp->article($id);
	unless ( $a ) {
	    xwarn ("? $tag\n");
	    # Retry 2. Reset server.
	    $nntp->close;
	    sleep(3);
	    &connect($server, $group);
	    $a = $nntp->article($id);
	    unless ( $a ) {
		die("? $tag\n");
	    }
	}
    }
    xwarn ("+r $rtag\n");

    $sz += length($_) foreach (@$a);	# for statistics

    if ( $rawfetch ) {
	my $file = $destdir.$id;
	open (F, ">$file") or die("$file: $!\n");
	print F @$a;
	close(F);
	next;
    }

    if ( @art ) {
	# Remove extraneous headers to prevent uudecode problems.
	while ( $a->[0] =~ /\S/ ) {
	    shift(@$a);
	}
    }
    push (@art, @$a);
    sleep ($delay) if $delay;
}

unless ( $rawfetch ) {
    my $delta = time - $st;
    $tag = "";
    if ( $delta && $sz ) {
	my $speed = $sz / $delta;
	$speed >>= 10;
	$tag .= " $speed Kbps";
    }

    my $e = new Convert::BulkDecoder(destdir => $destdir,
				     neat => \&neat);
    my $res = $e->decode(\@art);

    foreach my $parts ( @{$e->{parts}} ) {
	warn($parts->{file}, ": ", $parts->{result}, $tag, "\n");
    }
}

END {
    $nntp->close if $nntp;
}

################ Subroutines ################

sub connect {
    my ($server, $group) = @_;
    $nntp = new Net::NNTP($server);
    die("No $server?\n") unless $nntp;
    $nntp->reader();
    # Position at group.
    die("No such group: $group\n") unless $nntp->group($group);
}

sub xwarn {
    $_[0] =~ tr/\n -\176/_/c;
    warn($_[0]);
}

sub neat {
    local ($_) = @_;
    s/^\[a-z]://i;
    s/^.*?([^\\]+$)/$1/;
    # Make lowercase.
    $_ = lc($_);
    # Spaces and unprintables to _.
    s/\s+/_/g;
    s/\.\.+/./g;
    s/[\0-\040'`"\177-\240\/]/_/g;
    # Remove leading dots.
    s/^\.+//;
    # Remove : so we can store on VFAT disks :-(.
    s/:/_/g;
    $_;
}

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $comment;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'destdir=s'  => \$destdir,
		     'fetch'	  => \$rawfetch,
		     'comment=s'  => \$comment,
		     'dry-run|n'  => \$dry_run,
		     'delay=i'	  => \$delay,
		     'ident'	  => \$ident,
		     'verbose'	  => \$verbose,
		     'trace'	  => \$trace,
		     'help|?'	  => \$help,
		     'debug'	  => \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident() if $ident;
}

sub app_ident {
    warn ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [server]:group artnum [...]
    -comment NNN	comment
    -dry-run|n		don't
    -destdir		where to store the results
    -fetch		just fetch
    -delay NN		wait NN secs between fetches
    -help		this message
    -ident		show identification
    -verbose		verbose information
Usage: $0 -neat
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

__END__

=head1 NAME

mfetch - fetch and decode (multi-part) articles from a NNTP server

=head1 SYNOPSIS

  mfetch newszilla.news.com:alt.binaries.sounds.mp3.camel 35351 35353 35355 35350 35356

  NNTPHOST=newszilla.news.com; export NNTPHOST
  mfetch alt.binaries.sounds.mp3.camel 35351:35353:35355 35350:35356

  mfetch --destdir my_mp3_dir alt.binaries.sounds.mp3.camel 35351:35353:35355 35350:35356

=head1 DESCRIPTION

mfetch retrieves news articles from an NNTP server, and decodes them
to extract the (possible binary) contents. It is particular useful for
news postings that contain programs or binary data like sounds and
images.

=head1 COMMAND LINE ARGUMENTS

mfetch takes two arguments: the name of the news group, and a list of
article numbers. The name of the news group may be prefixed with the
name of an NNTP server, separated by a colon. If the NNTP server is
left unspecified, mfetch uses standard environment variables to find
the NNTP server name, see below.

The list of article numbers may be passed as distinct arguments, or
combined in colon separated lists, or any combination thereof.

mfetch uses Convert::BulkDecoder to decode the contents, and hence
supports UUdecoding, ydecoding and MIME attachments.

For yencoded contents, file consistency is verified using length and
checksum tests.

=head1 COMMAND LINE OPTIONS

=over

=item --destdir I<dir>

The name of the directory where the resultant contents must be placed.
Default is to put the contents in the current directory.

=item --fetch

Just fetch the articles, and store them under the article numbers. No
decoding is done.

=item --delay I<secs>

Pause for I<secs> seconds between article fetches to reduce the load
of the network and server.

=item --dry-run -n

Don't do anything but checking the arguments.

=item --comment I<text>

Remarks for this action.

=back

=head1 LIMITATIONS

Only yencoded data can be CRC checked. CRC checking is slow, so only
the partial checksums are verified.

For multi-part submissions, the article numbers must be passed in the
right order.

=head1 DEPENDENCIES

L<Net::NNTP>, L<Convert::BulkDecoder>.

=head1 ENVIRONMENT VARIABLES

To find the news server, mfetch uses environment variables
C<NNTPSERVER>, C<NEWSHOST>, or defaults to a host named C<news>.

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 SEE ALSO

L<Convert::BulkDecoder>, L<newsgrab>.

=head1 COPYRIGHT AND LICENCE

Copyright 2003 Squirrel Consultancy.

License: Artistic.

=cut
