use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use FindBin qw($Bin);

my $curl_config= $ENV{CURL_CONFIG} || "curl-config";

if (!grep /AsynchDNS/, `$curl_config --features`) {
    die "Did not find a curl_config binary, or curl was configured without AsynchDNS support. Bailing!";
}

my @curl_wantflags= grep /./, split /\s+/, join " ", (
    `$curl_config --cflags`,
    `$curl_config --libs`,
);

my (@libs, @inc, @object, @define);
for my $flag (@curl_wantflags) {
    if (uc substr($flag, 0, 2) eq '-L') {
        push @libs, $flag;
    } elsif (substr($flag, 0, 2) eq '-I') {
        push @inc, $flag;
    } elsif (substr($flag, 0, 2) eq '-D') {
        push @define, $flag;
    } elsif (substr($flag, 0, 1) eq '/') {
        push @object, $flag;
    } else {
        # Let MakeMaker figure it out, maybe
        push @libs, $flag;
        warn "Unknown flag: $flag";
    }
}

sub find_curl_h {
    my @all_inc;
    for my $include (@inc) {
        $include =~ s/\A-I//;
        push @all_inc, $include;
    }
    for my $include (split /\s+/, $Config{incpth}) {
        push @all_inc, $include;
    }

    for my $path (@all_inc) {
        my $curl_h = "$path/curl/curl.h";
        if (-f $curl_h) {
            return $curl_h;
        }
    }

    die "Could not locate a curl.h include";
}

system($^X, "$Bin/sync-curlopt.pl", find_curl_h()) and die "sync-curlopt failed";

WriteMakefile(
    NAME              => 'AnyEvent::YACurl',
    VERSION_FROM      => 'lib/AnyEvent/YACurl.pm', # finds $VERSION
    PREREQ_PM         => {
        "AnyEvent" => "7.0",
    },
    ABSTRACT_FROM     => 'lib/AnyEvent/YACurl.pm', # retrieve abstract from module
    AUTHOR            => 'Tom van der Woerdt <tvdw@cpan.org>',
    LIBS              => ["@libs"], # e.g., '-lm'
    DEFINE            => "@define", # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. @inc", # e.g., '-I. -I/usr/include/other'
    OBJECT            => "\$(O_FILES) @object",
    LICENSE           => "perl_5",
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/TvdW/perl-AnyEvent-YACurl.git',
                 web  => 'https://github.com/TvdW/perl-AnyEvent-YACurl',
             },
         },
    },
);
