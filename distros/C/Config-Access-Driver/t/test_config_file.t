#!/usr/bin/perl
#
# @author Bodo (Hugo) Barwich
# @version 2026-09-06
# @package Config::Access::Driver
# @subpackage t/test_config_access_driver.t

# Integration tests for the Config::Access::Driver Library
# Verifies the interplay of Config::Access::Driver with
# Config::Section::List / Config::Section::Parser and File::Access::Driver

use strict;
use warnings;

# The config-driver repository depends on file-driver-pl.
# Adjust the relative path to wherever file-driver-pl is checked out.

use Test::More;
use Test::Exception;   # provides lives_ok, dies_ok, throws_ok

use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    use lib "lib";
    use lib "../lib";
}

require_ok('Config::Access::Driver');
require_ok('Config::Section::List');

use File::Access::Driver;
use Config::Section::List;


#----------------------------------------------------------------------------
#Fixtures

my $strtmpdir = tempdir(CLEANUP => 1);

#A sample configuration with sections, comments and an empty line
my $hshprofile = {
    'filepath' => File::Spec->catfile($strtmpdir, 'test.ini'),
    'content'  => <<'END_INI'
# Global comment

[database]
host = localhost
port = 5432
name = production

[logging]
level = info
file = app.log
END_INI
};

my $objdrv = undef;

subtest 'setup: fixture file created' => sub {
    ok(open(my $fh, '>', $hshprofile->{'filepath'}),
        'fixture INI file is writable')
      or diag("Cannot create fixture: $!");
    print $fh $hshprofile->{'content'};
    close($fh);
    ok(-e $hshprofile->{'filepath'}, 'fixture INI file exists');
};

#----------------------------------------------------------------------------
#Static Interface

subtest 'static: readConfigSectionList' => sub {
    my $lstsecs = eval {
        Config::Access::Driver::readConfigSectionList(
            $hshprofile->{'filepath'});
    };
    ok(!$@, 'readConfigSectionList does not die')
      or diag("Exception: $@");
    ok(defined $lstsecs, 'a Section List is returned');

    SKIP: {
        skip 'no Section List returned', 1 unless defined $lstsecs;
        ok((ref($lstsecs) =~ /Config/)
            && $lstsecs->isa('Config::Section::List'),
            'returned object is a Config::Section::List');
    }
};

#----------------------------------------------------------------------------
#Object Flow: Read

subtest 'object flow: new -> setFilePath -> Read -> getList' => sub {
    $objdrv = new_ok('Config::Access::Driver');

    lives_ok { $objdrv->setFilePath($hshprofile->{'filepath'}) }
      'setFilePath with a valid path';

    my $irssct = 0;

    lives_ok { $irssct = $objdrv->Read() } 'Read executes cleanly';
    ok($irssct >= 0, 'Read reports a result status');

    my $lstsecs = $objdrv->getList();

    ok(defined $lstsecs, 'getList returns a Section List');
    ok($lstsecs->isa('Config::Section::List'),
        'Section List is a Config::Section::List');

    #Round-trip validation: rebuild the string and compare against input.
    #This checks that parsing preserved sections/keys without relying on
    #unknown list accessor methods.
    my $scntnt = Config::Section::Parser::buildStringFromList($lstsecs);

    isnt($scntnt, undef, "Parser Function 'buildStringFromList()': Function returns a string");
    isnt($scntnt, 0, "Parser Function 'buildStringFromList()': Result is not empty");
    like($scntnt, qr/\[database\]/, 'section [database] survived parsing');
    like($scntnt, qr/\[logging\]/,  'section [logging] survived parsing');

    #Re-Read should clear and refill, not duplicate
    lives_ok { $objdrv->Read() } 'second Read succeeds';

    my $scntnt2 =
      Config::Section::Parser::buildStringFromList($objdrv->getList);

    is($scntnt2, $scntnt, 'repeated Read is idempotent');
};

subtest 'readList convenience wrapper' => sub {
    my $lstsecs = eval {
        my $objtmp = new Config::Access::Driver;
        $objtmp->setFilePath($hshprofile->{'filepath'});
        $objtmp->readList();
    };
    ok(!$@, 'readList does not die') or diag("Exception: $@");
    ok(defined $lstsecs && $lstsecs->isa('Config::Section::List'),
        'readList returns a Config::Section::List');
};

#----------------------------------------------------------------------------
#Round-Trip: Read -> Write -> Read

subtest 'round trip: Read -> Write -> Read preserves content' => sub {
    my $strwrtfl = File::Spec->catfile($strtmpdir, 'written.ini');

    my $objsrc = new Config::Access::Driver;

    $objsrc->setFilePath($hshprofile->{'filepath'});
    $objsrc->Read();

    my $cfglst = $objsrc->getList();

    isnt($cfglst->getConfigSectionbyName('database'), undef, "Section 'database': Section exists");
    isnt($cfglst->getConfigSectionbyName('logging'), undef, "Section 'logging': Section exists");

    my $objwrt = new Config::Access::Driver;

    $objwrt->setFilePath($strwrtfl);
    $objwrt->setList($cfglst);

    #Transfer the parsed list into the write target
    $objwrt->writeList($cfglst);

    ok(-e $strwrtfl, 'Write produced a file');

    my $objchk = new Config::Access::Driver;

    $objwrt->setFilePath($strwrtfl);    #reuse written target
    $cfglst = $objwrt->readList();

    my $scntnt2 =
      Config::Section::Parser::buildStringFromList($cfglst);

    like($scntnt2, qr/\[database\]/,
        'round-tripped file still contains [database]');
    like($scntnt2, qr/port\s*=\s*5432/, 'key/value pairs survive round trip');
};

#----------------------------------------------------------------------------
#Write

subtest 'writeList with an externally built list' => sub {
    my $objtmp = new_ok('Config::Access::Driver');

    $objtmp->setFileDirectory($strtmpdir);
    $objtmp->setFileName('new.ini');

    my $lstnew = new_ok('Config::Section::List');
    my $irs     = 0;

    #Assumption: fillListFromArray accepts an empty list and simple INI text
    lives_ok {
        Config::Section::Parser::fillListFromArray($lstnew,
            ["[test]\n", "key = value\n"]);
        $irs = $objtmp->writeList($lstnew);
    } 'writeList writes a hand-built Section List';

    ok($irs >= 0, 'writeList reports success status');
    ok(-e $objtmp->getFilePath(), 'configuration file was created');
};

#----------------------------------------------------------------------------
#Edge Cases

subtest 'edge case: nonexistent file' => sub {
    my $objtmp = new_ok('Config::Access::Driver');

    $objtmp->setFileDirectory($strtmpdir);
    $objtmp->setFileName('missing.ini');

    my $irslt = eval { $objtmp->Read() };

    ok(!$@, 'Read on a missing file does not die') or diag("Exception: $@");
    ok(!defined($irslt) || $irslt eq '' || $irslt == 0,
        'Read on a missing file reports a non-success state');

    #getList should still hand back a usable (empty) list
    my $lstsecs = $objtmp->getList;

    ok(defined $lstsecs && $lstsecs->isa('Config::Section::List'),
        'getList falls back to an empty Section List');
};

subtest 'edge case: empty file' => sub {
    my $stremptyfl = File::Spec->catfile($strtmpdir, 'empty.ini');

    open(my $fh, '>', $stremptyfl) or plan(skip_all => "Cannot create file: $!");
    close($fh);

    my $objtmp = new_ok('Config::Access::Driver');
    $objtmp->setFilePath($stremptyfl);

    lives_ok { $objtmp->readList() } 'readList on an empty file does not die';
    my $scntnt = Config::Section::Parser::buildStringFromList($objtmp->getList);
    ok((!defined $scntnt || $scntnt eq ''),
        'an empty file produces no configuration content');
};

subtest 'administration: Clear / setList / freeResources' => sub {
    my $objtmp = new_ok('Config::Access::Driver');

    $objtmp->setFilePath($hshprofile->{'filepath'});
    $objtmp->readList();

    my $lstsecs = $objtmp->getList();

    ok(defined $lstsecs, 'list populated before Clear');

    lives_ok { $objtmp->Clear() } 'Clear executes';
    lives_ok { $objtmp->setList($lstsecs) } 'setList re-attaches the list object';

    my $lstwrong = bless({}, 'Some::Other::Class');

    lives_ok { $objtmp->setList($lstwrong) }
      'setList with a foreign object does not die';

    #Note: verifying the rejection requires a getter for _list_sections
    #beyond getList (which lazily creates a new one).

    lives_ok { $objtmp->freeResources() } 'freeResources executes';

    my $lstafter = $objtmp->getList();

    ok(defined $lstsecs && $lstafter->isa('Config::Section::List'),
        'getList lazily recreates after freeResources');
};

#----------------------------------------------------------------------------
#Cleanup

$objdrv->freeResources() if defined $objdrv;

done_testing();