use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Test::Alien::Build;
use Alien::Build::Plugin::Cleanse::BuildDir;
use Path::Tiny qw( path );

my $alien_file = q|
    use alienfile;
    use Path::Tiny qw( path );

    share {
      #start_url 'file://TARFILE';
      #plugin 'Download';
      #plugin Extract => 'tar';

      download sub { path('file1')->touch }; 
      extract sub { path('file2')->touch }; 

      plugin 'Cleanse::BuildDir';
      
      #  no need to actually do anything
      build [
        sub {},
      ]
    }
|;

#my $tarfile = path('./corpus/dist/foo-1.00.tar')->absolute;
#$alien_file =~ s/TARFILE/$tarfile/;

print $alien_file . "\n";

my $build = alienfile_ok ($alien_file);
alien_download_ok();
alien_extract_ok();

use Data::Dump qw /dd/;
print dd $build;
print "\n";

my $build_dir = $build->install_prop->{extract};
ok (-e $build_dir, 'build dir exists');

my $alien = alien_build_ok();

ok (!-e $build_dir, 'build dir no longer exists')
 or print join ', ',  glob ("$build_dir/*");


done_testing();
