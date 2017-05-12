#TODO give user choices about installing the quotes database
#i.e. location/permissions/owner, others?

use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');
   use File::Spec;
   use File::Copy;
   use File::Basename qw/dirname/;

   sub process_db_files {
      my $self = shift;
      my $qdb = File::Spec->catfile(qw(lib ACME QuoteDB DB quotedb), 'quotes.db');
      my $_t = File::Spec->catfile(qw(blib lib ACME QuoteDB DB quotedb), 'quotes.db');
      mkdir dirname($_t);
      chmod(0777, dirname($_t));
      copy($qdb, $_t);
      chmod(0666, $_t);
   }


   sub ACTION_install {
       my $self = shift;
       $self->SUPER::ACTION_install(@_);
       my $ddir =  $self->install_destination('lib');
       #TODO give user choices about installing the quotes database
       #my $ques = 'Where do you want to install the quotes database?';
       #my $quote_dest = $self->prompt($ques, $ddir);
       my $db = q{};
       my $perms = 0666;
       my $d_perms = 0777;
       #if ($quote_dest != $ddir) {
       #    die $! unless -d dirname $quote_dest;
       #    $db = $quote_dest;
       #    $perms = $self->prompt('File Permissions for the quotes database?',
       #                   $perms);
       #}
       if (!$db) {
         $db =
           File::Spec->catfile($ddir, 'ACME', 'QuoteDB', 'DB', 'quotedb', 'quotes.db');
       }
       ##chown('THIS_UNIX_USER' $db);
       ## prompt for the chown
       # XXX we need to change/fix this
       # ideas, let installer/user decide
       # create a new system user
       # others?
       ## create quotes db as world writable,... yikes
       chmod($d_perms, dirname($db));
       chmod($perms, $db);
   }
   
EOF

my $builder = $class->new(
    module_name         => 'ACME::QuoteDB',
    license             => 'perl',
    dist_author         => 'David Wright <david_v_wright@yahoo.com>',
    dist_version_from   => 'lib/ACME/QuoteDB.pm',
    build_requires => {
        #'Module::Build'    => '0.33',
        'Module::Build'    => '0.280801',
        'Test::More'       => 0.8,
        'Readonly'         => 1.03,
        'Data::Dumper'     => 2.121,
        'Carp'             => 1.04,
        #'criticism'        => 1.02,
        'version'          => 0.70,
        'aliased'          => 0.22,
        'File::Basename'   => 2.74,
        'DBD::SQLite'      => 1.14,
        'Class::DBI'       => '3.0.17',
        'HTML::TokeParser' => 2.37,
        'Text::CSV'        => 1.06, #1.10, # 1.13
        'Cwd'              => 3.25, #3.29
        'File::Spec'       => 3.2501, #3.29
        'File::Copy'       => 2.11,
        #'Test::Pod'       => 1.22
        #'Test::Pod::Coverage'  => 1.08
    },
    add_to_cleanup      => [ 'ACME-QuoteDB-*' ],
    # can't install quotes.db with nec's perms with ExtUtils::MakeMaker
    # (well, or can, but too hard figure out at the moment)
    #create_makefile_pl => 'traditional',
    create_makefile_pl => 'passthrough',
    db_files => {'lib/ACME/QuoteDB/DB/quotedb/quotes.db' => 
                    'lib/ACME/QuoteDB/DB/quotedb/quotes.db'},

);

$builder->add_build_element('db');
$builder->create_build_script();
