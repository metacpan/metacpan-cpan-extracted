# -*- mode: perl; c-basic-offset: 4; indent-tabs-mode: nil; -*-

use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

# I should maybe use something like Shipwright...
regen_README('lib/Dancer/SearchApp.pm');
#regen_EXAMPLES();

my @tests = map { glob $_ } 't/*.t', 't/*/*.t';

WriteMakefile1(
    #MIN_PERL_VERSION => '5.018', # because I use signatures
    NAME                => 'Dancer::SearchApp',
    AUTHOR              => q{Max Maischein <corion@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/SearchApp.pm',
    ABSTRACT_FROM       => 'lib/Dancer/SearchApp.pm',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/Corion/dancer-searchapp',
        },
    },

    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),

    PL_FILES            => {},
    PREREQ_PM => {
        'Exporter' => 5, # for use Exporter 'import'
        'Filter::signatures' => 0,

        'Moo' => 0, # we want some glorified hashes

        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3132,
        'JSON'       => 0, # we use the "JSON" serializer
        'HTML::Entities' => 0,
        'HTML::Restrict' => 0,
        'Template'   => 0,
        'Search::Elasticsearch' => 2.03,
        'Search::Elasticsearch::Role::Cxn::HTTP' => '2.03',
        'Search::Elasticsearch::Async' => '2.03',
        'Search::Elasticsearch::Client::2_0' => '5.00',
        'Search::Elasticsearch::Client::2_0::Async' => '2.03',
        'Apache::Tika::Async' => 0,

        'Promises'   => 0,
        'Path::Class' => 0,
        'URI::file' => 0,
        'URI::Escape' => 0,

        # For configuration management
        'Data::Diver' => 0,

        # For rendering our development Pod
        'Plack::Middleware::Pod' => 0,

        # For the IMAP/mail support, until we spin that off
        'Mail::IMAPClient' => 0,
        'MIME::WordDecoder' => 0,
        'MIME::Base64' => 0,
        'MIME::QuotedPrint' => 0,
        'Scalar::Util' => 0,
        'Encode' => 0,
        'Text::Markdown' => 0,
        'HTTP::Date' => 0,
        'Time::Piece' => 0,
        
        # For media files
        'MP3::Tag' => 0,
        'Image::ExifTool' => 0,
        
        # For ICAL files
        'Cal::DAV' => 0,
        },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-SearchApp-*' },

    test            => { TESTS => join( ' ', @tests ) },
);

1;

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;
    
    WriteMakefile(%params);
}

sub regen_README {
    eval {
        require Pod::Readme;

        my $parser = Pod::Readme->new();

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0], 'README');
    };
    eval {
        require Pod::Markdown;

        my $parser = Pod::Markdown->new();

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0]);
        open my $fh, '>', 'README.mkdn'
            or die "Couldn't open 'README.mkdn': $!";
        print $fh $parser->as_markdown;
    };
}

