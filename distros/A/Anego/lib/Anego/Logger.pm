package Anego::Logger;
use strict;
use warnings;
use utf8;
use parent qw/ Exporter /;

use Term::ANSIColor qw/ colored /;

our @EXPORT = qw/ infof warnf errorf /;

use constant {
    INFO  => 1,
    WARN  => 2,
    ERROR => 3,
};

our $COLORS = {
    INFO,  => 'cyan',
    WARN,  => 'yellow',
    ERROR, => 'red',
};

sub _print {
    my ($type, $string, @args) = @_;

    my $message = sprintf($string, (map { defined($_) ? $_ : '-' } @args));
    my $colored_message = defined $COLORS->{$type}
        ? colored $message, $COLORS->{$type}
        : $message;

    my $fh = $type && $type <= INFO ? *STDOUT : *STDERR;
    print {$fh} $colored_message;
}

sub infof { _print(INFO, @_) }

sub warnf { _print(WARN, @_) }

sub errorf {
    _print(ERROR, @_);
    exit 1;
}

1;
