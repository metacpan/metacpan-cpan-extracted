package Labyrinth::Plugin::CPAN::Builder;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '3.60';

=head1 NAME

Labyrinth::Plugin::CPAN::Builder - Plugin to build the static files that drive the dynamic site.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Mailer;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Variables;
use Labyrinth::Writer;

use Labyrinth::Plugin::CPAN;
use Labyrinth::Plugin::Articles::Site;

use Clone   qw(clone);
use Cwd;
use File::Path;
use File::Slurp;
use JSON::XS;
#use Sort::Versions;
use Time::Local;
use Try::Tiny;
use XML::RSS;
#use YAML::XS;
use version;

#use Devel::Size qw(total_size);

#----------------------------------------------------------------------------
# Variables

my $RECENT  = 200;

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 METHODS

=head2 Public Interface Methods

=over 4

=item BasePages

Regenerates all site pages.

=item Process

Simple control process.

=item IndexPages

Rebuilds the index pages for each author and distribution letter directory.

=item RemovePages

Master controller for removing reports from author and distribution pages.

=item RemoveAuthorPages

Routine for removing reports from author pages.

=item RemoveDistroPages

Routine for removing reports from distribution pages.

=item AuthorPages

Rebuilds a named author page.

=item DistroPages

Rebuilds a named distribution page.

=item StatsPages

Rebuilds the stats pages for pass matrix.

=item RecentPage

Regenerates the recent page, and associated files.

=back

=cut

sub BasePages {
    my $cache = sprintf "%s/static", $settings{webdir};
    mkpath($cache);
    $tvars{cache}   = $cache;
    $tvars{static}  = 1;

    $tvars{content} = "content/welcome.html";
    my $text = Transform( 'cpan/layout-static.html', \%tvars );
    overwrite_file( $cache . '/index.html', $text );

    my $site = Labyrinth::Plugin::Articles::Site->new();
    $tvars{content} = "articles/arts-item.html";
    for my $page (qw(help about)) {
        $cgiparams{'name'} = $page;
        $site->Item();
        $text = Transform( 'cpan/layout-static.html', \%tvars );
        overwrite_file( "$cache/page/$page.html", $text );
    }
}

sub Process {
    my ($self,$progress,$type) = @_;

    # check whether we are running split or combined queries
    my $types = $type ? "'$type'" : "'author','distro'";

    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    my $olderhit = 0;
    my $quickhit = 1;
    while(1) {
        my $cnt = IndexPages($cpan,$dbi,$progress,$type);
        $cnt += RemovePages($cpan,$dbi,$progress,$type);

        # shouldn't really hard code these :)
        my ($query,$loop,$limit) = ('GetRequests',10,10);
        ($query,$loop,$limit) = ('GetOlderRequests',1,100)  if($quickhit == 1);
        ($query,$loop,$limit) = ('GetSmallRequests',2,10)   if($quickhit == 3);
        ($query,$loop,$limit) = ('GetLargeRequests',2,25)   if($quickhit == 5); # typically these are long running author searches

        my %names;
        for(1..$loop) {
            my @rows = $dbi->GetQuery('hash',$query,{types => $types, limit => $limit});
            last    unless(@rows);

            for my $row (@rows) {
                next    unless(defined $row->{type});
                next    if($names{$row->{type}} && $names{$row->{type}}{$row->{name}});
                if(defined $progress) {
                    $progress->( ".. processing $row->{type} $row->{name} => $row->{count} $row->{total}" );
                }
                if($row->{type} eq 'author')    { AuthorPages($cpan,$dbi,$row->{name},$progress) }
                else                            { DistroPages($cpan,$dbi,$row->{name},$progress) }

                $names{$row->{type}}{$row->{name}} = 1; # prevent repeating the same update too quickly.
                $cnt++;
            }
        }

        my $req = _request_count($dbi);
        $progress->( "Processed $cnt pages, $req requests remaining." ) if(defined $progress);
        #sleep(300)   if($cnt == 0 || $req == 0);
        last         if($cnt == 0 || $req == 0);

        my $age = _request_oldest($dbi);
        my @row = $dbi->GetQuery('hash','GetLargeRequests',{types => $types, limit => 1});
        my $sum = $row[0]->{total};
        my $num = $row[0]->{count};

        $quickhit =
            $sum > $settings{buildlevel4}                           # very high sum of requests for one request type
                ? 5
                : $num > $settings{buildlevel5}                     # very high num of requests for one request type
                    ? 5
                    : $age > $settings{agelimit1}                   # requests older than x days take priority
                        ? 1
                        : $req < $settings{buildlevel1}             # low amount of requests
                            ? 1
                            : $req < $settings{buildlevel2}         # medium level of requests
                                ? ++$quickhit % 2
                                : $req < $settings{buildlevel3}     # high level of requests
                                    ? ++$quickhit % 4
                                    : $age > $settings{agelimit2}   # older than x days
                                        ? 1
                                        : ++$quickhit % 6;          # very high level of requests
    }
}

sub IndexPages {
    my ($cpan,$dbi,$progress,$type) = @_;

    # check whether we are running split or combined queries
    my $types = "'ixauth','ixdist'";
    $types = "'ixauth'" if($type && $type eq 'author');
    $types = "'ixdist'" if($type && $type eq 'distro');

    my @index = $dbi->GetQuery('hash','GetIndexRequests',{types => $types});
    for my $index (@index) {
        my ($type,@list);

        $progress->( ".. processing $index->{type} $index->{name}" )     if(defined $progress);

        if($index->{type} eq 'ixauth') {
            my @rows = $dbi->GetQuery('hash','GetAuthors',"$index->{name}%");
            @list = map {$_->{author}} @rows;
            $type = 'author';
        } else {
            my @rows = $dbi->GetQuery('hash','GetDistros',"$index->{name}%");
            @list = map {$_->{dist}} @rows;
            $type = 'distro';
        }

        my $cache = sprintf "%s/static/%s/%s", $settings{webdir}, $type, substr($index->{name},0,1);
        mkpath($cache);

        $tvars{letter}  = $index->{name};
        $tvars{cache}   = $cache;
        $tvars{content} = "cpan/$type-list.html";
        $tvars{list}    = \@list if(@list);
        my $text = Transform( 'cpan/layout-static.html', \%tvars );
        overwrite_file( $cache . '/index.html', $text );

        if($type eq 'distro') {
            $cache = sprintf "%s/stats/%s/%s", $settings{webdir}, $type, substr($index->{name},0,1);
            mkpath($cache);

            my $destfile = "$cache/index.html";
            #$progress->( ".. processing $index->{type} $index->{name} - $destfile" )     if(defined $progress);
            $tvars{content} = 'cpan/stats-distro-index.html';
            $tvars{cache}   = $cache;
            $text = Transform( 'cpan/layout-stats-static.html', \%tvars );
            overwrite_file( $cache . '/index.html', $text );
        }

        # remove requests
        $dbi->DoQuery('DeletePageRequests',{ids => '0'},$index->{type},$index->{name});
    }

    return scalar(@index);
}

sub RemovePages {
    my ($cpan,$dbi,$progress,$type) = @_;

    # check whether we are running split or combined queries
    my $types = "'rmauth','rmdist'";
    $types = "'rmauth'" if($type && $type eq 'author');
    $types = "'rmdist'" if($type && $type eq 'distro');

    my @rows = $dbi->GetQuery('hash','GetRequests',{types => $types, limit => 20});
    return 0    unless(@rows);

    my @index = $dbi->GetQuery('hash','GetIndexRequests',{types => $types});
    for my $index (@index) {
        my ($type,@list);

        $progress->( ".. processing $index->{type} $index->{name}" )     if(defined $progress);

        if($index->{type} eq 'rmauth') {
            # 2016-04-21 = Barbie - temporarily suspended line below to allow author pages to generate
            # seems to be a bug picking up UUID for PSIXDISTS :(
            RemoveAuthorPages($cpan,$dbi,$progress,$index->{name});
        } else {
            RemoveDistroPages($cpan,$dbi,$progress,$index->{name});
        }
    }
}

# note $name is NOT the author name, but the dist name! need to get the reports to track version and then author

sub RemoveAuthorPages {
    my ($cpan,$dbi,$progress,$name) = @_;
    my (%remove,%author,@reports);
    my $fail = 0;

    # get ids from the page requests
    my @requests = $dbi->GetQuery('hash','GetRequestIDs',{names => $name},'rmauth');
    my %requests = map { $_->{id} => 1 } grep { $_->{id} } @requests;

    return  unless(keys %requests);
    push my @ids, keys %requests;

    my $next = $dbi->Iterator('hash','GetReportsByIDs',{ids=>join(',',@ids)});
    while(my $row = $next->()) {
        my @latest = $dbi->GetQuery('hash','CheckLatest',$row->{dist},$row->{version});
        next    unless(@latest);
        $author{$latest[0]->{author}}++;
        $remove{$row->{dist}}{uc $row->{state}}++;
    }

    for my $author (keys %author) {
        my $cache = sprintf "%s/static/author/%s", $settings{webdir}, substr($author,0,1);
        my $destfile = "$cache/$author.json";

        try {
            # load JSON, if we have one
            if(-f $destfile) {
                $progress->( ".. processing rmauth $author $name (cleaning JSON file)" )     if(defined $progress);
                my $data  = read_file($destfile);
                $progress->( ".. processing rmauth $author $name (read JSON file)" )     if(defined $progress);
                my $store;
                eval { $store = decode_json($data) };
                $progress->( ".. processing rmauth $author $name (decoded JSON data)" )     if(defined $progress);
                if(!$@ && $store) {
                    for my $row (@$store) {
                        next    if($requests{$row->{id}});                      # filter out requests

                        push @reports, $row;
                    }
                }
                overwrite_file( $destfile, _make_json( \@reports ) );
            }

            # clean the summary, if we have one
            my @summary = $dbi->GetQuery('hash','GetAuthorSummary',$author);
            if(@summary) {
                $progress->( ".. processing rmauth $author $name (cleaning summary) " . scalar(@summary) . ' ' . ($summary[0] && $summary[0]->{dataset} ? 'true' : 'false') )     if(defined $progress);
                my $dataset = decode_json($summary[0]->{dataset});
                $progress->( ".. processing rmauth $author $name (decoded JSON summary)" )     if(defined $progress);

                for my $data ( @{ $dataset->{distributions} } ) {
                    my $dist = $data->{dist};
                    my $summ = $data->{summary};

                    next    unless($remove{$dist});

                    for my $state (keys %{ $remove{$dist} }) {
                        $summ->{ $state } -= $remove{$dist}{$state};
                        $summ->{ 'ALL'  } -= $remove{$dist}{$state};
                    }
                }

                $dbi->DoQuery('UpdateAuthorSummary',$summary[0]->{lastid},encode_json($dataset),$author);
            }

            # push in author queue to rebuild pages
            $dbi->DoQuery('PushAuthor',$author);
        } catch {
            $progress->( ".. failed rmauth $author $name (catch block)" )     if(defined $progress);
            $fail = 1;
        };
    }

    return 0 if($fail);

    # remove requests
    $dbi->DoQuery('DeletePageRequests',{ids => join(',',@ids)},'rmauth',$name);

    return scalar(@ids);
}

sub RemoveDistroPages {
    my ($cpan,$dbi,$progress,$name) = @_;

    # get ids from the page requests
    my @requests = $dbi->GetQuery('hash','GetRequestIDs',{names => $name},'rmdist');
    my %requests = map { $_->{id} => 1 } grep { $_->{id} } @requests;

    return  unless(keys %requests);
    push my @ids, keys %requests;

    my $exceptions = $cpan->exceptions;
    my $symlinks   = $cpan->symlinks;
    my $merged     = $cpan->merged;
    my $ignore     = $cpan->ignore;

    my @delete = ($name);
    if(   ( $name =~ /^[A-Za-z0-9][A-Za-z0-9\-_+.]*$/ && !$ignore->{$name} )
       || ( $exceptions && $name =~ /$exceptions/ ) ) {

        # Some distributions are known by multiple names. Rather than create
        # pages for each one, we try and merge them together into one.

        my $dist;
        if($symlinks->{$name}) {
            $name = $symlinks->{$name};
            $dist = join("','", @{$merged->{$name}});
            @delete = @{$merged->{$name}};
        } elsif($merged->{$name}) {
            $dist = join("','", @{$merged->{$name}});
            @delete = @{$merged->{$name}};
        } else {
            $dist = $name;
            @delete = ($name);
        }

        my @valid = $dbi->GetQuery('hash','FindDistro',{dist=>$dist});
        return  unless(@valid);

        my $cache = sprintf "%s/static/distro/%s", $settings{webdir}, substr($name,0,1);
        my $destfile = "$cache/$name.json";

        # get reports
        my (%remove,@reports);
        my $next = $dbi->Iterator('hash','GetReportsByIDs',{ids=>join(',',@ids)});
        while(my $row = $next->()) {
            # hash of dist => summary => PASS, FAIL, NA, UNKNOWN
            $remove{$row->{dist}}{$row->{version}}{uc $row->{state}}++;
        }

        # load JSON, if we have one
        if(-f $destfile) {
            my $data  = read_file($destfile);
            my $store;
            eval { $store = decode_json($data) };
            if(!$@ && $store) {
                for my $row (@$store) {
                    next    if($requests{$row->{id}});                      # filter out requests

                    push @reports, $row;
                }
            }
            overwrite_file( $destfile, _make_json( \@reports ) );
        }
    }

    # remove requests
    $dbi->DoQuery('DeletePageRequests',{ids => join(',',@ids)},'rmdist',$name);

    # push in author queue to rebuild pages
    $dbi->DoQuery('PushDistro',$name);

    return scalar(@ids);
}

# - build author pages
# - update summary
# - remove page request entries

sub AuthorPages {
    my ($cpan,$dbi,$name,$progress) = @_;
    return  unless(defined $name);

    $name = uc $name;

    my @ids = (0);
    my %vars = %{ clone (\%tvars) };
#LogDebug("AuthorPages: before tvars=".total_size(\%tvars)." bytes");

    my @valid = $dbi->GetQuery('hash','FindAuthor',$name);
    if(@valid) {
        my @dists = $dbi->GetQuery('hash','GetAuthorDists',$name);
        if(@dists) {
            my %dists = map {$_->{dist} => $_->{version}} @dists;
            my $cache = sprintf "%s/static/author/%s", $settings{webdir}, substr($name,0,1);
            mkpath($cache);

            my (@reports,%reports,%summary,$next);
            my $destfile = "$cache/$name.json";
            my $fromid   = '';
            my $lastid   = 0;

            # load the summary, if we have one
            my @summary = $dbi->GetQuery('hash','GetAuthorSummary',$name);
            $lastid = $summary[0]->{lastid} if(@summary);

            # load JSON, if we have one
            if(-f $destfile && $lastid) {
                my $data  = read_file($destfile);
                my $store;
                eval { $store = decode_json($data); };
                if(!$@ && $store) {
                    my %ids;
                    for my $row (@$store) {
                        next    if($lastid < $row->{id});
                        next    if($dists{$row->{dist}} ne $row->{version});    # ensure this is the latest dist version
                        next    if($ids{$row->{id}});	# auto clean duplicates

                        $ids{$row->{id}} = 1;

                        unshift @{$reports{$row->{dist}}}, $row;
                        $summary{$row->{dist}}->{ $row->{status} }++;
                        $summary{$row->{dist}}->{ 'ALL' }++;
                        push @reports, $row;
                    }

                    $fromid = " AND id > $lastid "  if($lastid);
                }
            }

            # if we have ids in the page requests, just update these
            my @requests = $dbi->GetQuery('hash','GetRequestIDs',{names => $name},'author');
            my %requests = map { $_->{id} => 1 } grep { $_->{id} } @requests;
            if(keys %requests) {
                $next = $dbi->Iterator('hash','GetReportsByIDs',{ids=>join(',',keys %requests)});
                push @ids, keys %requests;

            } else {
                # process all the reports from the last ID used
                if(scalar(@dists) > 300) {
                    # a fairly constant 83-93 seconds regardless of volume
                    $next = $dbi->Iterator('hash','GetAuthorDistReports',{fromid=>$fromid},$name);
                } else {
                    # 3-73 secs for dists of 1-100
                    my $lookup = 'AND ( ' . join(' OR ',map {"(dist = '$_->{dist}' AND version = '$_->{version}')"} @dists) . ' )';
                    $next = $dbi->Iterator('hash','GetAuthorDistReports3',{lookup=>$lookup,fromid=>$fromid});
                }
            }

            while(my $row = $next->()) {
                next    unless($dists{$row->{dist}} && $row->{version});
                next    if($dists{$row->{dist}} ne $row->{version});    # ensure this is the latest dist version

                $row->{perl} ||= '';
                $row->{perl} = "5.004_05" if $row->{perl} eq "5.4.4"; # RT 15162
                $row->{perl} =~ s/patch.*/patch blead/  if $row->{perl} =~ /patch.*blead/;
                my ($osname) = $cpan->OSName($row->{osname});

                $row->{status}       = uc $row->{state};
                $row->{ostext}       = $osname;
                $row->{distribution} = $row->{dist};
                $row->{distversion}  = $row->{dist} . '-' . $row->{version};
                $row->{csspatch}     = $row->{perl} =~ /\b(RC\d+|patch)\b/ ? 'pat' : 'unp';
                $row->{cssperl}      = $row->{perl} =~ /^5.(7|9|[1-9][13579])/ ? 'dev' : 'rel';

                push @{$reports{$row->{dist}}}, $row;
                $summary{$row->{dist}}->{ $row->{status} }++;
                $summary{$row->{dist}}->{ 'ALL' }++;
                $lastid = $row->{id}    if($lastid < $row->{id});
                unshift @reports, $row;
            }

            for my $dist (@dists) {
                $dist->{letter}     = substr($dist->{dist},0,1);
                $dist->{reports}    = 1 if($reports{$dist->{dist}});
                $dist->{summary}    = $summary{$dist->{dist}};
                $dist->{cssrelease} = $dist->{version} =~ /(_|-TRIAL)/ ? 'rel' : 'off';
                $dist->{csscurrent} = $dist->{type} eq 'backpan' ? 'back' : 'cpan';
            }

            $vars{builder}{author}          = $name;
            $vars{builder}{letter}          = substr($name,0,1);
            $vars{builder}{title}           = 'Reports for distributions by ' . $name;
            $vars{builder}{distributions}   = \@dists   if(@dists);
            $vars{builder}{processed}       = time;

            # insert summary details
            {
                my $dataset = encode_json($vars{builder});
                if(@summary)    { $dbi->DoQuery('UpdateAuthorSummary',$lastid,$dataset,$name); }
                else            { $dbi->DoQuery('InsertAuthorSummary',$lastid,$dataset,$name); }
            }

            # we have to do this here as we don't want all the reports in
            # the encoded summary, just whether we have reports or not
            for my $dist (@dists) {
                $dist->{reports}    = $reports{$dist->{dist}};
            }

            $vars{cache}           = $cache;
            $vars{content}         = 'cpan/author-reports-static.html';
            $vars{processed}       = formatDate(8);

# 2017-06-27 - Static page creation disabled, see GH#6 for more details: https://github.com/barbie/cpan-testers-www-reports/issues/6
#            # build other static pages
#            my $text = Transform( 'cpan/layout-static.html', \%vars );
#            overwrite_file( "$cache/$name.html", $text );

            my $text = Transform( 'cpan/author.js', \%vars );
            overwrite_file( "$cache/$name.js", $text );

            overwrite_file( "$cache/$name.json", _make_json( \@reports ) );
        }
    }

#LogDebug("AuthorPages: after  tvars=".total_size(\%tvars)." bytes");

    # remove requests
    $dbi->DoQuery('DeletePageRequests',{ids => join(',',@ids)},'author',$name);
}

# - build distro pages
# - update summary
# - remove page request entries

sub DistroPages {
    my ($cpan,$dbi,$name,$progress) = @_;
    return  unless(defined $name);

    my @ids = (0);
    my %vars = %{ clone (\%tvars) };

#LogDebug("DistroPages: before tvars=".total_size(\%tvars)." bytes");
#$progress->( ".. .. starting $name" ) if(defined $progress);

    my $exceptions = $cpan->exceptions;
    my $symlinks   = $cpan->symlinks;
    my $merged     = $cpan->merged;
    my $ignore     = $cpan->ignore;

    my @delete = ($name);
    if(   ( $name =~ /^[A-Za-z0-9][A-Za-z0-9\-_+.]*$/ && !$ignore->{$name} )
       || ( $exceptions && $name =~ /$exceptions/ ) ) {

        # Some distributions are known by multiple names. Rather than create
        # pages for each one, we try and merge them together into one.

        my $dist;
        if($symlinks->{$name}) {
            $name = $symlinks->{$name};
            $dist = join("','", @{$merged->{$name}});
            @delete = @{$merged->{$name}};
        } elsif($merged->{$name}) {
            $dist = join("','", @{$merged->{$name}});
            @delete = @{$merged->{$name}};
        } else {
            $dist = $name;
            @delete = ($name);
        }

#$progress->( ".. .. getting records for $name" ) if(defined $progress);
        my @valid = $dbi->GetQuery('hash','FindDistro',{dist=>$dist});
#$progress->( ".. .. retrieved records for $name" ) if(defined $progress);
        if(@valid) {
            my (@reports,%authors,%version,$summary,$byversion,$next);
            my $fromid = '';
            my $lastid = 0;

            # determine max dist/version for each pause id
            for(@valid) {
                $authors{$_->{author}}  = $_->{version};
                $version{$_->{version}} = { author => $_->{author}, new => 0, type => $_->{type}};
            }
            my %reports = map {$authors{$_} => []} keys %authors;

            # if we have a summary, process all reports to the last update from the JSON cache

            my @summary = $dbi->GetQuery('hash','GetDistroSummary',$name);
            $lastid = $summary[0]->{lastid} if(@summary);

            my $cache = sprintf "%s/static/distro/%s", $settings{webdir}, substr($name,0,1);
            my $destfile = "$cache/$name.json";
            mkpath($cache);

#$progress->( ".. .. loading JSON data for $name" ) if(defined $progress);
            # load JSON data if available
            if(-f $destfile && $lastid) {
                my $json = read_file($destfile);
                my $data;
                eval { $data = decode_json($json); };
                if(!$@ && $data) {
                    my %ids;
                    for my $row (@$data) {
                        next    if($lastid < $row->{id});
                        next    if($ids{$row->{id}});	# auto clean duplicates

                        $ids{$row->{id}} = 1;
                        push @reports, $row;

                        $summary->{ $row->{version} }->{ $row->{status} }++;
                        $summary->{ $row->{version} }->{ 'ALL' }++;
                        unshift @{ $byversion->{ $row->{version} } }, $row;

                        # record reports from max versions
                        unshift @{ $reports{$row->{version}} }, $row    if(defined $reports{$row->{version}});
                    }

                    $fromid = " AND id > $lastid ";
                }
            }
#$progress->( ".. .. loaded JSON data for $name" ) if(defined $progress);

            # if we have ids in the page requests, just update these
            my @requests = $dbi->GetQuery('hash','GetRequestIDs',{names => $dist},'distro');
            my %requests = map { $_->{id} => 1 } grep { $_->{id} } @requests;
            if(keys %requests) {
                $next = $dbi->Iterator('hash','GetReportsByIDs',{ids=>join(',',keys %requests)});
                push @ids, keys %requests;
            } else {
                $next = $dbi->Iterator('hash','GetDistroReports',{fromid => $fromid, dist => $dist});
            }

#$progress->( ".. .. starting data update for $name" ) if(defined $progress);
            while(my $row = $next->()) {
                $row->{perl} = "5.004_05"               if $row->{perl} eq "5.4.4"; # RT 15162
                $row->{perl} =~ s/patch.*/patch blead/  if $row->{perl} =~ /patch.*blead/;
                my ($osname) = $cpan->OSName($row->{osname});

                $row->{distribution} = $name;
                $row->{status}       = uc $row->{state};
                $row->{ostext}       = $osname;
                $row->{osvers}       = $row->{osvers};
                $row->{distversion}  = $name . '-' . $row->{version};
                $row->{csspatch}     = $row->{perl} =~ /\b(RC\d+|patch)\b/ ? 'pat' : 'unp';
                $row->{cssperl}      = $row->{perl} =~ /^5.(7|9|[1-9][13579])/ ? 'dev' : 'rel';
                $lastid = $row->{id}    if($lastid < $row->{id});
                unshift @reports, $row;

                $summary->{ $row->{version} }->{ $row->{status} }++;
                $summary->{ $row->{version} }->{ 'ALL' }++;
                push @{ $byversion->{ $row->{version} } }, $row;

                # record reports from max versions
                unshift @{ $reports{$row->{version}} }, $row    if($reports{$row->{version}});
                $version{$row->{version}}->{new} = 1;
            }
#$progress->( ".. .. summary data update complete for $name" ) if(defined $progress);

            for my $version ( keys %$byversion ) {
                my @list = @{ $byversion->{$version} };
                $byversion->{$version} = [ sort { $b->{id} <=> $a->{id} } @list ];
            }

            # ensure we cover all known versions
            my @rows = $dbi->GetQuery('array','GetDistVersions',{dist=>$dist});
            my @versions = map{$_->[0]} @rows;
            my %versions = map {my $v = $_; $v =~ s/[^\w\.\-]/X/g; $_ => $v} @versions;

            my %release;
            for my $version ( keys %versions ) {
                $release{$version}->{csscurrent} = $version{$version}->{type} eq 'backpan' ? 'back' : 'cpan';
                $release{$version}->{cssrelease} = $version =~ /(_|-TRIAL)/ ? 'dev' : 'off';
                $release{$version}->{header} = "<h2>$dist $version ";
                if($summary->{$version}{ALL}) {
                    $release{$version}->{header} .= "(<b> ";
                    for my $status (sort keys %{$summary->{$version}}) {
                        $release{$version}->{header} .= "<span class='$status'>$summary->{$version}{$status} $status";
                        if($summary->{$version}{$status} > 1) {
                            $release{$version}->{header} .= $status eq 'PASS' ? 'es' : 's';
                        }
                        $release{$version}->{header} .= "</span> ";
                    }
                    $release{$version}->{header} .= "</b>)";
                } else {
                    $release{$version}->{header} .= "(No reports)";
                }
                $release{$version}->{header} .= "</h2>";
            }
#$progress->( ".. .. version data update complete for $name" ) if(defined $progress);

# V1 code starts
#            my ($stats,$oses);
#            @rows = $dbi->GetQuery('hash','GetDistrosPass',{dist=>$dist});
#            for(@rows) {
#                my ($osname,$code) = $cpan->OSName($_->{osname});
#                $stats->{$_->{perl}}{$code}{count} = $_->{count};
#                $oses->{$code} = $osname;
#            }
##$progress->( ".. .. OS data update complete for $name" ) if(defined $progress);
#
#            # distribution PASS stats
#            my @stats = $dbi->GetQuery('hash','GetStatsPass',{dist=>$dist});
#            for(@stats) {
#                my ($osname,$code) = $cpan->OSName($_->{osname});
#                $stats->{$_->{perl}}{$code}{version} = $_->{version}
#                    if(!$stats->{$_->{perl}}->{$code} || _versioncmp($_->{version},$stats->{$_->{perl}}->{$code}{version}));
#            }
##$progress->( ".. .. Pass Stats data update complete for $name" ) if(defined $progress);
# V1 code end

# V2 code starts
#            # retrieve perl/os stats
#            my ($stats,$oses);
#            my @stats = $dbi->GetQuery('hash','GetStatsPass',{dist=>$dist});
#            for(@stats) {
#                my ($osname,$code) = $cpan->OSName($_->{osname});
#                $stats->{$_->{perl}}{$code}{version} = $_->{version}
#                    if(!$stats->{$_->{perl}}->{$code} || _versioncmp($_->{version},$stats->{$_->{perl}}->{$code}{version}));
#
#                $stats->{$_->{perl}}{$code}{count}++;
#                $oses->{$code} = $osname;
#            }
##$progress->( ".. .. Perl/OS data update complete for $name" ) if(defined $progress);
# V2 code end

# V3 code starts
            # retrieve perl/os stats
            my ($stats,$oses);
            my $lastref = 0;
            @rows = $dbi->GetQuery('hash','GetStatsStore',$name);
            for(@rows) {
                $stats->{$_->{perl}}{$_->{osname}}{storeid} = $_->{storeid};
                $stats->{$_->{perl}}{$_->{osname}}{version} = $_->{version};
                $stats->{$_->{perl}}{$_->{osname}}{count}   = $_->{counter};
                $stats->{$_->{perl}}{$_->{osname}}{updated} = 0;
                $oses->{$_->{osname}} = $_->{osname};
                $lastref = $_->{lastid};
            }

            # update perl/os stats
            my @stats = $dbi->GetQuery('hash','GetStatsPass2',{dist=>$dist},$lastref);
            for(@stats) {
                my ($osname,$code) = $cpan->OSName($_->{osname});
                my $perl = $_->{perl};
                $perl =~ s/ .*$//; # don't care about the patch/RC number

                $stats->{$perl}{$code}{updated} = 1;

                $stats->{$perl}{$code}{version} = $_->{version}
                    if(!$stats->{$perl}->{$code} || _versioncmp($_->{version},$stats->{$perl}->{$code}{version}));

                $stats->{$perl}{$code}{count}++;
                $oses->{$code} = $osname;
                $lastref = $_->{id} if($lastref < $_->{id});
            }

            # store perl/os stats
            for my $perl (keys %$stats) {
                for my $code (keys %{$stats->{$perl}}) {
                    next unless($stats->{$perl}{$code}{updated});
                    if($stats->{$perl}{$code}{storeid}) {
                        $dbi->DoQuery('UpdStatsStore',$name,$perl,$code,$stats->{$perl}{$code}{version},$stats->{$perl}{$code}{count},$lastref, $stats->{$perl}{$code}{storeid});
                    } else {
                        $dbi->DoQuery('SetStatsStore',$name,$perl,$code,$stats->{$perl}{$code}{version},$stats->{$perl}{$code}{count},$lastref);
                    }
                }
            }
#            $dbi->DoQuery('DelStatsStore',$name);
#            for my $perl (keys %$stats) {
#                for my $code (keys %{$stats->{$perl}}) {
#                    $dbi->DoQuery('SetStatsStore',$name,$perl,$code,$stats->{$perl}{$code}{version},$stats->{$perl}{$code}{count},$lastref);
#                }
#            }
#$progress->( ".. .. Perl/OS data update complete for $name" ) if(defined $progress);
# V3 code end

            my @stats_oses = sort keys %$oses;
            my @stats_perl = sort {_versioncmp($b,$a)} keys %$stats;
            my @stats_poff = grep {!/patch/} sort {_versioncmp($b,$a)} keys %$stats;

            $vars{title} = 'Reports for distribution ' . $name;

            $vars{builder}{distribution}    = $name;
            $vars{builder}{letter}          = substr($name,0,1);
            $vars{builder}{title}           = $vars{title};
            $vars{builder}{processed}       = time;

#$progress->( ".. .. memory data update complete for $name" ) if(defined $progress);

            # insert summary details
            {
                my $dataset = encode_json($vars{builder});
                if(@summary)    { $dbi->DoQuery('UpdateDistroSummary',$lastid,$dataset,$name); }
                else            { $dbi->DoQuery('InsertDistroSummary',$lastid,$dataset,$name); }
            }
#$progress->( ".. .. summary data stored for $name" ) if(defined $progress);

            $vars{versions}        = \@versions;
            $vars{versions_tag}    = \%versions;
            $vars{summary}         = $summary;
            $vars{release}         = \%release;
            $vars{byversion}       = $byversion;
            $vars{cache}           = $cache;
            $vars{processed}       = formatDate(8);

#$progress->( ".. .. building static pages for $name" ) if(defined $progress);

# 2017-06-27 - Static page creation disabled, see GH#6 for more details: https://github.com/barbie/cpan-testers-www-reports/issues/6
#            # build other static pages
#            $vars{content} = 'cpan/distro-reports-static.html';
#            my $text = Transform( 'cpan/layout-static.html', \%vars );
#            overwrite_file( "$cache/$name.html", $text );
##$progress->( ".. .. Static HTML page written for $name" ) if(defined $progress);

            my $text = Transform( 'cpan/distro.js', \%vars );
            overwrite_file( "$cache/$name.js", $text );
#$progress->( ".. .. JS page written for $name" ) if(defined $progress);

            overwrite_file( "$cache/$name.json", _make_json( \@reports ) );
#$progress->( ".. .. JSON page written for $name" ) if(defined $progress);

            $cache = sprintf "%s/stats/distro/%s", $settings{webdir}, substr($name,0,1);
            mkpath($cache);
            $vars{cache} = $cache;

            $vars{content} = 'cpan/stats-distro-static.html';
            $text = Transform( 'cpan/layout-stats-static.html', \%vars );
            overwrite_file( "$cache/$name.html", $text );
#$progress->( ".. .. Statistics HTML page written for $name" ) if(defined $progress);

            # generate symbolic links where necessary
            if($merged->{$name}) {
                my $cwd = getcwd;
                chdir("$settings{webdir}/static/distro");
                for my $dist (@{$merged->{$name}}) {
                    next    if($dist eq $name);
                    for my $ext (qw(html json js)) {
                        my $source = substr($name,0,1) . "/$name.$ext" ;
                        my $target = substr($dist,0,1) . "/$dist.$ext" ;
                        next    if(!-f $source || -f $target);

                        eval {symlink($source,$target) ; 1};
                    }
                }
                chdir($cwd);
#$progress->( ".. .. symbolic links created for $name" ) if(defined $progress);
            }
        }
    }

#LogDebug("DistroPages: after tvars=".total_size(\%tvars)." bytes");
#LogDebug("DistroPages: ids=@ids, distros=@delete");

    # remove requests
    while(@ids) {
#$progress->( ".. .. removing page_request entries for $name. ids=".scalar(@ids) ) if(defined $progress);
        my @remove = splice(@ids,0,100);
        $dbi->DoQuery('DeletePageRequests',{ids => join(',',@remove)},'distro',$_) for(@delete);
    };
#$progress->( ".. .. removed page_request entries for $name" ) if(defined $progress);
}

sub StatsPages {
    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    my $cache = sprintf "%s/stats", $settings{webdir};
    mkpath($cache);

    #print STDERR "StatsPages: cache=$cache\n";

    my (%data,%perldata,%perls,%all_osnames,%dists,%perlos,%lookup);

    no warnings( 'uninitialized', 'numeric' );

    my $next = $dbi->Iterator('hash','GetStats');

    # build data structures
    while ( my $row = $next->() ) {
        #next if not $row->{perl};
        #next if $row->{perl} =~ / /;
        #next if $row->{perl} =~ /^5\.(7|9|[1-9][13579])\b/; # ignore dev versions
        #next if $row->{version} =~ /[^\d.]/;

        $row->{perl} = "5.004_05" if $row->{perl} eq "5.4.4"; # RT 15162

        my ($osname,$oscode) = $cpan->OSName($row->{osname});
        $row->{osname} = $oscode;
        $lookup{$oscode} = $osname;

        $perldata{$row->{perl}}{$row->{dist}} = $row->{version}             if $perldata{$row->{perl}}{$row->{dist}} < $row->{version};
        $data{$row->{dist}}{$row->{perl}}{$row->{osname}} = $row->{version} if $data{$row->{dist}}{$row->{perl}}{$row->{osname}} < $row->{version};
        $perls{$row->{perl}}{reports}++;
        $perls{$row->{perl}}{distros}{$row->{dist}}++;
        $perlos{$row->{perl}}{$row->{osname}}++;
        $all_osnames{$row->{osname}}++;
    }

    my @versions = sort {_versioncmp($b,$a)} keys %perls;
    my $text;

    # page perl perl version cross referenced with platforms
    my %perl_osname_all;
    for my $perl ( @versions ) {
        my (@data,%oscounter,%dist_for_perl);
        for my $dist ( sort keys %{ $perldata{$perl} } ) {
            my @osversion;
            for my $oscode ( sort keys %{ $perlos{$perl} } ) {
                if ( defined $data{$dist}{$perl}{$oscode} ) {
                    push @osversion, { ver => $data{$dist}{$perl}{$oscode} };
                    $oscounter{$oscode}++;
                    $dist_for_perl{$dist}++;
                } else {
                    push @osversion, { ver => undef };
                }
            }
            push @data, {
                dist      => $dist,
                osversion => \@osversion,
            };
        }

        my @perl_osnames;
        for my $code ( sort keys %{ $perlos{$perl} } ) {
            if ( $oscounter{$code} ) {
                push @perl_osnames, { oscode => $code, osname => $lookup{$code}, cnt => $oscounter{$code} };
                $perl_osname_all{$code}{$perl} = $oscounter{$code};
            }
        }

        my $destfile        = "perl_${perl}_platforms.html";
        $tvars{osnames}     = \@perl_osnames;
        $tvars{dists}       = \@data;
        $tvars{perl}        = $perl;
        $tvars{cnt_modules} = scalar keys %dist_for_perl;
        $tvars{cache}       = $cache;
        $tvars{content}     = 'cpan/stats-perl-platform.html';
        $text = Transform( 'cpan/layout-stats-static.html', \%tvars );
        overwrite_file( "$cache/$destfile", $text );
    }

    my @perl_osnames;
    for(keys %perl_osname_all) {
        my ($name,$code) = $cpan->OSName($_);
        push @perl_osnames, {oscode => $code, osname => $name}
    }

    my (@perls,@data_perlplat,$parms,$destfile);
    for my $perl ( @versions ) {
        push @perls, {
            perl         => $perl,
            report_count => $perls{$perl}{reports},
            distro_count => scalar( keys %{ $perls{$perl}{distros} } ),
        };

        my @count;
        for my $os (keys %perl_osname_all) {
            my ($name,$code) = $cpan->OSName($os);
            push @count, { oscode => $code, osname => $name, count => $perl_osname_all{$os}{$perl} };
        }
        push @data_perlplat, {
            perl => $perl,
            count => \@count,
        };

        my (@data_perl,$cnt);
        for my $dist ( sort keys %{ $perldata{$perl} } ) {
            $cnt++;
            push @data_perl, {
                dist    => $dist,
                version => $perldata{$perl}{$dist},
            };
        }

        # page per perl version
        $destfile           = "perl_${perl}.html";
        $tvars{data}        = \@data_perl;
        $tvars{perl}        = $perl;
        $tvars{cnt_modules} = $cnt;
        $tvars{cache}       = $cache;
        $tvars{content}     = 'cpan/stats-perl-version.html';
        $text = Transform( 'cpan/layout-stats-static.html', \%tvars );
        overwrite_file( "$cache/$destfile", $text );
    }

    # how many test reports per platform per perl version?
    $destfile       = "perl_platforms.html";
    $tvars{osnames} = \@perl_osnames;
    $tvars{perlv}   = \@data_perlplat;
    $tvars{cache}   = $cache;
    $tvars{content} = 'cpan/stats-perl-platform-count.html';
    $text = Transform( 'cpan/layout-stats-static.html', \%tvars );
    overwrite_file( "$cache/$destfile", $text );

    # generate index.html
    $destfile       = "index.html";
    $tvars{perls}   = \@perls;
    $tvars{cache}   = $cache;
    $tvars{content} = 'cpan/stats-index.html';
    $text = Transform( 'cpan/layout-stats-static.html', \%tvars );
    overwrite_file( "$cache/$destfile", $text );

#    # create symbolic links
#    for my $link ('headings', 'background.png', 'style.css', 'cpan-testers.css') {
#        my $source = file( $directory, $link );
#        my $target = file( $directory, 'stats', $link );
#        next    if(!-e $source);
#        next    if( -e $target);
#        eval {symlink($source,$target) ; 1};
#    }
}

sub RecentPage {
    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    # Recent reports
    my @recent;
    my $count = $settings{rss_limit_recent} || $RECENT;
    my $next = $dbi->Iterator('hash','GetRecent',{limit => "LIMIT $count"});

    while ( my $row = $next->() ) {

        next unless $row->{version};
        my ($name) = $cpan->OSName($row->{osname});

        my $report = {
            guid         => $row->{guid},
            id           => $row->{id},
            dist         => $row->{dist},
            status       => uc $row->{state},
            version      => $row->{version},
            perl         => $row->{perl},
            osname       => $name,
            osvers       => $row->{osvers},
            platform     => $row->{platform},
        };
        push @recent, $report;
        last    if(--$count < 1);
    }

    my $cache = sprintf "%s/static", $settings{webdir};
    mkpath($cache);

    $tvars{recent}  = \@recent;
    $tvars{cache}   = $cache;
    $tvars{content} = 'cpan/recent.html';

    my $text = Transform( 'cpan/layout-static.html', \%tvars );
    overwrite_file( $cache . '/recent.html', $text );
    $tvars{recent} = undef;

    my $destfile = "$cache/recent.rss";
    overwrite_file( $destfile, _make_rss( 'recent', undef, \@recent ) );
}

#----------------------------------------------------------------------------
# Private Interface Functions

sub _request_count {
    my $dbi = shift;

    my @rows = $dbi->GetQuery('array','CountRequests');
    my $cnt = @rows ? $rows[0]->[0] : 0;
    return $cnt;
}

sub _request_oldest {
    my $dbi = shift;

    my @rows = $dbi->GetQuery('array','OldestRequest');
    my $cnt = @rows ? $rows[0]->[0] : 0;
    return $cnt;
}

sub _make_json {
    my ( $data ) = @_;
    return encode_json( $data );
}

sub _make_rss {
    my ( $type, $item, $data ) = @_;
    my ( $title, $link, $desc );

    if($type eq 'dist') {
        $title = "$item CPAN Testers Reports";
        $link  = "http://www.cpantesters.org/distro/".substr($item,0,1)."/$item.html";
        $desc  = "Automated test results for the $item distribution";
    } elsif($type eq 'recent') {
        $title = "Recent CPAN Testers Reports";
        $link  = "http://www.cpantesters.org/static/recent.html";
        $desc  = "Recent CPAN Testers reports";
    } elsif($type eq 'author') {
        $title = "Reports for distributions by $item";
        $link  = "http://www.cpantesters.org/author/".substr($item,0,1)."/$item.html";
        $desc  = "Reports for distributions by $item";
    } elsif($type eq 'nopass') {
        $title = "Failing Reports for distributions by $item";
        $link  = "http://www.cpantesters.org/author/".substr($item,0,1)."/$item.html";
        $desc  = "Reports for distributions by $item";
    }

    my $rss = XML::RSS->new( version => '1.0' );
    $rss->channel(
        title       => $title,
        link        => $link,
        description => $desc,
        syn         => {
            updatePeriod    => "daily",
            updateFrequency => "1",
            updateBase      => "1901-01-01T00:00+00:00",
        },
    );

    for my $test (@$data) {
        $rss->add_item(
            title => sprintf(
                "%s %s-%s %s on %s %s (%s)",
                map {$_||''}
                @{$test}{
                    qw( status dist version perl osname osvers platform )
                    }
            ),
            link => "$settings{reportlink2}/" . ($test->{guid} || $test->{id}),
        );
    }

    return $rss->as_string;
}

sub _versioncmp {
    my ($v1,$v2) = @_;
    my ($vn1,$vn2);

    $v1 =~ s/\s.*$//    if($v1);
    $v2 =~ s/\s.*$//    if($v2);

    return -1   if(!$v1 &&  $v2);
    return  0   if(!$v1 && !$v2);
    return  1   if( $v1 && !$v2);

    eval { $vn1 = version->parse($v1); };
    if($@) { return $v1 cmp $v2 }
    eval { $vn2 = version->parse($v2); };
    if($@) { return $v1 cmp $v2 }

    return $vn1 cmp $vn2;
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2017 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
