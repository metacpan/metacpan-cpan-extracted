#!/usr/bin/perl -w
use strict;

$|++;

=head1 NAME

sumhits - Sum all hit counters, older than a month

=head1 SYNOPSIS

  perl sumhits.pl

=head1 DESCRIPTION

This application retrieves all the hit counters older than one month, adds the
same counters and updates the database with a single entry total for each.

=cut

my $BASE;

# create images in pages
BEGIN {
    $BASE = '/var/www/reports';
}

#----------------------------------------------------------
# Additional Modules

use lib qw|../cgi-bin/lib ../cgi-bin/plugins|;
use Labyrinth::DBUtils;
use Labyrinth::Globals;
use Labyrinth::Variables;

use Getopt::Long;

#----------------------------------------------------------
# Code

Labyrinth::Globals::LoadSettings("$BASE/toolkit/sumhits-settings.ini");
$settings{autocommit} = 0;
Labyrinth::Globals::DBConnect();

my %options;
GetOptions( \%options, 'datetime|d=i' ) or die;
my $datetime = $options{datetime} ? $options{datetime} : time() - 60 * 60 * 24 * 7 * 6;

my @areas = $dbi->GetQuery('hash','GetHitAreas');
for my $rs (@areas) {
    my $area = $rs->{area};
    my @rows = $dbi->GetQuery('hash','SumHits',$datetime,$area);
    for my $row (@rows) {
        # no processing needed?
        next    if($row->{number} == 1 && $row->{createdate} == 0);

        $dbi->DoQuery('StartTrans');
        my $rows;
        if($row->{query}) {
            $rows = $dbi->DoQuery('DelAHit',$datetime,$row->{area},$row->{pageid},$row->{photoid},$row->{query});
        } else {
            $rows = $dbi->DoQuery('DelAHit2',$datetime,$row->{area},$row->{pageid},$row->{photoid});
        }
        $dbi->DoQuery('AddAHit',$row->{counter},$row->{area},$row->{pageid},$row->{photoid},$row->{query},0);
        $dbi->DoQuery('CommitTrans');

        $rows ||= 0;
        $row->{pageid}  ||= 0;
        $row->{photoid} ||= 0;
        $row->{counter} ||= 0;
        $row->{query}   ||= '';

        printf "[%6d,%6d] %9d,%15s,%4d,%5d,%s\n", $rows,$row->{number},$row->{counter},$row->{area},$row->{pageid},$row->{photoid},$row->{query};
    }
}

__END__

=head1 AUTHOR

  Copyright (c) 2002-2014 Barbie <barbie@cpan.org> Miss Barbell Productions.

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  See http://www.perl.com/perl/misc/Artistic.html

=cut
