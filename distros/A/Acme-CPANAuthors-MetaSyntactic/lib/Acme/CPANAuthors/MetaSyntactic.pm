package Acme::CPANAuthors::MetaSyntactic;
$Acme::CPANAuthors::MetaSyntactic::VERSION = '1.002';
use 5.006;
use strict;
use warnings;

use Acme::CPANAuthors::Register (
    ABIGAIL   => "Abigail",
    BINGOS    => "Chris Williams",
    BOOK      => "Philippe Bruhat (BooK)",
    ELBEHO    => "Laurent Boivin",
    ELLIOTJS  => "Elliot Shank",
    JFORGET   => "Jean Forget",
    JQUELIN   => "Jerome Quelin",
    MARKF     => "Mark Fowler",
    MCARTMELL => "Mike Cartmell",
    PERLANCAR => "perlancar",
    SAPER     => "Sebastien Aperghis-Tramoni",
    SHLOMIF   => "Shlomi Fish",
);

# from the unicode theme:
'DROMEDARY_CAMEL';

__END__

=head1 NAME

Acme::CPANAuthors::MetaSyntactic - MetaSyntactic CPAN authors

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors  = Acme::CPANAuthors->new("MetaSyntactic");

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions("BOOK");
    my $url      = $authors->avatar_url("BOOK");
    my $kwalitee = $authors->kwalitee("BOOK");
    my $name     = $authors->name("BOOK");

See documentation for L<Acme::CPANAuthors> for more details.

=head1 DESCRIPTION

This class provides a hash of CPAN authors' PAUSE ID and name to
the L<Acme::CPANAuthors> module. All the authors listed have published
a distribution containing themes for L<Acme::MetaSyntactic>.

=head1 AUTHOR

Philippe Bruhat (BooK), <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2014-2016 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
