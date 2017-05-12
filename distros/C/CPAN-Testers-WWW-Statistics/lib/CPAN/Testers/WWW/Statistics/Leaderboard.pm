package CPAN::Testers::WWW::Statistics::Leaderboard;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '1.21';

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Statistics::Leaderboard - CPAN Testers Statistics leaderboard.

=head1 SYNOPSIS

  my %hash = { config => 'options' };
  my $obj = CPAN::Testers::WWW::Statistics->new(%hash);
  my $lb = CPAN::Testers::WWW::Statistics::Leaderboard->new(parent => $obj);

  $ct->process( renew    => 1 );        # renew all counts
  $ct->process( update   => 1 );        # update counts for the last 3 months
  $ct->process( postdate => '201206' ); # update counts for specified month
  $ct->process( check    => 1 );        # check for discrepancies

=head1 DESCRIPTION

Using the cpanstats database, this module provides the data in the 
'leaderboard' table within the 'cpanstats' database. The data itself is then
used by the Pages module to create the leaderboard pages.

Previously this information was held in a JSON file, but maintaining accurate
data has been problematic.

Note that this package should not be called directly, but via its parent as:

  my %hash = { config => 'options' };
  my $obj = CPAN::Testers::WWW::Statistics->new(%hash);

  $obj->leaderboard( %options ); # above for the list of options

=cut

# -------------------------------------
# Public Methods

=head1 INTERFACE

=head2 The Constructor

=over 4

=item * new

Page creation object. Allows the user to turn or off the progress tracking.

new() takes an option hash as an argument, which may contain 'progress => 1'
to turn on the progress tracker.

=back

=cut

sub new {
    my $class = shift;
    my %hash  = @_;

    die "Must specify the parent statistics object\n"   unless(defined $hash{parent});

    my $self = {parent => $hash{parent}};
    bless $self, $class;

    return $self;
}

=head2 Public Methods

=over 4

=item * renew

Renew all OS counts for all month entries.

=item * update

Update all OS counts for the last 3 months.

=item * postdate

Update all OS counts for the specified month.

=item * check

Verify monthy counts with source table to ensure all OS counts have been
appropriately applied.

=item * results

Provides the data as a hash for the required months, with the OS and tester
names as subsidary keys.

Note that month '999999' is a special case, and is an accumulation of all other
months, from those requested. Thus if only '999999' is requested the top level
hash return will only consist of one date, and will be a sum of all months.

=back

=cut

sub renew {
    my $self = shift;

    $self->{parent}->_log("START renew");
    $self->_update( 'SELECT distinct(postdate) as postdate FROM cpanstats' );
    $self->{parent}->_log("STOP renew");
}

sub postdate {
    my ($self,$date) = @_;

    $self->{parent}->_log("START postdate = $date");
    $self->_update( "SELECT '$date' as postdate" );
    $self->{parent}->_log("STOP postdate");
}

sub update {
    my $self = shift;

    $self->{parent}->_log("START update");
    $self->_update( 'SELECT distinct(postdate) as postdate FROM cpanstats ORDER BY postdate DESC LIMIT 3' );
    $self->{parent}->_log("STOP update");
}

sub check {
    my $self = shift;

    my $sql1 = 
            'SELECT postdate,COUNT(id) AS qty FROM cpanstats '.
            'WHERE type=2 '.
            'GROUP BY postdate';
    my $sql2 =
            'SELECT postdate,SUM(score) AS qty FROM leaderboard '.
            'GROUP BY postdate '.
            'ORDER BY postdate';

    my %hash;
    my @rows = $self->{parent}->{CPANSTATS}->get_query('hash',$sql1);
    for my $row (@rows) {
        $hash{ $row->{postdate} } = $row->{qty};
    }

    my %data;
    @rows = $self->{parent}->{CPANSTATS}->get_query('hash',$sql2);
    for my $row (@rows) {
        next if($hash{ $row->{postdate} } == $row->{qty});
        my $str = sprintf "%s, %d, %d", $row->{postdate}, $hash{ $row->{postdate} }, $row->{qty};
        $self->{parent}->_log($str);

        $data{$row->{postdate}}{cpanstats}   = $hash{ $row->{postdate} };
        $data{$row->{postdate}}{leaderboard} = $row->{qty};
    }

    return \%data;
}

sub results {
    my $self = shift;
    my %dates = map {$_ => 1} @{ shift() };

    my $sql1 = q{SELECT * FROM leaderboard ORDER BY postdate,osname};
#    my $sql1 = q{
#        SELECT l.*, p.name, p.pause
#        FROM leaderboard l
#        LEFT JOIN testers.profile p ON p.testerid=l.testerid
#        ORDER BY postdate,osname
#    };

    my %hash;
    my @rows = $self->{parent}->{CPANSTATS}->get_query('hash',$sql1);
    for my $row (@rows) {
        my $tester = $self->{parent}->tester_lookup($row->{addressid},$row->{testerid});
        $tester ||= $row->{tester};

        if($dates{ $row->{postdate} }) {
            $hash{ $row->{postdate} }{$row->{osname}}{$tester} = $row->{score};
        } elsif($dates{ '999999' }) {
            $hash{ '999999' }{$row->{osname}}{$tester} += $row->{score};
        }
    }

    # make sure we reference an empty hash, not undef
    for(keys %dates) {
        $hash{$_} = {}    unless(defined $hash{$_});
    }

    return \%hash;
}

# -------------------------------------
# Private Methods

sub _update {
    my $self = shift;

    my $sql1 = shift;
    my $sql2 = 'SELECT osname,tester,COUNT(id) AS count FROM cpanstats '.
               'WHERE postdate=? AND type=2 '.
               'GROUP BY osname,tester ORDER BY tester,osname';
    my $sql3 = 'REPLACE INTO leaderboard (postdate,osname,tester,score,addressid,testerid) VALUES (?,?,?,?,?,?)';
    my $sql4 = 'DELETE FROM leaderboard WHERE postdate=?';

    my @rows = $self->{parent}->{CPANSTATS}->get_query('hash',$sql1);
    for my $row (@rows) {
        $self->{parent}->_log("postdate = $row->{postdate}");

        $self->{parent}->{CPANSTATS}->do_query($sql4,$row->{postdate});

        my (%hash,%names);
        my $next = $self->{parent}->{CPANSTATS}->iterator('hash',$sql2,$row->{postdate});
        while(my $row2 = $next->()) {
            my ($name,$addressid,$testerid) = $self->{parent}->tester($row2->{tester});
            my $osname = lc $row2->{osname};

            #$self->{parent}->_log( sprintf "%s,%s,%d", $osname, $name, $row2->{count} );
            $hash{$osname}{$name}{score}    += $row2->{count};
            $hash{$osname}{$name}{addressid} = $addressid;
            $hash{$osname}{$name}{testerid}  = $testerid;
            #$self->{parent}->_log( sprintf "%s,%s,%d", $osname, $name, $hash{$osname}{$name}{score} );
        }

        for my $osname (keys %hash) {
            for my $name (keys %{ $hash{$osname} }) {
                $self->{parent}->{CPANSTATS}->do_query($sql3, 
                    $row->{postdate}, $osname, $name, 
                    $hash{$osname}{$name}{score},
                    $hash{$osname}{$name}{addressid},
                    $hash{$osname}{$name}{testerid});
            }
        }
    }
}

q("I'll never forget him (the leader of the pack)");


__END__

=head1 CPAN TESTERS FUND

CPAN Testers wouldn't exist without the help and support of the Perl 
community. However, since 2008 CPAN Testers has grown far beyond the 
expectations of it's original creators. As a consequence it now requires
considerable funding to help support the infrastructure.

In early 2012 the Enlightened Perl Organisation very kindly set-up a
CPAN Testers Fund within their donatation structure, to help the project
cover the costs of servers and services.

If you would like to donate to the CPAN Testers Fund, please follow the link
below to the Enlightened Perl Organisation's donation site.

F<https://members.enlightenedperl.org/drupal/donate-cpan-testers>

If your company would like to support us, you can donate financially via the
fund link above, or if you have servers or services that we might use, please
send an email to admin@cpantesters.org with details.

Our full list of current sponsors can be found at our I <3 CPAN Testers site.

F<http://iheart.cpantesters.org>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Statistics

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Reports>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2015 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
