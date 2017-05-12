#!/usr/bin/perl -w
use strict;

$|++;

my $VERSION = '3.44';
my $LABYRINTH = '5.13';

=head1 NAME

reports-checker - Build reports pages

=head1 SYNOPSIS

  perl reports-checker.pl

=head1 DESCRIPTION

??.

=cut

my $BASE;

BEGIN {
    $BASE = '/var/www/reports';
}

#----------------------------------------------------------
# Additional Modules

use lib qw|../cgi-bin/lib ../cgi-bin/plugins|;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Globals;
use Labyrinth::Variables;

use Labyrinth::Plugin::Content;
use Labyrinth::Plugin::CPAN;

use JSON::XS;
use File::Find::Rule;
use File::Slurp;
use Getopt::Long;

#----------------------------------------------------------
# Variables

my $AUTHORS = '/var/www/reports/html/static/author';
my $DISTROS = '/var/www/reports/html/static/distro';
my $BACKPAN = '/opt/projects/BACKPAN/authors/id';

#----------------------------------------------------------
# Code

my %options;
if(!GetOptions( \%options, 'update|u', 'verbose|v')) {
    print STDERR "$0 [--update] [--verbose]\n";
    exit;
}

{

    Labyrinth::Variables::init();   # initial standard variable values
    Labyrinth::Globals::LoadSettings("$BASE/cgi-bin/config/settings.ini");
    Labyrinth::Globals::DBConnect();

    SetLogFile( FILE   => $settings{'logfile'},
                USER   => 'labyrinth',
                LEVEL  => 0,
                CLEAR  => 1,
                CALLER => 1);

    my $content = Labyrinth::Plugin::Content->new();
    $content->GetVersion();

    my $cpan = Labyrinth::Plugin::CPAN->new();
    my $dbx = $cpan->DBX('cpanstats');
    $cpan->Configure();

    _log("Start");

    prep_hashes($cpan,$dbx);

#    check_author_summary($cpan,$dbx);
#    check_distro_summary($cpan,$dbx);

#    check_author_static($cpan,$dbx);
#    check_distro_static($cpan,$dbx);

#    check_author_rss($cpan,$dbx);
#    check_distro_rss($cpan,$dbx);

#    check_author_lower($cpan,$dbx);
    check_distro_lower($cpan,$dbx);

#    check_author_json($cpan,$dbx);
#    check_distro_json($cpan,$dbx);

    _log("Finish");
}

sub prep_hashes {
    my ($cpan,$dbx) = @_;

    my @authors = $dbx->GetQuery('hash','GetAllAuthors');
    my %authors = map { $_->{author} => 1 } @authors;
    my $authors = scalar(@authors);

    $cpan->{data}{authors}{tote} = $authors;
    $cpan->{data}{authors}{list} = \@authors;
    $cpan->{data}{authors}{hash} = \%authors;

    my $ignore      = $cpan->ignore();
    my $symlinks    = $cpan->symlinks();

    my @distros = $dbx->GetQuery('hash','GetAllDistrosX');
    my %distros = map { $_->{dist} => 1 } @distros;
    $distros{$_} = 1 for(keys %$symlinks);
    my %lower = map { lc $_->{dist} => $_->{dist} } @distros;
    $lower{lc $_} = $symlinks->{$_} for(keys %$symlinks);
    my $distros = scalar(keys %distros);

    $cpan->{data}{distros}{tote} = $distros;
    $cpan->{data}{distros}{list} = \@distros;
    $cpan->{data}{distros}{hash} = \%distros;
    $cpan->{data}{distros}{case} = \%lower;
}

sub check_author_summary {
    my ($cpan,$dbx) = @_;
    my ($fixed,$pushed) = (0,0);
    my $count = $cpan->{data}{authors}{tote};

    for my $row (@{ $cpan->{data}{authors}{list} }) {
        my @summary = $dbx->GetQuery('hash','GetAuthorSummary',$row->{author});
        if(@summary) {
            my $tvars = decode_json($summary[0]->{dataset});
            next    unless($tvars->{distributions});

            my $done = 0;
            for my $dist (@{$tvars->{distributions}}) {
                if($dist->{version} =~ /-TRIAL/) {
                    $dist->{cssrelease} = 'dev';
                    $done = 1;
                }
            }

            next    unless($done);

            my $dataset = encode_json($tvars);
            $dbx->DoQuery('UpdateAuthorSummary',$summary[0]->{lastid},$dataset,$summary[0]->{name}) 
                                            if($options{update});
            _log("FIXED: $row->{author}")   if($options{verbose});
            $fixed++;
        }
    }

    _log("Author Summary: count=$count, fixed=$fixed, pushed=$pushed, ok=".($count-$fixed-$pushed));
}

sub check_distro_summary {
    my ($cpan,$dbx) = @_;
    my ($count,$fixed,$pushed) = (0,0,0);

    my $ignore      = $cpan->ignore();
    my $symlinks    = $cpan->symlinks();

    for my $row (@{ $cpan->{data}{distros}{list} }) {
        my $name = $symlinks->{$row->{dist}} || $row->{dist};
        next    if($ignore->{$name});

        $count++;
        my @summary = $dbx->GetQuery('hash','GetDistroSummary',$row->{dist});
        if(@summary) {
            my $tvars = decode_json($summary[0]->{dataset});
            next;

            my $dataset = encode_json($tvars);
            $dbx->DoQuery('UpdateDistroSummary',$summary[0]->{lastid},$dataset,$summary[0]->{name}) if($options{update});
            _log("FIXED: $row->{dist}")                 if($options{verbose});
            $fixed++;
        } else {
            $dbx->DoQuery('PushDistro',$row->{dist})    if($options{update});
            _log("UPDATE: $row->{dist}")                if($options{verbose});
            $pushed++;
        }
    }

    _log("Distro Summary: count=$count, fixed=$fixed, pushed=$pushed, ok=".($count-$fixed-$pushed));
}

sub check_author_static {
    my ($cpan,$dbx) = @_;
    my ($fixed,$pushed) = (0,0);

    my @files = File::Find::Rule->file()->name('*.html')->in($AUTHORS);
    my $count = scalar @files;

    for my $file (@files) {
        my $content = read_file($file);
        my ($name) = ($file =~ m!.*/(.*?)\.html$!);

        if(     $content =~ m!/(author|distro)/\w{2,}! || 
                $content =~ m!/static/! ||
                $content =~ m!/stats/dist/\w{2,}!
            ) {
            $fixed++;
            _log("FIXED: $name")    if($options{verbose});
        } elsif($content !~ m!CPAN Testers Reports v$VERSION is powered by Labyrinth v$LABYRINTH!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } elsif($content =~ m!\d+<span class="[^A-Z]+"> [^A-Z]!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } else {
            next;
        }
        
        $dbx->DoQuery('PushAuthor',$name)   if($options{update});
    }

    _log("Author Static: count=$count, fixed=$fixed, pushed=$pushed, ok=".($count-$fixed-$pushed));
}

sub check_distro_static {
    my ($cpan,$dbx) = @_;
    my ($fixed,$pushed) = (0,0);

    my $ignore = $cpan->ignore();
    my @files = File::Find::Rule->file()->name('*.html')->in($DISTROS);
    my $count = scalar @files;

    for my $file (@files) {
        my ($name) = ($file =~ m!.*/(.*?)\.html$!);
        next    if($ignore->{$name});
        my $content = read_file($file);

        if(     $content =~ m!/(author|distro)/\w{2,}! || 
                $content =~ m!/static/! ||
                $content =~ m!/stats/dist/\w{2,}!
            ) {
            $fixed++;
            _log("FIXED: $name")    if($options{verbose});
        } elsif($content !~ m!CPAN Testers Reports v3.03 is powered by Labyrinth v4.16!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } elsif($content =~ m!<h1>Report Summary</h1>\s*</div>!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } else {
            next;
        }
        
        $dbx->DoQuery('PushDistro',$name)   if($options{update});
    }

    _log("Distro Static: count=$count, fixed=$fixed, pushed=$pushed, ok=".($count-$fixed-$pushed));
}

sub check_author_rss {
    my ($cpan,$dbx) = @_;
    my ($fixed,$pushed) = (0,0);

    my @files = File::Find::Rule->file()->name('*.rss')->in($AUTHORS);
    my $count = scalar @files;

    for my $file (@files) {
        my $content = read_file($file);
        my ($name) = ($file =~ m!.*/(.*?)(-nopass)?\.rss$!);

        if($content =~ m!<title>[^A-Z]+!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } elsif($content !~ m!/cpan/report/!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } elsif($file =~ /nopass/ && $content =~ m!<title>(PASS)!) {
            $fixed++;
            _log("FIXED: $name")    if($options{verbose});
        } else {
            next;
        }
        
        $dbx->DoQuery('PushAuthor',$name)   if($options{update});
    }

    _log("Author RSS: count=$count, fixed=$fixed, pushed=$pushed, ok=".($count-$fixed-$pushed));
}

sub check_distro_rss {
    my ($cpan,$dbx) = @_;
    my ($fixed,$pushed) = (0,0);

    my $ignore = $cpan->ignore();
    my @files = File::Find::Rule->file()->name('*.rss')->in($DISTROS);
    my $count = scalar @files;

    for my $file (@files) {
        my ($name) = ($file =~ m!.*/(.*?)\.html$!);
        next    if($ignore->{$name});
        my $content = read_file($file);

        if($content =~ m!<title>[^A-Z]+!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } elsif($content !~ m!/cpan/report/!) {
            $pushed++;
            _log("UPDATE: $name")   if($options{verbose});
        } else {
            next;
        }
        
        $dbx->DoQuery('PushDistro',$name)   if($options{update});
    }

    _log("Distro RSS: count=$count, fixed=$fixed, pushed=$pushed, ok=".($count-$fixed-$pushed));
}

sub check_author_lower {
    my ($cpan,$dbx) = @_;
    my ($ok,$errors,$moved,$removed) = (0,0,0,0);

    my %names = %{ $cpan->{data}{authors}{hash} };
    my $count =    $cpan->{data}{authors}{tote};

    my @files = File::Find::Rule->file()->name('*.json')->in($AUTHORS);
    my $files = scalar(@files);

    for my $file (sort @files) {
        my ($name) = $file =~ m!/([^/]+)\.json$!;
        my $old = sprintf "$AUTHORS/%s/%s",    substr($name,0,1),    $name;
        my $new = sprintf "$AUTHORS/%s/%s", uc substr($name,0,1), uc $name;

        # file names correct
        if($names{$name}) {
            $names{$name} = 2;
            $ok++;

        # file name mispelt, no correct version
        } elsif($names{uc $name} && ! -f "$new.json") {
            my $error = 0;
            my @cmds;
            for my $ext (qw(json rss yaml js html)) {
                my $old_file = "$old.$ext";
                my $new_file = "$new.$ext";
                if(-f $new_file) {
                    _log("WARNING: '$new_file' exists [mv $old $new_file]")             if($options{verbose});
                    $error++;
                } elsif(! -f $old_file && $ext ne 'rss') {
                    _log("WARNING: '$old_file' doesn't exist [mv $old_file $new_file]") if($options{verbose});
                    $error++;
                } elsif(! -f $old_file && $ext eq 'rss') {
                    next;
                } else {
                    push @cmds, "mv $old_file $new_file";
                }
            }

            if($error == 0) {
                for(@cmds) {
                    _log("COMMAND: $_") if($options{verbose});
                    system($_)          if($options{update});
                }
                $moved++;
                $names{uc $name} = 2;
            } else {
                $errors++;
            }

        # file name mispelt, correct version exists
        } elsif($names{uc $name} && -f "$new.json") {
            my $error = 0;
            my @cmds;
            for my $ext (qw(json rss yaml js html)) {
                my $old_file = "$old.$ext";
                my $new_file = "$new.$ext";
                if(! -f $new_file) {
                    _log("WARNING: '$new_file' doesn't exist [rm $old_file]")       if($options{verbose});
                    $error++;
                } elsif(! -f $old_file && $ext ne 'rss') {
                    _log("WARNING: '$old_file' doesn't exist [rm $old_file]")       if($options{verbose});
                    $error++;
                } elsif(! -f $old_file && $ext eq 'rss') {
                    next;
                } else {
                    push @cmds, "rm $old_file";
                }
            }
 
            if($error == 0) {
                for(@cmds) {
                    _log("COMMAND: $_") if($options{verbose});
                    system($_)          if($options{update});
                }
                $removed++;
                $names{uc $name} = 2;
            } else {
                $errors++;
            }
        } else {
            _log("WARNING: UNKNOWN Author file [$name] [$old] [$new]") if($options{verbose});
            $errors++;
        }
    }

    my $missing = scalar( grep {$names{$_} == 1} keys %names );

    _log("Author Lower: count=$count, files=$files, missing=$missing, moved=$moved, removed=$removed, errors=$errors, ok=$ok");
}

sub check_distro_lower {
    my ($cpan,$dbx) = @_;
    my ($ok,$errors) = (0,0);

    #my %lower = %{ $cpan->{data}{distros}{case} };
    my %names = %{ $cpan->{data}{distros}{hash} };
    #my $count =    $cpan->{data}{distros}{tote};

    my $count = 0;

    #use Data::Dumper;
    #_log("DEBUG: names=".Dumper(\%names)) if($options{verbose});
    #_log("DEBUG: lower=".Dumper(\%lower)) if($options{verbose});

    my @files = File::Find::Rule->file()->name('*.json')->in($DISTROS);
    my $files = scalar(@files);

    for my $file (sort @files) {
        $count++;

        my ($name1) = $file =~ m!/([^/]+)\.json$!;
        my $name2 = $name1;

        if($names{$name1}) {
            $name2 = $names{$name1}; # map to correct name
        }

        my @rows = $dbx->GetQuery('hash','GetUploadByName',$name2);
        for my $row (@rows) {
            if($row->{dist} eq $name2) {
                $match = $name2;
                last;
            }

            next if($match);

            if(lc $row->{dist} eq lc $name2) {
                $match = $row->{dist};
                next;
            }
        }

        unless($match) {
            _log("WARNING: UNKNOWN Distro file [$name1,$name2] [$file]") if($options{verbose});
            $errors++;
            next;
        }

        $ok++;

        my $old = sprintf "$DISTROS/%s/%s", substr($name1,0,1), $name1;
        my $new = sprintf "$DISTROS/%s/%s", substr($match,0,1), $match;

        # remove old files
        for my $ext (qw(json js html)) {
            unlink("$old.$ext") if($options{update};
        }

        # file name mispelt, no correct version
        if(-f "$new.json") {
            unlink("$new.json") if($options{update};
        }

        $dbx->DoQuery('PushDistro',$name)   if($options{update});
    }

    _log("Distro Lower: count=$count, errors=$errors, ok=$ok");
}

sub check_author_json {
    my ($cpan,$dbx) = @_;
    my ($ok,$updated,$missing,$empty) = (0,0,0,0);

    my $count = $cpan->{data}{authors}{tote};

    for my $row (@{ $cpan->{data}{authors}{list} }) {
        my $name = $row->{author};
        my $file = sprintf "$BACKPAN/%s/%s/%s", uc substr($name,0,1), uc substr($name,0,2), uc $name;
        next    unless(-d $file);
        $file = sprintf "$AUTHORS/%s/%s.json", uc substr($name,0,1), $name;
        if(-f $file) {
            my $json = read_file($file);
            my $data = decode_json($json);
            next    unless(scalar(@$data));

            my $trial = 0;
            for my $d (@$data) {
                if($d->{version} =~ /-TRIAL/) {
                    $trial = 1;
                    $d->{cssrelease} = 'dev';
                }
            }

            if($trial) {
                $updated++  if($trial);
                if($options{update}) {
                    $json = encode_json($data);
                    write_file($file,$json);
                }
                _log("UPDATE: $name")                if($options{verbose});
            } else {
                $ok++;
            }
        } else {
            $missing++;
            $dbx->DoQuery('PushAuthor',$name)    if($options{update});
            _log("MISSING: $name")                if($options{verbose});
        }
    }

    _log("Author JSON: count=$count, empty=$empty, missing=$missing, updated=$updated, pushed=".($missing+$updated).", ok=$ok");
}

sub check_distro_json {
    my ($cpan,$dbx) = @_;
    my ($ok,$updated,$missing,$empty) = (0,0,0,0);

    my $ignore = $cpan->ignore();
    my $symlinks = $cpan->symlinks();

    my %names = %{ $cpan->{data}{distros}{hash} };
    my $count =    $cpan->{data}{distros}{tote};

    for my $dist (keys %names) {
        my $name = $symlinks->{$dist} || $dist;
        next    if($ignore->{$name});

        my $file = sprintf "$DISTROS/%s/%s.json", uc substr($name,0,1), $name;

        if(-f $file) {
            my $json = read_file($file);
            my $data = decode_json($json);
            next    unless(scalar(@$data));

            my $trial = 0;
            for my $d (@$data) {
                if($d->{version} =~ /-TRIAL/) {
                    $trial = 1;
                    $d->{cssrelease} = 'dev';
                }
            }

            if($trial) {
                $updated++  if($trial);
                if($options{update}) {
                    $json = encode_json($data);
                    write_file($file,$json);
                }
                _log("UPDATE: $name")                if($options{verbose});
            } else {
                $ok++;
            }
        } else {
            $missing++;
            $dbx->DoQuery('PushDistro',$name)   if($options{update});
            _log("MISSING: $name")              if($options{verbose});
        }
    }

    _log("Distro JSON: count=$count, empty=$empty, missing=$missing, updated=$updated, pushed=".($missing+$updated).", ok=$ok");
}

sub _log {
    my @date = localtime(time);
    my $date = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $date[5]+1900, $date[4]+1, $date[3], $date[2], $date[1], $date[0];
    print "$date " . join(' ',@_ ). "\n";
}
__END__

=head1 AUTHOR

  Copyright (c) 2009-2013 Barbie <barbie@cpan.org> Miss Barbell Productions.

=head1 LICENSE

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
