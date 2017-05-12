

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBD::PgLite',
    VERSION_FROM => 'lib/DBD/PgLite.pm', # finds \$VERSION
    AUTHOR       => 'Baldur Kristinsson (bk@mbl.is)',
    ABSTRACT     => 'PostgreSQL emulation mode for SQLite',
    PREREQ_PM    => {
                     'Test::More' => 0.44,
					 'DBI' => 1.30,
					 'DBD::SQLite' => 1.0,
					 'Text::Iconv' => 1.0,
					 'MIME::Base64' => 2.0,
					 'Digest::MD5' => 2.0,
					 'Math::Trig' => 1.0,
					 'File::Copy' => 2.0,
					 'Storable' => 2.0,
                    },
);
