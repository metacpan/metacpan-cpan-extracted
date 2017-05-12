#
# useful for testing configure files
#
use strict;
use warnings;
use blib;
use Config::Scoped;
use Getopt::Std;
use Data::Dumper;
use Dumpvalue;

$Data::Dumper::Indent=1;

my $dv = Dumpvalue->new( compactDump => 1 )
  or die "Can't create a Dumpvalue object,";

my %opts;
getopts( 'lwvtdDc', \%opts ) or usage();

my $cfg_file;
$cfg_file = shift || usage() unless $opts{t};

local $::RD_TRACE = 40 if $opts{v};

my $parser = Config::Scoped->new(
    file     => $cfg_file,
    $opts{w} ? (warnings => 'off') : (),
    $opts{l} ? (lc => 1) : (),
  )
  or die "Can't create a scoped parser,";

my $config;

unless ( $opts{c} ) {
    if ( $opts{t} ) {
        my $text = join '', <>;
        $config = $parser->parse( text => $text );
	warn $@ if $@;
    }
    else {
        $config = $parser->parse;
	warn $@ if $@;
    }

    $parser->store_cache || die "can't store the config hash,"
      if defined $config && $opts{d};

}
else {
    $config = $parser->retrieve_cache
      or die "can't read config cache,";
}

$dv->dumpValue($config) unless $opts{D};
print Data::Dumper->Dump([$config], ['config']) if $opts{D};
exit 0;

sub usage {
    die <<USAGE;
Usage: $0 [-v] [-t] [-d] [-c] [cfg_file]
	-w		warnings off
	-l		lowercase on
	-v		verbose
	-t		read text to parse from stdin
	-d		dump cfg hash, Dumpvalue
	-D		dump cfg hash, Data::Dumper
	-c		use cached cfg hash
USAGE
}

# vim: cindent sm nohls sw=2 sts=2
