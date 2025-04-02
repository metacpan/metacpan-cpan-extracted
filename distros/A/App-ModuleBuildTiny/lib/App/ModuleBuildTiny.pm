package App::ModuleBuildTiny;

use 5.014;
use warnings;
our $VERSION = '0.049';

use Exporter 5.57 'import';
our @EXPORT = qw/modulebuildtiny/;

use Config;
use CPAN::Meta;
use Data::Section::Simple 'get_data_section';
use Encode qw/encode_utf8 decode_utf8/;
use ExtUtils::Manifest 1.75 qw/manifind maniskip maniread/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath/;
use File::Slurper qw/write_text write_binary read_binary/;
use File::Spec::Functions qw/catfile rel2abs/;
use Getopt::Long 2.36 'GetOptionsFromArray';
use JSON::PP qw/decode_json/;
use Module::Runtime 'require_module';
use Text::Template;

use App::ModuleBuildTiny::Dist;

use Env qw/$AUTHOR_TESTING $RELEASE_TESTING $AUTOMATED_TESTING $EXTENDED_TESTING $NONINTERACTIVE_TESTING $SHELL $HOME $USERPROFILE/;

Getopt::Long::Configure(qw/require_order gnu_compat bundling/);

sub prompt {
	my($mess, $def) = @_;

	my $dispdef = defined $def ? " [$def]" : "";

	local $|=1;
	local $\;
	print "$mess$dispdef ";

	my $ans = <STDIN> // '';
	chomp $ans;
	return $ans ne '' ? decode_utf8($ans) : $def // '';
}

sub prompt_yn {
	my ($description, $default) = @_;
	my $result;
	do {
		$result = prompt("$description [y/n]", $default ? 'y' : 'n');
	} while (length $result and $result !~ /^(y|n|-)/i);
	return lc(substr $result, 0 , 1) eq 'y';
}

sub create_license_for {
	my ($license_name, $author) = @_;
	my $module = "Software::License::$license_name";
	require_module($module);
	return $module->new({ holder => $author });
}

sub fill_in {
	my ($template, $hash) = @_;
	return Text::Template->new(TYPE => 'STRING', SOURCE => $template)->fill_in(HASH => $hash);
}

sub write_module {
	my %opts = @_;
	my $template = get_data_section('Module.pm') =~ s/ ^ % (\w+) /=$1/gxmsr;
	my $filename = catfile('lib', split /::/, $opts{module_name}) . '.pm';
	my $content = fill_in($template, \%opts);
	mkpath(dirname($filename));
	write_text($filename, $content);
	return $filename;
}

sub write_changes {
	my %opts = @_;
	my $template = get_data_section('Changes');
	my $content = fill_in($template, \%opts);
	write_text('Changes', $content);
}

sub write_maniskip {
	my $distname = shift;
	write_text('MANIFEST.SKIP', "#!include_default\n$distname-.*\nREADME.pod\n");
}

sub write_readme {
	my %opts = @_;
	my $template = get_data_section('README');
	write_text('README', fill_in($template, \%opts));
}

sub read_json {
	my $filename = shift;
	-f $filename or return;
	return decode_json(read_binary($filename));
}

sub write_json {
	my ($filename, $content) = @_;
	my $dirname = dirname($filename);
	mkdir $dirname if not -d $dirname;
	my $json = JSON::PP->new->utf8->pretty->canonical->encode($content);
	return write_binary($filename, $json);
}

sub bump_versions {
	my (%opts) = @_;
	require App::RewriteVersion;
	my $app = App::RewriteVersion->new(%opts);
	my $trial = delete $opts{trial};
	my $new_version = defined $opts{version} ? delete $opts{version} : $app->bump_version($app->current_version);
	$app->rewrite_versions($new_version, is_trial => $trial);
}

sub insert_options {
	my ($opts, $config) = @_;
	$opts->{add_repository} = !!$config->{auto_repo};
	$opts->{add_bugtracker} = !!$config->{auto_tracker};
}

sub regenerate {
	my ($files, $config, %opts) = @_;
	my %files = map { $_ => 1 } @{$files};
	my @dirty = @{$files};

	if ($opts{bump}) {
		bump_versions(%opts);
		$files{'Changes'}++;
		push @dirty, 'Changes';
	}

	insert_options(\%opts, $config);
	my $dist = App::ModuleBuildTiny::Dist->new(%opts, regenerate => \%files);
	my @generated = grep { $files{$_} } $dist->files;
	for my $filename (@generated) {
		say "Updating $filename" if $opts{verbose};
		write_binary($filename, $dist->get_file($filename)) if !$opts{dry_run};
	}

	if ($opts{commit}) {
		require Git::Wrapper;
		my $git = Git::Wrapper->new('.');
		if ($opts{bump}) {
			push @dirty, 'lib';
			push @dirty, 'script' if -d 'script';
		}
		my $allowed = join '|', map qr{^\Q$_\E$}, @dirty;
		my @modified = grep /$allowed/, $git->ls_files({ modified => 1 });

		if (@modified) {
			my @changes = $dist->get_changes;
			my $version = 'v' . $dist->version;
			my $message = $opts{message} || ($opts{bump} ? join '', $version, "\n\n", @changes : 'Regenerate');
			$git->commit({ m => $message }, @dirty);
		} else {
			say "No modifications to commit";
		}
	}
}

my %prompt_for = (
	open => \&prompt,
	yn => \&prompt_yn,
);

my @config_items = (
	[ 'author'       , 'What is the author\'s name?', 'open' ],
	[ 'email'        , 'What is the author\'s email?', 'open',  ],
	[ 'license'      , 'What license do you want to use?', 'open', 'Perl_5' ],

	[ 'write_build'  , 'Do you want to write your build files to your filesystem?', 'yn', !!1],
	[ 'write_license', 'Do you want to write your LICENSE file to your filesystem?', 'yn', !!1],
	[ 'write_readme' , 'Do you want to write your README file to your filesystem?', 'yn', !!1],

	[ 'auto_git'     , 'Do you want mbtiny to automatically handle git for you?', 'yn', !!1 ],
	[ 'auto_bump'    , 'Do you want mbtiny to automatically bump on regenerate for you?', 'yn', !!1 ],
	[ 'auto_scan'    , 'Do you want mbtiny to automatically scan dependencies for you?', 'yn', !!1 ],
	[ 'auto_repo'    , 'Do you want mbtiny to automatically add a repository link to the metadata', 'yn', !!1 ],
	[ 'auto_tracker' , 'Do you want mbtiny to automatically add a bugtracker link to the metadata', 'yn', !!1 ],
);

sub ask {
	my ($config, $item, $local_default) = @_;
	my ($key, $description, $type, $global_default) = @{$item};
	my $value = $prompt_for{$type}->($description, $local_default // $global_default);

	if ($value ne '-') {
		$config->{$key} = $type eq 'open' ? $value : $value ? $JSON::PP::true : $JSON::PP::false;
	}
	else {
		delete $config->{$key};
	}
}

sub show_item {
	my ($config, $key, $type) = @_;
	return defined $config->{$key} ? $type eq 'open' ? $config->{$key} : $config->{$key} ? 'true' : 'false' : '(undefined)';
}

sub get_settings_file {
	local $HOME = $USERPROFILE if $^O eq 'MSWin32';
	return catfile(glob('~'), qw/.mbtiny conf/);
}

my %default_settings = (
	auto_bump     => 1,
	auto_git      => 1,
	auto_scan     => 1,

	write_build   => 1,
	write_license => 1,
	write_readme  => 1,
);

sub get_settings {
	my $default = shift // {};
	my $settings_file = get_settings_file;
	my $settings = -f $settings_file ? read_json($settings_file) : $default;
	for my $item (@config_items) {
		my ($key, $description, $type, $default) = @{$item};
		next unless exists $settings->{$key};
		next unless $type eq 'yn';
		$settings->{$key} = !!$settings->{$key};
	}
	return $settings;
}

my $config_file = 'dist.json';

sub get_config {
	my $config = -f $config_file ? read_json($config_file) : {};
	for my $item (@config_items) {
		my ($key, $description, $type, $default) = @{$item};
		next unless exists $config->{$key};
		next unless $type eq 'yn';
		$config->{$key} = !!$config->{$key};
	}
	return $config;
}

sub extra_tests {
	my @dirs;
	if ($AUTHOR_TESTING) {
		push @dirs, 'xt/author';
		push @dirs, glob 'xt/*.t';
	}
	push @dirs, 'xt/release' if $RELEASE_TESTING;
	push @dirs, 'xt/extended' if $EXTENDED_TESTING;
	return grep -e, @dirs;
}

my @build_files = qw/Build.PL META.json META.yml MANIFEST/;

sub regenerate_files {
	my $config = shift;
	my @result;
	push @result, @build_files if $config->{write_build}   // 1;
	push @result, 'LICENSE'    if $config->{write_license} // 1;
	push @result, 'README'     if $config->{write_readme}  // 1;
	return @result;
}

my %boolean = (
	true  => !!1,
	false => !!0,
);

my %actions = (
	dist => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, \my %opts, qw/trial verbose!/) or return 2;
		my $dist = App::ModuleBuildTiny::Dist->new(%opts);
		insert_options(\%opts, get_config);
		die "Trial mismatch" if $opts{trial} && $dist->release_status ne 'testing';
		$dist->preflight_check(%opts);
		my $filename = $dist->archivename;
		printf "tar czf %s %s\n", $filename, join ' ', $dist->files if $opts{verbose};
		$dist->write_tarball($filename);
		return 0;
	},
	distdir => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, \my %opts, qw/trial verbose!/) or return 2;
		insert_options(\%opts, get_config);
		my $dist = App::ModuleBuildTiny::Dist->new(%opts);
		$dist->write_dir($dist->fullname, $opts{verbose});
		return 0;
	},
	test => sub {
		my @arguments = @_;
		$AUTHOR_TESTING = 1;
		GetOptionsFromArray(\@arguments, 'release!' => \$RELEASE_TESTING, 'author!' => \$AUTHOR_TESTING, 'automated!' => \$AUTOMATED_TESTING,
			'extended!' => \$EXTENDED_TESTING, 'non-interactive!' => \$NONINTERACTIVE_TESTING, 'jobs|j=i' => \my $jobs, 'inc|I=s@' => \my @inc)
			or return 2;
		insert_options(\my %opts, get_config);
		my $dist = App::ModuleBuildTiny::Dist->new(%opts);
		my @args;
		push @args, '-j', $jobs if defined $jobs;
		push @args, map {; '-I', rel2abs($_) } @inc;
		push @args, 't' if -e 't';
		push @args, extra_tests();
		return $dist->run(commands => [ [ 'prove', '-br', @args ] ], build => 1, verbose => 1);
	},
	upload => sub {
		my @arguments = @_;
		my $config = get_config;
		my %opts = $config->{auto_git} ? (tag => 1, push => '') : ();
		GetOptionsFromArray(\@arguments, \%opts, qw/trial config=s silent tag! push:s nopush|no-push/) or return 2;
		insert_options(\%opts, get_config);

		my $dist = App::ModuleBuildTiny::Dist->new;
		$dist->preflight_check(%opts);
		local ($AUTHOR_TESTING, $RELEASE_TESTING) = (1, 1);
		my @commands = ([ './Build', 'test' ]);
		my @extra_tests = extra_tests;
		push @commands, [ 'prove', '-br', @extra_tests ] if @extra_tests;
		$dist->run(commands => \@commands, build => 1, verbose => !$opts{silent}) or return 1;

		my $sure = prompt_yn('Do you want to continue the release process?', !!0);
		if ($sure) {
			my $file = $dist->write_tarball($dist->archivename);
			require CPAN::Upload::Tiny;
			CPAN::Upload::Tiny->VERSION('0.009');
			my $uploader = CPAN::Upload::Tiny->new_from_config_or_stdin($opts{config});
			$uploader->upload_file($file);
			print "Successfully uploaded $file\n" if not $opts{silent};

			if ($opts{tag}) {
				require Git::Wrapper;
				my $git = Git::Wrapper->new('.');
				my $version = 'v' . $dist->version;
				$git->tag('-m' => $version, $version);
			}

			if (defined $opts{push} and not $opts{nopush}) {
				require Git::Wrapper;
				my $git = Git::Wrapper->new('.');

				my @remote = length $opts{push} ? $opts{push} : ();
				$git->push(@remote);
				$git->push({ tags => 1 }, @remote) if $opts{tag};
			}
		}
		return 0;
	},
	run => sub {
		my @arguments = @_;
		die "No arguments given to run\n" if not @arguments;
		GetOptionsFromArray(\@arguments, 'build!' => \(my $build = 1)) or return 2;
		insert_options(\my %opts, get_config);
		my $dist = App::ModuleBuildTiny::Dist->new(%opts);
		return $dist->run(commands => [ \@arguments ], build => $build, verbose => 1);
	},
	shell => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, 'build!' => \my $build) or return 2;
		insert_options(\my %opts, get_config);
		my $dist = App::ModuleBuildTiny::Dist->new(%opts);
		return $dist->run(commands => [ [ $SHELL ] ], build => $build, verbose => 0);
	},
	listdeps => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, \my %opts, qw/json only_missing|only-missing|missing omit_core|omit-core=s author versions/) or return 2;
		insert_options(\%opts, get_config);
		my $dist = App::ModuleBuildTiny::Dist->new(%opts);

		require CPAN::Meta::Prereqs::Filter;
		my $prereqs = CPAN::Meta::Prereqs::Filter::filter_prereqs($dist->meta->effective_prereqs, %opts);

		if (!$opts{json}) {
			my @phases = qw/build test configure runtime/;
			push @phases, 'develop' if $opts{author};

			my $reqs = $prereqs->merged_requirements(\@phases);
			$reqs->clear_requirement('perl');

			my @modules = sort { lc $a cmp lc $b } $reqs->required_modules;
			if ($opts{versions}) {
				say "$_ = ", $reqs->requirements_for_module($_) for @modules;
			}
			else {
				say for @modules;
			}
		}
		else {
			require JSON::PP;
			print JSON::PP->new->ascii->canonical->pretty->encode($prereqs->as_string_hash);
		}
		return 0;
	},
	regenerate => sub {
		my @arguments = @_;
		my $config = get_config;
		my %opts;
		GetOptionsFromArray(\@arguments, \%opts, qw/trial bump! version=s verbose dry_run|dry-run commit! scan! message=s/) or return 2;
		my @files = @arguments ? @arguments : regenerate_files($config);
		if (!@arguments) {
			$opts{bump}   //= $config->{auto_bump};
			$opts{commit} //= $config->{auto_git};
			$opts{scan}   //= $config->{auto_scan};
		}

		regenerate(\@files, $config, %opts);

		return 0;
	},
	scan => sub {
		my @arguments = @_;
		my %opts = (sanitize => 1);
		GetOptionsFromArray(\@arguments, \%opts, qw/omit_core|omit-core=s sanitize! omit=s@/) or return 2;
		insert_options(\%opts, get_config);
		my $dist = App::ModuleBuildTiny::Dist->new(%opts, regenerate => { 'META.json' => 1 });
		my $prereqs = $dist->scan_prereqs(%opts);
		write_json('prereqs.json', $prereqs->as_string_hash);
		return 0;
	},
	setup => sub {
		my @arguments = @_;
		my $config_file = get_settings_file();
		my $config = -f $config_file ? read_json($config_file) : {};

		my $mode = @arguments ? shift @arguments : 'upgrade';

		if ($mode eq 'upgrade') {
			for my $item (@config_items) {
				next if defined $config->{ $item->[0] };
				ask($config, $item);
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'minimal') {
			for my $item (@config_items) {
				next if defined $config->{ $item->[0] };
				if (defined $item->[3]) {
					$config->{ $item->[0] } = $item->[3];
				} else {
					ask($config, $item);
				}
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'all') {
			for my $item (@config_items) {
				ask($config, $item, $config->{ $item->[0] });
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'get') {
			my ($key, $value) = @arguments;
			my ($item) = grep { $_->[0] eq $key } @config_items;
			die "No such known key $key" if not $item;
			my (undef, $description, $type, $default) = @{$item};
			say show_item($config, $key, $type);
		}
		elsif ($mode eq 'set') {
			my ($key, $value) = @arguments;
			my $item = grep { $_->[0] eq $key } @config_items;
			die "No such known key $key" if not $item;
			if ($item->[2] eq 'yn') {
				$config->{$key} = $boolean{$value} // die "Unknown boolean value '$value'\n";
			} else {
				$config->{$key} = $value;
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'list') {
			for my $item (@config_items) {
				my ($key, $description, $type, $default) = @{$item};
				say "\u$key: " . show_item($config, $key, $type);
			}
		}
		elsif ($mode eq 'reset') {
			return not unlink $config_file;
		}
		return 0;
	},
	config => sub {
		my @arguments = @_;
		my $settings = get_settings;
		my $config = get_config;

		my $mode = @arguments ? shift @arguments : 'upgrade';

		my @items = grep { $_->[2] ne 'open' } @config_items;
		if ($mode eq 'upgrade') {
			for my $item (@items) {
				next if defined $config->{ $item->[0] };
				ask($config, $item, $settings->{ $item->[0] });
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'all') {
			for my $item (@items) {
				my $default = $config->{ $item->[0] } // $settings->{ $item->[0] };
				ask($config, $item, $default);
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'copy') {
			for my $item (@items) {
				my ($key) = @{$item};
				$config->{$key} = $settings->{$key} if exists $settings->{$key};
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'get') {
			my ($key, $value) = @arguments;
			my ($item) = grep { $_->[0] eq $key } @config_items;
			die "No such known key $key" if not $item;
			my (undef, $description, $type, $default) = @{$item};
			say show_item($config, $key, $type);
		}
		elsif ($mode eq 'set') {
			my ($key, $value) = @arguments;
			my $item = grep { $_->[0] eq $key } @config_items;
			die "No such known key $key" if not $item;
			$config->{$key} = $boolean{$value} // die "Unknown boolean value '$value'\n";
			write_json($config_file, $config);
		}
		elsif ($mode eq 'list') {
			for my $item (@items) {
				my ($key, $description, $type, $default) = @{$item};
				say "\u$key: " . show_item($config, $key, $type);
			}
		}
		elsif ($mode eq 'reset') {
			return not unlink $config_file;
		}
		return 0;
	},
	mint => sub {
		my @arguments = @_;

		my $settings = get_settings(\%default_settings);

		my $distname = decode_utf8(shift @arguments // die "No distribution name given\n") =~ s/::/-/gr;

		my %args = (
			author   => $settings->{author},
			email    => $settings->{email},
			license  => $settings->{license},
			version  => '0.000',
			dirname  => $distname,
			abstract => 'INSERT YOUR ABSTRACT HERE',
			init_git => $settings->{auto_git},
		);
		my %config;
		my @options = qw/version=s abstract=s dirname=s init_git|init-git/;
		for my $config_item (@config_items) {
			my $entry = $config_item->[0] =~ s{^(\w+_\w+)\K$}{ '|' . $1 =~ tr/_/-/r }er;
			push @options, $entry . ($config_item->[2] eq 'yn' ? '!' : '=s');
		}
		GetOptionsFromArray(\@arguments, \%args, @options) or return 2;
		for my $item (@config_items) {
			my ($key, $description, $type, $default) = @{$item};
			if ($type eq 'open') {
				$args{$key} //= prompt($description, $default);
			}
			else {
				$config{$key} = $args{$key} // $settings->{$key} // prompt_yn($description, $default);
			}
		}

		my $license = create_license_for(delete $args{license}, $args{author});

		die "Directory $args{dirname} already exists\n" if -e $args{dirname};
		mkdir $args{dirname};
		chdir $args{dirname};
		$args{module_name} = $distname =~ s/-/::/gr;

		my $module_file = write_module(%args, notice => $license->notice);
		write_changes(%args, distname => $distname);
		write_maniskip($distname);
		write_json('dist.json', \%config);
		mkdir 't';

		write_json('metamerge.json', { name => $distname }) if $distname ne $args{dirname};

		my @regenerate_files = regenerate_files(\%config);
		regenerate(\@regenerate_files, \%args, scan => $config{auto_scan});

		if ($args{init_git}) {
			my $ignore = join "\n", qw/*.bak *.swp *.swo *.tdy *.tar.gz/, "$distname-*", '';
			write_text('.gitignore', $ignore);

			require Git::Wrapper;
			my $git = Git::Wrapper->new('.');
			$git->init;
			$git->add(@regenerate_files, 'Changes', 'MANIFEST.SKIP', 'dist.json', '.gitignore', $module_file, grep -e, 'metamerge.json');
			$git->commit({ message => 'Initial commit' });
		}

		return 0;
	},
	version => sub {
		say $VERSION;
	},
);

sub modulebuildtiny {
	my ($action, @arguments) = @_;
	die "No action given\n" unless defined $action;
	my $call = $actions{$action};
	die "No such action '$action' known\n" if not $call;
	return $call->(@arguments);
}

1;

=head1 NAME

App::ModuleBuildTiny - A standalone authoring tool for Module::Build::Tiny and Dist::Build

=head1 DESCRIPTION

App::ModuleBuildTiny contains the implementation of the L<mbtiny> tool.

=head1 FUNCTIONS

=over 4

=item * modulebuildtiny($action, @arguments)

This function runs a modulebuildtiny command. It expects at least one argument: the action. It may receive additional ARGV style options dependent on the command.

The actions are documented in the L<mbtiny> documentation.

=back

=head1 SEE ALSO

=head2 Similar programs

=over 4

=item * L<Dist::Zilla|Dist::Zilla>

An extremely powerful but somewhat heavy authoring tool.

=item * L<Minilla|Minilla>

A more minimalistic than Dist::Zilla but still somewhat customizable authoring tool.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ Changes
Revision history for {{ $distname }}

          - Initial release to an unsuspecting world

@@ Module.pm
package {{ $module_name }};

use strict;
use warnings;

our $VERSION = '{{ $version }}';

1;

{{ '__END__' }}

%pod

%encoding utf-8

%head1 NAME

{{ $module_name }} - {{ $abstract }}

%head1 DESCRIPTION

Write a full description of the module and its features here.

%head1 AUTHOR

{{ $author }} <{{ $email }}>

%head1 COPYRIGHT AND LICENSE

{{ $notice }}

