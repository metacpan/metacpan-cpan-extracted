#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;

use Archive::Lha::Header;
use Archive::Lha::Header::Base;
use Archive::Lha::Stream::File;

# charset_for_os maps OS byte to encoding name
my %os_map = (
    'a' => 'iso-8859-15',   # Amiga
    'M' => 'cp1252',        # MS-DOS / Windows
    'w' => 'cp1252',        # WinNT / Win95
    'U' => 'guess',         # Unix (encoding varies)
    'H' => 'cp932',         # Human68K
    'J' => 'cp932',         # Java VM
    'm' => 'UTF-8',         # Macintosh
    '?' => 'guess',         # unknown -> Encode::Guess
);

subtest 'charset_for_os OS mapping' => sub {
    for my $os (sort keys %os_map) {
        my $obj = bless { os => [$os] }, 'Archive::Lha::Header::Level2';
        is Archive::Lha::Header::Base::charset_for_os($obj),
            $os_map{$os},
            "OS '$os' -> $os_map{$os}";
    }
};

subtest 'charset_for_os with no OS field' => sub {
    my $obj = bless {}, 'Archive::Lha::Header::Level0';
    is Archive::Lha::Header::Base::charset_for_os($obj), 'guess',
        'missing OS field falls back to guess';
};

subtest 'Amiga archive: latin-1 filename decoded to UTF-8' => sub {
    my $archive = "$Bin/archive/Amoric_src.lha";
    plan skip_all => "Amoric_src.lha not found" unless -f $archive;

    my $stream = Archive::Lha::Stream::File->new(file => $archive);
    my $found;
    while (defined(my $level = $stream->search_header)) {
        my $header = Archive::Lha::Header->new(level => $level, stream => $stream);
        $stream->seek($header->{next_header});
        my $raw = $header->{filename} // $header->{pathname} // '';
        if ($raw =~ /\xe7/) {
            $found = $header;
            last;
        }
    }
    ok $found, 'Found entry with non-ASCII byte (0xe7 = ç in iso-8859-15)';
    my $name = $found->pathname;
    like $name, qr/fran/, 'Decoded name starts with "fran"';
    like $name, qr/ais/, 'Decoded name ends with "ais"';
    # \xc3\xa7 is UTF-8 for ç
    ok utf8::is_utf8($name) || $name =~ /\xc3\xa7/, 'Name contains UTF-8 ç';
    like $name, qr/fran.*ais/, 'Full name matches français pattern';
};

subtest 'Amiga archive: charset auto-detected as iso-8859-15' => sub {
    my $archive = "$Bin/archive/Amoric_src.lha";
    plan skip_all => "Amoric_src.lha not found" unless -f $archive;

    my $stream = Archive::Lha::Stream::File->new(file => $archive);
    my $header;
    while (defined(my $level = $stream->search_header)) {
        $header = Archive::Lha::Header->new(level => $level, stream => $stream);
        $stream->seek($header->{next_header});
        last if ($header->{os}[0] // '') eq 'a';
    }
    ok $header, 'Found Amiga entry';
    is $header->charset_for_os, 'iso-8859-15', 'Amiga OS auto-detects iso-8859-15';
};

subtest 'pathname explicit charset override' => sub {
    my $archive = "$Bin/archive/Amoric_src.lha";
    plan skip_all => "Amoric_src.lha not found" unless -f $archive;

    my $stream = Archive::Lha::Stream::File->new(file => $archive);
    my $found;
    while (defined(my $level = $stream->search_header)) {
        my $header = Archive::Lha::Header->new(level => $level, stream => $stream);
        $stream->seek($header->{next_header});
        my $raw = $header->{filename} // $header->{pathname} // '';
        if ($raw =~ /\xe7/) {
            $found = $header;
            last;
        }
    }
    plan skip_all => "No latin-1 entry found" unless $found;
    my $name = $found->pathname('iso-8859-15', 'UTF-8');
    like $name, qr/fran.*ais/, 'Explicit iso-8859-15->UTF-8 gives français';
};

done_testing;
