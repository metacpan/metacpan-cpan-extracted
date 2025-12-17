use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use File::Temp;
use Git::Raw;
use CPAN::InGit;
use v5.36;

skip_all 'Avoiding queries to public CPAN unless you set TEST_CPAN_INGIT_FETCH_MODULE'
   unless $ENV{TEST_CPAN_INGIT_FETCH_MODULE};

# TEST_CPAN_INGIT_DIR=repo1 prove -lv t/10-init-mirror-of-cpan.t
# TEST_CPAN_INGIT_DIR=repo1 TEST_CPAN_INGIT_FETCH_MODULE=Crypt::DES prove -lv t/11-fetch-dist.t

my $mod= $ENV{TEST_CPAN_INGIT_FETCH_MODULE};
my $repodir= $ENV{TEST_CPAN_INGIT_GIT_DIR}
   // File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_INGIT_CLEANUP} // 1);
my $git_repo= Git::Raw::Repository->init($repodir, 1); # new bare repo in tmpdir
note "repo at $repodir";

subtest autofetch => sub {
   my $cpan_repo= CPAN::InGit->new(repo => $git_repo);
   my $mirror= $cpan_repo->create_archive_tree('www_cpan_org',
      upstream_url => 'https://www.cpan.org',
      autofetch => 1,
   );
   ok( $mirror->package_details_blob, 'auto-fetched packages.details.txt' );
   ok( my $dist= $mirror->get_module_dist($mod), "have dist listed for $mod" );
   ok( $mirror->get_path("authors/id/$dist"), "auto-fetched authors/id/$dist" );
   ok( $mirror->has_changes, 'has_changes' )
      unless $ENV{TEST_CPAN_INGIT_GIT_DIR};
   ok( $mirror->commit("Added $dist for $mod"), 'commit mirror' );
};

subtest fetch_dependencies => sub {
   my $cpan_repo= CPAN::InGit->new(repo => $git_repo);
   ok( my $mirror= $cpan_repo->get_archive_tree('www_cpan_org'), 'found mirror' );
   my $app_pan= $cpan_repo->create_archive_tree('my_app_'.rand,
      default_import_sources => [ 'www_cpan_org' ],
      corelist_perl_version  => '5.026',
   );

   $app_pan->import_modules({ $mod => 0 });
   ok( $app_pan->has_changes )
      unless $ENV{TEST_CPAN_INGIT_GIT_DIR};
   ok( $app_pan->commit("Added $mod"), 'commit app_pan' );
};

done_testing;
