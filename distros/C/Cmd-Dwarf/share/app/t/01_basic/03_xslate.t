use Dwarf::Pragma;
use Test::More 0.88;
use Cwd qw(abs_path);
use File::Find;
use FindBin qw($Bin);
use Text::Xslate;

my $warn;
my $basedir = abs_path("$Bin/../../tmpl");
my $tx = Text::Xslate->new(
	verbose      => 1,
	warn_handler => sub { $warn .= join '', @_ },
	cache        => 0,
	path         => [ $basedir ],
);

my @files;
find(sub {
	return if -d $File::Find::name;
	return if $File::Find::name =~ m@\.DS_Store@;
	return if $File::Find::name =~ m@/(\.svn)/|~$@;
	my $path = abs_path($File::Find::name);
	$path =~ s|^$basedir/||;
	push @files, $path;
}, $basedir);

test($_) foreach (@files);

done_testing();

sub test {
	my ($file) = @_;
	$warn = '';
	eval {
		$tx->render($file, {});
	};
	is $warn, '', "$file: no warn";
	is $@, '', "$file: eval OK";
}

