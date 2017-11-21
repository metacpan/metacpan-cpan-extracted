use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.057

use Test::More;

plan tests => 129 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Acme/MetaSyntactic/Themes.pm',
    'Acme/MetaSyntactic/abba.pm',
    'Acme/MetaSyntactic/afke.pm',
    'Acme/MetaSyntactic/alice.pm',
    'Acme/MetaSyntactic/alphabet.pm',
    'Acme/MetaSyntactic/amber.pm',
    'Acme/MetaSyntactic/antlers.pm',
    'Acme/MetaSyntactic/asterix.pm',
    'Acme/MetaSyntactic/barbapapa.pm',
    'Acme/MetaSyntactic/barbarella.pm',
    'Acme/MetaSyntactic/batman.pm',
    'Acme/MetaSyntactic/ben_and_jerry.pm',
    'Acme/MetaSyntactic/bible.pm',
    'Acme/MetaSyntactic/booze.pm',
    'Acme/MetaSyntactic/bottles.pm',
    'Acme/MetaSyntactic/browser.pm',
    'Acme/MetaSyntactic/buffy.pm',
    'Acme/MetaSyntactic/calvin.pm',
    'Acme/MetaSyntactic/camelidae.pm',
    'Acme/MetaSyntactic/care_bears.pm',
    'Acme/MetaSyntactic/chess.pm',
    'Acme/MetaSyntactic/colors.pm',
    'Acme/MetaSyntactic/colours.pm',
    'Acme/MetaSyntactic/constellations.pm',
    'Acme/MetaSyntactic/contrade.pm',
    'Acme/MetaSyntactic/counting_rhyme.pm',
    'Acme/MetaSyntactic/counting_to_one.pm',
    'Acme/MetaSyntactic/crypto.pm',
    'Acme/MetaSyntactic/currency.pm',
    'Acme/MetaSyntactic/dancers.pm',
    'Acme/MetaSyntactic/debian.pm',
    'Acme/MetaSyntactic/dilbert.pm',
    'Acme/MetaSyntactic/discworld.pm',
    'Acme/MetaSyntactic/doctor_who.pm',
    'Acme/MetaSyntactic/donmartin.pm',
    'Acme/MetaSyntactic/dwarves.pm',
    'Acme/MetaSyntactic/elements.pm',
    'Acme/MetaSyntactic/evangelion.pm',
    'Acme/MetaSyntactic/fabeltjeskrant.pm',
    'Acme/MetaSyntactic/facecards.pm',
    'Acme/MetaSyntactic/fawlty_towers.pm',
    'Acme/MetaSyntactic/flintstones.pm',
    'Acme/MetaSyntactic/french_presidents.pm',
    'Acme/MetaSyntactic/garbage.pm',
    'Acme/MetaSyntactic/garfield.pm',
    'Acme/MetaSyntactic/gems.pm',
    'Acme/MetaSyntactic/good_omens.pm',
    'Acme/MetaSyntactic/groo.pm',
    'Acme/MetaSyntactic/haddock.pm',
    'Acme/MetaSyntactic/hhgg.pm',
    'Acme/MetaSyntactic/iata.pm',
    'Acme/MetaSyntactic/icao.pm',
    'Acme/MetaSyntactic/invasions.pm',
    'Acme/MetaSyntactic/jabberwocky.pm',
    'Acme/MetaSyntactic/jamesbond.pm',
    'Acme/MetaSyntactic/jerkcity.pm',
    'Acme/MetaSyntactic/linux.pm',
    'Acme/MetaSyntactic/loremipsum.pm',
    'Acme/MetaSyntactic/lotr.pm',
    'Acme/MetaSyntactic/lucky_luke.pm',
    'Acme/MetaSyntactic/magic8ball.pm',
    'Acme/MetaSyntactic/magicroundabout.pm',
    'Acme/MetaSyntactic/magma.pm',
    'Acme/MetaSyntactic/mars.pm',
    'Acme/MetaSyntactic/metro.pm',
    'Acme/MetaSyntactic/monty_spam.pm',
    'Acme/MetaSyntactic/muses.pm',
    'Acme/MetaSyntactic/nis.pm',
    'Acme/MetaSyntactic/nobel_prize.pm',
    'Acme/MetaSyntactic/norse_mythology.pm',
    'Acme/MetaSyntactic/octothorpe.pm',
    'Acme/MetaSyntactic/olympics.pm',
    'Acme/MetaSyntactic/opcodes.pm',
    'Acme/MetaSyntactic/oulipo.pm',
    'Acme/MetaSyntactic/pantagruel.pm',
    'Acme/MetaSyntactic/pasta.pm',
    'Acme/MetaSyntactic/pause_id.pm',
    'Acme/MetaSyntactic/peanuts.pm',
    'Acme/MetaSyntactic/pgpfone.pm',
    'Acme/MetaSyntactic/phonetic.pm',
    'Acme/MetaSyntactic/pie.pm',
    'Acme/MetaSyntactic/planets.pm',
    'Acme/MetaSyntactic/pm_groups.pm',
    'Acme/MetaSyntactic/pokemon.pm',
    'Acme/MetaSyntactic/pooh.pm',
    'Acme/MetaSyntactic/pop2.pm',
    'Acme/MetaSyntactic/pop3.pm',
    'Acme/MetaSyntactic/pornstars.pm',
    'Acme/MetaSyntactic/pumpkings.pm',
    'Acme/MetaSyntactic/punctuation.pm',
    'Acme/MetaSyntactic/pynchon.pm',
    'Acme/MetaSyntactic/python.pm',
    'Acme/MetaSyntactic/quantum.pm',
    'Acme/MetaSyntactic/regions.pm',
    'Acme/MetaSyntactic/reindeer.pm',
    'Acme/MetaSyntactic/renault.pm',
    'Acme/MetaSyntactic/robin.pm',
    'Acme/MetaSyntactic/roman.pm',
    'Acme/MetaSyntactic/scooby_doo.pm',
    'Acme/MetaSyntactic/screw_drives.pm',
    'Acme/MetaSyntactic/services.pm',
    'Acme/MetaSyntactic/shadok.pm',
    'Acme/MetaSyntactic/simpsons.pm',
    'Acme/MetaSyntactic/sins.pm',
    'Acme/MetaSyntactic/smtp.pm',
    'Acme/MetaSyntactic/smurfs.pm',
    'Acme/MetaSyntactic/space_missions.pm',
    'Acme/MetaSyntactic/sql.pm',
    'Acme/MetaSyntactic/stars.pm',
    'Acme/MetaSyntactic/state_flowers.pm',
    'Acme/MetaSyntactic/summerwine.pm',
    'Acme/MetaSyntactic/swords.pm',
    'Acme/MetaSyntactic/tarot.pm',
    'Acme/MetaSyntactic/teletubbies.pm',
    'Acme/MetaSyntactic/thunderbirds.pm',
    'Acme/MetaSyntactic/tld.pm',
    'Acme/MetaSyntactic/tmnt.pm',
    'Acme/MetaSyntactic/tokipona.pm',
    'Acme/MetaSyntactic/tour_de_france.pm',
    'Acme/MetaSyntactic/trigan.pm',
    'Acme/MetaSyntactic/unicode.pm',
    'Acme/MetaSyntactic/us_presidents.pm',
    'Acme/MetaSyntactic/userfriendly.pm',
    'Acme/MetaSyntactic/vcs.pm',
    'Acme/MetaSyntactic/viclones.pm',
    'Acme/MetaSyntactic/wales_towns.pm',
    'Acme/MetaSyntactic/weekdays.pm',
    'Acme/MetaSyntactic/yapc.pm',
    'Acme/MetaSyntactic/zodiac.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


