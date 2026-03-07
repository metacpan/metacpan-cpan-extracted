package oses;
# ABSTRACT: A shortcut in the fashion of oose.pm
our $VERSION = '1.000';
use strict;
use warnings;


BEGIN {
    my $package;
    sub import { $package = $_[1] || 'Bot' }
    use Filter::Simple sub { s/^/package $package;\nuse Moses;\n/; }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

oses - A shortcut in the fashion of oose.pm

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    perl -Ilib -Moses=T -MNet::Twitter -e'event irc_public=>sub {
    Net::Twitter->new(username=>$ARGV[0],password=>$ARGV[1])->update($_[ARG2])
    };T->run'

=head1 DESCRIPTION

A source filter shortcut module in the fashion of C<oose.pm> that automatically
adds a package declaration and C<use Moses;> to your code.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/perigrin/adam-bot-framework/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
