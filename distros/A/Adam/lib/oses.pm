package oses;
BEGIN {
  $oses::VERSION = '0.91';
}
# ABSTRACT: A shortcut in the fashion of oose.pm
# Dist::Zilla: +PodWeaver
use strict;
use warnings;

BEGIN {
    my $package;
    sub import { $package = $_[1] || 'Bot' }
    use Filter::Simple sub { s/^/package $package;\nuse Moses;\n/; }
}

1;


=pod

=head1 NAME

oses - A shortcut in the fashion of oose.pm

=head1 VERSION

version 0.91

=head1 SYNOPSIS

perl -Ilib -Moses=T -MNet::Twitter -e'event irc_public=>sub {
Net::Twitter->new(username=>$ARGV[0],password=>$ARGV[1])->update($_[ARG2])
};T->run'

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

