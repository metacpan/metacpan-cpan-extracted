package Acme::CPANAuthors::Acme::CPANAuthors::Authors;
use strict;
use warnings;

=head1 NAME

Acme::CPANAuthors::Acme::CPANAuthors::Authors - We are CPAN authors who have authored Acme::CPANAuthors modules

=cut

use version; our $VERSION = version->declare('v1.0.0');
use Acme::CPANAuthors::Register (
    ABIGAIL  => q[Abigail],          # A::C::Dutch ...or not.
    ACALPINI => q[Aldo Calpini],     # A::C::Italian
    ASHLEY   => q[Ashley Pond V],    # A::C::Misanthrope
    AZAWAWI =>
        q[أحمد محمد زواوي - Ahmad M. Zawawi],    # A::C::Arabic
    BARBIE    => q[Barbie],                               # A::C::British
    BINGOS    => q[Chris Williams],                       # A::C::POE
    BRACETA   => q[Luís Azevedo],                        # A::C::Portuguese
    BURAK     => q[Burak Gürsoy],                        # A::C::Turkish
    ETHER     => q[Karen Etheridge],                      # A::C::Nonhuman
    FAYLAND   => q[Fayland 林],                          # A::C::Chinese
    FLORA     => q[Florian Ragwitz],                      # A::C::German
    GARU      => q[Breno G. de Oliveira],                 # A::C::Brazilian
    GRAY      => q[gray],                                 # A::C::GitHub
    GUGOD     => q[劉康民],                            # A::C::Taiwanese
    HINRIK    => q[Hinrik Örn Sigurðsson],              # A::C::Icelandic
    ISHIGAKI  => q[Kenichi Ishigaki],                     # The Original
    JEEN      => q[Jeen Lee],                             # A::C::Korean
    JLMARTIN  => q[Jose Luis Martinez Torres],            # A::C::Catalonian
    KAARE     => q[Kaare Rasmussen],                      # A::C::Danish
    KENTARO   => q[Kentaro Kuribayashi],                  # A::C::GeekHouse
    MARCEL    => q[Marcel Grünauer == hanekomu],         # A::C::Austrian
    MONS      => q[Mons Anderson],                        # A::C::AnyEvent
    RBO       => q[Robert Bohne],                         # A::C::German
    SALVA     => q[Salvador Fandiño García],            # A::C::Spanish
    SANKO     => q[Sanko Robinson],                       # Hey, that's me!
    SAPER     => q[Sébastien Aperghis-Tramoni],          # A::C::French
    SFINK     => q[Steve A Fink],                         # A::C::Not
    SHANTANU  => q[Shantanu Bhadoria],                    # A::C::India
    SHARIFULN => q[Анатолий Шарифулин],  # A::C::Russian
    SHARYANTO => q[Steven Haryanto],                      # A::C::Indonesian
    SHLOMIF   => q[Shlomi Fish],                          # A::C::Israeli
    SKIM      => q[Michal Špaček],                      # A::C::Czech
    SROMANOV  => q[Сергей Романов],          # A::C::Belarusian
    VPIT      => q[Vincent Pit],                          # A::C::You're_using
    WOLDRICH  => q[Magnus Woldrich],                      # A::C::Swedish
    ZOFFIX    => q[Zoffix Znet]                           # A::C::Canadian
);

sub _regen {
    require HTTP::Tiny;
    my $data    = '';
    my $authsec = 0;
    my %authors;
    die "Failed\n"
        unless HTTP::Tiny->new->request(
        'GET',
        'http://www.cpan.org/modules/02packages.details.txt',
        {data_callback => sub {    # Don't scrape the whole file
             my $chunk = shift;
             if ($chunk =~ m[^Acme::CPANAuthors]sm) {
                 $authsec++;
                 $data .= $chunk;
             }
             elsif ($authsec) {    # No more Authors in 02packages
                 while ($data
                     =~ m[^(?:Acme::CPANAuthors(?:::(\S+))?).+\w/\w\w/(\w+)/.+$]mg
                     )
                 {   $authors{$2} //= [];
                     push @{$authors{$2}}, $1;
                 }
                 my %old = authors();    # Current authors
                 my @new = grep { defined $old{$_} ? () : $_ } keys %authors;
                 print scalar(@new)
                     . " new Acme::CPANAuthors authors to add\n";
                 return if !@new;
                 require MetaCPAN::API;
                 my $mcpan = MetaCPAN::API->new();
                 binmode(STDOUT, ':utf8');

                 for my $id (sort @new) {
                     my $author = $mcpan->author($id);
                     printf "    %s => q[%s], # %s\n", $id, $author->{name},
                         join ', ', map { 'A::C::' . $_ } @{$authors{$id}};
                 }
                 exit    # We're done
             }
             }
        }
        )->{success};
}
1;

=head1 Synopsis

    use Acme::CPANAuthors;

    my $authors = Acme::CPANAuthors->new('Acme::CPANAuthors::Acme::CPANAuthors::Authors');

    $number   = $authors->count;
    @ids      = $authors->id;
    @distros  = $authors->distributions('ACALPINI');
    $url      = $authors->avatar_url('SHLOMIF');
    $kwalitee = $authors->kwalitee('SANKO');

=head1 Description

This class provides a hash of Pause IDs/names of Acme::CPANAuthors::*
authorin' CPAN authors.

I started this module because
L<Acme::CPANAuthors::UnitedStates|Acme::CPANAuthors::UnitedStates> doesn't
exist and apparently I'm not listed in
L<Acme::CPANAuthors::Japanese|Acme::CPANAuthors::Japanese>. ((sigh)) I just
want to be a part of something... great... greater... than-- um, sorry, lost
my train of thought.

Anyway, I decided both L<Acme::CPANAuthors::Earth|Acme::CPANAuthors::Earth>
(well covered between http://search.cpan.org/author/ and
http://pause.perl.org/pause/query?ACTION=who_is) and
L<Acme::CPANAuthors::Authors|Acme::CPANAuthors::Authors> (only include authors
who have published at least one distribution, script, etc.) would just be too
time consuming for a 3AM lapse in judgement so... there you are.

=head1 Installation

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=head1 Maintenance

Have you authored a module in the C<Acme::CPANAuthors> namespace, aren't
listed here, and would like to be? Or are you currently listed but have since
turned away from your deviant, C<Acme> ways and would like to be removed? Just
contact me L<via email|/"AUTHOR"> or stop by the Issue Tracker and I'll fix ya
right up.

=head1 Bugs

Report any bugs or feature requests to the Issue tracker or
directly to L<me via email|/"AUTHOR">. I'll keep you up to date on any related
changes.

Seriously, it's just a list of names... what could possibly go wrong?

E<lt>_E<lt>

E<gt>_E<gt>

Yeah.

=head1 Support

You can find documentation for this module with the perldoc command.

    perldoc Acme::CPANAuthors::Acme::CPANAuthors::Authors

You can also look for information at:

=over 4

=item * Issue Tracker: Acme::CPANAuthors::Acme::CPANAuthors::Authors' bug tracker

http://github.com/sanko/acme-cpanauthors-acme-cpanauthors-authors/issues/

=item * AnnoCPAN: Annotated CPAN documentation

http://annocpan.org/dist/Acme-CPANAuthors-Acme-CPANAuthors-Authors

=item * CPAN Ratings

http://cpanratings.perl.org/d/Acme-CPANAuthors-Acme-CPANAuthors-Authors

=item * Search CPAN

http://search.cpan.org/dist/Acme-CPANAuthors-Acme-CPANAuthors-Authors

=item * Version Control Repository:

http://github.com/sanko/acme-cpanauthors-acme-cpanauthors-authors/

=back

=head1 See Also

L<Acme::CPANAuthors|Acme::CPANAuthors>,
L<Acme::CPANAuthors::Japanese|Acme::CPANAuthors::Japanese>,
L<Acme::CPANAuthors::Misanthrope|Acme::CPANAuthors::Misanthrope>,
L<Acme::CPANAuthors::Not|Acme::CPANAuthors::Not>, et al.

See the examples found in F</scripts/> for usage.

=head1 Acknowledgements

Kenichi Ishigaki for L<Acme::CPANAuthors|Acme::CPANAuthors>

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2013 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.  See the F<LICENSE>
file included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://ww.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
