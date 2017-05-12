package Labyrinth::Plugin::CPAN::Tester;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.15';

=head1 NAME

Labyrinth::Plugin::CPAN::Tester - Tester Plugin for CPAN Testers Admin website.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Mailer;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

use Labyrinth::Plugin::CPAN;

use Data::Dumper;
use Digest::SHA qw(sha1_hex);
use Time::Local;

#----------------------------------------------------------------------------
# Variables

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

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    nickname    => { type => 0, html => 1 },
    realname    => { type => 1, html => 1 },
    email       => { type => 1, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 METHODS

=over 4

=item Browse

List dates for which tester

=item Reports

List reports for given day

=item Find

Find a report by ID.

=item List

List marked reports

=item Mark

Request report removal

=item Unmark

Remove request report removal

=item Delete

Remove marked reports from the cpanstats reports listings. 

Note that reports are not truly deleted, they are merely filtered out of any 
cpanstats reports processing.

=item Dist

List reports that the tester has submitted reports for.

=back

=cut

sub Browse  {
    return  unless RealmCheck('tester','admin');

    my $userid = $tvars{'loginid'};
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});
    #my @addrs = $dbi->GetQuery('hash','GetTesterAddressIndex',$userid);
    #return  unless(@addrs);

    #my $addrs = join('|', map {$_->{email}} @addrs);
    #my $ids = join(',', map {$_->{id}} @addrs);

    my %dates;
    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');

    #my $dates = $dbx->Iterator('hash','XGetReportDates',{ids => $ids});
    my $next = $dbx->Iterator('hash','GetReportDates',$userid);
    while(my $row = $next->()) {
        my ($y,$m,$d) = $row->{fulldate} =~ /(\d{4,4})(\d{2,2})(\d{2,2})/;
        #$m = int($m);
        $dates{$y}{year} = $y;
        $dates{$y}{months}->{$m}{month} = $months{int($m)};
        $dates{$y}{months}->{$m}{days}->{$d}{day} = int($d);
    }

    LogDebug(Dumper(\%dates));

    my @y;
    for my $y (sort {$b <=> $a } keys %dates) {
        my @m;
        for my $m ( sort {$b <=> $a } keys %{$dates{$y}{months}} ) {
            my @d = sort {$a <=> $b } keys %{$dates{$y}{months}{$m}{days}};
            push @m, {days => \@d, month => $months{int($m)}, mon => $m};
        }
        push @y, {months => \@m, year => $y};
    }

    $tvars{data}{dates} = \@y if(@y);
    #$tvars{data}{dates} = \%dates if(keys %dates);
}

sub Reports  {
    return  unless RealmCheck('tester','admin');

    for(keys %date_fields) {
           if($date_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
        elsif($date_fields{$_}->{html} == 2) { $cgiparams{$_} =  SafeHTML($cgiparams{$_}); }
    }

    return  if FieldCheck(\@date_all,\@date_man);

    my $userid = $tvars{'loginid'};
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});
#    my @addrs = $dbi->GetQuery('hash','GetTesterAddress',$userid);
#    return  unless(@addrs);

#    my $addrs = join('|', map {$_->{email}} @addrs);

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my $date = sprintf "%04d%02d%02d\%", $tvars{data}{y},$tvars{data}{m},$tvars{data}{d};
#    my @rows = $dbx->GetQuery('hash','GetReportList',{addrs => $addrs},$date);
    my @rows = $dbx->GetQuery('hash','GetReportList',$userid,$date);
    for my $row (@rows) {
        my @report = $dbx->GetQuery('hash','GetReport',$row->{id});
        $row->{$_} = $report[0]->{$_}   for(keys %{$report[0]});
        my @author = $dbx->GetQuery('hash','GetAuthor',$report[0]->{dist},$report[0]->{version});
        $row->{$_} = $author[0]->{$_}   for(keys %{$author[0]});

        next    unless($row->{fulldate});
        $row->{fulldate} = _parse_date($row->{fulldate});
    }
    $tvars{data}{reports} = \@rows  if(@rows);

    $date = timelocal(0,0,12,$tvars{data}{d},$tvars{data}{m}-1,$tvars{data}{y});
    $tvars{data}{date} = formatDate(10,$date);
}

sub Find  {
    return  unless RealmCheck('tester','admin');
    $tvars{searched} = 1;

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','FindReport',$cgiparams{guid});
    if(@rows) {
        $tvars{data}{reports} = \@rows;
        SetCommand('tester-report');
    }
}

sub List {
    return  unless RealmCheck('tester','admin');
    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows;

    if($tvars{realm} eq 'admin' && !$tvars{user}{tester}) {
        @rows = $dbi->GetQuery('hash','ListAllMarkedReports');
    } else {
        my $userid = $tvars{'loginid'};
        $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});
        @rows = $dbi->GetQuery('hash','ListMarkedReports',$userid);
    }

    for my $row (@rows) {
        next    unless($row->{fulldate});
        $row->{fulldate} = _parse_date($row->{fulldate});
        $row->{profile} = $cpan->GetTesterProfile($row->{guid},$row->{tester});
    }

    $tvars{data}{reports} = \@rows  if(@rows);
}

sub Mark  {
    return  unless RealmCheck('tester','admin');

    my @data;

    $tvars{body}{success} = 0;
    $tvars{body}{result} = 'failed';

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','GetReports',{ids => join(',',CGIArray('DELETE'))});
    for my $row (@rows) {
        # now mark the report
        $dbi->DoQuery('MarkReport',$row->{id},$row->{addressid},$row->{tester},$row->{author},time());
        push @data, $row->{id};
    }

    $tvars{body}{success} = 1;
    $tvars{body}{result}  = 'marked';
    $tvars{body}{data}    = join(',',@data);
    $tvars{realm} = 'json';
}

sub Unmark  {
    return  unless RealmCheck('tester','admin');

    $tvars{body}{success} = 0;
    $tvars{body}{result} = 'failed';

    my @ids = CGIArray('DELETE');
    my $userid = $tvars{'loginid'};
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','GetReports',{ids => join(',',@ids)});

    my @data;
    if($tvars{realm} eq 'admin' && !$tvars{user}{tester}) {
        @data = @ids;
    } else {
        @data = grep {$_} map { my (undef,undef,$uid) = $cpan->FindTester($_->{tester}); $uid = $userid ? $_->{id} : 0 } @rows;
    }

    # unmark the reports
    $dbi->DoQuery('UnmarkTesterReports',{ids => join(',',@data)});

    $tvars{body}{success} = 1;
    $tvars{body}{result}  = 'unmarked';
    $tvars{body}{data}    = join(',',@data);
    $tvars{realm} = 'json';

#    LogDebug("body=".Dumper($tvars{body}));
}

sub Delete  {
    return  unless RealmCheck('tester','admin');

    my @ids = CGIArray('DELETE');
    my $userid = $tvars{'loginid'};
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','GetReports',{ids => join(',',@ids)});

    my @data;
    if($tvars{realm} eq 'admin' && !$tvars{user}{tester}) {
        @data = @ids;
    } else {
        @data = grep {$_} map { my (undef,undef,$uid) = $cpan->FindTester($_->{tester}); $uid = $userid ? $_->{id} : 0 } @rows;
    }

    for my $row (@rows) {
        next if($row->{type} == 3);
        $dbx->DoQuery('UpdateGrade',3,$row->{id});

        # for the reports builder
        $dbx->DoQuery('PageRequest','rmdist',$row->{dist},$row->{id});
        $dbx->DoQuery('PageRequest','rmauth',$row->{dist},$row->{id});

        # for the statistics scripts
        $dbx->DoQuery('DeleteReportHistory',$row->{id},$row->{state},$row->{postdate},$row->{dist},$row->{version},$row->{type},3);
    }

    # remove marked reports
    $dbi->DoQuery('UnmarkTesterReports',{ids => join(',',@data)});

    $tvars{body}{success} = 1;
    $tvars{body}{result}  = 'deleted';
    $tvars{body}{data}    = join(',',@data);
    $tvars{realm} = 'json';
}

sub Dist {
    return  unless RealmCheck('tester','admin');

    SetTester();

    $cgiparams{dist} =~ s/::/-/g;

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','FindDistro',$cgiparams{dist});
    unless(@rows) {
        SetCommand('tester-distro');
        $tvars{errmess} = 'Sorry, no such distribution found. Please try again.';
        return;
    }

    my ($prev,$next,$order) = ('','','DESC');
    @rows = $dbx->GetQuery('hash','ListReports2',{'prev'=>$prev,'next'=>$next,'order'=>$order},$cgiparams{userid},$cgiparams{dist});
    if(@rows) {
        for(@rows) {
            my ($y,$m,$d) = $_->{fulldate} =~ /^(\d{4})(\d{2})(\d{2})/;
            $_->{showdate} = sprintf "%04d-%02d-%02d", $y, $m, $d;
        }
        $tvars{data}{reports} = \@rows;

        my @prev = $dbx->GetQuery('hash','CountReports2',{'prev'=>"AND x.guid > '$rows[0]->{guid}'"},$cgiparams{userid},$cgiparams{dist});
        my @next = $dbx->GetQuery('hash','CountReports2',{'next'=>"AND x.guid < '$rows[-1]->{guid}'"},$cgiparams{userid},$cgiparams{dist});

        $tvars{pager}{prev} = $rows[0]->{guid}  if(@prev && $prev[0]->{count} > 0);
        $tvars{pager}{next} = $rows[-1]->{guid} if(@next && $next[-1]->{count} > 0);
    }
}

=head2 Tester Email Interface Methods

=over 4

=item CheckLock

Checks whether the specified user account is currently locked.

=item Lock

Tester has just registered on the site, lock the user profile until email is 
confirmed.

=item UnLock

Tester has clicked registration confirmation link, and logged in successfully, 
unlock the user profile.

=item Submit

Tester has submitted an email address used to submit a test report. Save as
unconfirmed and send email confirmation.

=item Email

Send email to tester to confirm email address.

=item Remove

Remove registered email from this user profile.

=item Confirm

Tester has clicked the confirmation link, provide login to finalise 
confirmation.

=item Confirmed

Tester has confirmed login, mark email as confirmed, and map email to 
addressid.

=item Verify

Allow admin to verify and confirm a tester's email address.

=item Verified

List verified email addresses for specified tester.

=back

=cut

sub CheckLock {
    my $userid = $tvars{'loginid'};
    my @row = $dbi->GetQuery('hash','GetUserByID',$userid);
    return  if(@row && !$row[0]->{locked});

    Labyrinth::Session::Logout();

    $tvars{redirect} = '';
    SetCommand('tester-locked');
}

sub Lock {
    return  unless RealmCheck('public','tester','admin');
    my $userid = $cgiparams{'userid'};
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});
    $dbi->DoQuery('LockUser',$userid);
    $dbi->DoQuery('SetRealm','tester',$userid);

    my $user = GetUser($userid);

    $tvars{data}{realname}  = $user->{realname};
    $tvars{data}{email}     = $user->{email};
    $tvars{data}{template}  = 'mailer/user-confirm.eml';
}

sub UnLock {
    return  unless RealmCheck('tester','admin','public');
    
    my $email;
    my ($code,$userid) = split('/',$cgiparams{code});

    if($tvars{realm} eq 'admin' && $tvars{user}{tester}) {
        $userid = $tvars{user}{tester};
        $email = $cgiparams{confirm};
    } else {
        my @confirm = $dbi->GetQuery('hash','CheckConfirmedCode',$code);
        return  unless(@confirm && $confirm[0]->{userid} == $userid);
        $email = $confirm[0]->{email};
    }

    $dbi->DoQuery('UnLockUser',$userid);
    $dbi->DoQuery('ConfirmedEmail',$userid,$email,$code);
}

sub Submit {
    return  unless RealmCheck('tester','admin');
    my $userid = $tvars{'loginid'};
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});

    $cgiparams{'userid'} = $userid;

    $tvars{data}{realname}  = UserName($userid);
    $tvars{data}{email}     = $cgiparams{email};
    $tvars{data}{template}  = 'mailer/tester-confirm.eml';
    $tvars{thanks} = 1;
}

sub Email {
    return  unless RealmCheck('public','tester','admin');

    my $userid = $cgiparams{userid};
    my $code;

    my @email = $dbi->GetQuery('hash','CheckConfirmedEmail',$userid,$tvars{data}{'email'});
    if(@email) {
        $code = $email[0]->{confirm};
    } else {
        my $data = $tvars{data}{'email'} . $$ . time . 'ajfpfgjalkshj';
        $code = sha1_hex($data);
        $dbi->DoQuery('UnConfirmedEmail',$userid,$tvars{data}{'email'},$code);
    }

    MailSend(   template        => $tvars{data}{'template'},
                name            => $tvars{data}{'realname'},
                recipient_email => $tvars{data}{'email'},
                code            => "$code/$userid",
                webpath         => "$tvars{docroot}$tvars{webpath}",
                nowrap          => 1
    );

    if(!MailSent()) {
        $tvars{errcode} = 'BADMAIL';
    }
}

sub Remove {
    return  unless RealmCheck('tester','admin');

    return SetCommand('tester-verify') if($cgiparams{confirm});

    my $userid = $tvars{'loginid'};
    $userid = $cgiparams{testerid}  if($tvars{realm} eq 'admin' && $cgiparams{testerid});
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});

    if($cgiparams{confirm} && $tvars{realm} eq 'admin') {
        my $cpan = Labyrinth::Plugin::CPAN->new();
        my $dbx = $cpan->DBX('cpanstats');
        my @rows = $dbx->GetQuery('hash','FindAddresses',$cgiparams{confirm});
        for(@rows) {
            $dbi->DoQuery('MapAddresses',$userid,$_->{addressid});
        }

        $dbi->DoQuery('ConfirmedEmail',$userid,$cgiparams{confirm});
        return;
    }

    my @mails = CGIArray('MAILS');
    return  unless @mails;

    $dbi->DoQuery('RemoveEmail',{mails => "'" . join("','",@mails) . "'"},$userid);
}

sub Confirm {
    my ($code,$userid) = split('/',$cgiparams{code});

    my @confirm = $dbi->GetQuery('hash','CheckConfirmedCode',$code);
    return  unless(@confirm && $confirm[0]->{userid} == $userid);
    
    return SetCommand('tester-unconfirmed') unless(@confirm && $confirm[0]->{userid} == $userid);

    # confirm this email
    $dbi->DoQuery('ConfirmedEmail',$userid,$confirm[0]->{email},$code);

    # map emails to addresses
    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx  = $cpan->DBX('cpanstats');
    my @rows = $dbx->GetQuery('hash','FindAddresses',$confirm[0]->{email});
    for(@rows) {
        $dbi->DoQuery('MapAddresses',$userid,$_->{addressid});
    }
}

sub Confirmed {
    return  unless RealmCheck('tester');
    $dbi->DoQuery('ConfirmedEmail',$tvars{'loginid'},$cgiparams{email},$cgiparams{code});
}

sub Verify {
    return  unless RealmCheck('admin');
    my $userid = $tvars{'loginid'};
    $userid = $cgiparams{testerid}  if($tvars{realm} eq 'admin' && $cgiparams{testerid});
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});

    my @confirm = $dbi->GetQuery('hash','CheckConfirmedEmail',$userid,$cgiparams{confirm});
    return  unless(@confirm);

    $dbi->DoQuery('ConfirmedEmail',$userid,$cgiparams{confirm},$confirm[0]->{confirm});
}

sub Verified {
    return  unless RealmCheck('tester','admin');
    my $userid = $tvars{data}{'userid'} || $tvars{'loginid'};
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});
    my @rows = $dbi->GetQuery('hash','GetTesterAddress',$userid);
    $tvars{data}{confirmed} = \@rows    if(@rows);
}

=head2 Admin Interface Methods

=over 4

=item Admin

Prepare Admin login as tester.

=item Imposter

Allow Admin to login as named tester.

=item Clear

Clear Imposter status and return to Admin.

=item Merge

Merge Testers Profiles in testers database.

=item Assign

Assign tester addresses to a given profile in the testers database.

=item Edit

Edit Tester Profile in testers database.

=back

=cut

sub Admin {
    return  unless RealmCheck('admin');
    $tvars{where} = "AND u.realm='tester' AND u.userid > 3";
}

sub Imposter {
    return  unless RealmCheck('admin');
    UpdateSession('name' => 'imposter:' . $cgiparams{userid});
    $tvars{user}{tester} = $cgiparams{userid};
}

sub Clear {
    return  unless RealmCheck('admin');
    UpdateSession('name' => 'Admin');
    $tvars{user}{name} = 'Admin';
    delete $tvars{user}{tester};
    delete $tvars{user}{fakename};
}

sub Merge {
    return  unless RealmCheck('admin');

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');

    $cgiparams{$_} ||= '' for(qw(remp rems merge));

    # list primaries
    my (@ids,$ids);
    if($cgiparams{primary}) {
        @ids = ($cgiparams{primary});
    } else {
        @ids = grep {$_ ne "$cgiparams{remp}"} CGIArray('PRIMARY');
    }
    if(@ids) {
        my $ids = join(",",@ids);
        my @rows = $dbx->GetQuery('hash','ListTestersbyID',{ids=>$ids});
        $tvars{primary} = \@rows if(@rows);
    }
    my %ids = map {$_ => 1} @ids, $cgiparams{rems};

    # list secondaries
    @ids = grep {!$ids{$_}} CGIArray('SECONDARY');
    if($cgiparams{secondary} && !$ids{$cgiparams{secondary}}) {
        push @ids, $cgiparams{secondary};
    }
    if(@ids) {
        my $ids = join(",",@ids);
        my @rows = $dbx->GetQuery('hash','ListTestersbyID',{ids=>$ids});
        $tvars{secondary} = \@rows if(@rows);
    }

    if($cgiparams{merge} eq 'merge') {
        my $ids = join(",",map {$_->{testerid}} @{$tvars{secondary}});
        $dbx->DoQuery('MergeTesters',{ids=>$ids},$tvars{primary}[0]->{testerid});
        $dbx->DoQuery('DeleteProfile',{ids=>$ids});
        delete $tvars{secondary};
    }

    # search for name, pause or email
    if($cgiparams{name}) {
        my @testers = $dbx->GetQuery('hash','FindTesters',"\%$cgiparams{name}\%","\%$cgiparams{name}\%","\%$cgiparams{name}\%");
        $tvars{results} = \@testers if(@testers);
        $tvars{search} = $cgiparams{name};
    }
}

sub Assign {
    return  unless RealmCheck('admin');

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');

    $cgiparams{$_} ||= '' for(qw(remp rems assign));

    # list primaries
    my (@ids,$ids,%primary,%secondary);
    if($cgiparams{primary}) {
        @ids = ($cgiparams{primary});
    } else {
        @ids = grep {$_ ne "$cgiparams{remp}"} CGIArray('PRIMARY');
    }
    if(@ids) {
        $primary{$_} = 1    for(@ids);
        my $ids = join(",",@ids);
        my @rows = $dbx->GetQuery('hash','ListTestersbyID',{ids=>$ids});
        $tvars{primary} = \@rows if(@rows);
    }
    my %ids = map {$_ => 1} @ids, $cgiparams{rems};

    # list secondaries
    @ids = grep {!$ids{$_}} CGIArray('SECONDARY');
    if($cgiparams{secondary} && !$ids{$cgiparams{secondary}}) {
        push @ids, $cgiparams{secondary};
    }
    if(@ids) {
        $secondary{$_} = 1    for(@ids);
        my $ids = join(",",@ids);
        my @rows = $dbx->GetQuery('hash','ListAddressbyID',{ids=>$ids});
        $tvars{secondary} = \@rows if(@rows);
    }

    if($cgiparams{assign} eq 'assign') {
        my $ids = join(",",map {$_->{addressid}} @{$tvars{secondary}});
        $dbx->DoQuery('AssignTesters',{ids=>$ids},$tvars{primary}[0]->{testerid});
#        delete $tvars{secondary};

        # reset secondary addresses
        my @rows = $dbx->GetQuery('hash','ListAddressbyID',{ids=>$ids});
        $tvars{secondary} = \@rows if(@rows);
    }

    # search for name, pause or email
    if($cgiparams{name}) {
        my @rows = $dbx->GetQuery('hash','FindTesters',"\%$cgiparams{name}\%","\%$cgiparams{name}\%","\%$cgiparams{name}\%");
        my @profiles = grep { ! $primary{$_->{testerid}} } @rows;
        $tvars{profiles} = \@profiles if(@profiles);

        if($cgiparams{name} eq 'unassigned') {
            @rows = $dbx->GetQuery('hash','FindAddressUnassigned');
        } else {
            @rows = $dbx->GetQuery('hash','FindAddress',"\%$cgiparams{name}\%");
        }

        my @addresses = grep { ! $secondary{$_->{addressid}} } @rows;
        $tvars{addresses} = \@addresses if(@addresses);
        $tvars{search} = $cgiparams{name};
    }
}

sub Edit {
    $tvars{body}{success} = 0;
    $tvars{body}{result} = 'failed';

#LogDebug("1.".$cgiparams{name});
#LogDebug("2.".join(' ', map {ord($_)} split(//,$cgiparams{name})));

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');

    if($cgiparams{testerid}) {
        $dbx->DoQuery('UpdateProfile',$cgiparams{name},$cgiparams{pause},$cgiparams{testerid});
    } else {
        $dbx->DoQuery('CreateProfile',$cgiparams{name},$cgiparams{pause});
    }

    $tvars{body}{success} = 1;
    $tvars{body}{result} = 'saved';
    $tvars{realm} = 'json';
}

sub _parse_date {
    my $date = shift;
    my ($Y,$M,$D,$h,$m) = ($date =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/);
    return $date    unless($Y && $M && $D);

    $h ||= 0;
    $m ||= 0;

    return sprintf "%02d/%02d/%04d %02d:%02d", $D,$M,$Y, $h,$m;
}

=head2 Admin Interface Methods : Local Profiles

=over 4

=item SetTester

Set the tester profile to be edited.

=item RegisteredEmails

Manage tester's registered emails.

=item EditProfile

Edit tester profile

=item SaveProfile

Save tester profile

=item GetContact

Retrieve the current contact address for the current user.

=item SetContact

Save contact address for te current user.

=back

=cut

sub SetTester {
    my $userid = $tvars{'loginid'};
    $userid = $cgiparams{testerid}  if($tvars{realm} eq 'admin' && $cgiparams{testerid});
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});
    $cgiparams{userid} = $userid;
}

sub RegisteredEmails {
    return  unless RealmCheck('tester','admin');

    my $userid = $tvars{'loginid'};
    $userid = $cgiparams{testerid}  if($tvars{realm} eq 'admin' && $cgiparams{testerid});
    $userid = $tvars{user}{tester}  if($tvars{realm} eq 'admin' && $tvars{user}{tester});

    my @rows = $dbi->GetQuery('hash','RegisteredEmails',$userid);
    $tvars{data}{confirmed} = \@rows if(@rows);
}

sub EditProfile {
    return  unless RealmCheck('admin');

    $cgiparams{userid} = $tvars{user}{tester} or return;

#    return  unless MasterCheck();
    return  unless AuthorCheck('GetUserByID','userid',ADMIN);

    $tvars{data}{admin}   = Authorised(ADMIN);
}

sub GetContact {
    my ($row) = $dbi->GetQuery('hash','GetContact',$cgiparams{'userid'});
    if($row && $row->{testerid}) {
        $tvars{data}{contact}  = $row->{contact};
        $tvars{data}{testerid} = $row->{testerid};
    }
}

sub SaveProfile {
    return  unless RealmCheck('admin');

    $cgiparams{userid} = $tvars{user}{tester} or return;
    return  unless AuthorCheck('GetUserByID','userid',ADMIN);

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    my @fields = (  $tvars{data}{'nickname'}, $tvars{data}{'realname'},
                    $tvars{data}{'email'},    0
    );

    $dbi->DoQuery('SaveUser',@fields,$cgiparams{'userid'});
}

sub SetContact {
    $dbi->DoQuery('SetContact',$cgiparams{'contact'},$cgiparams{'testerid'})
        if($cgiparams{'contact'} && $cgiparams{'testerid'});
    $dbi->DoQuery('UpdateProfile',$cgiparams{'realname'},$cgiparams{'nickname'},$cgiparams{'testerid'})
        if($cgiparams{'realname'} && $cgiparams{'testerid'});
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
