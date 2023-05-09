package Acme::Onion;
use strict;
use warnings;

our $VERSION = "0.03";

BEGIN {
    push @INC, sub {
        my ($coderef, $file) = @_;

        (my $onion = $file) =~ s/\.pm$/.🧅/;

        for my $dir (@INC) {
            my $filepath = $dir . '/' . $onion;

            next if ! -e $filepath || -d _ || -b _;

            if (open my $fh, '<', $filepath) {
                $INC{$file} = $filepath;
                return $fh;
            }
        }
        return;
    }
};

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Onion - .🧅 file extension in Perl.

=head1 SYNOPSIS

    ❯ tree examples/lib
    examples/lib
    └── Hello.🧅

    ❯ cat examples/lib/Hello.🧅
    package Hello;
    sub onion { 'Hello 🧅' }
    1;

    ❯ perl -Iexamples/lib -MAcme::Onion -MHello -E 'say Hello->onion';
    Hello 🧅

=head1 DESCRIPTION

Acme::Onion is a Perl module designed to enable the use of .🧅 file extension alongside traditional .pm files. It provides a simple, yet unique way to organize and manage your Perl code.

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

