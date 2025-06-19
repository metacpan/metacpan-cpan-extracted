require 5.006000;
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'AsposeCellsCloud::CellsApi',
  'LICENSE' => 'MIT',
  'VERSION' => '25.6.1',
  'ABSTRACT' =>'Aspose.Cells Cloud SDK',
  'AUTHOR' =>'Aspose.Cells',
  'PREREQ_PM' => {
                   'Carp' => 0,
                   'Data::Dumper' => 0,
                   'Date::Parse' => 0,
                   'DateTime' => 0,
                   'Digest::HMAC_SHA1' => 0,
                   'Exporter' => 0,
                   'HTTP::Headers' => 0,
                   'HTTP::Request::Common' => 0,
                   'HTTP::Response' => 0,
                   'HTTP::Status' => 0,
                   'JSON' => 0,
                   'LWP::UserAgent' => 0,
                   'Log::Any' => 0,
                   'MIME::Base64' => 0,
                   'Module::Runtime' => 0,
                   'Scalar::Util' => 0,
                   'Test::Exception' => 0,
                   'Test::More' => '0.10',
                   'File::Slurp' => 0,
                   'URI::Escape' => 0,
                   'URI::Query' => 0,
                   'strict' => 0,
                   'utf8' => 0,
                   'warnings' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [],
  'PL_FILES' => {}
)
;
