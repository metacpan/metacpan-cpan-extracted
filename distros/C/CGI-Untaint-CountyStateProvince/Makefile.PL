use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME                => 'CGI::Untaint::CountyStateProvince',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Untaint/CountyStateProvince.pm',
    ABSTRACT_FROM        => 'lib/CGI/Untaint/CountyStateProvince.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'CGI::Untaint' => 0,
    }, dist => $dist,
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		# 'Test::Kwalitee' => 0,
    }, clean               => { FILES => 'CGI-Untaint-CountyStateProvince-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			repository => 'https://github.com/nigelhorne/CGI-Untaint-CountyStateProvince',
			type => 'git',
			url => 'git://github.com/nigelhorne/CGI-Untaint-CountyStateProvince.git',
			web => 'https://github.com/nigelhorne/CGI-Untaint-CountyStateProvince'
    		},
		bugtracker => {
			mailto => 'bug-CGI-Untaint-CountyStateProvince@rt.cpan.org',
			url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Untaint-CountyStateProvince',
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Untaint-CountyStateProvince'
		}
	},
    },
);
