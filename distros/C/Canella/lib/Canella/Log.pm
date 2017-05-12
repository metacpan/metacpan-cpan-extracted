package Canella::Log;
use strict;
use Exporter 'import';
use Log::Minimal ();

our @EXPORT = @Log::Minimal::EXPORT;

BEGIN {
    foreach my $method (@Log::Minimal::EXPORT) {
        no strict 'refs';
        *{$method} = sub {
            local $Log::Minimal::COLOR = 1;
            local $Log::Minimal::PRINT = \&MYPRINT;
            "Log::Minimal::$method"->(@_);
        };
    }
}

sub MYPRINT {
    my ($time, $type, $message, $trace) = @_;
    my $fh = $type =~ /^(?:WARN|CRIT:)$/ ? \*STDERR : \*STDOUT;

    printf $fh ( "%s %s\n", $time, $message );
}

1;