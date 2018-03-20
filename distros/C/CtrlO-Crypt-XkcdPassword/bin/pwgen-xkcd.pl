#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# PODNAME: pwgen-xkcd.pl
# ABSTRACT: Generate a xkcd-style password

use CtrlO::Crypt::XkcdPassword;
use Getopt::Long;
use Pod::Usage qw(pod2usage);

binmode STDOUT, ":utf8";

my $words    = 4;
my $digits   = 0;
my $language = 'en-GB';
my $help     = 0;

GetOptions(
    "words=i"    => \$words,
    "digits=i"   => \$digits,
    "language=s" => \$language,
    "help|?"     => \$help
);
pod2usage(1) if ($help);
say CtrlO::Crypt::XkcdPassword->new( language => $language )
    ->xkcd( words => $words, digits => $digits );

__END__

=pod

=encoding UTF-8

=head1 NAME

pwgen-xkcd.pl - Generate a xkcd-style password

=head1 VERSION

version 1.004

=head1 USAGE

  pwgen-xkcd.pl [options]

  Options:
    --words      Number of words to generate, default 4
    --digits     Add some digits, default 0
    --language   Language of word list, default en-GB

=head1 SEE ALSO

See C<perldoc CtrlO::Crypt::XkcdPassword> for even more info.

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
