#!/usr/bin/perl

use strict;
use warnings;
use Test::Most tests => 9;

use App::Prove::Plugin::TraceUse;

my $dt1 = <<'EOT1';
Modules used from -e:
   1.  DateTime 0.78, -e line 0 [main]
   2.    strict 1.07, DateTime.pm line 8
   3.    warnings 1.13, DateTime.pm line 9
   4.    Carp 1.26, DateTime.pm line 42
   5.      Exporter 5.66, Carp.pm line 35
  71.        Exporter::Heavy 5.66, Exporter.pm line 16
   6.    DateTime::Duration 0.78, DateTime.pm line 43
   7.      DateTime::Helpers 0.78, DateTime/Duration.pm line 11
   8.        Scalar::Util 1.25, DateTime/Helpers.pm line 9
   9.          List::Util 1.25, Scalar/Util.pm line 11
  10.            XSLoader 0.16, List/Util.pm line 20
  11.      Params::Validate 1.07, DateTime/Duration.pm line 12
  12.        Module::Implementation 0.06, Params/Validate.pm line 12
  13.          Module::Runtime 0.013, Module/Implementation.pm line 9
  18.            Params::Validate::XS 1.07, Module/Runtime.pm line 317
  45.            Class::Load::XS, Module/Runtime.pm line 317 (FAILED)
  46.            Class::Load::PP 0.20, Module/Runtime.pm line 317
  47.              Package::Stash 0.33, Class/Load/PP.pm line 9
  48.                Package::Stash::XS 0.25, Package/Stash.pm line 24 (eval 20)
  49.                Package::DeprecationManager 0.13, Package/Stash.pm line 56
  14.          Try::Tiny 0.11, Module/Implementation.pm line 10
  15.            vars 1.02, Try/Tiny.pm line 6
  16.              warnings::register 1.02, vars.pm line 7
  17.        Params::Validate::Constants 1.07, Params/Validate.pm line 13
  19.      overload 1.18, DateTime/Duration.pm line 21
  20.        overloading 0.02, overload.pm line 85
  21.      constant 1.23, DateTime/Duration.pm line 23
  22.        utf8 1.09, constant.pm line 36
  23.          utf8_heavy.pl, utf8.pm line 17
  24.            unicore/Heavy.pl, utf8_heavy.pl line 176 [utf8]
  25.            unicore/lib/Perl/_PerlIDS.pl, utf8_heavy.pl line 518 [utf8]
  26.    DateTime::Locale 0.45, DateTime.pm line 45
  27.      DateTime::Locale::Base, DateTime/Locale.pm line 10
  28.        List::MoreUtils 0.33, DateTime/Locale/Base.pm line 8
  29.          DynaLoader 1.14, List/MoreUtils.pm line 6
  30.            Config, DynaLoader.pm line 22
  31.      DateTime::Locale::Catalog, DateTime/Locale.pm line 11
  57.      DateTime::Locale::en_US, DateTime/Locale.pm line 280 (eval 25)
  32.    DateTime::TimeZone 1.57, DateTime.pm line 46
  33.      DateTime::TimeZone::Catalog 1.57, DateTime/TimeZone.pm line 11
  34.      DateTime::TimeZone::Floating 1.57, DateTime/TimeZone.pm line 12
  35.        parent 0.225, DateTime/TimeZone/Floating.pm line 9
  36.          Class::Singleton 1.4, parent.pm line 20
  37.          DateTime::TimeZone::OffsetOnly 1.57, parent.pm line 20
  38.            DateTime::TimeZone::UTC 1.57, DateTime/TimeZone/OffsetOnly.pm line 11
  39.      DateTime::TimeZone::Local 1.57, DateTime/TimeZone.pm line 13
  40.        Class::Load 0.20, DateTime/TimeZone/Local.pm line 9
  41.          base 2.18, Class/Load.pm line 7
  58.            DateTime::Locale::en, base.pm line 81 (eval 26)
  59.            DateTime::Locale::root, base.pm line 81 (eval 27)
  42.          Data::OptList 0.107, Class/Load.pm line 8
  43.            Params::Util 1.07, Data/OptList.pm line 10
  44.            Sub::Install 0.926, Data/OptList.pm line 11
  50.        File::Spec 3.39_02, DateTime/TimeZone/Local.pm line 11
  51.          File::Spec::Unix 3.39_02, File/Spec.pm line 22
  52.    POSIX 1.30, DateTime.pm line 49
  53.      Fcntl 1.11, POSIX.pm line 17
  54.      Tie::Hash 1.04, POSIX.pm line 419 [POSIX::SigRt]
  55.    integer 1.00, DateTime.pm line 702
  56.    DateTime::Infinite 0.78, DateTime.pm line 70
  60.  Set::Object 1.26, -e line 0 [main]
  61.    AutoLoader 5.72, Set/Object.pm line 503
  62.    Set::Object::Weak, Set/Object.pm line 1091
  63.  LWP::Simple 6.00, -e line 0 [main]
  64.    HTTP::Status 6.03, LWP/Simple.pm line 14
  65.    LWP::UserAgent 6.05, LWP/Simple.pm line 26
  66.      HTTP::Request 6.00, LWP/UserAgent.pm line 10
  67.        HTTP::Message 6.03, HTTP/Request.pm line 3
  68.          HTTP::Headers 6.00, HTTP/Message.pm line 7
  69.            Storable 2.34, HTTP/Headers.pm line 282
  70.              Log::Agent, Storable.pm line 27 (FAILED)
  72.          URI 1.60, HTTP/Message.pm line 12 (eval 31)
  73.            URI::Escape 3.31, URI.pm line 22
  74.      HTTP::Response 6.03, LWP/UserAgent.pm line 11
  75.      HTTP::Date 6.02, LWP/UserAgent.pm line 12
  76.        Time::Local 1.2000, HTTP/Date.pm line 11
  77.      LWP 6.05, LWP/UserAgent.pm line 14
  78.      LWP::Protocol 6.00, LWP/UserAgent.pm line 15
  79.        LWP::MemberMixin, LWP/Protocol.pm line 3
  80.      HTTP::Config 6.00, LWP/UserAgent.pm line 770
  81.      Encode 2.44, LWP/UserAgent.pm line 999
  82.        Encode::Alias 2.15, Encode.pm line 48
  83.        bytes 1.04, Encode.pm line 325 [Encode::utf8]
  84.        Encode::Config 2.05, Encode.pm line 53
  85.        Encode::ConfigLocal, Encode.pm line 60 (FAILED)
  86.        Encode::Encoding 2.05, Encode.pm line 241
  87.      Encode::Locale 1.03, LWP/UserAgent.pm line 1000
  88.        I18N::Langinfo 0.08_02, Encode/Locale.pm line 58
  89.  XML::LibXML 2.0004, -e line 0 [main]
  90.    XML::LibXML::Error 2.0004, XML/LibXML.pm line 24
  91.      Data::Dumper 2.135_06, XML/LibXML/Error.pm line 257
  92.    XML::LibXML::NodeList 2.0004, XML/LibXML.pm line 25
  93.      XML::LibXML::Boolean 2.0004, XML/LibXML/NodeList.pm line 15
  94.        XML::LibXML::Number 2.0004, XML/LibXML/Boolean.pm line 12
  95.          XML::LibXML::Literal 2.0004, XML/LibXML/Number.pm line 12
  96.    XML::LibXML::XPathContext 2.0004, XML/LibXML.pm line 26
  97.    IO::Handle 1.33, XML/LibXML.pm line 27
  98.      Symbol 1.07, IO/Handle.pm line 264
  99.      SelectSaver 1.02, IO/Handle.pm line 265
 100.      IO 1.25_06, IO/Handle.pm line 266
 101.    XML::LibXML::AttributeHash 2.0004, XML/LibXML.pm line 1497 [XML::LibXML::Element]
 102.    XML::SAX::Exception 1.08, XML/LibXML.pm line 1995 [XML::LibXML::_SAXParser]
Possible proxies:
   4 -e line 0, sub main::BEGIN
   3 Module/Runtime.pm line 317, sub Module::Runtime::require_module
   2 parent.pm line 20, sub parent::import
   2 base.pm line 81, sub base::import
EOT1

my $tr = App::Prove::Plugin::TraceUse::_parse_traceuse( $dt1 );

isa_ok( $tr, "Tree::Simple" );
ok( $tr->isRoot, "root is root" );
ok( !$tr->isLeaf, "root is not a leaf" );
ok( !$tr->getChild(0)->isRoot, "first child is not root" );

## 1st gen children
cmp_deeply( $tr->getChild(0)->getNodeValue, [qw/DateTime 0.78/], "1st node" );
cmp_deeply( $tr->getChild(1)->getNodeValue, [qw/Set::Object 1.26/], "2nd node" );
cmp_deeply( $tr->getChild(2)->getNodeValue, [qw/LWP::Simple 6.00/], "3rd node" );
cmp_deeply( $tr->getChild(3)->getNodeValue, [qw/XML::LibXML 2.0004/], "4th node" );

## some 2nd gen's
cmp_deeply( $tr->getChild(0)->getChild(0)->getNodeValue, [qw/strict 1.07/], "node 1.1" );

done_testing();
