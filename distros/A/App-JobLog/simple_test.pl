#!/usr/bin/perl 

# ABSTRACT: for debugging single time expressions

use Modern::Perl;
use lib 'lib';
use App::JobLog::TimeGrammar;
use File::Temp;
use DateTime;
use App::JobLog::Config qw(
  start_pay_period
  pay_period_length
  DIRECTORY
);

my $dir = File::Temp->newdir();
$ENV{ DIRECTORY() } = $dir;
my $start_pay_period = DateTime->new( year => 2011, month => 2, day => 13 );
start_pay_period($start_pay_period);
pay_period_length(14);

my $line = join( ' ', @ARGV );

eval {
    if ( my ( $h1, $h2 ) = parse($line) )
    {
        print "$line: $h1 - $h2\n";
    }
};
print $@ if $@;
