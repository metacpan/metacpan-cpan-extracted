package Labyrinth::Plugin::CPAN::Author;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.15';

=head1 NAME

Labyrinth::Plugin::CPAN::Author - Author Plugin for CPAN Testers Admin website.

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

use Labyrinth::Plugin::CPAN;

use Data::Dumper;
use LWP::UserAgent;
use MIME::Base64;
use Net::SSLeay qw(get_https make_headers);
use Sort::Versions;
use Time::Local;

#----------------------------------------------------------------------------
# Variables

my ($backpan,$oncpan);

# The following distributions are considered exceptions from the norm and
# are to be added on a case by case basis.
my $EXCEPTIONS = 'Test.php|Net-ITE.pm|CGI.pm';

my %date_fields = (
    y   => { type => 1, html => 1 },
    m   => { type => 1, html => 1 },
    d   => { type => 1, html => 1 },
);

my (@date_man,@date_all);
for(keys %date_fields) {
    push @date_man, $_     if($date_fields{$_}->{type});
    push @date_all, $_;
}

my %months = (
    1  => 'January',
    2  => 'February',
    3  => 'March',
    4  => 'April',
    5  => 'May',
    6  => 'June',
    7  => 'July',
    8  => 'August',
    9  => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December',
);

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 METHODS

=head2 Public Interface Methods

=over 4

=item Login

Author Login mechanism. Uses the PAUSE authentication system.

=item Logged

Ensure correct user is logged in.

=item Browse

List authors dists which have reports.

=item Distro

List distributions released by the author.

=item Dist

List reports for the given distribution released by the author.

=item Browser

List dates for which author's distribution releases which have reports.

=item Reports

List reports for the given author's distribution releases.

=item Testers

List testers who have submitted reports for the author distributions.

=item Tester

List reports submitted by the given tester for the author distributions.

=item Find

Find a report by ID.

=item Mark

Request report removal

=item Unmark

Remove request report removal

=item Marked

List those reports the author has marked for removal.

=back

=cut

sub Login {
    my $result = LWP::UserAgent->new->get("https://pause.perl.org/pause/authenquery",
            Authorization =>
                'Basic ' . MIME::Base64::encode("$cgiparams{pause}:$cgiparams{eject}",'')
    );

    if($result->code == 200) {
        my @rows = $dbi->GetQuery('hash','CheckUser','PAUSE','PAUSE');

        # add entry to session table
        my $session;
        (   $session,
            $tvars{user}{name},
            $tvars{'loginid'},
            $tvars{realm},
            $tvars{langcode}
        ) = Labyrinth::Session::_save_session(uc $cgiparams{pause},$rows[0]->{userid},$rows[0]->{realm},$rows[0]->{langcode});

        # set template variables
        $tvars{'loggedin'}   = 1;
        $tvars{user}{folder} = 1;
        $tvars{user}{option} = 0;
        $tvars{user}{userid} = $tvars{'loginid'};
        $tvars{user}{access} = VerifyUser($tvars{'loginid'});
        $tvars{realm} ||= 'public';

    } else {
        $tvars{errmess} = 'That username/password failed to be authenticated by PAUSE';
        $tvars{errcode} = 'ERROR';
    }
}

sub Logged  {
    return  unless RealmCheck('pause','admin');
}

sub Browse  {
    return  unless RealmCheck('pause','admin');

    my $author  = $tvars{user}{name};
    $author =~ s/^imposter://;

    # What distributions have been released by this author?
    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('array','GetAuthorDists',$author);
    my @dists = map {$_->[0]} @rows;

    my %dists;
    for my $dist (@dists ) {
        next    unless($dist =~ /^[A-Za-z0-9][A-Za-z0-9\-_]*$/
                    || $dist =~ /$EXCEPTIONS/);
        next    if(defined $dists{$dist});
        #print "... dist $dist\n";

        $dists{$dist} = 1;
    }

    if(keys %dists) {
        my @distros = sort keys %dists;
        $tvars{data}{dists} = \@distros;
        $tvars{hash}{dists} = \%dists;
    }
}

sub Distro  {
    return  unless RealmCheck('pause','admin');

    my $author  = $tvars{user}{name};
    $author =~ s/^imposter://;

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','GetAuthorDists',$author);

    $tvars{data}{distros} = \@rows  if(@rows);
}

sub Dist  {
    return  unless RealmCheck('pause','admin');

    my $dist    = $cgiparams{dist};
    my $version = $cgiparams{version};
    my $author  = $tvars{user}{name};
    $author =~ s/^imposter://;

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('array','GetAuthorDistVersions',$author,$dist);
    my @versions = map {$_->[0]} @rows;

    my %versions = map {$_ => 1} @versions;
    @versions = sort {versioncmp($b,$a)} keys %versions;
    $version ||= $versions[0];

    $tvars{data}{distribution} = $dist;
    $tvars{data}{version}      = $version;
    $tvars{data}{ddversions}   = DropDownList($version,'version',@versions);

    @rows = $dbx->GetQuery('hash','GetAuthorReports',$dist,$version);
    for my $row (@rows) {
        next    unless($row->{fulldate});
        $row->{fulldate} = _parse_date($row->{fulldate});
        $row->{profile} = $cpan->GetTesterProfile($row->{guid},$row->{tester});
    }
    $tvars{data}{reports} = \@rows  if(@rows);
}

sub Browser  {
    return  unless RealmCheck('pause','admin');

    # get list of distributions for this author
    Browse();
    my $dists = "'" . join("','",@{$tvars{data}{dists}}) . "'";

    my %dates;
    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    #my @dates = $dbx->GetQuery('hash','GetAuthorReportDates',{dists => $dists});
    #for(@dates) {
    
    my $next = $dbx->Iterator('hash','GetAuthorReportDates',{dists => $dists});
    while(my $row = $next->()) {
        my ($y,$m,$d) = $row->{fulldate} =~ /(\d{4,4})(\d{2,2})(\d{2,2})/;
        #$m = int($m);
        $dates{$y}{year} = $y;
        $dates{$y}{months}->{$m}{month} = $months{int($m)};
        $dates{$y}{months}->{$m}{days}->{$d}{day} = int($d);
    }

    #$tvars{data}{dates} = \%dates if(keys %dates);

    my @y;
    for my $y (sort {$b <=> $a } keys %dates) {
        my @m;
        for my $m (sort {$b <=> $a } keys %{$dates{$y}{months}}) {
            my @d = sort {$a <=> $b } keys %{$dates{$y}{months}{$m}{days}};
            push @m, {days => \@d, month => $months{int($m)}, mon => $m};
        }
        push @y, {months => \@m, year => $y};
    }

    $tvars{data}{dates} = \@y if(@y);
}

sub Reports  {
    return  unless RealmCheck('tester','admin');

    for(keys %date_fields) {
           if($date_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
        elsif($date_fields{$_}->{html} == 2) { $cgiparams{$_} =  SafeHTML($cgiparams{$_}); }
    }

    return  if FieldCheck(\@date_all,\@date_man);

    # get list of distributions for this author
    Browse();
    my $dists = "'" . join("','",@{$tvars{data}{dists}}) . "'";

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my $date = sprintf "%04d%02d%02d\%", $tvars{data}{y},$tvars{data}{m},$tvars{data}{d};
    my @rows = $dbx->GetQuery('hash','GetAuthorReportList',{dists => $dists},$date);
    for my $row (@rows) {
        next    unless($row->{fulldate});
        $row->{fulldate} = _parse_date($row->{fulldate});
        $row->{profile} = $cpan->GetTesterProfile($row->{guid},$row->{tester});
        LogDebug("profile=".Dumper($row->{profile}));
    }
    $tvars{data}{reports} = \@rows  if(@rows);

    $date = timelocal(0,0,12,$tvars{data}{d},$tvars{data}{m}-1,$tvars{data}{y});
    $tvars{data}{date} = formatDate(10,$date);
}

sub Testers  {
    return  unless RealmCheck('pause','admin');

    my $letter = $cgiparams{letter} || 'A';

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');

    my @rows;
    if($letter eq '9') {
        @rows = $dbx->GetQuery('hash','ListTesters9');
    } else {
        @rows = $dbx->GetQuery('hash','ListTesters',{letter => $letter});
    }

    $tvars{data}{testers} = \@rows  if(@rows);
}

sub Tester  {
    return  unless RealmCheck('pause','admin');

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');

    my @tester = $dbx->GetQuery('hash','GetTesterByID',$cgiparams{testerid});
    if(@tester) {
        $tvars{data}{tester} = $tester[0];
        $tvars{data}{letter} = uc substr($tester[0]->{name},0,1);
    }

    my ($prev,$next,$order) = ('','','DESC');
    if($cgiparams{'prev'}) {
        $prev  = "AND x.guid > '$cgiparams{prev}'";
        $order = 'ASC';
    } elsif($cgiparams{'next'}) {
        $next  = "AND x.guid < '$cgiparams{next}'";
        $order = 'DESC';
    }

    my @rows = $dbx->GetQuery('hash','ListReports',{'prev'=>$prev,'next'=>$next,'order'=>$order},$tvars{user}{author},$cgiparams{testerid});
    if(@rows) {
        for(@rows) {
            my ($y,$m,$d) = $_->{fulldate} =~ /^(\d{4})(\d{2})(\d{2})/;
            $_->{showdate} = sprintf "%04d-%02d-%02d", $y, $m, $d;
        }
        if($prev) {
            my @revs = reverse @rows;
            @rows = @revs;
        }
        $tvars{data}{reports} = \@rows;

        my @prev = $dbx->GetQuery('hash','CountReports',{'prev'=>"AND x.guid > '$rows[0]->{guid}'"},$cgiparams{testerid});
        my @next = $dbx->GetQuery('hash','CountReports',{'next'=>"AND x.guid < '$rows[-1]->{guid}'"},$cgiparams{testerid});

        $tvars{pager}{prev} = $rows[0]->{guid}  if(@prev && $prev[0]->{count} > 0);
        $tvars{pager}{next} = $rows[-1]->{guid} if(@next && $next[-1]->{count} > 0);
    }
}

sub Find  {
    return  unless RealmCheck('pause','admin');
    $tvars{searched} = 1;

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','FindReport',$cgiparams{guid});
    if(@rows) {
        $tvars{data}{reports} = \@rows;
        SetCommand('author-report');
    }
}

sub Mark  {
    return  unless RealmCheck('pause','admin');

    $tvars{body}{success} = 0;
    $tvars{body}{result} = 'failed';

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','GetReports',{ids => join(',',CGIArray('DELETE'))});

    # get list of distributions for this author
    Browse();

    my $author  = $tvars{user}{author};

    my (%done,@data);
    for my $row (@rows) {
        next    unless($tvars{hash}{dists}{$row->{dist}});

        my ($email,$name,$userid,$addressid) = $cpan->FindTester($row->{tester});
        LogDebug("$author marks the report '$row->{id}' tested by '$row->{tester}', mapping to '$email' / '$name' / '$userid' / '$addressid'");

        # mark the report
        $dbi->DoQuery('MarkReport',$row->{id},$addressid,$email,$author,time());
        push @data, $row->{id};

        # now email the tester to let them know
        next  if($done{mail}{$email});
        next  if($done{user}{$userid});
        $done{mail}{$email}  = 1;

        if($userid > 0) {
            $done{user}{$userid} = 1;

            # send mail to tester
            MailSend(   template        => 'mailer/marked.eml',
                        name            => $name,
                        recipient_email => $email
            );

            if(!MailSent()) {
                $tvars{body}{errcode} = 'BADMAIL';
            }
        }
    }

    $tvars{body}{success} = 1;
    $tvars{body}{result}  = 'marked';
    $tvars{body}{data}    = join(',',@data);
    $tvars{realm} = 'json';

    LogDebug("body=".Dumper($tvars{body}));

}

sub Unmark  {
    return  unless RealmCheck('pause','admin');

    $tvars{body}{success} = 0;
    $tvars{body}{result} = 'failed';

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','GetReports',{ids => join(',',CGIArray('DELETE'))});
    my @data = map {$_->{id}} @rows;

    my $author  = $tvars{user}{author};

    # unmark the reports
    $dbi->DoQuery('UnmarkAuthorReports',{ids => join(',',@data)},$author);

    $tvars{body}{success} = 1;
    $tvars{body}{result}  = 'unmarked';
    $tvars{body}{data}    = join(',',@data);
    $tvars{realm} = 'json';

#    LogDebug("body=".Dumper($tvars{body}));
}

sub Marked {
    return  unless RealmCheck('pause','admin');
    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows;

    if($tvars{realm} eq 'admin' && !$tvars{user}{author}) {
        @rows = $dbi->GetQuery('hash','ListAllMarkedReports');
    } else {
        my $userid = $tvars{'loginid'};
        $userid = $tvars{user}{author}  if($tvars{realm} eq 'admin' && $tvars{user}{author});
        @rows = $dbi->GetQuery('hash','ListMarkedAuthorReports',$userid);
    }

    for my $row (@rows) {
        next    unless($row->{fulldate});
        $row->{fulldate} = _parse_date($row->{fulldate});
        $row->{profile} = $cpan->GetTesterProfile($row->{guid},$row->{tester});
    }

    $tvars{data}{reports} = \@rows  if(@rows);
}

=head2 Admin Interface Methods

=over 4

=item Admin

Prepare Admin login as author.

=item Imposter

Clear Imposter status and return to Admin.

=item Clear

Return admin to normal admin state.

=back

=cut

sub Admin  {
    return  unless RealmCheck('admin');
    $tvars{where} = "AND u.realm='author' AND u.userid > 3";
}

sub Imposter  {
    return  unless RealmCheck('admin');
    UpdateSession('name' => 'imposter:' . $cgiparams{pause});
    $tvars{user}{author} = $cgiparams{pause};
}

sub Clear  {
    return  unless RealmCheck('admin');
    UpdateSession('name' => 'Admin');
    $tvars{user}{name} = 'Admin';
    delete $tvars{user}{author};
    delete $tvars{user}{fakename};
}

sub _parse_date {
    my $date = shift;
    my ($Y,$M,$D,$h,$m) = ($date =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/);
    return $date    unless($Y && $M && $D);

    $h ||= 0;
    $m ||= 0;

    return sprintf "%02d/%02d/%04d %02d:%02d", $D,$M,$Y, $h,$m;
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
