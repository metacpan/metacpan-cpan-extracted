BEGIN {
  use strict; use warnings;
  my %missing = map {
    eval qq{ require $_ };
    $@ ? ($_=>1) : ()
  } qw( Carp Env experimental overload strict warnings );
  if(%missing)
  {
    print "Your Perl is missing core modules: @{[ sort keys %missing ]}\n";
    print "Ideally if you are using the system Perl you can install the appropriate\n";
    print "package which includes the core Perl modules.  On at least some versions\n";
    print "of Fedora, CentOS and RHEL, this is the `perl-core` package.\n";
    print "\n";
    print " % dnf install perl-core\n";
    print "   ~ or ~\n";
    print " % yum install perl-core\n";
    print "\n";
    print "If you really want to install dual-life modules from CPAN, then you can\n";
    print "use cpanm:\n";
    print "\n";
    print " % cpanm @{[ sort keys %missing ]}\n";
    print "\n";
    print "Note that some core modules are not available from CPAN.\n";
    exit;
  }
}
BEGIN {
  use strict; use warnings;
  unless(eval q{ use 5.022; 1}) {
    print "Perl 5.022 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.62.
use strict;
use warnings;
use 5.022;
use ExtUtils::MakeMaker 6.64;
require "./inc/mymm.pl";

my %WriteMakefileArgs = (
  "ABSTRACT"           => "C-family abstract syntax tree output tool",
  "AUTHOR"             => "Graham Ollis <plicease\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.64",
    "File::Which"         => 0
  },
  "DISTNAME"         => "Clang-CastXML",
  "LICENSE"          => "perl",
  "MIN_PERL_VERSION" => "5.022",
  "NAME"             => "Clang::CastXML",
  "PM"               => {
    "lib/Clang/CastXML.pm"                                                       => "\$(INST_LIB)/Clang/CastXML.pm",
    "lib/Clang/CastXML/Container.pm"                                             => "\$(INST_LIB)/Clang/CastXML/Container.pm",
    "lib/Clang/CastXML/Exception.pm"                                             => "\$(INST_LIB)/Clang/CastXML/Exception.pm",
    "lib/Clang/CastXML/Exception/ParseException.pm"                              => "\$(INST_LIB)/Clang/CastXML/Exception/ParseException.pm",
    "lib/Clang/CastXML/Exception/ProcessException.pm"                            => "\$(INST_LIB)/Clang/CastXML/Exception/ProcessException.pm",
    "lib/Clang/CastXML/Exception/ProcessException/BadCastXMLVersionException.pm" => "\$(INST_LIB)/Clang/CastXML/Exception/ProcessException/BadCastXMLVersionException.pm",
    "lib/Clang/CastXML/Exception/ProcessException/IntrospectException.pm"        => "\$(INST_LIB)/Clang/CastXML/Exception/ProcessException/IntrospectException.pm",
    "lib/Clang/CastXML/Exception/UsageException.pm"                              => "\$(INST_LIB)/Clang/CastXML/Exception/UsageException.pm",
    "lib/Clang/CastXML/Find.pm"                                                  => "\$(INST_LIB)/Clang/CastXML/Find.pm",
    "lib/Clang/CastXML/Wrapper.pm"                                               => "\$(INST_LIB)/Clang/CastXML/Wrapper.pm",
    "lib/Clang/CastXML/Wrapper/Result.pm"                                        => "\$(INST_LIB)/Clang/CastXML/Wrapper/Result.pm"
  },
  "PREREQ_PM" => {
    "Capture::Tiny"    => 0,
    "File::Which"      => 0,
    "Moo"              => "2.0",
    "Path::Tiny"       => 0,
    "Ref::Util"        => 0,
    "StackTrace::Auto" => 0,
    "Throwable"        => 0,
    "XML::Parser"      => 0
  },
  "TEST_REQUIRES" => {
    "Devel::Hide" => 0,
    "Test2::V0"   => "0.000060",
    "Test::XML"   => 0
  },
  "VERSION" => "0.02",
  "test"    => {
    "TESTS" => "t/*.t"
  }
);

mymm::myWriteMakefile(%WriteMakefileArgs);