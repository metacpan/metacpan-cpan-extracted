
use strict;
use warnings FATAL => 'all';
  
use Apache::Test qw(plan ok have_lwp);
use Apache::TestUtil qw(t_cmp);
use Apache::TestRequest qw(GET_BODY GET);
  
my @options = (
		'<option name="ReadmeName" value="FOOTER" />',
		'<option name="HeaderName" value="HEADER" />',
		'<option name="IndexStyleSheet" value="/index.xslt" />',
		'<option name="DirectoryIndex" value="index.html" />',
		'<option name="DirectoryIndex" value="index.shtml" />',
		'<option name="RenderXSLTEnvVar" value="RenderXSLT" />',
		'<option name="FileTypesFilename" value="filetypes.dat" />',
		'<option name="DefaultIcon" value="/icons/__unknown.png" />',
		'<option name="RenderXSLT" value="0" />',
		'<option name="AddIcon" value="(IMG,/icons/image.xbm) .gif" />',
		'<option name="AddIcon" value="(IMG,/icons/image.xbm) .jpg" />',
		'<option name="AddIcon" value="(IMG,/icons/image.xbm) .xbm" />',
		'<option name="AddIcon" value="/icons/dir.xbm ^^DIRECTORY^^" />',
		'<option name="AddIcon" value="/icons/backup.xbm *~" />',
	);

plan tests => scalar(@options);
  
my $url = '/';
my $data = GET_BODY($url);

for (@options) {
	my ($option) = $_ =~ /name="(.+?)"/;
	(my $regex = $_) =~ s/([\.\[\]\(\)\{\}\*\+\?\^\$])/\\$1/g;
	ok t_cmp(
		$data,
		qr{$regex},
		"option $option"
	);
}

