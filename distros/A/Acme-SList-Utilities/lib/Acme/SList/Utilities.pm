package Acme::SList::Utilities;
$Acme::SList::Utilities::VERSION = '0.04';
use strict;
use warnings;

use File::Copy;
use File::Slurp;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(crdir sdate sduration commify target dircopy);

sub crdir {
    my ($path) = @_;

    my $dir = '';
    for my $elem (split m{[/\\]}xms, $path) {
        if ($elem =~ m{\A \s* \z}xms) {
            $! = 33; # Domain error
            return;
        }
        $dir .= $elem.'/';
        if ($elem ne '..' and !-d $dir) {
            mkdir $dir or return;
        }
    }
    return 1;
}

sub dircopy {
    my ($from, $to) = @_;

    $from =~ s{/+ \z}''xms;
    $to   =~ s{/+ \z}''xms;

    for my $file (read_dir $from) {
        copy "$from/$file", "$to/$file" or return;
    }

    return 1;
}

sub sdate {
    my ($stamp) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = localtime $stamp;
    return sprintf("%02d/%02d/%04d %02d:%02d:%02d",
      $mday, $mon + 1, $year + 1900, $hour, $min, $sec);
}

sub sduration { # calculate a duration ($_[0]...$_[1])
    my ($from, $to) = @_;

    my $tsec  = $to - $from;     my $sec  = $tsec % 60;
    my $tmin  = int($tsec / 60); my $min  = $tmin % 60;
    my $thour = int($tmin / 60); my $hour = $thour;

    my $dur = "$sec sec";
    $dur = "$min min ".$dur  unless $min  == 0;
    $dur = "$hour hrs ".$dur unless $hour == 0;
    return $dur;
}

sub commify {
    my ($number) = @_;

    1 while $number =~ s/^([-+]?\d+)(\d{3})/$1_$2/;
    $number =~ s/\./,/;
    return $number;
}

sub target {
    my ($Program) = @_;

    if (defined($ENV{'SL_Target'}) and $ENV{'SL_Target'} ne '') {
        my $sl_target = lc $ENV{'SL_Target'};
        if ($sl_target !~ m{\A [0-9a-z]{0,4} \z}xms) {
            die "Variable SL_Target: '$sl_target' contains non-alphanumeric characters or is more than 4 characters long";
        }
        return "SList-$Program-$sl_target";
    }
    return "SList-$Program";
}

1;

__END__

=head1 NAME

Acme::SList::Utilities - Various utilitiy-functions for the SList suite of programs

=head1 SYNOPSIS

    use Acme::SList::Utilities qw(crdir sdate sduration commify);

    crdir '../dir1/dir2/dir3' or die "Error: Can't create directory because $!";

    print 'today is: ', sdate(time), "\n";

    my $from = time;
    sleep(4);
    my $to = time;
    print 'Time passed: ', sduration($from, $to), "\n";

    my $number = 1234567.89876;
    print 'number commified: ', commify($number), "\n";

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
