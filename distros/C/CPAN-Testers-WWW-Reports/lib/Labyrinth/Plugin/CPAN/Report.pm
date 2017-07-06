package Labyrinth::Plugin::CPAN::Report;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '3.60';

=head1 NAME

Labyrinth::Plugin::CPAN::Report - Plugin to handle Report pages.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Variables;
use Labyrinth::Writer;

use Labyrinth::Plugin::CPAN;

use CPAN::Testers::Common::Article;
use CPAN::Testers::Common::Utils qw(nntp_to_guid guid_to_nntp);
use CPAN::Testers::Fact::LegacyReport;
use CPAN::Testers::Fact::TestSummary;
use File::Slurp;
use HTML::Entities;
use JSON::XS;
use Metabase::Resource;
use XML::RSS;
use YAML::XS;

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 METHODS

=head2 Public Interface Methods

=over 4

=item View

View a specific report.

=item AuthorRSS

Return the RSS feed for a given author.

=item DistroRSS

Return the RSS feed for a given distribution.

=item load_rss

Reads the appropriate JSON file and returns an RSS feed.

=item make_rss

Creates an RSS feed from a given data set.

=item AuthorYAML

Return the YAML feed for a given author.

=item DistroYAML

Return the YAML feed for a given distribution.

=item load_yaml

Reads the appropriate JSON file and returns an YAML feed.

=back

=cut

sub View {
    if($cgiparams{id} =~ /^\d+$/) {
        my @rows = $dbi->GetQuery('hash','GetStatReport',$cgiparams{id});
        if(@rows) {
            if($rows[0]->{guid} =~ /^[0-9]+\-[-\w]+$/) {
                my $id = guid_to_nntp($rows[0]->{guid});
                _parse_nntp_report($id);
            } else {
                $cgiparams{id} = $rows[0]->{guid};
                _parse_guid_report();
            }
        } else {
            #$tvars{errcode} = 'NEXT';
            #$tvars{command} = 'cpan-distunk';
        }
   } else {
        my $id = guid_to_nntp($cgiparams{id});
        if($id) {
            _parse_nntp_report($id);
        } else {
          _parse_guid_report();
        }
    }

    unless($tvars{article}{article}) {
        if($cgiparams{id} =~ /^\d+$/) {
            $tvars{article}{id} = $cgiparams{id};
        } else {
            $tvars{article}{guid} = $cgiparams{id};
        }
    }

    if($cgiparams{raw}) {
        $tvars{article}{raw} = $cgiparams{raw};
        $tvars{realm} = 'popup';
    } else {
        $tvars{realm} = 'wide';
    }
}

sub AuthorRSS { load_rss('author'); }
sub DistroRSS { load_rss('distro'); }

sub load_rss {
    my $type = shift;
    my $nopass = 0;

    if($cgiparams{name} =~ /(.*)\-nopass/) {
        $cgiparams{name} = $1;
        $nopass = 1;
    }

    my @dt = localtime(time);
    my $olddate = sprintf "%04d%02d%02d%02d%02d", $dt[5]+1899, $dt[4], $dt[3], $dt[2], $dt[1];

    my $cache = sprintf "%s/static/%s/%s/%s", $settings{webdir}, $type, substr($cgiparams{name},0,1), $cgiparams{name};
    #LogDebug("cache=$cache");

    # load JSON data if available
    if(-f "$cache.json") {
        my $json = read_file("$cache.json");
        my $data = decode_json($json);
        my @reports;
        for my $row (sort {$b->{fulldate} <=> $a->{fulldate}} @$data) {
            next    if($row->{fulldate} lt $olddate); # ignore anything older than a year
            next    if($nopass && $row->{state} =~ /PASS|NA/i);
            push @reports, $row;
        }

        $type = 'nopass'    if($nopass);
        $tvars{body} = make_rss( $type, $cgiparams{name}, \@reports );

    # fall back to any existing RSS
    } else {
        my $file = $nopass ? "$cache-nopass.rss" : "$cache.rss";
        $tvars{body} = read_file("$cache.rss")  if(-f $file);
    }

    $tvars{realm} = 'rss';
}

sub make_rss {
    my ( $type, $item, $data ) = @_;
    my ( $title, $link, $desc );

    if($type eq 'distro') {
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

    #use Data::Dumper;
    #LogDebug("first report = ".Dumper($data->[0]));

    my $rss = XML::RSS->new( version => '2.0' );
    $rss->channel(
        title           => $settings{rsstitle},
        link            => $settings{rsslink},
        description     => $settings{rssdesc},
        language        => 'en',
        copyrights      => $settings{copyright},
        pubDate         => formatDate(16),
        managingEditor  => $settings{rsseditor},
        webMaster       => $settings{rssmaster},
        generator       => 'Labyrinth v' . $tvars{'labversion'},
    );

    for my $test (@$data) {
        $test->{fulldate} ||= '000000000000';
        $test->{guid}     ||= '';
        $test->{id}       ||= 0;

        my $title = sprintf "%s %s-%s %s on %s %s (%s)", map {$_||''} @{$test}{ qw( status dist version perl osname osvers platform ) };

        #LogDebug("ERROR: $test->{fulldate} - $title");

        my $time = unformatDate(22,$test->{fulldate});
        my $date = formatDate(16,$time);

        #LogDebug("title=".$title);
        #LogDebug("link="."$settings{reportlink2}/" . ($test->{guid} || $test->{id}));
        #LogDebug("guid="."$settings{reportlink2}/" . ($test->{guid} || $test->{id}));
        #LogDebug("pubDate=$date");

        $rss->add_item(
            title       => $title,
            description => $title,
            link        => "$settings{reportlink2}/" . ($test->{guid} || $test->{id}),
            guid        => "$settings{reportlink2}/" . ($test->{guid} || $test->{id}),
            pubDate     => $date,
        );
    }

    #LogDebug("rss = ".$rss->as_string);

    # the following hacks are necessary as XML::RSS doesn't fully support RSS v2.0
    $link =~ s/\.html$/\.rss/;
    $link =~ s/\.rss/-nopass.rss/   if($type eq 'nopass');
    my $str = $rss->as_string;
    $str =~ s!<rss version="2.0"!<rss version="2.0"\nxmlns:atom="http://www.w3.org/2005/Atom"!;
    $str =~ s!<channel>!<channel>\n<atom:link href="$link" rel="self" type="application/rss+xml" />!;

    return $str;
}

sub AuthorYAML { load_yaml('author'); }
sub DistroYAML { load_yaml('distro'); }

sub load_yaml {
    my $type = shift;
    my $cache = sprintf "%s/static/%s/%s/%s", $settings{webdir}, $type, substr($cgiparams{name},0,1), $cgiparams{name};

    #LogDebug("cache=$cache");

    # load JSON data if available
    if(-f "$cache.json") {
        my $json = read_file("$cache.json");
        my $data = decode_json($json);
        my @reports;
        for my $row (@$data) {
            push @reports, $row;
        }

        $tvars{body} = Dump( \@reports );

    # fall back to any existing RSS
    } elsif(-f "$cache.yaml") {
        $tvars{body} = read_file("$cache.yaml");
    }

    $tvars{realm} = 'yaml';
}

#----------------------------------------------------------------------------
# Private Interface Functions

sub _parse_nntp_report {
    my $nntpid = shift;
    my @rows;

    unless($nntpid) {
       @rows = $dbi->GetQuery('hash','GetStatReport',$cgiparams{id});
       return  unless(@rows);
       $nntpid = guid_to_nntp($rows[0]->{guid});
    }

    @rows = $dbi->GetQuery('hash','GetArticle',$nntpid);
       return  unless(@rows);

    $rows[0]->{article} = SafeHTML($rows[0]->{article});
    $tvars{article} = $rows[0];
    ($tvars{article}{head},$tvars{article}{body}) = split(/\n\n/,$rows[0]->{article},2);

    my $object = CPAN::Testers::Common::Article->new($rows[0]->{article});
    return  unless($object);

    $tvars{article}{nntp}    = 1;
    $tvars{article}{id}      = $cgiparams{id};
    $tvars{article}{body}    = $object->body;
    $tvars{article}{subject} = $object->subject;
    $tvars{article}{from}    = $object->from;
    $tvars{article}{from}    =~ s/\@.*//;
    $tvars{article}{post}    = $object->postdate;

    my @date = $object->date =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/;
    $tvars{article}{date}    = sprintf "%04d-%02d-%02dT%02d:%02d:00Z", @date;

    return      if($tvars{article}{subject} =~ /Re:/i);
    return      unless($tvars{article}{subject} =~ /(CPAN|FAIL|PASS|NA|UNKNOWN)\s+/i);

    my $state = lc $1;

    if($state eq 'cpan') {
        if($object->parse_upload()) {
            $tvars{article}{dist}    = $object->distribution;
            $tvars{article}{version} = $object->version;
            $tvars{article}{author}  = $object->author;
            $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);
        }
    } else {
        if($object->parse_report()) {
            $tvars{article}{dist}    = $object->distribution;
            $tvars{article}{version} = $object->version;
            $tvars{article}{author}  = $object->from;
            $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);
        }
    }
}

sub _parse_guid_report {
    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    my @rows = $dbi->GetQuery('hash','GetMetabaseByGUID',$cgiparams{id});
    return  unless(@rows);

    my $data = decode_json($rows[0]->{report});
    my $fact = CPAN::Testers::Fact::LegacyReport->from_struct( $data->{'CPAN::Testers::Fact::LegacyReport'} );
    $tvars{article}{article}    = SafeHTML($fact->{content}{textreport});
    #$tvars{article}{id}         = $rows[0]->{id};
    $tvars{article}{guid}       = $rows[0]->{guid};

    my $report = CPAN::Testers::Fact::TestSummary->from_struct( $data->{'CPAN::Testers::Fact::TestSummary'} );
    my ($osname) = $cpan->OSName($report->{content}{osname});

    $tvars{article}{state}      = lc $report->{content}{grade};
    $tvars{article}{platform}   = $report->{content}{archname};
    $tvars{article}{osname}     = $osname;
    $tvars{article}{osvers}     = $report->{content}{osversion};
    $tvars{article}{perl}       = $report->{content}{perl_version};
    $tvars{article}{created}    = $report->{metadata}{core}{creation_time};

    my $dist                    = Metabase::Resource->new( $report->{metadata}{core}{resource} );
    $tvars{article}{dist}       = $dist->metadata->{dist_name};
    $tvars{article}{version}    = $dist->metadata->{dist_version};

    ($tvars{article}{author},$tvars{article}{from}) = _get_tester( $report->creator );
    $tvars{article}{author} =~ s/\@/ [at] /g;
    $tvars{article}{from}   =~ s/\@/ [at] /g;
    $tvars{article}{from}   =~ s/\./ [dot] /g;

    if($tvars{article}{created}) {
        my @created = $tvars{article}{created} =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/; # 2010-02-23T20:33:52Z
        $tvars{article}{postdate}   = sprintf "%04d%02d", $created[0], $created[1];
        $tvars{article}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[0], $created[1], $created[2], $created[3], $created[4];
    } else {
        my @created = localtime(time);
        $tvars{article}{postdate}   = sprintf "%04d%02d", $created[5]+1900, $created[4]+1;
        $tvars{article}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[5]+1900, $created[4]+1, $created[3], $created[2], $created[1];
    }

    $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);

    $tvars{article}{subject} = sprintf "%s %s-%s %s %s", 
        uc $tvars{article}{state}, $tvars{article}{dist}, $tvars{article}{version}, $tvars{article}{perl}, $tvars{article}{osname};
}

sub _get_tester {
    my $creator = shift;

    #$dbi->{'mysql_enable_utf8'} = 1;
    my @rows = $dbi->GetQuery('hash','GetTesterFact',$creator);
    return ($creator,$creator)  unless(@rows);

    #$rows[0]->{fullname} = encode_entities($rows[0]->{fullname});
    $rows[0]->{email} ||= $creator;
    $rows[0]->{email} =~ s/\'/''/g if($rows[0]->{email});
    return ($rows[0]->{fullname},$rows[0]->{email});
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
