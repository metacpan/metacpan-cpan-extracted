use warnings;
use strict;

use 5.006;
use inc::Module::Install 1.00;

# adapted from DBIx::Class::Schema::Loader Makefile

use Getopt::Long();

my $getopt = Getopt::Long::Parser->new(
  config => [qw/gnu_getopt bundling_override no_ignore_case pass_through/]
);
my $args = {
  skip_author_deps => undef,
};
$getopt->getoptions($args, 'skip_author_deps');
if (@ARGV) {
  warn "\nIgnoring unrecognized option(s): @ARGV\n\n";
}

perl_version '5.006';
name         'DBIx-Class-Schema-Loader-DBI-RelPatterns';
license      'perl';
all_from     'lib/DBIx/Class/Schema/Loader/DBI/RelPatterns.pm';

# core, but specific versions not available on older perls
test_requires 'Exporter'               => '5.63';
test_requires 'File::Temp'             => '0.16';
test_requires 'File::Path'             => '2.07';

test_requires 'DBD::SQLite'            => '1.29';
test_requires 'DBI'                    => '1.57';
test_requires 'namespace::clean'       => 0;
test_requires 'Test::Exception'        => '0.31';
test_requires 'Test::More'             => '0.94';

requires 'Carp::Clan'                  => 0;
requires 'Class::Accessor::Grouped'    => '0.09002';
requires 'DBIx::Class::Schema::Loader' => '0.05';
requires 'MRO::Compat'                 => '0.09';

if ($Module::Install::AUTHOR && ! $args->{skip_author_deps}) {
    eval "require $_; 1"
      or die "\nYou need $_ installed to run this Makefile.PL in author mode:\n\n$@\n"
      foreach qw(Module::Install::ReadmeFromPod Module::Install::ReadmeMarkdownFromPod);

    warn "\n*** AUTHOR MODE: some optional dependencies converted to hard requires.\n\n";

    test_requires 'DBD::SQLite'        => '1.40'; # with statistics_info method support
    test_requires 'Test::Differences'  => '0.60';

    readme_from();
    readme_markdown_from_pod();
    realclean_files( qw[MANIFEST README README.mkdn] );
}

tests_recursive;

repository 'https://github.com/azlewa/DBIx-Class-Schema-Loader-DBI-RelPatterns';

auto_install;
WriteAll;
