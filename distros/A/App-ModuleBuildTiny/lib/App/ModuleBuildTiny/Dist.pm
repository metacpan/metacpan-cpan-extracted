package App::ModuleBuildTiny::Dist;

use 5.014;
use strict;
use warnings;
our $VERSION = '0.037';

use CPAN::Meta;
use Config;
use Encode qw/encode_utf8 decode_utf8/;
use File::Basename qw/basename dirname/;
use File::Copy qw/copy/;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions qw/catfile catdir rel2abs/;
use File::Slurper qw/write_text read_text read_binary/;
use File::chdir;
use ExtUtils::Manifest qw/manifind maniskip maniread/;
use Module::Runtime 'require_module';
use Module::Metadata 1.000037;
use Pod::Escapes qw/e2char/;
use POSIX 'strftime';


use Env qw/@PERL5LIB @PATH/;

my $Build = $^O eq 'MSWin32' ? 'Build' : './Build';

sub find {
	my ($re, @dir) = @_;
	my $ret;
	File::Find::find(sub { $ret++ if /$re/ }, @dir);
	return $ret;
}

sub mbt_version {
	return '0.039';
}

sub prereqs_for {
	my ($meta, $phase, $type, $module, $default) = @_;
	return $meta->effective_prereqs->requirements_for($phase, $type)->requirements_for_module($module) // $default // 0;
}

sub uptodate {
	my ($destination, @source) = @_;
	return if not -e $destination;
	for my $source (grep { defined && -e } @source) {
		return if -M $destination > -M $source;
	}
	return 1;
}

sub distfilename {
	my $distname = shift;
	return catfile('lib', split /-/, $distname) . '.pm';
}

sub generate_readme {
	my $distname = shift;
	my $filename = distfilename($distname);
	die "Main module file $filename doesn't exist\n" if not -f $filename;
	my $parser = Pod::Simple::Text->new;
	$parser->output_string( \my $content );
	$parser->parse_characters(1);
	$parser->parse_file($filename);
	return decode_utf8($content);
}

sub load_jsonyaml {
	my $file = shift;
	require Parse::CPAN::Meta;
	return Parse::CPAN::Meta->load_file($file);
}

sub load_mergedata {
	my $mergefile = shift;
	if (defined $mergefile and -r $mergefile) {
		return load_jsonyaml($mergefile);
	}
	return;
}

sub distname {
	my $extra = shift;
	return delete $extra->{name} if defined $extra->{name};
	return basename(rel2abs('.')) =~ s/ (?: ^ (?: perl|p5 ) - | [\-\.]pm $ )//xr;
}

sub detect_license {
	my ($data, $filename, $authors, $mergedata) = @_;
	if ($mergedata->{license} && @{$mergedata->{license}} == 1) {
		require Software::LicenseUtils;
		Software::LicenseUtils->VERSION(0.103014);
		my $spec_version = $mergedata->{'meta-spec'} && $mergedata->{'meta-spec'}{version} ? $mergedata->{'meta-spec'}{version} : 2;
		my @guess = Software::LicenseUtils->guess_license_from_meta_key($mergedata->{license}[0], $spec_version);
		die "Couldn't parse license from metamerge: @guess\n" if @guess > 1;
		if (@guess) {
			my $class = $guess[0];
			require_module($class);
			return $class->new({holder => join(', ', @{$authors})});
		}
	}
	my (@license_sections) = grep { /licen[cs]e|licensing|copyright|legal|authors?\b/i } $data->pod_inside;
	for my $license_section (@license_sections) {
		next unless defined ( my $license_pod = $data->pod($license_section) );
		require Software::LicenseUtils;
		Software::LicenseUtils->VERSION(0.103014);
		my $content = "=head1 LICENSE\n" . $license_pod;
		my @guess = Software::LicenseUtils->guess_license_from_pod($content);
		next if not @guess;
		die "Couldn't parse license from $license_section in $filename: @guess\n" if @guess != 1;
		my $class = $guess[0];
		my ($year) = $license_pod =~ /.*? copyright .*? ([\d\-]+)/;
		require_module($class);
		return $class->new({holder => join(', ', @{$authors}), year => $year});
	}
	die "No license found in $filename\n";
}

sub get_changes {
	my $self = shift;
	my $version = quotemeta $self->meta->version;
	open my $changes, '<:raw', 'Changes' or die "Couldn't open Changes file";
	my (undef, @content) = grep { / ^ $version (?:-TRIAL)? (?:\s+|$) /x ... /^\S/ } <$changes>;
	pop @content while @content && $content[-1] =~ / ^ (?: \S | \s* $ ) /x;
	return @content;
}

sub preflight_check {
	my ($self, %opts) = @_;

	die "Changes appears to be empty\n" if not $self->get_changes;

	my $meta_version = $self->{meta}->version;
	die "Version is still zero\n" if $meta_version eq '0.000';

	die "Abstract is not set\n" if $self->{meta}->abstract eq 'INSERT YOUR ABSTRACT HERE';

	if ($opts{tag}) {
		require Git::Wrapper;
		my $git = Git::Wrapper->new('.');

		die "Dirty state in repository\n" if $git->status->is_dirty;
		die "Tag v$meta_version already exists\n" if eval { $git->rev_parse({ quiet => 1, verify => 1}, "v$meta_version") };
	}

	my $module_name = $self->{meta}->name =~ s/-/::/gr;
	my $detected_version = $self->{data}->version($module_name);
	die sprintf "Version mismatch between module and meta, did you forgot to run regenerate? (%s versus %s)\n", $detected_version, $meta_version if $detected_version != $meta_version;
}

sub scan_files {
	my ($files, $omit) = @_;
	my $combined = CPAN::Meta::Requirements->new;
	require Perl::PrereqScanner;
	my $scanner = Perl::PrereqScanner->new;
	for my $file (@{$files}) {
		my $prereqs = $scanner->scan_file($file);
		$combined->add_requirements($prereqs);
	}
	$combined->clear_requirement($_) for @{$omit};
	return $combined
}

sub _scan_prereqs {
	my ($omit, %opts) = @_;
	my (@runtime_files, @test_files);
	File::Find::find(sub { push @runtime_files, $File::Find::name if -f && /\.pm$/ }, 'lib') if -d 'lib';
	File::Find::find(sub { push @runtime_files, $File::Find::name if -f }, 'script') if -d 'script';
	File::Find::find(sub { push @test_files, $File::Find::name if -f && /\.(t|pm)$/ }, 't') if -d 't';

	my $runtime = scan_files(\@runtime_files, $omit);
	my $test = scan_files(\@test_files, $omit);

	my $prereqs = CPAN::Meta::Prereqs->new({
		runtime   => { requires => $runtime->as_string_hash },
		test      => { requires => $test->as_string_hash },
		configure => { requires => { 'Module::Build::Tiny' => mbt_version() } },
	});
	require CPAN::Meta::Prereqs::Filter;
	return CPAN::Meta::Prereqs::Filter::filter_prereqs($prereqs, %opts);
}


sub scan_prereqs {
	my ($self, %opts) = @_;
	my @omit = (@{ $opts{omit} // [] }, keys %{ $self->{meta}->provides });
	return _scan_prereqs(\@omit, %opts);
}

sub load_prereqs {
	my ($provides, %opts) = @_;
	my @prereqs;
	if (-f 'prereqs.json') {
		push @prereqs, load_jsonyaml('prereqs.json');
	}
	if (-f 'prereqs.yml') {
		push @prereqs, load_jsonyaml('prereqs.yml');
	}
	if (-f 'cpanfile') {
		require Module::CPANfile;
		push @prereqs, Module::CPANfile->load('cpanfile')->prereq_specs;
	}
	if ($opts{scan}) {
		push @prereqs, _scan_prereqs([ keys %{$provides} ])->as_string_hash;
	}

	if (@prereqs == 1) {
		return $prereqs[0];
	}
	elsif (@prereqs == 0) {
		return {};
	}
	else {
		@prereqs = map { CPAN::Meta::Prereqs->new($_) } @prereqs;
		my $prereqs = $prereqs[0]->with_merged_prereqs([ @prereqs[1..$#prereqs] ]);
		$prereqs->as_string_hash;
	}
}

sub new {
	my ($class, %opts) = @_;
	my $mergefile = $opts{mergefile} // (grep { -f } qw/metamerge.json metamerge.yml/)[0];
	my $mergedata = load_mergedata($mergefile) // {};
	my $distname = distname($mergedata);
	my $filename = distfilename($distname);
	my $podname = $filename =~ s/\.pm$/.pod/r;

	my $data = Module::Metadata->new_from_file($filename, collect_pod => 1, decode_pod => 1) or die "Couldn't analyse $filename: $!";
	my $pod_data = -e $podname && Module::Metadata->new_from_file($podname, collect_pod => 1, decode_pod => 1) // $data;
	my @authors = map { s/E<([^>]+)>/e2char($1)/ge; m/ \A \s* (.+?) \s* \z /x } grep { /\S/ } split /\n/, $pod_data->pod('AUTHOR') // $pod_data->pod('AUTHORS') // '' or warn "Could not parse any authors from `=head1 AUTHOR` in $filename";
	my $license = detect_license($pod_data, $filename, \@authors, $mergedata);

	my $load_meta = !%{ $opts{regenerate} // {} } && uptodate('META.json', 'cpanfile', 'prereqs.json', 'prereqs.yml', $mergefile);
	my $meta = $load_meta ? CPAN::Meta->load_file('META.json', { lazy_validation => 0 }) : do {
		my ($abstract) = ($pod_data->pod('NAME') // '')  =~ / \A \s+ \S+ \s? - \s? (.+?) \s* \z /x or warn "Could not parse abstract from `=head1 NAME` in $filename";
		my $version = $data->version($data->name) // die "Cannot parse \$VERSION from $filename";

		my $provides = Module::Metadata->provides(version => 2, dir => 'lib');
		my $prereqs = load_prereqs($provides, %opts);
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
			release_status => $opts{trial} // $version =~ /_/ ? 'testing' : 'stable',
			generated_by   => "App::ModuleBuildTiny version $VERSION",
			'meta-spec'    => {
				version    => '2',
				url        => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec'
			},
			x_spdx_expression => $license->spdx_expression,
		};
		if (%{$mergedata}) {
			require CPAN::Meta::Merge;
			$metahash = CPAN::Meta::Merge->new(default_version => '2')->merge($metahash, $mergedata);
		}

		# this avoids a long-standing CPAN.pm bug that incorrectly merges runtime and
		# "build" (build+test) requirements by ensuring requirements stay unified
		# across all three phases
		require CPAN::Meta::Prereqs::Filter;
		my $filtered = CPAN::Meta::Prereqs::Filter::filter_prereqs(CPAN::Meta::Prereqs->new($metahash->{prereqs}), sanitize => 1);
		my $merged_prereqs = $filtered->merged_requirements([qw/runtime build test/], ['requires']);
		my %seen;
		for my $phase (qw/runtime build test/) {
			my $requirements = $filtered->requirements_for($phase, 'requires');
			for my $module ($requirements->required_modules) {
				$requirements->clear_requirement($module);
				next if $seen{$module}++;
				my $module_requirement = $merged_prereqs->requirements_for_module($module);
				$requirements->add_string_requirement($module => $module_requirement);
			}
		}
		$metahash->{prereqs} = $filtered->as_string_hash;

		$metahash->{provides} //= $provides if not $metahash->{no_index};
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
		my $minimum_perl = prereqs_for($meta, qw/runtime requires perl 5.008/);
		"# This Build.PL for $dist_name was generated by mbtiny $VERSION.\nuse $minimum_perl;\nuse Module::Build::Tiny $minimum_mbt;\nBuild_PL();\n";
	};
	$files{'META.json'} //= $meta->as_string;
	$files{'META.yml'} //= $meta->as_string({ version => 1.4 });
	$files{LICENSE} //= $license->fulltext;
	$files{README} //= generate_readme($dist_name);
	if ($opts{regenerate}{Changes}) {
		my $time = strftime("%Y-%m-%d %H:%M:%S%z", localtime);
		my $header = sprintf "%-9s %s\n", $meta->version, $time;
		$files{Changes} = read_text('Changes') =~ s/(?<=\n\n)/$header/er;
	}
	# This must come last
	$files{MANIFEST} //= join '', map { "$_\n" } sort keys %files;

	return bless {
		files => \%files,
		meta  => $meta,
		license => $license,
		data => $data,
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
	for my $filename ($self->files) {
		$arch->add_data($filename, $self->get_file($filename), { mode => oct '0644'} );
	}
	my $file = $name . ".tar.gz";
	$arch->write($file, &Archive::Tar::COMPRESS_GZIP, $name);
	return $file;
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

sub run {
	my ($self, %opts) = @_;
	require File::Temp;
	my $dir  = File::Temp::tempdir(CLEANUP => 1);
	$self->write_dir($dir, $opts{verbose});
	local $CWD = $dir;
	if ($opts{build}) {
		system $Config{perlpath}, 'Build.PL';
		system $Config{perlpath}, 'Build';
		my @extralib = map { rel2abs(catdir('blib', $_)) } 'arch', 'lib';
		local @PERL5LIB = (@extralib, @PERL5LIB);
		local @PATH = (rel2abs(catdir('blib', 'script')), @PATH);
		say join ' ', @{ $opts{command} } if $opts{verbose};
		return not system @{ $opts{command} };
	}
	else {
		say join ' ', @{ $opts{command} } if $opts{verbose};
		return not system @{ $opts{command} };
	}
}

for my $method (qw/meta license/) {
	no strict 'refs';
	*$method = sub { my $self = shift; return $self->{$method}; };
}

for my $method (qw/name version release_status/) {
	no strict 'refs';
	*$method = sub { my $self = shift; return $self->{meta}->$method; }
}

sub fullname {
	my $self = shift;
	my $trial = $self->release_status eq 'testing' && $self->version !~ /_/;
	return $self->meta->name . '-' . $self->meta->version . ($trial ? '-TRIAL' : '' );
}
1;
