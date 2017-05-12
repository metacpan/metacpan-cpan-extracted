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
    $BASE = '/var/www/cpanblog';
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
GetOptions( \%options, 'datetime|d' );
my $datetime = $options{datetime} ? $options{datetime} : time() - 60 * 60 * 24 * 7 * 6;

my @areas = $dbi->GetQuery('hash','GetHitAreas');
for my $rs (@areas) {
    my $area = $rs->{area};
    my @rows = $dbi->GetQuery('hash','SumHits',$datetime,$area);
    for my $row (@rows) {
        # no processing needed?
        next    if($row->{number} == 1 && $row->{createdate} == 0);

        $dbi->DoQuery('StartTrans');
        my $rows = $dbi->DoQuery('DelAHit',$datetime,$row->{area},$row->{pageid},$row->{photoid},$row->{query});
        $dbi->DoQuery('AddAHit',$row->{counter},$row->{area},$row->{pageid},$row->{photoid},$row->{query},0);
        $dbi->DoQuery('CommitTrans');
        printf "[%6d] %6d,%15s,%3d,%3d,%s\n", $rows, $row->{counter},$row->{area},$row->{pageid},$row->{photoid},$row->{query};
    }
}

__END__

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2011 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
