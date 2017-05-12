#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '0.09';

#----------------------------------------------------------------------------

=head1 NAME

maintain-index.pl - script to maintain the cpanadmin.ixaddress table.

=head1 SYNOPSIS

  maintain-index.pl --config=files.ini [--run] p--verbose]

=head1 DESCRIPTION

Rebuilds the cpanadmin.ixaddress table, based on the confirmed email addresses
in the cpanadmin.ixtester table, and the testers.address table.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use Config::IniFiles;
use Getopt::ArgvFile default=>1;
use Getopt::Long;

use CPAN::Testers::Common::DBUtils;

# -------------------------------------
# Variables

my %options;

# -------------------------------------
# Program

init_options();
rebuild();

# -------------------------------------
# Functions

sub rebuild {
    my $next;

    my $next = $options{source}->iterator('hash',"SELECT * FROM users");
    while(my $row = $next->()) {
        $options{source}->do_query('DELETE FROM ixaddress WHERE userid=?',$row->{userid})   if($options{run});
        _log("delete old entries for $row->{realname} [$row->{userid}]");
        my $next2 = $options{source}->iterator('hash',"SELECT * FROM ixtester WHERE userid=? AND confirmed=1", $row->{userid});
        while(my $row2 = $next2->()) {
            my @rows = $options{source}->get_query('hash','SELECT addressid FROM testers.address WHERE email=?',$row2->{email});
            for my $addr (@rows) {
                $options{source}->do_query('INSERT INTO ixaddress SET userid=?,addressid=?',$row->{userid},$addr->{addressid})    if($options{run});
                _log("mapped $row->{userid} to $addr->{addressid} for $row2->{email}");
            }
        }
    }
}

sub init_options {
    GetOptions( \%options,
        'config=s',
        'run',
        'verbose',
        'help|h',
    );

    _help(1)    if($options{help});

    die "Configuration file [$options{config}] not found\n" unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure cpanstats DB
    my %opts = map {$_ => $cfg->val('DATABASE',$_);} qw(driver database dbfile dbhost dbport dbuser dbpass);
    $options{source} = CPAN::Testers::Common::DBUtils->new(%opts);

    die "Cannot configure SOURCE database\n"    unless($options{source});
}

sub _help {
    my $full = shift;

    if($full) {
        print <<HERE;

Usage: $0 \\
         [-config=<file>] [-h] [-v]

  --config=<file>   database configuration file
  -h                this help screen
  -v                verbose mode

HERE

    }

    print "$0 v$VERSION\n";
    exit(0);
}


sub _log {
    return  unless($options{verbose});

    print join(' ',@_) . "\n";
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
