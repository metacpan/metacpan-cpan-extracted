#!/usr/bin/perl -w
# vim:ts=4:sw=4:tw=78

BEGIN {
	use File::Basename qw();
	use Cwd qw();
	use vars qw($ROOT);
	$ROOT = chdir(File::Basename::dirname($0)) && Cwd::getcwd();
}

use strict;
use Colloquy::Bot::Simple qw(daemonize);
use vars qw($VERSION $SELF $ROOT);

($SELF = $0) =~ s|^.*/||;
$VERSION = sprintf('%d.%02d', q$Revision: 516 $ =~ /(\d+)/g);
$SIG{'ALRM'} = sub { die "Alarm Caught; login took too long"; };
$SIG{'INT'}  = sub { die "Interrupt caught"; };

# Connect
alarm(10);
my $talker = Colloquy::Bot::Simple->new(
		host => '127.0.0.1',
		port => 1236,
		username => 'CpanBot',
		password => 'topsecret',
	);
alarm(0);

# Detach and loop
daemonize("/tmp/$SELF.pid",1);
chdir($ROOT) || die "Unable to change directory to $ROOT: $!";
$talker->listenLoop(\&event_callback, 600);
$talker->quit;

exit;

sub event_callback {
	my $talker = shift;
	my $event = @_ % 2 ? { alarm => 1 } : { @_ };

	if (exists $event->{alarm}) {
		print "Callback called as ALARM interrupt handler\n";
		cpan_rss_callback($talker,$event);

	} elsif ($event->{msgtype} eq 'TELL') {
		$talker->whisper($event->{person}, 'Pardon?');
	}

	return 0;
}

sub cpan_rss_callback {
	my ($talker,$event) = @_;

	use XML::RSS::Parser qw();
	use Date::Parse qw(str2time);
	my $parser = new XML::RSS::Parser;
	my $feed = $parser->parse_uri('http://search.cpan.org/uploads.rdf');

	my ($lastDate,$lastModule) = ('','');
	if (open(FH,"</var/tmp/lastCpanPkgDate.dat")) {
		($lastDate,$lastModule) = split(/\t/,<FH>);
		close(FH);
	}

	my $recentDate = 0;
	my $recentModule = '';
	foreach my $item ($feed->query("//item")) {
		my $date = str2time($item->query("dc:date")->text_content());
		my $module = $item->query("title")->text_content();
		my $link = $item->query("link")->text_content();
		my $desc = ''; eval { $desc = $item->query("description")->text_content(); };
		$desc = " - $desc" if $desc;

		$recentDate ||= $date;
		$recentModule ||= $module;
		last if ($lastDate > $date || $lastModule eq $module);

		$talker->whisper('%cpan', "$module $desc");
	}

	if (open(FH,">/var/tmp/lastCpanPkgDate.dat")) {
		print FH "$recentDate\t$recentModule";
		close(FH);
	}
}



