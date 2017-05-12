#!/usr/bin/perl -w
use strict;

$|++;

my $VERSION = '3.34';
my $LABYRINTH = '5.00';

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

use CPAN::Testers::Common::Article;

#----------------------------------------------------------
# Variables

my $AUTHORS = '/var/www/reports/html/static/author';
my $DISTROS = '/var/www/reports/html/static/distro';
my $BACKPAN = '/opt/projects/BACKPAN/authors/id';

my %osfix = (
    '3DMSWin32' => 'mswin32',
    'darwiThis' => 'darwin',
    'freeb'     => 'freebsd',
    'li'        => 'linux',
    'lin'       => 'linux',
    'linThis'   => 'linux',
    'linu'      => 'linux',
    'linuThis'  => 'linux',
    'linuxThis' => 'linux',
    'lThis'     => 'linux',
    'netb'      => 'netbsd',
    'netbs'     => 'netbsd',
    'openThis'  => 'openbsd',

    'openosname=openbsd' => 'openbsd',
    'osname=openosname=openbsd' => 'openbsd'
);

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

    check_osname($cpan,$dbx);

    _log("Finish");
}

sub prep_hashes {
    my ($cpan,$dbx) = @_;

    my @osname = $dbx->GetQuery('hash','AllOSNames');
    my %osname = map { $_->{osname} => 1 } @osname;
    my %oscode = map { $_->{ostitle} => $_->{osname} } @osname;
    my $osname = scalar(@osname);

    $cpan->{data}{osname}{tote} = $osname;
    $cpan->{data}{osname}{list} = \@osname;
    $cpan->{data}{osname}{hash} = \%osname;
    $cpan->{data}{osname}{code} = \%oscode;
}

sub check_osname {
    my ($cpan,$dbx) = @_;
    my $fixed = 0;

    my $next = $dbx->Iterator('hash','GetReportBlankOS');
    while(my $row = $next->()) {
        my @meta = $dbx->GetQuery('hash','GetMetabaseByGUID',$row->{guid});
        if(@meta) { 
             my ($osname, $archname, $report) = _check_arch_os($meta[0]);
        
             if($cpan->{data}{osname}{hash}{ $osname }) {
                 _log("UPDATE: $row->{id} => $osname");
                 $dbx->DoQuery('SetReportOS',$osname,$row->{id}) if($options{update});
                 $fixed++;

             } elsif($cpan->{data}{osname}{code}{ $osname }) {
                 $osname = $cpan->{data}{osname}{code}{ $osname };
                 _log("UPDATE: $row->{id} => $osname");
                 $dbx->DoQuery('SetReportOS',$osname,$row->{id}) if($options{update});
                 $fixed++;

             } elsif($cpan->{data}{osname}{hash}{ lc $osname }) {
                 $osname = lc $osname;
                 _log("UPDATE: $row->{id} => $osname");
                 $dbx->DoQuery('SetReportOS',$osname,$row->{id}) if($options{update});
                 $fixed++;

             } elsif($osfix{ $osname }) {
                 $osname = $osfix{ $osname };
                 _log("UPDATE: $row->{id} => $osname");
                 $dbx->DoQuery('SetReportOS',$osname,$row->{id}) if($options{update});
                 $fixed++;

             } else {
                 _log("BAD OS: $row->{id} osname=$osname, archname=$archname, report=$report");
             }

        } else {
             _log("MISSING: $row->{id}");
        }
    }

    _log("Fix: fixed=$fixed");
}

sub _check_arch_os {
    my $row = shift;

    my $data = decode_json($row->{report});

    my $fact = decode_json($data->{'CPAN::Testers::Fact::LegacyReport'}{content});
    my $textreport = $fact->{textreport};

    # create a fake mail, as CTC::Article parses a mail like text block
    my $mail = <<EMAIL;
From: fake\@example.com
To: fake\@example.com
Subject: PASS Fake-0.01
Date: 01-01-2010 01:01:01 Z

$textreport
EMAIL
    my $object = CPAN::Testers::Common::Article->new( $mail ) or return;
    $object->parse_report();

    return $object->osname(), $object->archname, $textreport;
}


sub _log {
    my @date = localtime(time);
    my $date = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $date[5]+1900, $date[4]+1, $date[3], $date[2], $date[1], $date[0];
    print "$date " . join(' ',@_ ). "\n";
}
__END__

=head1 AUTHOR

  Copyright (c) 2009-2010 Barbie <barbie@cpan.org> Miss Barbell Productions.

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  See http://www.perl.com/perl/misc/Artistic.html

=cut
