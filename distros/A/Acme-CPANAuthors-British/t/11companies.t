#!perl
use strict;
use warnings;
use Test::More;

plan skip_all => "can't load Acme::CPANAuthors"
    unless eval "use Acme::CPANAuthors; 1";
plan tests => 9;

my $authors  = eval { Acme::CPANAuthors->new("British::Companies") };
is( $@, "", "creating a new Acme::CPANAuthors object with British Companies" );
isa_ok( $authors, "Acme::CPANAuthors" );

my $number = 12;
is( $authors->count, $number, " .. \$authors->count matches current count" );

my @ids = $authors->id;
cmp_ok( ~~@ids, ">", 0, " .. \$authors->id gives a non-empty list" );
is( ~~@ids, $number, " .. \$authors->id equals \$authors->count" );

SKIP: {
    my $file;
    eval { $file = Acme::CPANAuthors::Utils::_cpan_authors_file() };
    skip "CPAN configuration not available", 4 if($@ || !$file);

    $file = undef;
    eval { $file = Acme::CPANAuthors::Utils::_cpan_packages_file() };
    skip "CPAN configuration not available", 4 if($@ || !$file);

    my @distros  = $authors->distributions('FOTANGO');
    cmp_ok( ~~@distros, ">", 0, " .. \$authors->distributions('FOTANGO') gives a non-empty list" );

    @distros = $authors->distributions('XXXXXX');
    cmp_ok( ~~@distros, "==", 0, " .. \$authors->distributions('XXXXXX') gives an empty list" );

    my $name = $authors->name('GMGRD');
    cmp_ok( length($name), ">", 0, " .. \$authors->name('GMGRD') gives a non-empty string" );

#    SKIP: {
#        skip "en.gravatar.com is not available", 1
#            if(pingtest('en.gravatar.com'));
#
#        my $url;
#        eval { $url = $authors->avatar_url('GMGRD') };
#        skip "en.gravatar.com is not available", 1 if($@);
#        $url ||= '';
#        cmp_ok( length($url), ">", 0, " .. \$authors->avatar_url('GMGRD') gives a non-empty string" );
#    }

    SKIP: {
        skip "api.cpanauthors.org is not available", 1
            if(pingtest('api.cpanauthors.org'));

        my $kwalitee;
        eval { $kwalitee = $authors->kwalitee('BBC') };
        skip "api.cpanauthors.org is not available", 1 if($@);
        isa_ok( $kwalitee, "HASH", " .. \$authors->kwalitee('BBC')" );
    }
}

sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    eval { system($cmd) }; 
    if($@) {                # can't find ping, or wrong arguments?
        diag();
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}
