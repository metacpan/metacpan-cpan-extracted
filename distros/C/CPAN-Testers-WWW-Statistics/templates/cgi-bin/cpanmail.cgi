#!/usr/bin/perl -w
use strict;
$|++;

my $VERSION = '1.14';

#----------------------------------------------------------------------------

=head1 NAME

cpanmail.cgi - script to access a tester's email address for a given report.

=head1 SYNOPSIS

  perl cpanmail.cgi

=head1 DESCRIPTION

Given a report identifier, either as a report ID or a Metabase GUID, will
perform a look up to retrieve the tester's email address for the given report
identifier.

=cut

# -------------------------------------
# Library Modules

use CGI;
#use CGI::Carp qw(fatalsToBrowser);
use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use Template;

# -------------------------------------
# Variables

my $LOG = 'logs/cpanstats.log';
my $CONFIG = './cpanmail.ini';

my %tvars;

# -------------------------------------
# Program

my $cgi = CGI->new();
my $id  = $cgi->param('id');        # new style

if($id && $id =~ /^(\d+)$/) {
    $tvars{id} = $1;
} elsif($id && $id =~ /^([-\w]+)$/) {
    $tvars{guid} = $1;
}

my $found = 0;
if($tvars{id} || $tvars{guid}) {
    if(-f $CONFIG) {
        $found = retrieve_from_db(
            id      => $tvars{id},
            guid    => $tvars{guid}
        );
    }

    $found ||= 5;
} else {
    $found = 3;
}

$tvars{found} = $found;
write_results();

# -------------------------------------
# Subroutines

=item retrieve_from_db

Access the database and retrieve the required article data.

=cut

sub retrieve_from_db {
    my %hash = @_;
    my $cfg;

    # load configuration file
    local $SIG{'__WARN__'} = \&_alarm_handler;
    eval { $cfg = Config::IniFiles->new( -file => $CONFIG ); };
    return 0    unless($cfg && !$@);

    # configure databases
    my $db = 'CPANSTATS';
    return 0    unless($cfg->SectionExists($db));
    my %opts = map {my $v = $cfg->val($db,$_); defined($v) ? ($_ => $v) : () }
                    qw(driver database dbfile dbhost dbport dbuser dbpass);
    my $dbh = CPAN::Testers::Common::DBUtils->new(%opts);
    return 0    unless($dbh);

    my $sql;
    if(defined $hash{id}) {
        $sql = "SELECT * FROM cpanstats WHERE id=$hash{id}";
    } elsif(defined $hash{guid}) {
        $sql = "SELECT * FROM cpanstats WHERE guid='$hash{guid}'";
    }

    my @rows = $dbh->get_query('hash',$sql);
    return 0    unless(@rows);

    $tvars{id}      = $rows[0]->{id};
    $tvars{guid}    = $rows[0]->{guid};
    $tvars{subject} = sprintf "%s %s-%s %s %s", uc $rows[0]->{state}, $rows[0]->{dist}, $rows[0]->{version}, $rows[0]->{perl}, $rows[0]->{osname};

    # find testers preferred contact address
    $sql = 'SELECT tp.* FROM testers.address ta '
        .  'LEFT JOIN testers.profile tp ON tp.testerid=ta.testerid '
        .  'WHERE ta.address=? ORDER BY tp.testerid DESC';
    @mails = $dbh->get_query('hash',$sql,$rows[0]->{tester});

    $tvars{from}   = $mails[0]->{contact} if(@mails);
    $tvars{from} ||= $rows[0]->{tester};    # just in case

    return 1;
}

=item write_results

Outputs the results using Template Toolkit

=cut

sub write_results {
    # deter spammers
    if($tvars{from}) {
        $tvars{from} =~ s/\@/ at /g;
        $tvars{from} =~ s/\./ dot /g;
    }

    my %config = (								# provide config info
		RELATIVE		=> 1,
		ABSOLUTE		=> 1,
		INCLUDE_PATH	=> '..',
		INTERPOLATE		=> 0,
		POST_CHOMP		=> 1,
		TRIM			=> 1,
	);

    print $cgi->header;
	my $parser = Template->new(\%config);		# initialise parser
	$parser->process('response.html',\%tvars)	# parse the template
		or die $parser->error();
}

sub _alarm_handler { return; }

__END__

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org. However, it would help
greatly if you are able to pinpoint problems or even supply a patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<CPAN::Testers::WWW::Statistics>.

F<http://stats.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
