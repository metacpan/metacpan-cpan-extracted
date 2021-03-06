# Note: this file was auto-generated by Module::Build::Compat version 0.4003
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'Data::Downloader',
  'VERSION_FROM' => 'lib/Data/Downloader.pm',
  'PREREQ_PM' => {
                   'DBD::SQLite' => '1.33',
                   'DBIx::Simple' => '1.32',
                   'Digest::MD5::File' => 0,
                   'Fcntl' => 0,
                   'File::Basename' => 0,
                   'File::Compare' => 0,
                   'File::Path' => 0,
                   'File::Slurp' => 0,
                   'File::Spec' => 0,
                   'File::Temp' => 0,
                   'File::stat' => 0,
                   'Filesys::Df' => 0,
                   'FindBin' => 0,
                   'IO::File' => 0,
                   'Lingua::EN::Inflect' => 0,
                   'List::MoreUtils' => 0,
                   'Log::Log4perl' => '1.23',
                   'Log::Log4perl::CommandLine' => 0,
                   'Number::Format' => 0,
                   'Parallel::ForkManager' => 0,
                   'Params::Validate' => 0,
                   'Pod::Usage::CommandLine' => 0,
                   'Rose::DB' => 0,
                   'Rose::DB::Object' => 0,
                   'Rose::DateTime' => 0,
                   'SQL::Abstract' => 0,
                   'Scalar::Util' => 0,
                   'Smart::Comments' => 0,
                   'String::Template' => '0.06',
                   'Sub::Exporter' => 0,
                   'Time::HiRes' => 0,
                   'XML::LibXML' => 0,
                   'YAML::XS' => 0,
                   'if' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'bin/dado',
                   'bin/dado_rebuild_meta'
                 ],
  'PL_FILES' => {}
)
;
