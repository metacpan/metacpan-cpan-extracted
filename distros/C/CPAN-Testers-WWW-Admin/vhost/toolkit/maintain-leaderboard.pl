#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '0.09';

#----------------------------------------------------------------------------

=head1 NAME

maintain-leaderboard.pl - script to maintain the cpanstats.leaderboard table.

=head1 SYNOPSIS

  maintain-leaderboard.pl --config=files.ini

=head1 DESCRIPTION

Builds the tables from existing data, both in the cpanstats and metabase
databases, and stand-alone files used by the system.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use Compress::Zlib;
use Config::IniFiles;
use DateTime;
use File::Basename;
use File::Slurp;
use Getopt::ArgvFile default=>1;
use Getopt::Long;
use HTML::Entities;
use IO::File;
use LWP::UserAgent;
use Path::Class;
use Parse::CPAN::Authors;
use Template;
use Time::Piece;
use WWW::Mechanize;

use CPAN::Testers::Common::DBUtils;

# -------------------------------------
# Variables

my $DEBUG = 0;

my %defaults = (
    'address'   => 'data/addresses.txt',
    'mailrc'    => 'data/01mailrc.txt',
);

my (%result,%options,%address);
my $parsed = 0;

# -------------------------------------
# Program

init_options();
load_addresses();
build();

# -------------------------------------
# Functions

sub build {
    my $next;

    my $next = $options{source}->iterator('hash',"SELECT * FROM leaderboard WHERE testerid=0");
    while(my $row = $next->()) {
        #print "tester=$row->{tester}\n";
        if( my $profile = $address{names}{$row->{tester}} ) {
            #print "1.profile=".join(',',@$profile)."\n";
            next    if($address{names}{$row->{tester}}->[2] && $address{names}{$row->{tester}}->[2] eq $row->{tester});
            $address{names}{$row->{tester}}->[2] = $row->{tester};
            $options{source}->do_query('UPDATE leaderboard SET addressid=?,testerid=? WHERE tester=?',@$profile);
            #print "- updated\n";
        } elsif( my $profile = $address{email}{$row->{tester}} ) {
            #print "2.profile=".join(',',@$profile)."\n";
            next    if($address{email}{$row->{tester}}->[2] && $address{email}{$row->{tester}}->[2] eq $row->{tester});
            $address{email}{$row->{tester}}->[2] = $row->{tester};
            $options{source}->do_query('UPDATE leaderboard SET addressid=?,testerid=? WHERE tester=?',@$profile);
            #print "- updated\n";
        } elsif( my $profile = $address{address}{$row->{tester}} ) {
            #print "3.profile=".join(',',@$profile)."\n";
            next    if($address{address}{$row->{tester}}->[2] && $address{address}{$row->{tester}}->[2] eq $row->{tester});
            $address{address}{$row->{tester}}->[2] = $row->{tester};
            $options{source}->do_query('UPDATE leaderboard SET addressid=?,testerid=? WHERE tester=?',@$profile);
            #print "- updated\n";
        }
    }
}

sub load_addresses {
    my @rows = $options{source}->get_query('hash','SELECT a.*,p.name,p.pause FROM testers.address a LEFT JOIN testers.profile p ON p.testerid=a.testerid');
    for my $row (@rows) {
        my %names = ( email => $row->{email}, address => $row->{address} );
        if($row->{name} && $row->{pause}) {
            $names{name} = "$row->{name} ($row->{pause})";
        } elsif($row->{name}) {
            $names{name} = $row->{name};
        } else {
            $names{name} = $row->{address};
        }

        for my $key (keys %names) {
            if($names{$key} =~ /\@/) {
                $names{$key} =~ s/\./ /g;
                $names{$key} =~ s/\@/ \+ /g;
                $names{$key} =~ s/</&lt;/g;
                $names{$key} =~ s/>/&gt;/g;
            }

            $names{$key} =~ s/'/&#39;/g;
            $names{$key} =~ s/"/&quot;/g;
        }

        $names{name} = encode_entities($names{name})
            if($names{name} !~ /\&(\#x?\d+|\w+)\;/);


        $address{names}{$names{name}}       = [ $row->{addressid}, $row->{testerid} ];
        $address{email}{$names{email}}      = [ $row->{addressid}, $row->{testerid} ];
        $address{address}{$names{address}}  = [ $row->{addressid}, $row->{testerid} ];
    }

    #use Data::Dumper;
    #print "address=" . Dumper(\%address);
}

sub init_options {
    GetOptions( \%options,
        'config=s',
        'verbose',
        'help|h',
        'version|V'
    );

    _help(1)    if($options{help});
    _help(0)    if($options{version});

    die "Configuration file [$options{config}] not found\n" unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure cpanstats DB
    my %opts = map {$_ => $cfg->val('CPANSTATS',$_);} qw(driver database dbfile dbhost dbport dbuser dbpass);
    $options{source} = CPAN::Testers::Common::DBUtils->new(%opts);

    die "Cannot configure SOURCE database\n"    unless($options{source});

    # use defaults if none provided
    for my $opt (qw(address mailrc verbose logfile logclean)) {
        $options{$opt} ||= $cfg->val('MASTER',$opt) || $defaults{$opt};
    }
}

sub _help {
    my $full = shift;

    if($full) {
        print <<HERE;

Usage: $0 \\
         [-config=<file>] [-h] [-V]

  --config=<file>   database configuration file
  -h                this help screen
  -V                program version

HERE

    }

    print "$0 v$VERSION\n";
    exit(0);
}


sub _log {
    return  unless($options{logfile});

    my $mode = $options{logclean} ? 'w+' : 'a+';
    my $log = IO::File->new($options{logfile},$mode) or die "Cannot open file [$options{logfile}]: $!\n";
    $options{logclean} = 0;

    my $ts = DateTime->now->datetime();
    print $log join(' ',$ts,@_) . "\n";
    $log->close;
}

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Admin

=head1 SEE ALSO

L<CPAN::WWW::Testers>,
L<CPAN::Testers::WWW::Admin>

F<http://www.cpantesters.org/>,
F<https://admin.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2014 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
