use strict;
use Test::More;

use Archive::Tar;
use Container::Builder;

my $builder = Container::Builder->new(debian_pkg_hostname => 'iaan.be');
# haha gets renamed to /app
$builder->copy('t/haha', '/app', 0755, 0, 0);
$builder->copy('t/haha/', '/app', 0755, 0, 0);
# haha becomes a subfolder, /app/haha
$builder->copy('t/haha', '/app/', 0755, 0, 0);
$builder->copy('t/haha/', '/app/', 0755, 0, 0);

my @layers = $builder->get_layers();
{
	my $tar = $layers[0]->generate_artifact();
	open(my $fh, '<', \$tar);
	my @tar_files = Archive::Tar->list_archive($fh);
	ok(grep { $_ eq './app/hihi.txt' } @tar_files, 'contains ./app/hihi.txt');
	ok(grep { $_ eq './app/hehe/hihi/ghehe.txt' } @tar_files, 'contains ./app/hehe/hihi/ghehe.txt');
}
{
	my $tar = $layers[1]->generate_artifact();
	open(my $fh, '<', \$tar);
	my @tar_files = Archive::Tar->list_archive($fh);
	ok(grep { $_ eq './app/hihi.txt' } @tar_files, 'contains ./app/hihi.txt');
	ok(grep { $_ eq './app/hehe/hihi/ghehe.txt' } @tar_files, 'contains ./app/hehe/hihi/ghehe.txt');
}
{
	my $tar = $layers[2]->generate_artifact();
	open(my $fh, '<', \$tar);
	my @tar_files = Archive::Tar->list_archive($fh);
	ok(grep { $_ eq './app/haha/hihi.txt' } @tar_files, 'contains ./app/haha/hihi.txt');
	ok(grep { $_ eq './app/haha/hehe/hihi/ghehe.txt' } @tar_files, 'contains ./app/haha/hehe/hihi/ghehe.txt');
}
{
	my $tar = $layers[3]->generate_artifact();
	open(my $fh, '<', \$tar);
	my @tar_files = Archive::Tar->list_archive($fh);
	ok(grep { $_ eq './app/haha/hihi.txt' } @tar_files, 'contains ./app/haha/hihi.txt');
	ok(grep { $_ eq './app/haha/hehe/hihi/ghehe.txt' } @tar_files, 'contains ./app/haha/hehe/hihi/ghehe.txt');
}
{
	my $tar = $layers[3]->generate_artifact();
	open(my $fh, '<', \$tar);
	my $t = Archive::Tar->new();
	$t->read($fh);
	my @files = $t->get_files( './app/haha/hehe/hihi/ghehe.txt' );
	ok(@files == 1, 'found the file');
	ok($files[0]->{mode} == 0644, 'Mode of fle is 0644');
}

done_testing;
