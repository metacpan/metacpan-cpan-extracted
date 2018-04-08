#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.01';

use App::diceware;
use Getopt::Long 'HelpMessage';

GetOptions(
    'language|l=s'    => \(my $language = 'en'),
    'length|size|s=i' => \(my $length   = 5),
    'pretty|p'        => \my $pretty,
    'help|h' => sub {HelpMessage(0)},
) or HelpMessage(1);

print_passphrase();

sub print_passphrase {
    my $diceware = App::diceware->new({language => $language});
    my $passphrase
        = $diceware->passphrase({length => $length, pretty => $pretty});
    print "$passphrase\n";
}

=head1 NAME

diceware.pl - Generate a Diceware passphrase

=head1 SYNOPSIS

  --language,-l   Wordlist language (de|en, default: en)
  --length|size,-s     Number of words in passphrase (default: 5)
  --pretty,-p     Separate words in passphrase with '-'
  --help,-h       Print this help

=head1 AUTHOR

Johann Rolschewski E<lt>jorol@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Johann Rolschewski

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
