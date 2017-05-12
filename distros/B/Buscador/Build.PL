use strict;
use lib qw(lib);
use Buscador::Build;

my $build = Buscador::Build->new(
    module_name => "Buscador",
    license     => "perl",
    scripts     => [ 'bin/buscador-import' ],
    requires    => {
        'Apache::MVC'                 => 0,
        'Cache::FileCache'            => 0,
        'Class::DBI::Pager'           => 0,
        'Date::Parse'                 => 0,
        'Email::Find'                 => 0,
        'Email::Store'                => 0.24,
        'Email::Store::HTML'          => 0,
        'Email::Store::NamedEntity'   => 0,
        'Email::Store::Plucene'       => 0,
        'Email::Store::Pristine'      => 1.21,
        'Email::Store::Summary'       => 1.2,
        'Email::Store::Thread'        => 1.2,
        'File::NCopy'                 => 0,
        'HTML::Entities'              => 0,
        'Mail::Thread::Arc'           => 0.22,
        'Mail::Thread::Chronological' => 0,
        'Maypole::Cache'              => 0,
        'Maypole::Redirect'           => 0,
        'MIME::Base64'                => 0,
        'Module::Pluggable::Ordered'  => 0,
        'Plucene'                     => 1.17,
        'Sys::Hostname'               => 0,
        'Text::Decorator'             => 1.2,
        'Text::Unidecode'             => 0,
        'Text::Context'               => 0,
        'Time::Piece'                 => 0,
        'URI::Find::Schemeless::Stricter' => 0,
    },
    create_makefile_pl => 'passthrough',
    dynamic_config => 1,
);

$build->{config}{__extras_from} = [ 'templates', 'chrome' ];

$|= 1;
print "Checking for existing Buscador::Root... ";

my $D_ROOT = '/usr/local/buscador';
eval {
    require Buscador::Root;
    print "found. setting defaults based on existing install\n";
    $D_ROOT = $Buscador::Root::root;
};

print "failed. selecting regular defaults\n"
  if $@;

my $ROOT = $build->prompt("where do we install to guv?", $D_ROOT);

print "Generating Buscador::Root from your answers\n";
open(IN,  "<Root.pm.in")
  or die "couldn't open Root.pm.in: $!";
open(OUT, ">lib/Buscador/Root.pm")
  or die "couldn't open Root.pm for write: $!";
while (<IN>) {
    s'@@ROOT@@'$ROOT'e;
    print OUT $_;
}
close IN  or die "error closing Root.pm.in: $!";
close OUT or die "error closing Root.pm: $!";

$build->{config}{__extras_destination} = $ROOT;

$build->create_build_script;


