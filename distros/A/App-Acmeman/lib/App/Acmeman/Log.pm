package App::Acmeman::Log;
use strict;
use warnings;
use File::Basename;
use parent 'Exporter';

my @exv = qw(
        EX_OK        
	EX_USAGE     
	EX_DATAERR   
	EX_NOINPUT   
	EX_SOFTWARE  
	EX_OSFILE    
	EX_CANTCREAT 
	EX_NOPERM    
	EX_CONFIG
);

my @fnv = qw(error debug abend debug_level);

our @EXPORT_OK = (@fnv, @exv);
    
our %EXPORT_TAGS = (
    'all' => [@fnv],
    'sysexits' => [@exv]);

our $progname = basename($0);
our $debug_level = 0;

use constant {
    EX_OK           => 0,
    EX_USAGE        => 64,
    EX_DATAERR      => 65,
    EX_NOINPUT      => 66,
    EX_SOFTWARE     => 70,
    EX_OSFILE       => 72,
    EX_CANTCREAT    => 73,
    EX_NOPERM       => 77,
    EX_CONFIG       => 78
};

sub debug_level {
    my $lev = shift;
    if ($lev) {
	$debug_level = $lev;
    }
    $debug_level;
}

sub error {
    my $msg = shift;
    local %_ = @_;
    print STDERR "$progname: ";
    print STDERR "$_{prefix}: " if defined($_{prefix});
    print STDERR "$msg\n"
}

sub debug {
    my $l = shift;
    error(join(' ',@_), prefix => 'DEBUG') if $debug_level >= $l;
}

sub abend {
    my $code = shift;
    error(@_);
    exit $code;
}

1;

