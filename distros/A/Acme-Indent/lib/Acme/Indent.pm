package Acme::Indent;
$Acme::Indent::VERSION = '0.04';
use strict;
use warnings;

use Carp;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(ai);
our @EXPORT_OK = qw();

sub ai {
    my @lines = split m{\n}xms, $_[0];

    my $result = '';
    my $empty = '';

    my $shft = 0;
    my $data = 0;

    for my $l (@lines) {
        unless ($data) {
            if ($l =~ m{\A (\s*) \S}xms) {
                $shft = length($1);
                $data = 1;
            }
        }

        if ($data) {
            my ($spaces, $text);

            if (length($l) >= $shft) {
                $spaces = substr($l, 0, $shft);
                $text = substr($l, $shft);
            }
            else {
                $spaces = $l;
                $text = '';
            }

            if ($spaces =~ m{\S}xms) {
                carp "Found characters ('$spaces') in indentation zone";
            }

            if ($text =~ m{\S}xms) {
                $result .= $empty.$text."\n";
                $empty = '';
            }
            else {
                $empty .= "\n";
            }
        }
    }

    return $result;
}

1;

__END__

=head1 NAME

Acme::Indent - Proper indentation for multi-line strings

=head1 SYNOPSIS

    use Acme::Indent qw(ai);

    my $mini_prog = ai(q^
        my $token = 'B';
        print "Begin test $token\n";

        my $ph = {a => 'abc', z => 'xyz'};
        my @list = qw(a r z);

        while (@list) {
            my $key = shift @list;
            if ($ph->{$key})) {
                print $ph->{$key}, "\n";
            }
        }

        $token = 'E';
        print "End test $token\n";
    ^);

    print "Mini-Prog:\n";
    print "----+----1----+----2----+----3----+----4----+----5----+----6\n";
    print $mini_prog;
    print "----+----1----+----2----+----3----+----4----+----5----+----6\n";

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
