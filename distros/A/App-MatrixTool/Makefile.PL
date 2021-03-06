# Note: this file was auto-generated by Module::Build::Compat version 0.4218
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'App::MatrixTool',
  'VERSION_FROM' => 'lib/App/MatrixTool.pm',
  'PREREQ_PM' => {
                   'File::Slurper' => 0,
                   'Future' => '0.33',
                   'IO::Async::Resolver' => '0.68',
                   'IO::Async::Resolver::DNS' => '0.06',
                   'IO::Async::SSL' => 0,
                   'JSON' => 0,
                   'List::Util' => '1.29',
                   'MIME::Base64' => 0,
                   'Module::Pluggable::Object' => 0,
                   'Module::Runtime' => 0,
                   'Net::Async::HTTP' => '0.40',
                   'Protocol::Matrix' => 0,
                   'Protocol::Matrix::HTTP::Federation' => 0,
                   'Struct::Dumb' => 0,
                   'URI::Escape' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'bin/matrixtool'
                 ],
  'PL_FILES' => {}
)
;
