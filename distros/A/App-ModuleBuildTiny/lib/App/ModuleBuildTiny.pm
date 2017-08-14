package App::ModuleBuildTiny;

use 5.010;
use strict;
use warnings;
our $VERSION = '0.022';

use Exporter 5.57 'import';
our @EXPORT = qw/modulebuildtiny/;

use Carp qw/croak/;
use Config;
use CPAN::Meta;
use Data::Section::Simple 'get_data_section';
use Encode qw/encode_utf8 decode_utf8/;
use ExtUtils::Manifest qw/manifind maniskip maniread/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath/;
use File::Slurper qw/write_text write_binary read_binary/;
use File::Spec::Functions qw/catfile catdir rel2abs/;
use Getopt::Long 2.36 'GetOptionsFromArray';
use JSON::PP qw/encode_json decode_json/;
use Module::Runtime 'require_module';
use Pod::Simple::Text 3.23;
use Text::Template;

use App::ModuleBuildTiny::Dist;

use Env qw/$AUTHOR_TESTING $RELEASE_TESTING $AUTOMATED_TESTING $SHELL $HOME $USERPROFILE/;

Getopt::Long::Configure(qw/require_order pass_through gnu_compat/);

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
	my $template = get_data_section('Module.pm');
	$template =~ s/ ^ % (\w+) /=$1/gxms;
	my $filename = catfile('lib', split /::/, $opts{module_name}) . '.pm';
	my $content = fill_in($template, \%opts);
	mkpath(dirname($filename));
	write_text($filename, $content);
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
	maniskip(); # This expands the #!include_default as a side-effect
	unlink 'MANIFEST.SKIP.bak' if -f 'MANIFEST.SKIP.bak';
}

sub write_readme {
	my %opts = @_;
	my $template = get_data_section('README');
	write_text('README', fill_in($template, \%opts));
}

sub get_home {
	local $HOME = $USERPROFILE if $^O eq 'MSWin32';
	return glob '~';
}

sub get_config {
	return catfile(get_home(), qw/.mbtiny conf/);
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
	return write_binary($filename, encode_json($content));
}

my @config_items = (
	[ 'author'  , 'What is the author\'s name?' ],
	[ 'email'   , 'What is the author\'s email?' ],
	[ 'license' , 'What license do you want to use?', 'Perl_5' ],
);

my %actions = (
	dist => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, 'verbose!' => \my $verbose);
		my $dist = App::ModuleBuildTiny::Dist->new;
		my $name = $dist->meta->name . '-' . $dist->meta->version;
		printf "tar czf $name.tar.tz %s\n", join ' ', $dist->files if ($verbose || 0) > 0;
		$dist->write_tarball($name);
		return 0;
	},
	distdir => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, 'verbose!' => \my $verbose);
		my $dist = App::ModuleBuildTiny::Dist->new;
		$dist->write_dir($dist->meta->name . '-' . $dist->meta->version, $verbose);
		return 0;
	},
	test => sub {
		my @arguments = @_;
		$AUTHOR_TESTING = 1;
		GetOptionsFromArray(\@arguments, 'release!' => \$RELEASE_TESTING, 'author!' => \$AUTHOR_TESTING, 'automated!' => \$AUTOMATED_TESTING);
		my $dist = App::ModuleBuildTiny::Dist->new;
		return $dist->run(command => [ $Config{perlpath}, 'Build', 'test' ], build => 1);
	},
	upload => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, 'config=s' => \my $config_file, 'silent' => \my $silent);

		my $dist = App::ModuleBuildTiny::Dist->new;
		$dist->run(command => [ $Config{perlpath}, 'Build', 'test' ], build => 1) or return 1;
		my $name = $dist->meta->name . '-' . $dist->meta->version;
		my $file = $dist->write_tarball($name);
		require CPAN::Upload::Tiny;
		my $uploader = CPAN::Upload::Tiny->new_from_config($config_file);
		$uploader->upload_file($file);
		print "Successfully uploaded $file\n" if not $silent;
		return 0;
	},
	run => sub {
		my @arguments = @_;
		croak "No arguments given to run" if not @arguments;
		GetOptionsFromArray(\@arguments, 'build!' => \(my $build = 1));
		my $dist = App::ModuleBuildTiny::Dist->new();
		return $dist->run(command => \@arguments, build => $build);
	},
	shell => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, 'build!' => \my $build);
		my $dist = App::ModuleBuildTiny::Dist->new();
		return $dist->run(command => [ $SHELL ], build => $build);
	},
	listdeps => sub {
		my @arguments = @_;
		GetOptionsFromArray(\@arguments, \my %opts, qw/json only_missing|only-missing|missing omit_core|omit-core=s author versions/);
		my $dist = App::ModuleBuildTiny::Dist->new;

		require CPAN::Meta::Prereqs::Filter;
		my $prereqs = CPAN::Meta::Prereqs::Filter::filter_prereqs($dist->meta->effective_prereqs, %opts, sanitize => 1);

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
			print JSON::PP->new->ascii->pretty->encode($prereqs->as_string_hash);
		}
		return 0;
	},
	regenerate => sub {
		my @arguments = @_;
		my %files = map { $_ => 1 } @arguments ? @arguments : qw/Build.PL META.json META.yml MANIFEST LICENSE README/;

		my $dist = App::ModuleBuildTiny::Dist->new(regenerate => \%files);
		for my $filename ($dist->files) {
			write_text($filename, $dist->get_file($filename)) if $dist->is_generated($filename);
		}
		return 0;
	},
	configure => sub {
		my @arguments = @_;
		my $home = get_home;
		my $config_file = catfile($home, qw/.mbtiny conf/);

		my $mode = @arguments ? $arguments[0] : 'upgrade';

		if ($mode eq 'upgrade') {
			my $config = -f $config_file ? read_json($config_file) : {};
			for my $item (@config_items) {
				my ($key, $description, $default) = @{$item};
				next if defined $config->{$key};
				$config->{$key} = prompt($description, $default);
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'all') {
			my $config = {};
			for my $item (@config_items) {
				my ($key, $description, $default) = @{$item};
				$config->{$key} = prompt($description, $default);
			}
			write_json($config_file, $config);
		}
		elsif ($mode eq 'reset') {
			return not unlink $config_file;
		}
		return 0;
	},
	mint => sub {
		my @arguments = @_;

		my $config_file = get_config();
		croak "No config file present, please run mbtiny configure" if not -f $config_file;
		my $config = read_json($config_file);
		croak "Config not readable, please run mbtiny configure" if not defined $config;

		my $distname = decode_utf8(shift @arguments || croak 'No distribution name given');
		croak "Directory $distname already exists" if -e $distname;

		my %args = (
			%{ $config },
			version => '0.001',
			dirname => $distname,
		);
		GetOptionsFromArray(\@arguments, \%args, qw/author=s email=s version=s abstract=s license=s dirname=s/);

		my $license = create_license_for(delete $args{license}, $args{author});

		mkdir $args{dirname};
		chdir $args{dirname};
		($args{module_name} = $distname) =~ s/-/::/g; # 5.014 for s///r?

		write_module(%args, notice => $license->notice);
		write_text('LICENSE', $license->fulltext);
		write_changes(%args, distname => $distname);
		write_maniskip($distname);

		return 0;
	},
);

sub modulebuildtiny {
	my ($action, @arguments) = @_;
	croak 'No action given' unless defined $action;
	my $call = $actions{$action};
	croak "No such action '$action' known\n" if not $call;
	return $call->(@arguments);
}

1;

=head1 NAME

App::ModuleBuildTiny - A standalone authoring tool for Module::Build::Tiny

=head1 VERSION

version 0.022

=head1 DESCRIPTION

App::ModuleBuildTiny contains the implementation of the L<mbtiny> tool.

=head1 FUNCTIONS

=over 4

=item * modulebuildtiny($action, @arguments)

This function runs a modulebuildtiny command. It expects at least one argument: the action. It may receive additional ARGV style options dependent on the command.

The actions are documented in the L<mbtiny> documentation.

=back

=head1 SEE ALSO

=head2 Helpers

=over 4

=item * L<scan-prereqs-cpanfile|scan-prereqs-cpanfile>

A tool to automatically generate a L<cpanfile> for you.

=item * L<cpan-upload|cpan-upload>

A program that facilitates upload the tarball as produced by C<mbtiny>.

=item * L<perl-reversion|perl-reversion>

A tool to bump the version in your modules.

=item * L<perl-bump-version|perl-bump-version>

An alternative tool to bump the version in your modules

=back

=head2 Similar programs

=over 4

=item * L<Dist::Zilla|Dist::Zilla>

An extremely powerful but somewhat heavy authoring tool.

=item * L<Minilla|Minilla>

A more minimalistic but still somewhat customizable authoring tool.

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

{{ $version }}
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

%head1 VERSION

{{ $version }}

%head1 DESCRIPTION

Write a full description of the module and its features here.

%head1 AUTHOR

{{ $author }} <{{ $email }}>

%head1 COPYRIGHT AND LICENSE

{{ $notice }}

