package Labyrinth::Plugin::CPAN::Preferences;

use strict;
use warnings;

our $VERSION = '0.20';

=head1 NAME

Labyrinth::Plugin::CPAN::Preferences - Handles preferences pages.

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

use LWP::UserAgent;
use MIME::Base64;
use Net::SSLeay qw(get_https make_headers);
use Sort::Versions;
use Time::Local;

#----------------------------------------------------------------------------
# Variables

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

my %pref_fields = (
    dist        => { type => 1, html => 1 },
    active      => { type => 1, html => 0 },
    ignored     => { type => 0, html => 0 },
    report      => { type => 1, html => 0 },
    grade       => { type => 1, html => 0 },
    tuple       => { type => 1, html => 1 },
    version     => { type => 1, html => 0 },
    versions    => { type => 0, html => 0 },
    patches     => { type => 0, html => 0 },
    perl        => { type => 1, html => 0 },
    perls       => { type => 0, html => 0 },
    platform    => { type => 1, html => 0 },
    platforms   => { type => 0, html => 0 },
);

my (@pref_man,@pref_all);
for(keys %pref_fields) {
    push @pref_man, $_     if($pref_fields{$_}->{type});
    push @pref_all, $_;
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

=item Default

Default preferences page.

=item Distros

Author distributions list page.

=item Distro

Single distribution preferences page.

=item XDropDownMultiList

Provide a drop down multi-select list, base on a list of strings.

=item XDropDownMultiRows

Provide a drop down multi-select list, base on a list of rows.

=item DefSave

Save default preferences.

=item DistSave

Save distribution preferences.

=item Delete

Delete the preferences for a distribution, and use the default preferences.

=back

=cut

sub Login {
    # if a regular login or no login, use the core login mechanism
    if(!$cgiparams{pause} || !$cgiparams{eject} || $cgiparams{pause} =~ /\@/) {
        $cgiparams{cause}  = $cgiparams{pause};
        $cgiparams{effect} = $cgiparams{eject};

        LogDebug("pause=$cgiparams{pause}, eject=$cgiparams{eject}");
        LogDebug("cause=$cgiparams{cause}, effect=$cgiparams{effect}");

        $tvars{errcode} = 'NEXT';
        $tvars{command} = 'user-logged';
        return;
    }

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

        # set login activity
        $dbi->DoQuery('UpdateAuthorLogin',time(),$tvars{user}{name});

    } else {
        $tvars{errmess} = 2;
        $tvars{errcode} = 'ERROR';
    }
}

sub Logged  {
    return  unless RealmCheck('author','admin');
}

sub Default {
    return  unless RealmCheck('author','admin');
    my $author = $tvars{user}{author} || $tvars{user}{name};
    my @rows = $dbi->GetQuery('hash','GetAuthorDefault',$author);
    $tvars{data} = $rows[0]  if(@rows);

    my $cpan  = Labyrinth::Plugin::CPAN->new();

    my @perls = sort {versioncmp($b->{perl},$a->{perl})} $dbi->GetQuery('hash','GetPerlVersions');

    $cpan->Configure();
    my $archs = $cpan->osnames();
    my @archs = map {{oscode => $_, osname => $archs->{$_}}} sort {lc $archs->{$a} cmp lc $archs->{$b}} keys %$archs;

    $tvars{data}{ddarch} = XDropDownMultiRows($tvars{data}{platform},'platforms','oscode','osname',5,@archs);
    $tvars{data}{ddperl} = XDropDownMultiRows($tvars{data}{perl},'perls','perl','perl',5,@perls);
}

sub Distros {
    return  unless RealmCheck('author','admin');

    my $author  = $tvars{user}{author} || $tvars{user}{name};

    my $cpan  = Labyrinth::Plugin::CPAN->new();
    my @rows  = $dbi->GetQuery('array','GetAuthorDists',$author);
    my @dists = map {$_->[0]} @rows;

    my @distros = $dbi->GetQuery('hash','GetAuthorDistros',$author);
    my %distros = map {$_->{distribution} => $_} @distros;
    for(keys %distros) {
        $distros{$_}->{name}   = $_;

        $distros{$_}->{grade} =~ s/PASS/P/;
        $distros{$_}->{grade} =~ s/FAIL/F/;
        $distros{$_}->{grade} =~ s/UNKNOWN/U/;
        $distros{$_}->{grade} =~ s/NA/N/;
        $distros{$_}->{grade} =~ s/,//g;

        $distros{$_}->{tuple} =~ s/ALL/A/;
        $distros{$_}->{tuple} =~ s/FIRST/F/;

        $distros{$_}->{version} =~ s/ALL/A/;
        $distros{$_}->{version} =~ s/LATEST/L/;
        $distros{$_}->{version} =~ s/(NOT|INC).*/C/;

        $distros{$_}->{perl} =~ s/ALL/A/;
        $distros{$_}->{perl} =~ s/(NOT|INC).*/C/;
        $distros{$_}->{perl} .= '+P'    if($distros{$_}->{perl} eq 'A' && $distros{$_}->{patches});

        $distros{$_}->{platform} =~ s/ALL/A/;
        $distros{$_}->{platform} =~ s/(NOT|INC).*/C/;
    }

    # check whether any distributions have had their ignore status altered
    if($cgiparams{enable}) {
        my $updated = 0;
        my @check = CGIArray('dists');
        my %check = @check ? map {$_=>1} @check : ();
        my @list;

        # ensure user checked are disabled in the DB
        for(@check) {
            next    if($distros{$_} && $distros{$_}->{ignored} == 1);
            $updated = 1;
            if(defined $distros{$_}) {
                push @list, "'$_'";
                $distros{$_}->{ignored} = 2;
            } else {
                $dbi->DoQuery('InsertDistroPrefs',1,1,'FAIL','FIRST','LATEST',0,'ALL','ALL',$author,$_);
                $distros{$_}->{ignored} = 1;
            }
        }
        $dbi->DoQuery('SetAuthorIgnore',{dists => join(',',@list)},2,$author) if(@list);

        # ensure user unchecked are enabled in the DB
        @list = ();
        for(keys %distros) {
            next    if($check{$_});
            $updated = 1;
            my @rows = $dbi->GetQuery('hash','GetAuthorDistro',$author,$_);
            if(@rows) {
                if($rows[0]->{ignored} == 1 ) {
                    $dbi->DoQuery('DeleteDistroPrefs', $author, $_);
                    delete $distros{$_};
                } else {
                    push @list, "'$_'";
                    $distros{$_}->{ignored} = 0;
                }
            }
        }
        $dbi->DoQuery('SetAuthorIgnore',{dists => join(',',@list)},0,$author) if(@list);

        $tvars{thanks} = 1  if($updated);
    }

    @distros = ();
    my %dists = map {$_ => 1} @dists;
    for my $dist (sort keys %dists) {
        next    unless($dist =~ /^[A-Za-z0-9][A-Za-z0-9\-_]*$/
                    || $dist =~ /$EXCEPTIONS/);
        if(defined $distros{$dist}) {
            if($distros{$dist}->{ignored}) {
                push @distros, {name => $dist, ignored => $distros{$dist}->{ignored}};
            } else {
                push @distros, $distros{$dist}
            }
        } else {
            push @distros, {name => $dist, ignored => 0};
        }
    }

    $tvars{data}{dists} = \@distros;
    #$tvars{hash}{dists} = \%dists;
}

sub Distro {
    return  unless RealmCheck('author','admin');

    my $author  = $tvars{user}{author} || $tvars{user}{name};
    my $dist    = $cgiparams{dist};
    my $version = $cgiparams{version};

    my @rows = $dbi->GetQuery('hash','GetAuthorDistro',$author,$dist);
    $tvars{data} = $rows[0]  if(@rows);
    $tvars{data}{dist} = $dist;

    my $cpan  = Labyrinth::Plugin::CPAN->new();
    my @vers  = $dbi->GetQuery('array','GetAuthorDistVersions',$author,$dist);
    my @versions = sort {versioncmp($b,$a)} map {$_->[0]} @vers;
    $tvars{data}{ddversions} = XDropDownMultiList($version,'versions',5,@versions);

    my @perls = sort {versioncmp($b->{perl},$a->{perl})} $dbi->GetQuery('hash','GetPerlVersions');

    $cpan->Configure();
    my $archs = $cpan->osnames();
    my @archs = map {{oscode => $_, osname => $archs->{$_}}} sort {lc $archs->{$a} cmp lc $archs->{$b}} keys %$archs;

    $tvars{data}{ddarch} = XDropDownMultiRows($tvars{data}{platform},'platforms','oscode','osname',5,@archs);
    $tvars{data}{ddperl} = XDropDownMultiRows($tvars{data}{perl},'perls','perl','perl',5,@perls);

    for(qw(version perl platform)) {
        $tvars{data}{$_} =~ s/,/, /g;
        $tvars{data}{$_} =~ s/(NOT|INC),/$1:/g;
    }
}

sub XDropDownMultiList {
    my ($opts,$name,$count,@items) = @_;
    my %opts;

    if(defined $opts) {
        if(ref($opts) eq 'ARRAY') {
            %opts = map {$_ => 1} @$opts;
        } elsif($opts =~ /,/) {
            %opts = map {$_ => 1} split(/,/,$opts);
        } elsif($opts) {
            %opts = ("$opts" => 1);
        }
    }

    my %hash = ( name => $name );
    for(@items) {
        push @{$hash{options}}, { index    => $_,
                                  value    => $_,
                                  selected => (defined $opts && $opts{$_} ? 1 : 0)};
    }

    return \%hash;
}

sub XDropDownMultiRows {
    my ($opts,$name,$index,$value,$count,@items) = @_;
    my %opts;

    if(defined $opts) {
        if(ref($opts) eq 'ARRAY') {
            %opts = map {$_ => 1} @$opts;
        } elsif($opts =~ /,/) {
            %opts = map {$_ => 1} split(/,/,$opts);
        } elsif($opts) {
            %opts = ("$opts" => 1);
        }
    }

    my %hash = ( name => $name );
    for(@items) {
        push @{$hash{options}}, { index    => $_->{$index},
                                  value    => $_->{$value},
                                  selected => (defined $opts && $opts{$_->{$index}} ? 1 : 0)};
    }

    return \%hash;
}


sub DefSave {
    return  unless RealmCheck('author','admin');

    for(keys %pref_fields) {
           if($pref_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($pref_fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($pref_fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@pref_all,\@pref_man);

    my $author = $tvars{user}{author} || $tvars{user}{name};

    # change reporting activity
    $dbi->DoQuery('UpdateAuthorActive',$tvars{data}{active},$author);

    _save_distprefs($author,'-');
}

sub DistSave {
    return  unless RealmCheck('author','admin');

    for(keys %pref_fields) {
           if($pref_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($pref_fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($pref_fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@pref_all,\@pref_man);

    my $author  = $tvars{user}{author} || $tvars{user}{name};

    _save_distprefs($author,$tvars{data}{dist});
}

sub _save_distprefs {
    my ($author,$dist) = @_;
    my @fields;

    $tvars{data}{patches} = $tvars{data}{patches} ? 1 : 0;

    # save default settings
    for(qw(grade versions perls platforms)) {
        my @array = CGIArray($_);
        #LogDebug("$_ => @array");
        $tvars{data}{$_} = join(',',@array);
        #LogDebug("tvars($_) => $tvars{data}{$_}");
    }
    for(qw(version perl platform)) {
        next    if($tvars{data}{$_} eq 'ALL');
        next    if($tvars{data}{$_} eq 'LATEST');   # only applicable to version
        next    unless($tvars{data}{$_ . 's'});
        $tvars{data}{$_} .= ',' . $tvars{data}{$_ . 's'};
    }
    push @fields, $tvars{data}{$_}   for(qw(ignored report grade tuple version patches perl platform));

    my @rows = $dbi->GetQuery('hash','GetAuthorDistro',$author,$dist);
    if(@rows)   { $dbi->DoQuery('UpdateDistroPrefs',@fields, $author, $dist) }
    else        { $dbi->DoQuery('InsertDistroPrefs',@fields, $author, $dist) }

    $tvars{thanks} = 1;
}

sub Delete {
    return  unless RealmCheck('author','admin');

    my $author  = $tvars{user}{author} || $tvars{user}{name};
    my $dist    = $cgiparams{dist};

    my @rows = $dbi->GetQuery('hash','GetAuthorDistro',$author,$dist);
    $dbi->DoQuery('DeleteDistroPrefs', $author, $dist)  if(@rows);
}

=head2 Admin Interface Methods

=over 4

=item Admin

Prepare Admin login as author.

=item Imposter

Allow Admin to login as named author.

=item Clear

Clear imposter status and return to Admin.

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
