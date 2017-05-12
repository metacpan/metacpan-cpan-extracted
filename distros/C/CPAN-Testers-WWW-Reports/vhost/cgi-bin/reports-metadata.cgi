#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '3.53';

#----------------------------------------------------------------------------

=head1 NAME

reports-metadata.cgi - program to return CPAN Testers report metadata

=head1 SYNOPSIS

  perl reports-metadata.cgi

=head1 DESCRIPTION

Called in a CGI context, returns the current reporting statistics for a CPAN
distribution, depending upon the parameters provided.

Primary Query String parameters are

=over 4

item * date

Retrieve report data for a specific date. The results of this requests are
intended to be used to provide a further range request.

item * range

Retrieve reports for a set of id ranges, up to a maximum of 2500 reports. 

Ranges can be open ended, such that "range=-10000" retrieves the first 2500 
reports and "range=10000-" will retrieve reports from the given id to the 
latest report respective, or the next 2500 as appropriate. Note that "range=-"
is valid, but will only retrieve the first 2500 reports.

If range is a single id, only that report id is returned, if found.

=back

=cut

# -------------------------------------
# Library Modules

use CGI;
use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use Data::Dumper;
use Getopt::Long;
use IO::File;
use JSON::XS;

# -------------------------------------
# Variables

my $DEBUG = 1;

my $LIMIT = 2500;

my $VHOST = '/var/www/reports/';
my (%options,%cgiparams,%data,$cgi);

my %rules = (
    date    => qr/^(\d{4}\-\d{2}\-\d{2})$/i,
    range   => qr/^((?:\d+)?\-(?:\d+)?|\d+)$/i,
);


# -------------------------------------
# Program

init_options();
process_date()  if($cgiparams{date});
process_range() if($cgiparams{range});
writer();

# -------------------------------------
# Subroutines

sub init_options {
    GetOptions( 
        \%options,
        'config=s',
        'date=s',
        'range=s'
    );

    $options{config} ||= $VHOST . 'cgi-bin/config/settings.ini';

    error("Must specific the configuration file\n")             unless($options{config});
    error("Configuration file [$options{config}] not found\n")  unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure upload DB
    for my $db (qw(CPANSTATS)) {
        my %opts = map {$_ => $cfg->val($db,lc $db . '_' . $_);} qw(driver database dbfile dbhost dbport dbuser dbpass);
        $options{$db} = CPAN::Testers::Common::DBUtils->new(%opts);
        error("Cannot configure '$options{database}' database\n")   unless($options{$db});
    }

    $cgi = CGI->new;

    #audit("DEBUG: configuration done");

    for my $key (qw(date range)) {
        my $val = $cgi->param($key);
        $cgiparams{$key} = $1   if($val =~ $rules{$key});
    }

    #audit('DEBUG: cgiparams=',Dumper(\%cgiparams));
}

sub process_date {
    my (@list,$min,$max);

    my $where = sprintf "WHERE fulldate LIKE '%04d%02d%02d\%'", ( $cgiparams{date} =~ /(\d+)\D+(\d+)\D+(\d+)/ );
    my $sql = "SELECT id FROM cpanstats $where";
    #audit("DEBUG: sql=$sql");

    my $next = $options{CPANSTATS}->iterator('hash', $sql );
    while ( my $row = $next->() ) {
        push @list, $row->{id};

        $min ||= $row->{id};
        $max ||= $row->{id};

        $min = $row->{id}   if($row->{id} < $min);
        $max = $row->{id}   if($row->{id} > $max);
    }

    %data = (
        list    => \@list,
        from    => $min,
        to      => $max,
        range   => "$min-$max"
    );

    #audit('DEBUG: data=',Dumper(\%data));
}

sub process_range {
    my ($from,$to) = $cgiparams{range} =~ /^(\d*)\D+(\d*)$/;
    my ($where,@args);

    if($cgiparams{range} =~ /^(\d+)$/) {
        $from = $1;
        $where = "WHERE id = ?";
        @args = ($from);

    } elsif($from && $to) {
        $to = $from + $LIMIT if($to > $from + $LIMIT);
        @args = ($from, $to);
    } elsif($from) {
        $where = "WHERE id >= ? LIMIT ?";
        @args = ($from, $LIMIT);
    } elsif($to) {
        $where = "WHERE id >= ? AND id <= ?";
        @args = ($to - $LIMIT, $to);
    } else {
        my @rows = $options{CPANSTATS}->get_query('hash', 'SELECT max(id) FROM cpanstats' );
        $to = $rows[0]->{id};
        $where = "WHERE id >= ? AND id <= ?";
        @args = ($to - $LIMIT, $to);        
    }

    my $sql = "SELECT * FROM cpanstats $where";
    #audit("DEBUG: sql=$sql, args=[@args]");

    my $next = $options{CPANSTATS}->iterator('hash', $sql, @args );
    while ( my $row = $next->() ) {
        #audit("DEBUG: id=$row->{id}");
        $data{ $row->{id} } = $row;
    }
}

sub writer {
    my $result;

    my $data = encode_json(\%data);
    #audit("DEBUG: data=" . $data ? 'YES' : 'NO');
    #audit("DEBUG: data=$data");

    print $cgi->header('application/json') . $data . "\n";
}

sub error {
    audit('ERROR:',@_);
    print STDERR @_;
    print $cgi->header('text/plain'), "Error retrieving data\n";
    exit;
}

sub audit {
    return  unless($DEBUG);

    my @date = localtime(time);
    my $date = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $date[5]+1900, $date[4]+1, $date[3], $date[2], $date[1], $date[0];

    my $fh = IO::File->new($VHOST . 'cgi-bin/cache/metadata-audit.log','a+') or return;
    print $fh "$date " . join(' ',@_ ). "\n";
    $fh->close;
}

1;

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers=WWW-Reports

=head1 SEE ALSO

L<CPAN::Testers::WWW::Statistics>,
L<CPAN::Testers::WWW::Wiki>,
L<CPAN::Testers::WWW::Blog>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>,
F<http://blog.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2012-2014 Barbie <barbie@cpan.org>

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
