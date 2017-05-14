package App::ModuleBuildTiny::Dist;

use 5.010;
use strict;
use warnings;
our $VERSION = '0.020';

use Carp qw/croak/;
use Config;
use Encode qw/encode_utf8 decode_utf8/;
use File::Basename qw/basename dirname/;
use File::Copy qw/copy/;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions qw/catfile catdir rel2abs/;
use File::Slurper qw/write_text read_binary/;
use ExtUtils::Manifest qw/manifind maniskip maniread/;
use Module::Runtime 'require_module';

use Env qw/@PERL5LIB @PATH/;

my $Build = $^O eq 'MSWin32' ? 'Build' : './Build';

sub prereqs_for {
	my ($meta, $phase, $type, $module, $default) = @_;
	return $meta->effective_prereqs->requirements_for($phase, $type)->requirements_for_module($module) || $default || 0;
}

sub uptodate {
	my ($destination, @source) = @_;
	return if not -e $destination;
	for my $source (grep { defined && -e } @source) {
		return if -M $destination < -M $source;
	}
	return 1;
}

sub generate_readme {
	my $distname = shift;
	(my $filename = "lib/$distname.pm") =~ s{-}{/};
	croak "Main module file $filename doesn't exist" if not -f $filename;
	my $parser = Pod::Simple::Text->new;
	$parser->output_string( \my $content );
	$parser->parse_characters(1);
	$parser->parse_file($filename);
	return $content;
}

sub load_mergedata {
	my $mergefile = shift;
	if (defined $mergefile and -r $mergefile) {
		require Parse::CPAN::Meta;
		return Parse::CPAN::Meta->load_file($mergefile);
	}
	return;
}

sub distname {
	my $extra = shift;
	return delete $extra->{name} if defined $extra->{name};
	my $distname = basename(rel2abs('.'));
	$distname =~ s/(?:^(?:perl|p5)-|[\-\.]pm$)//x;
	return $distname;
}

sub detect_license {
	my ($data, $filename, $authors) = @_;
	my (@license_sections) = grep { /licen[cs]e|licensing|copyright|legal|authors?\b/i } $data->pod_inside;
	for my $license_section (@license_sections) {
		next unless defined ( my $license_pod = $data->pod($license_section) );
		require Software::LicenseUtils;
		my $content = "=head1 LICENSE\n" . $license_pod;
		my @guess = Software::LicenseUtils->guess_license_from_pod($content);
		next if not @guess;
		croak "Couldn't parse license from $license_section in $filename: @guess" if @guess != 1;
		my $class = $guess[0];
		my ($year) = $license_pod =~ /.*? copyright .*? ([\d\-]+)/;
		require_module($class);
		return $class->new({holder => join(', ', @{$authors}), year => $year});
	}
	croak "No license found in $filename";
}

sub checkchanges {
	my $version = quotemeta shift;
	open my $changes, '<:raw', 'Changes' or die "Couldn't open Changes file";
	my (undef, @content) = grep { / ^ $version (?:-TRIAL)? (?:\s+|$) /x ... /^\S/ } <$changes>;
	pop @content while @content && $content[-1] =~ / ^ (?: \S | \s* $ ) /x;
	warn "Changes appears to be empty\n" if not @content
}

sub new {
	my ($class, %opts) = @_;
	my $mergefile = $opts{mergefile} || (grep { -f } qw/metamerge.json metamerge.yml/)[0];
	my $mergedata = load_mergedata($mergefile) || {};
	my $distname = distname($mergedata);
	my $filename = catfile('lib', split /-/, $distname) . '.pm';

	require Module::Metadata; Module::Metadata->VERSION('1.000009');
	my $data = Module::Metadata->new_from_file($filename, collect_pod => 1) or die "Couldn't analyse $filename: $!";
	my @authors = map { / \A \s* (.+?) \s* \z /x } grep { /\S/ } split /\n/, $data->pod('AUTHOR') // '' or warn "Could not parse any authors from `=head1 AUTHOR` in $filename";
	my $license = detect_license($data, $filename, \@authors);

	my $load_meta = !%{ $opts{regenerate} || {} } && uptodate('META.json', 'cpanfile', $mergefile);
	my $meta = $load_meta ? CPAN::Meta->load_file('META.json', { lazy_validation => 0 }) : do {
		my ($abstract) = ($data->pod('NAME') // '')  =~ / \A \s+ \S+ \s? - \s? (.+?) \s* \z /x or warn "Could not parse abstract from `=head1 NAME` in $filename";
		my $version = $data->version($data->name) // die "Cannot parse \$VERSION from $filename";

		my $prereqs = -f 'cpanfile' ? do { require Module::CPANfile; Module::CPANfile->load('cpanfile')->prereq_specs } : {};
		$prereqs->{configure}{requires}{'Module::Build::Tiny'} //= mbt_version();
		$prereqs->{develop}{requires}{'App::ModuleBuildTiny'} //= $VERSION;

		my $metahash = {
			name           => $distname,
			version        => $version->stringify,
			author         => \@authors,
			abstract       => $abstract,
			dynamic_config => 0,
			license        => [ $license->meta2_name ],
			prereqs        => $prereqs,
			release_status => $version =~ /_|-TRIAL$/ ? 'testing' : 'stable',
			generated_by   => "App::ModuleBuildTiny version $VERSION",
			'meta-spec'    => {
				version    => '2',
				url        => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec'
			},
		};
		if (%{$mergedata}) {
			require CPAN::Meta::Merge;
			$metahash = CPAN::Meta::Merge->new(default_version => '2')->merge($metahash, $mergedata);
		}
		$metahash->{provides} ||= Module::Metadata->provides(version => 2, dir => 'lib') if not $metahash->{no_index};
		CPAN::Meta->create($metahash, { lazy_validation => 0 });
	};

	my %files;
	if (not $opts{regenerate}{MANIFEST} and -r 'MANIFEST') {
		%files = %{ maniread() };
	}
	else {
		my $maniskip = maniskip;
		%files = %{ manifind() };
		delete $files{$_} for grep { $maniskip->($_) } keys %files;
	}
	delete $files{$_} for keys %{ $opts{regenerate} };
	
	my $dist_name = $meta->name;
	$files{'Build.PL'} //= do {
		my $minimum_mbt  = prereqs_for($meta, qw/configure requires Module::Build::Tiny/);
		my $minimum_perl = prereqs_for($meta, qw/runtime requires perl 5.006/);
		"# This Build.PL for $dist_name was generated by mbtiny $VERSION.\nuse $minimum_perl;\nuse Module::Build::Tiny $minimum_mbt;\nBuild_PL();\n";
	};
	$files{'META.json'} //= $meta->as_string;
	$files{'META.yml'} //= $meta->as_string({ version => 1.4 });
	$files{LICENSE} //= $license->fulltext;
	$files{README} //= generate_readme($dist_name);
	# This must come last
	$files{MANIFEST} //= join '', map { "$_\n" } sort keys %files;

	return bless {
		files => \%files,
		meta  => $meta,
		license => $license
	}, $class
}

sub write_dir {
	my ($self, $dir, $verbose) = @_;
	mkpath($dir, $verbose, oct '755');
	my $files = $self->{files};
	for my $filename (keys %{$files}) {
		my $target = catfile($dir, $filename);
		mkpath(dirname($target)) if not -d dirname($target);
		if ($files->{$filename}) {
			write_text($target, $files->{$filename});
		}
		else {
			copy($filename, $target);
		}
	}
}

sub write_tarball {
	my ($self, $name) = @_;
	require Archive::Tar;
	my $arch = Archive::Tar->new;
	checkchanges($self->meta->version);
	for my $filename ($self->files) {
		$arch->add_data($filename, $self->get_file($filename), { mode => oct '0644'} );
	}
	$arch->write($name, &Archive::Tar::COMPRESS_GZIP, $name);
	return;
}

sub files {
	my $self = shift;
	return keys %{ $self->{files} };
}

sub get_file {
	my ($self, $filename) = @_;
	return if not exists $self->{files}{$filename};
	my $raw = $self->{files}{$filename};
	return $raw ? encode_utf8($raw) : read_binary($filename);
}

sub is_generated {
	my ($self, $filename) = @_;
	return if not exists $self->{files}{$filename};
	return length $self->{files}{$filename};
}

sub run {
	my ($self, %opts) = @_;
	require File::Temp;
	my $dir  = File::Temp::tempdir(CLEANUP => 1);
	$self->write_dir($dir, $opts{verbose});
	chdir $dir;
	if ($opts{build}) {
		system $Config{perlpath}, 'Build.PL';
		system $Config{perlpath}, 'Build';
		my @extralib = map { rel2abs(catdir('blib', $_)) } 'arch', 'lib';
		local @PERL5LIB = (@extralib, @PERL5LIB);
		local @PATH = (rel2abs(catdir('blib', 'script')), @PATH);
		return not system @{ $opts{command} };
	}
	else {
		return not system @{ $opts{command} };
	}
}

for my $method (qw/meta license/) {
	no strict 'refs';
	*$method = sub { my $self = shift; return $self->{$method}; };
}

for my $method (qw/name version/) {
	no strict 'refs';
	*$method = sub { my $self = shift; return $self->{meta}->$method; }
}

1;
