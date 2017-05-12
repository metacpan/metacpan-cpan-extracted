package Term::ReadLine::Caroline;
use strict;
use warnings;
use utf8;
use 5.008_001;
use Term::Encoding qw/term_encoding/;

our @ISA = qw(Term::ReadLine::Stub);

use Caroline;

sub ReadLine { __PACKAGE__ }

sub new {
    my $class = shift;

    # Support multi byte characters
    my $encoding = term_encoding();
    binmode *STDIN,  ":encoding(${encoding})";
    binmode *STDOUT, ":encoding(${encoding})";

    my $self = bless {
        caroline => Caroline->new(),
        IN => *STDIN,
        OUT => *STDOUT,
        Attribs => {},
    }, $class;
}

sub caroline { shift->{caroline} }


sub readline {
    my ( $self, $prompt ) = @_;
    if (my $cb = $self->{Attribs}->{completion_callback}) {
        $self->caroline->completion_callback($cb);
    }
    my $line = $self->caroline->readline($prompt);
    $self->caroline->history_add($line) if defined($line) && $line =~ /\S/;
    return $line;
}

sub WriteHistory {
    my ($self, $filename) = @_;
    $self->caroline->write_history_file($filename);
}

sub StifleHistory {
    my ($self, $limit) = @_;
    $self->caroline->history_max_len($limit);
}

sub addhistory {
    my $self = shift;
    for my $entry (@_) {
        $self->caroline->history_add($entry);
    }
}
sub AddHistory { shift->addhistory(@_) }
sub GetHistory { shift->{history} }

sub IN { shift->{IN} }
sub OUT { shift->{OUT} }

sub MinLine { undef }



sub findConsole {
    my $console;
    my $consoleOUT;

    if (-e "/dev/tty" and $^O ne 'MSWin32') {
    $console = "/dev/tty";
    } elsif (-e "con" or $^O eq 'MSWin32') {
       $console = 'CONIN$';
       $consoleOUT = 'CONOUT$';
    } else {
    $console = "sys\$command";
    }

    if (($^O eq 'amigaos') || ($^O eq 'beos') || ($^O eq 'epoc')) {
    $console = undef;
    }
    elsif ($^O eq 'os2') {
      if ($DB::emacs) {
    $console = undef;
      } else {
    $console = "/dev/con";
      }
    }

    $consoleOUT = $console unless defined $consoleOUT;
    $console = "&STDIN" unless defined $console;
    if ($console eq "/dev/tty" && !open(my $fh, "<", $console)) {
      $console = "&STDIN";
      undef($consoleOUT);
    }
    if (!defined $consoleOUT) {
      $consoleOUT = defined fileno(STDERR) && $^O ne 'MSWin32' ? "&STDERR" : "&STDOUT";
    }
    ($console,$consoleOUT);
}

our %Features = (
    addHistory => 1,
    getHistory => 1,
);

sub Attribs { shift->{Attribs} }

sub Features { \%Features }

sub ornaments {
    # NIY
}

1;

__END__

=encoding utf8

=head1 NAME

Term::ReadLine::Caroline - Term::ReadLine style wrapper for Caroline

=head1 SYNOPSIS

    use Term::ReadLine;

    my $t = Term::ReadLine->new('program name');
    while (defined($_ = $t->readline('prompt> '))) {
        ...
        $t->addhistory($_) if /\S/;
    }

=head1 DESCRIPTION

Term::ReadLine::Caroline provides L<Term::ReadLine> interface using L<Caroline>.

You can use Caroline with this wrapper module, but I *recommend* to use L<Caroline> directly.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

This module provides interface for L<Term::ReadLine>, based on L<Caroline>.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
