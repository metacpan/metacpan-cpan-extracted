#!perl
use strict;
use warnings;
use Test::More;

plan skip_all => "can't load Acme::CPANAuthors"
    unless eval "use Acme::CPANAuthors; 1";
plan tests => 10;

my $authors  = eval { Acme::CPANAuthors->new("British") };
is( $@, "", "creating a new Acme::CPANAuthors object with British authors" );
isa_ok( $authors, "Acme::CPANAuthors" );

my $number = 299;
is( $authors->count, $number, " .. \$authors->count matches current count" );

my @ids = $authors->id;
cmp_ok( ~~@ids, ">", 0, " .. \$authors->id gives a non-empty list" );
is( ~~@ids, $number, " .. \$authors->id equals \$authors->count" );

SKIP: {
    my $file;
    eval { $file = Acme::CPANAuthors::Utils::_cpan_authors_file() };
    skip "CPAN configuration not available", 5 if($@ || !$file);

    $file = undef;
    eval { $file = Acme::CPANAuthors::Utils::_cpan_packages_file() };
    skip "CPAN configuration not available", 5 if($@ || !$file);

    my @distros  = $authors->distributions('BARBIE');
    cmp_ok( ~~@distros, ">", 0, " .. \$authors->distributions('BARBIE') gives a non-empty list" );

    @distros = $authors->distributions('XXXXXX');
    cmp_ok( ~~@distros, "==", 0, " .. \$authors->distributions('XXXXXX') gives an empty list" );

    my $name = $authors->name('DGL');
    cmp_ok( length($name), ">", 0, " .. \$authors->name('DGL') gives a non-empty string" );
    $name = $authors->name('BARBIE');
    is($name, "Barbie", " .. \$authors->name('BARBIE') returns Barbie" );

#    SKIP: {
#        skip "en.gravatar.com is not available", 2
#            if(pingtest('en.gravatar.com'));
#
#        my $url;
#        eval { $url = $authors->avatar_url('BARBIE') };
#        skip "en.gravatar.com is not available", 1 if($@);
#        $url ||= '';
#        is($url, 'http://www.gravatar.com/avatar/2459f554c069e44527716e3f35e1d0d1', ".. \$authors->avatar_url('BARBIE') returns a URL" );
#
#        eval { $url = $authors->avatar_url('BINGOS') };
#        skip "en.gravatar.com is not available", 1 if($@);
#        $url ||= '';
#        cmp_ok( length($url), ">", 0, " .. \$authors->avatar_url('BINGOS') gives a non-empty string" );
#    }

    SKIP: {
        skip "api.cpanauthors.org is not available", 1
            if(pingtest('api.cpanauthors.org'));

        my $kwalitee;
        eval { $kwalitee = $authors->kwalitee('JONALLEN') };
        skip "api.cpanauthors.org is not available", 1 if($@);
        isa_ok( $kwalitee, "HASH", " .. \$authors->kwalitee('JONALLEN')" );
    }
}

sub pingtest {
    my $domain = shift or return 1;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    eval { system($cmd) };
    if($@) {                # can't find ping, or wrong arguments?
        diag($@);
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}
