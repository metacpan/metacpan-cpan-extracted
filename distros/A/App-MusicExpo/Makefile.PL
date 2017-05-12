use 5.014000;
use ExtUtils::MakeMaker;

my @optionals = (
	qw/Audio::FLAC::Header           0
	   Audio::Opusfile               0
	   MP3::Info                     0
	   MP4::Info                     0
	   Ogg::Vorbis::Header::PurePerl 0/,
);

sub is_installed {
	my ($module) = @_;
	eval "require $module"
}

my @extra_prereqs;

unless (grep \&is_installed, @optionals) {
	my $answer = '';
	while (!$answer) {
		my $yn = lc prompt 'None of the optional dependencies are installed. Install all of them? (default: y) [y/n]', 'y';
		$answer = $yn if $yn eq 'y' || $yn eq 'n';
	}
	@extra_prereqs = @optionals if $answer eq 'y';
}

WriteMakefile(
	NAME             => 'App::MusicExpo',
	VERSION_FROM     => 'lib/App/MusicExpo.pm',
	ABSTRACT_FROM    => 'lib/App/MusicExpo.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES        => [ 'musicexpo' ],
	MIN_PERL_VERSION => 5.014,
	LICENSE          => 'perl',
	SIGN             => 1,
	PREREQ_PM        => {
		qw/HTML::Template::Compiled      0
		   Memoize                       0
		   DB_File                       0/,
		@extra_prereqs
	},
	META_MERGE         => {
		dynamic_config => 1,
		resources      => {
			repository => 'http://git.ieval.ro/?p=app-musicexpo.git'
		},
		recommends     => { @optionals },
	}
);
