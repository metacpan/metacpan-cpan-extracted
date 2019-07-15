use strict;
use warnings;

use lib 'inc';
use BSONConfig;

BSONConfig::check_for_compiler();

use 5.010001;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "XS implementation of MongoDB's BSON serialization",
  "AUTHOR" => "David Golden <david\@mongodb.com>",
  "CONFIGURE_REQUIRES" => {
    "Config::AutoConf" => "0.22",
    "ExtUtils::MakeMaker" => 0,
    "Path::Tiny" => "0.052"
  },
  "DISTNAME" => "BSON-XS",
  "LICENSE" => "apache",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "BSON::XS",
  "OBJECT" => "xs/XS\$(OBJ_EXT) bson/bson-atomic\$(OBJ_EXT) bson/bson-clock\$(OBJ_EXT) bson/bson-context\$(OBJ_EXT) bson/bson-decimal128\$(OBJ_EXT) bson/bson-error\$(OBJ_EXT) bson/bson-iso8601\$(OBJ_EXT) bson/bson-iter\$(OBJ_EXT) bson/bson-keys\$(OBJ_EXT) bson/bson-md5\$(OBJ_EXT) bson/bson-memory\$(OBJ_EXT) bson/bson-oid\$(OBJ_EXT) bson/bson-reader\$(OBJ_EXT) bson/bson-string\$(OBJ_EXT) bson/bson-timegm\$(OBJ_EXT) bson/bson-utf8\$(OBJ_EXT) bson/bson-value\$(OBJ_EXT) bson/bson-version\$(OBJ_EXT) bson/bson-writer\$(OBJ_EXT) bson/bson\$(OBJ_EXT)",
  "PREREQ_PM" => {
    "BSON" => "1.012000",
    "XSLoader" => 0,
    "boolean" => 0,
    "strict" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "B" => 0,
    "BSON" => "1.012000",
    "BSON::OID" => 0,
    "BSON::Types" => 0,
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Devel::Peek" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "JSON::MaybeXS" => 0,
    "JSON::PP" => "2.97001",
    "MIME::Base64" => 0,
    "Math::BigInt" => 0,
    "Path::Tiny" => "0.054",
    "Scalar::Util" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.96",
    "Tie::IxHash" => 0,
    "base" => 0,
    "constant" => 0,
    "lib" => 0,
    "utf8" => 0
  },
  "VERSION" => "v0.8.0",
  "XS" => {
    "xs/XS.xs" => "xs/XS.c"
  },
  "clean" => {
    "FILES" => "xs/XS\$(OBJ_EXT) bson/bson-atomic\$(OBJ_EXT) bson/bson-clock\$(OBJ_EXT) bson/bson-context\$(OBJ_EXT) bson/bson-decimal128\$(OBJ_EXT) bson/bson-error\$(OBJ_EXT) bson/bson-iso8601\$(OBJ_EXT) bson/bson-iter\$(OBJ_EXT) bson/bson-keys\$(OBJ_EXT) bson/bson-md5\$(OBJ_EXT) bson/bson-memory\$(OBJ_EXT) bson/bson-oid\$(OBJ_EXT) bson/bson-reader\$(OBJ_EXT) bson/bson-string\$(OBJ_EXT) bson/bson-timegm\$(OBJ_EXT) bson/bson-utf8\$(OBJ_EXT) bson/bson-value\$(OBJ_EXT) bson/bson-version\$(OBJ_EXT) bson/bson-writer\$(OBJ_EXT) bson/bson\$(OBJ_EXT)"
  },
  "test" => {
    "TESTS" => "t/*.t t/common/*.t t/corpus/*.t t/mapping/*.t t/regression/*.t"
  }
);

my %FallbackPrereqs = (
  "B" => 0,
  "BSON" => "1.012000",
  "BSON::OID" => 0,
  "BSON::Types" => 0,
  "Carp" => 0,
  "Data::Dumper" => 0,
  "Devel::Peek" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "JSON::MaybeXS" => 0,
  "JSON::PP" => "2.97001",
  "MIME::Base64" => 0,
  "Math::BigInt" => 0,
  "Path::Tiny" => "0.054",
  "Scalar::Util" => 0,
  "Test::Deep" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "0.96",
  "Tie::IxHash" => 0,
  "XSLoader" => 0,
  "base" => 0,
  "boolean" => 0,
  "constant" => 0,
  "lib" => 0,
  "strict" => 0,
  "utf8" => 0,
  "version" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

BSONConfig::configure(\%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

{

    package MY;

    use Config;

    sub const_cccmd {
        my $ret = shift->SUPER::const_cccmd(@_);
        return q{} unless $ret;

        if ( $Config{cc} =~ /^cl\b/i ) {
            warn 'you are using MSVC... we may not have gotten some options quite right.';
            $ret .= ' /Fo$@';
        }
        else {
            $ret .= ' -o $@';
        }

        return $ret;
    }

    sub postamble {
        my $txt = <<'EOF';

cover : pure_all
        HARNESS_PERL_SWITCHES=-MDevel::Cover make test

ptest : pure_all
        HARNESS_OPTIONS=j9 make test

EOF
        $txt =~ s/^ +/\t/mg;
        return $txt;
    }

}
