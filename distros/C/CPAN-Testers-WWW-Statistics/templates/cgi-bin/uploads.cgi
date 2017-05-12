#!/usr/bin/perl -w
use strict;
$|++;

my $VERSION = '0.01';

#----------------------------------------------------------------------------

=head1 NAME

uploads.cgi - script to list the last 30 days of uploads.

=head1 SYNOPSIS

  perl uploads.cgi

=head1 DESCRIPTION

Displays a list of the last 30 days of uploads.

=cut

# -------------------------------------
# Library Modules

use CGI;
#use CGI::Carp qw(fatalsToBrowser);
use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use DateTime;
use IO::File;
use Sort::Rank qw(rank_sort);
use Template;

# -------------------------------------
# Variables

my $LOG = 'logs/cpanstats.log';
my $CONFIG = './cpanmail.ini';

my %tvars;

# -------------------------------------
# Program

my $cgi = CGI->new();

process();
results();

# -------------------------------------
# Subroutines

=item process

Access the database and retrieve the required article data.

=cut

sub process {
    my %hash = @_;
    my $cfg;

    # load configuration file
    local $SIG{'__WARN__'} = \&_alarm_handler;
    eval { $cfg = Config::IniFiles->new( -file => $CONFIG ); };
    return 0    unless($cfg && !$@);

    # configure databases
    my $db = 'CPANSTATS';
    return 0    unless($cfg->SectionExists($db));
    my %opts = map {my $v = $cfg->val($db,$_); defined($v) ? ($_ => $v) : () }
                    qw(driver database dbfile dbhost dbport dbuser dbpass);
    my $dbh = CPAN::Testers::Common::DBUtils->new(%opts);
    return 0    unless($dbh);

    my $sql = q[
        SELECT DATE(FROM_UNIXTIME(released)) AS reldate,
               COUNT(*) AS num_dists,
               COUNT(distinct author) AS num_authors 
          FROM uploads 
         WHERE DATE(FROM_UNIXTIME(released)) >= DATE_SUB(NOW(),INTERVAL 30 DAY) 
      GROUP BY DATE(FROM_UNIXTIME(released))
      ORDER BY DATE(FROM_UNIXTIME(released)) DESC
    ];

    my @rows = $dbh->get_query('hash',$sql);
    if(@rows) {
        for my $row (@rows) {
            my ($y,$m,$d) = split('-',$row->{reldate});
            my $dt = DateTime->new({ year => $y, month => $m, day => $d });
            $row->{day} = ucfirst $dt->day_abbr;
        }

        $tvars{rows} = \@rows;
    }

    $sql = q[
        SELECT DATE(FROM_UNIXTIME(released)) AS name,
               COUNT(*) AS score
          FROM uploads 
      GROUP BY DATE(FROM_UNIXTIME(released))
      ORDER BY score DESC
         LIMIT 10
    ];

    my @releases = $dbh->get_query('hash',$sql);
    if(@releases) {
        my @sorted = rank_sort(\@releases);
        $tvars{releases} = \@sorted;
    }

    $sql = q[
        SELECT DATE(FROM_UNIXTIME(released)) AS name,
               COUNT(distinct author) AS score 
          FROM uploads 
      GROUP BY DATE(FROM_UNIXTIME(released))
      ORDER BY score DESC
         LIMIT 10
    ];

    my @authors = $dbh->get_query('hash',$sql);
    if(@authors) {
        my @sorted = rank_sort(\@authors);
        $tvars{authors} = \@sorted;
    }

    # top submitters today
    $sql = q[
        SELECT author AS name,
               COUNT(*) AS score 
          FROM uploads 
         WHERE DATE(FROM_UNIXTIME(released)) = DATE(NOW())
      GROUP BY author
      ORDER BY score DESC
         LIMIT 100
    ];

    my @submitters = $dbh->get_query('hash',$sql);
    if(@submitters) {
        my @sorted = rank_sort(\@submitters);
        $tvars{submitters} = \@sorted;
    }


    #neocpanism data
    $sql = q[
        SELECT x.name,
               COUNT(*) AS score 
          FROM (    SELECT dist,
                           DATE(FROM_UNIXTIME(MIN(released))) AS name 
                      FROM uploads
                  GROUP BY dist) AS x
      GROUP BY x.name
      ORDER BY score DESC
         LIMIT 10
    ];

    my @neodist = $dbh->get_query('hash',$sql);
    if(@neodist) {
        my @sorted = rank_sort(\@neodist);
        $tvars{neodist} = \@sorted;
    }

    $sql = q[
        SELECT x.name,
               COUNT(*) AS score 
          FROM (    SELECT author,
                           DATE(FROM_UNIXTIME(MIN(released))) AS name 
                      FROM uploads
                  GROUP BY author) AS x
      GROUP BY x.name
      ORDER BY score DESC
         LIMIT 10
    ];

    my @neoauth = $dbh->get_query('hash',$sql);
    if(@neoauth) {
        my @sorted = rank_sort(\@neoauth);
        $tvars{neoauth} = \@sorted;
    }


    # graph data
    my $today    = DateTime->now;
    my $tomorrow = DateTime->now->add( days => 1 );

    $tvars{start}   = DateTime->new({
        year      => $today->year,
        month     => $today->month,
        day       => $today->day,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC'
    })->epoch;
    $tvars{finish}  = DateTime->new({
        year      => $tomorrow->year,
        month     => $tomorrow->month,
        day       => $tomorrow->day,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC'
    })->epoch;

    $tvars{start}  = int($tvars{start}  / 600);
    $tvars{finish} = int($tvars{finish} / 600);

    $sql = q[
        SELECT round(released/600,0) AS reldate,
               COUNT(*) AS num
          FROM uploads
         WHERE DATE(FROM_UNIXTIME(released)) = DATE(NOW())
      GROUP BY round(released/600,0)
      ORDER BY released
    ];

    my @uploads = $dbh->get_query('hash',$sql);
    {
        my $last = $tvars{start};
        my $sum = 0;
        my (%data1,@data1,@data2,@data3,@data4);
        $data1{ $tvars{start} } = 0;

        for my $row (@uploads) {
            $sum += $row->{num};
            $data1{ $row->{reldate}} = $sum;
            $last = $row->{reldate};
        }

        my $cnt = 0;
        foreach(my $time = $tvars{start} ; $time <= $last ; $time++) {
            $cnt = $data1{$time} if($data1{$time});
            push @data1, { reldate => reldate(DateTime->from_epoch( epoch => $time*600 )->hms('')), num => $cnt };
        }

        foreach(my $time = $last ; $time <= $tvars{finish} ; $time++) {
            $cnt = $sum > 0 ? int( $sum / ($last - $tvars{start}) * ($time - $tvars{start}) ) : 0;
            push @data2, { reldate => reldate(DateTime->from_epoch( epoch => $time*600 )->hms('')), num => $cnt };
        }
        $data2[-1]->{reldate} = '24';

        push @data3, { reldate => '0', num => 150 }, { reldate => '24', num => 150 };
        push @data4, { reldate => '0', num => 1000 }, { reldate => '24', num => 1000 };

        $tvars{data}{layer1} = \@data1;
        $tvars{data}{layer2} = \@data2;
        $tvars{data}{layer3} = \@data3;
        $tvars{data}{layer4} = \@data4;
    }

    $sql = q[
        SELECT author,
               min(released) AS reldate
          FROM uploads
         WHERE DATE(FROM_UNIXTIME(released)) = DATE(NOW())
      GROUP BY author
      ORDER BY reldate
    ];

    my @uauthors = $dbh->get_query('hash',$sql);
    {
        my $last = $tvars{start};
        my $sum = 0;
        my (%data1,@data1,@data2,@data3,@data4);
        $data1{ $tvars{start} } = 0;

        for my $author (@uauthors) {
            my $time = int($author->{reldate} / 600);
            $sum++;
            $data1{ $time } = $sum;
            $last = $time;
        }

        my $cnt = 0;
        foreach(my $time = $tvars{start} ; $time <= $last ; $time++) {
            $cnt = $data1{$time} if($data1{$time});
            push @data1, { reldate => reldate(DateTime->from_epoch( epoch => $time*600 )->hms('')), num => $cnt };
        }

        foreach(my $time = $last ; $time <= $tvars{finish} ; $time++) {
            $cnt = $sum > 0 ? int( $sum / ($last - $tvars{start}) * ($time - $tvars{start}) ) : 0;
            push @data2, { reldate => reldate(DateTime->from_epoch( epoch => $time*600 )->hms('')), num => $cnt };
        }
        $data2[-1]->{reldate} = '24';

        push @data3, { reldate => '0', num => 74 }, { reldate => '24', num => 74 };
        push @data4, { reldate => '0', num => 100 }, { reldate => '24', num => 100 };

        $tvars{data}{layer5} = \@data1;
        $tvars{data}{layer6} = \@data2;
        $tvars{data}{layer7} = \@data3;
        $tvars{data}{layer8} = \@data4;
    }
}

sub reldate {
    my $time = shift;
    $time = int($time) / 10000;
    my $mod = $time - int($time);
    return int($time) if($mod == 0);
    return sprintf "%.2f", int($time) + ($mod/0.6);
}

=item results

Outputs the results using Template Toolkit

=cut

sub results {
    my %config = (								# provide config info
		RELATIVE		=> 1,
		ABSOLUTE		=> 1,
		INCLUDE_PATH	=> '.',
		INTERPOLATE		=> 0,
		POST_CHOMP		=> 1,
		TRIM			=> 1,
	);

    print $cgi->header;
	my $parser = Template->new(\%config);		# initialise parser
	$parser->process('uploads.html',\%tvars,'../uploads.html')	# parse the template
		or die $parser->error();
}

sub _alarm_handler () { return; }

__END__

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org. However, it would help
greatly if you are able to pinpoint problems or even supply a patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<CPAN::Testers::WWW::Statistics>.

F<http://stats.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2011 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
