#!/usr/bin/perl -w

# this won't work out the box. I'll fix it in a later release. But it's what
# we use to look at the output from the chumping module (Blog). See
# http://2lmc.org/blog

use strict;
use Template;
use CGI;
use Time::Local;
use Calendar::Simple;
use Digest::MD5 qw(md5_hex);
use LWP::Simple;
use Image::Size;
use DBI;

my $vars = {};

my $db = DBI->connect("DBI:mysql:database=jerakeen", "2lmc", "2lmc");

my %title;
if (open(TITLES, "titles.txt")) {
    while (<TITLES>) {
        chomp;
        next unless $_;
        my ($url, $title) = split(/\s+/, $_, 2);
        $title{$url} = $title if $title;
    }
    close(TITLES);
}


my $timestamp = CGI::param("timestamp");
my $blog_id = CGI::param("blog_id");
my $upper = CGI::param("upper");
my $lower = CGI::param("lower");
my $search = CGI::param("search");

my $day = CGI::param("day");
my $month = CGI::param("month");
my $year = CGI::param("year");

my $title;

if ($day and $month and $year) {
    $lower = timegm(0, 0, 0, $day, $month-1, $year-1900);
    $upper = timegm(59, 59, 23, $day, $month-1, $year-1900);
    $title = sprintf("%04d/%02d/%02d", $year, $month, $day);
} elsif ($month and $year) {
    $lower = timegm(0, 0, 0, 1, $month-1, $year-1900);
    $upper = timegm(0, 0, 0, 1, $month, $year-1900) if $month < 12;
    $upper = timegm(0, 0, 0, 1, 0, $year-1899) if $month >= 12;
    $title = sprintf("%04d/%02d", $year, $month);
} elsif ($year) {
    $lower = timegm(0, 0, 0, 1, 0, $year-1900);
    $upper = timegm(59, 59, 23, 1, 0, $year-1899);
    $title = sprintf("%04d", $year);
}

$upper = 1500000000 unless defined($upper); # TODO - fix before Fri Jul 14 02:40:00 2017
$lower = 0 unless defined($lower);

my @calendar = calendar($month, $year, 1);
my $dates_ref = get_link_days($month, $year);
@calendar = merge(\@calendar, $dates_ref);

my @lt = localtime;
$vars->{calendar} = \@calendar;
$vars->{month} = $month || $lt[4]+1;
$vars->{year} = $year || $lt[5]+1900;
$vars->{today} = $day || $lt[3];
my @monthnames = (qw(dummy Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec));
$vars->{monthnames} = \@monthnames;
my @entries;

my $entry;

my $query;
if ($search) {
    my $sql = "SELECT DISTINCT mindblog.* FROM mindblog,mindblog_comments ";
    $sql .= "WHERE mindblog.blog_id=mindblog_comments.blog_id AND (";
    my @terms = split(/[\s,]+/, $search);
    $sql .= join(" AND ", map { "(mindblog.data LIKE '%$_%' OR mindblog_comments.data LIKE '%$_%')" } @terms);
    $sql .= ") ORDER BY mindblog.timestamp DESC LIMIT 20";

    print STDERR $sql;
    
    $query = $db->prepare($sql);
    $query->execute();
    $title = "search results for ".join(", ", @terms);

} elsif ($blog_id) {
    $query = $db->prepare("SELECT * FROM mindblog WHERE blog_id=? ORDER BY timestamp DESC");
    $query->execute($blog_id);

} elsif ($timestamp) {
    $query = $db->prepare("SELECT * FROM mindblog WHERE timestamp=? ORDER BY timestamp DESC");
    $query->execute($timestamp);
    
} elsif ($upper and $lower) {
    $query = $db->prepare("SELECT * FROM mindblog WHERE timestamp>? AND timestamp<? ORDER BY timestamp DESC");
    $query->execute($lower, $upper);

} else {
    $query = $db->prepare("SELECT * FROM mindblog ORDER BY timestamp DESC LIMIT 20");
    $query->execute();
    $title = "recent entries";
}

my $comment_query = $db->prepare("SELECT * FROM mindblog_comments WHERE blog_id=? ORDER BY timestamp");

while (my $row = $query->fetchrow_hashref) {

    $row->{data} =~ s/#\s*$//;

    if ($row->{data} =~ /^http:\S+$/) {
        my $title = get_title($row->{data});
        $row->{data} = "[$row->{data}|$title]" if $title;
    }
    $row->{message} = blog_filter($row->{data});

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime($row->{timestamp});
    $row->{date} = sprintf("%04d/%02d/%02d %02d:%02d", $year+1900, $mon+1, $mday, $hour, $min);

    $comment_query->execute($row->{blog_id});
    my $comments = [];
    while (my $comment = $comment_query->fetchrow_hashref) {
        $comment->{message} = blog_filter($comment->{data});
        push(@$comments, $comment);
    }

    $row->{comments} = $comments;

    push(@{$vars->{entries}}, $row);

}

if ($vars->{entries} and length(@{$vars->{entries}}) == 1) {
    $title ||= $vars->{entries}->[0]->{message};
    $title =~ s/<[^>]+>//g;
}

$title ||= "ramblings";
$vars->{title} = "2lmc blog - $title";
$vars->{sub_title} = $title;

$vars->{url} = CGI::url();

my @desc = (
            "on the internet, nobody knows you're not the Gartner Group",
            "Lasciate ogni speranza voi ch'entrate",
            "We laugh at Devil Bunny",
            "as despised by muttley",
           );

$vars->{description} = $desc[3];

my $tt = Template->new(POST_FOLD=>1, PRE_FOLD=>1);

my $template = "chump.tem";

if (defined(CGI::param("rss"))) {
    $template = "rss.tem";
    print CGI::header("text/xml");
    for (@{$vars->{entries}}) {
        $_->{title} = $_->{message};
        $_->{title} =~ s/<[^>]+>//g;
    }
} else {
    print CGI::header();
}

$tt->process($template, $vars) || print $tt->error();


sub blog_filter {
    my $text = shift;

    return '' if (!defined $text); # catch empty 'bc' mistakes

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/((?:^|[\b\s]))(http:\/\/[^>\s\"]+)/$1<a href="$2">$2<\/a>/gi;
    $text =~ s/\+\[([^\]]+)\]/chump_image($1)/eig;
    $text =~ s/\[([^\]]+)\]/chump($1)/eig;

    $text =~ s/\*([\w']+)\*/<b>$1<\/b>/ig;
    $text =~ s/\s\/(\w+)\/\s/<i>$1<\/i>/ig;

    return $text;
}

sub chump {
    my $text = shift;
    my ($one, $two) = split(/\|/, $text);
    $one =~ s/^\s+//;
    $one =~ s/\s+$//;
    $two =~ s/^\s+// if $two;
    $two =~ s/\s+$// if $two;


    if ($two) {
        # Ok, so we have [<one>|<two>]. We want to Do The Right Thing, and
        # not require people to remember which way round to put the link and
        # title. This is pretty easy to get right - 90% of the time, the link
        # is really obvious. These tests will catch 99% of the cases.

        # catch 'real' urls - http://, ftp://, etc.
        if ($one =~ /^\w+:\/\//) {
            return "<a href=\"$one\">$two</a>";
        } elsif ($two =~ /^\w+:\/\//) {
            return "<a href=\"$two\">$one</a>";

        # catch just numbers, guess if it's a blog_id or a timestamp
        # TODO if we ever have >10^8 blog entries, this will break.
        # Hopefuly, time() will be larger by then, and I can adjust this
        # number.
        } elsif ($one =~ /^\d{8,}$/) {
            return "<a href=\"".CGI::url()."?timestamp=$one\">$two</a>";
        } elsif ($one =~ /^\d+$/) {
            return "<a href=\"".CGI::url()."?blog_id=$one\">$two</a>";
        } elsif ($two =~ /^\d{8,}$/) {
            return "<a href=\"".CGI::url()."?timestamp=$two\">$one</a>";
        } elsif ($two =~ /^\d+$/) {
            return "<a href=\"".CGI::url()."?blog_id=$two\">$one</a>";

        # Finally, if we've matched neither end so far, try to pick up a
        # simpler form of uri, things like mailto:me@address.com.
        } elsif ($one =~ /^\w+:/) {
            return "<a href=\"$one\">$two</a>";
        } elsif ($two =~ /^\w+:/) {
            return "<a href=\"$two\">$one</a>";

        # ok, you got me. I'm stumped. Print /something/, at least.
        } else {
            return "[$one|$two]";
        }
                
    } else {
        if ($one =~ /^\w+:\/\//) {
            return "<a href=\"$one\">$one</a>";
        } elsif ($one =~ /^\d{8,}$/) {
            return "<a href=\"".CGI::url()."?timestamp=$one\">$one</a>";
        } elsif ($one =~ /^\d+$/) {
            return "<a href=\"".CGI::url()."?blog_id=$one\">$one</a>";
        } else {
            my $query = $db->prepare("SELECT * FROM infobot WHERE object=?");
            $query->execute("blog_shortcut $one");
            my $row = $query->fetchrow_hashref();
            return "[$one]" unless $row;
            return $row->{description} unless ($row->{description} =~ /\[(.*)\]/);
            return chump($1);
        }
    }
}

sub chump_image {
    my $text = shift;

    unless ($text =~ /(?:gif|jpe?g|png)$/i) {
        return "<br><iframe src=\"$text\" width=500 height=300></iframe><font size=-1>[<a href=\"$text\">$text</a>]</font><br>";
    }
    my $link = $text;
    my $hash = md5_hex($text);
    my $file = "cache/$hash";
    unless (-e "$file.jpg") {
        $text =~ s/&amp;/&/ig;
        $text =~ s/%2E/./ig;
        $text =~ s/%3A/:/ig;
        $text =~ s/%2F/\//ig;
        print STDERR "Getting $text to $hash\n";
        mirror($text, $file);
        print STDERR "Converting to jpg\n";
        print STDERR `convert \"$file\" \"$file.jpg\"`;
        my ($width, $height) = imgsize("$file.jpg");
        if (($width > 300) or ($height > 150)) {
            print STDERR "Resizing\n";
            `convert -resize 300x150 \"$file.jpg\" \"$file.jpg\"`;
            
        } else {
            undef $link;
        }
    }
    my $ret = "<br>";
    $ret .= "<a href=\"$link\">" if $link;
    $ret .= "<img src=\"http://2lmc.org/blog/$file.jpg\" alt=\"$text\" title=\"$text\">";
    $ret .= "</a>" if $link;
    $ret .= "<br>";
    return $ret;
}

sub get_title {
    my $url = shift;
    return $title{$url} if $title{$url};

    print STDERR "title for $url not cached\n";
    my $title;

    my $data = get($url);

    unless ($data) {
        print STDERR "  Can't get page\n";

    } elsif ($data =~ /<title>([^<]+)<\/title>/i) {
        $title = $1;
        $title =~ s/\|//g;
        $title =~ s/\n//g;
        $title =~ s/^\s+//;
        $title =~ s/\s+$//;
        print STDERR "  Found title $title\n";

    } else {
        print STDERR "  Can't find title\n";
    }

    $title ||= $url;
    $title{$url} = $title;
    save_titles();
    return $url;
}

sub save_titles {
    if (open(TITLES, ">titles.txt")) {
        for (keys(%title)) {
            print TITLES "$_ $title{$_}\n";
        }
        close(TITLES);
    } else {
        print STDERR "Can't save titles: $!\n";
    }
    
}

sub get_link_days {
  my ($month, $year) = @_;

  my ($start, $end)  = get_epochs($month, $year);
  my %dates;

  my $sql = "SELECT DISTINCT(FLOOR(timestamp/86400)) FROM mindblog WHERE timestamp > ? AND timestamp < ?";

  my $query = $db->prepare($sql);
  $query->execute($start, $end);

  my $comment_query = $db->prepare("SELECT * FROM mindblog_comments WHERE blog_id=? ORDER BY timestamp");
  
  while (my $row = $query->fetchrow_arrayref) {
#    print "Got ", Dumper($row);

    my ($day, $link) = get_url($row->[0]);

    $dates{$day} = $link;
  }  

  return \%dates;
}

sub merge {
  my ($cal, $dates) = @_;
  
  foreach my $week (@{ $cal }) { 
    foreach my $day (@{ $week }) {
      next if (!defined $day);
      if (exists $dates->{$day}) {
        $day = { $day => $dates->{$day} };
      } else {
        $day = { $day => undef };
      }
    }
  }
  
  return @{ $cal };
}

sub get_epochs {
  my ($mon, $year) = @_;
  
  my @lt = localtime;
  $mon  = $lt[4]+1    if (!$mon);
  $year = $lt[5]+1900 if (!$year);

  my $start_time = timelocal(0,0,0,1,$mon-1,$year-1900); 
  my $end_time;
  if ($mon < 12) {
    $end_time = timelocal(0,0,0,1,$mon,$year-1900); 
  } else {
    $end_time = timelocal(0,0,0,1,0,$year-1900+1); 
  }

  return ($start_time, $end_time); 
}

sub get_url {
  my $date  = shift;

  my $epoch = $date*86400;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime($epoch);

  my $link = sprintf("?day=%d;month=%d;year=%d", $mday, $mon+1, $year+1900);
  return ($mday, $link);
}
