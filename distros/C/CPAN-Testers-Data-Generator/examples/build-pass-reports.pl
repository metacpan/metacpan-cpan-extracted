#!/usr/bin/perl -w
use strict;

$|++;

use CPAN::Testers::Common::DBUtils;
use Config::IniFiles;
use Getopt::Long;

my %options;
my $config = 'data/settings.ini';

GetOptions( \%options, 'config=s', 'from=i', 'to=i' ) or die "Usage: $0 [--config=<file>] [--from=<id>] [--to=<id>]\n";

$options{config} ||= $config;
$options{from}   ||= 0;

{
    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure databases
    my $dbx;
    my $db = 'CPANSTATS';
    die "No configuration for $db database\n"   unless($cfg->SectionExists($db));
    my %opts = map {$_ => ($cfg->val($db,$_)||undef);} qw(driver database dbfile dbhost dbport dbuser dbpass);
    $opts{AutoCommit} = 0;
    $dbx = CPAN::Testers::Common::DBUtils->new(%opts);
    die "Cannot configure $db database\n" unless($dbx);
    $dbx->{'mysql_enable_utf8'}    = 1 if($opts{driver} =~ /mysql/i);
    $dbx->{'mysql_auto_reconnect'} = 1 if($opts{driver} =~ /mysql/i);

    my @max = $dbx->get_query('hash','SELECT max(id) as max, count(*) as total FROM cpanstats');
    my $max = $max[0]->{max};
    my $total = $max[0]->{total};

    $options{to} ||= $max;

    print "max = $max, total = $total\n";

    my $top = int($max / 1000000) + 1;
    my $count = 0;
    for my $id (0 .. $top) {
        my $start  =  $id      * 1000000;
        my $finish = ($id + 1) * 1000000;

        next                    if($finish < $options{from});
        $start = $options{from} if($start  < $options{from});
        $finish = $options{to}  if($start  < $options{to} && $finish > $options{to});

        my $iterator = $dbx->iterator('hash',"SELECT * FROM cpanstats WHERE id >= $start AND id < $finish ORDER BY id");
        while(my $row = $iterator->()) {
            my $perl = $row->{perl};
            $perl =~ s/\s.*//;  # only need to know the main release

            $dbx->do_query('INSERT IGNORE passreports SET platform=?, osname=?, perl=?, dist=?, postdate=?',
                $row->{platform},
                $row->{osname},
                $perl,
                $row->{dist},
                $row->{postdate}
            );

            $count++;
            printf "$row->{id} / $max = %.2f\n", (($count / $total) % 100)
                if ($count % 100000 == 0);
        }
    }
}
