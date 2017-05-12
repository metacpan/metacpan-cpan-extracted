use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More;

plan tests => 34 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/RandomPerson.pm',
    'Data/RandomPerson/Choice.pm',
    'Data/RandomPerson/Names.pm',
    'Data/RandomPerson/Names/AncientGreekFemale.pm',
    'Data/RandomPerson/Names/AncientGreekMale.pm',
    'Data/RandomPerson/Names/ArabicFemale.pm',
    'Data/RandomPerson/Names/ArabicLast.pm',
    'Data/RandomPerson/Names/ArabicMale.pm',
    'Data/RandomPerson/Names/BasqueFemale.pm',
    'Data/RandomPerson/Names/BasqueMale.pm',
    'Data/RandomPerson/Names/CelticFemale.pm',
    'Data/RandomPerson/Names/CelticMale.pm',
    'Data/RandomPerson/Names/EnglishFemale.pm',
    'Data/RandomPerson/Names/EnglishLast.pm',
    'Data/RandomPerson/Names/EnglishMale.pm',
    'Data/RandomPerson/Names/Female.pm',
    'Data/RandomPerson/Names/HindiFemale.pm',
    'Data/RandomPerson/Names/HindiMale.pm',
    'Data/RandomPerson/Names/JapaneseFemale.pm',
    'Data/RandomPerson/Names/JapaneseMale.pm',
    'Data/RandomPerson/Names/Last.pm',
    'Data/RandomPerson/Names/LatvianFemale.pm',
    'Data/RandomPerson/Names/LatvianMale.pm',
    'Data/RandomPerson/Names/Male.pm',
    'Data/RandomPerson/Names/ModernGreekFemale.pm',
    'Data/RandomPerson/Names/ModernGreekLast.pm',
    'Data/RandomPerson/Names/ModernGreekMale.pm',
    'Data/RandomPerson/Names/SpanishFemale.pm',
    'Data/RandomPerson/Names/SpanishLast.pm',
    'Data/RandomPerson/Names/SpanishMale.pm',
    'Data/RandomPerson/Names/ThaiFemale.pm',
    'Data/RandomPerson/Names/ThaiMale.pm',
    'Data/RandomPerson/Names/VikingFemale.pm',
    'Data/RandomPerson/Names/VikingMale.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


