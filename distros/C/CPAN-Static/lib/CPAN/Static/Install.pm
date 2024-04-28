package CPAN::Static::Install;
$CPAN::Static::Install::VERSION = '0.006';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/configure build test install supports_static_install opts_from_args_list opts_from_args_string/;
our %EXPORT_TAGS = (
	'all' => \@EXPORT_OK,
);

use CPAN::Meta;
use ExtUtils::Config 0.003;
use ExtUtils::Helpers 0.020 qw/make_executable split_like_shell man1_pagename man3_pagename detildefy/;
use ExtUtils::Install qw/pm_to_blib/;
use ExtUtils::InstallPaths 0.002;
use File::Basename qw/dirname/;
use File::Find ();
use File::Path qw/mkpath/;
use File::Spec::Functions qw/catfile catdir rel2abs abs2rel splitdir curdir/;
use Getopt::Long 2.36 qw/GetOptionsFromArray/;
use JSON::PP 2 qw/encode_json decode_json/;
use Scalar::Util 'blessed';

sub write_file {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or die "Could not open $filename: $!\n";
	print $fh $content;
}
sub read_file {
	my ($filename) = @_;
	open my $fh, '<', $filename or die "Could not open $filename: $!\n";
	return do { local $/; <$fh> };
}

my @getopt_flags = qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s config=s%
                      uninst:1 verbose:1 dry_run:1 pureperl-only:1 create_packlist=i jobs=i/;

sub opts_from_args_list {
	my (@args) = @_;
	GetOptionsFromArray(\@args, \my %result, @getopt_flags);
	return %result;
}

sub opts_from_args_string {
	my $arg = shift;
	my @args = defined $arg ? split_like_shell($arg) : ();
	return opts_from_args_list(@args);
}

sub supports_static_install {
	my $meta = shift;
	if (!$meta) {
		return undef unless -f 'META.json';
		$meta = CPAN::Meta->load_file('META.json');
	}
	my $static_version = $meta->custom('x_static_install') || 0;
	return $static_version == 1 ? $static_version : undef;
}

sub configure {
	my %args = @_;
	die "Unsupported static install version" if defined $args{static_version} and int $args{static_version} != 1;
	$args{config} = $args{config}->values_set if blessed($args{config});
	my $meta = CPAN::Meta->load_file('META.json');
	my %env = opts_from_args_string($ENV{PERL_MB_OPT});
	printf "Saving configuration for '%s' version '%s'\n", $meta->name, $meta->version;
	write_file('_static_build_params', encode_json([ \%env, \%args ]));
	$meta->save('MYMETA.json');
}

sub manify {
	my ($input_file, $output_file, $section, $opts) = @_;
	return if -e $output_file && -M $input_file <= -M $output_file;
	my $dirname = dirname($output_file);
	mkpath($dirname, $opts->{verbose}) if not -d $dirname;
	require Pod::Man;
	Pod::Man->new(section => $section)->parse_from_file($input_file, $output_file);
	print "Manifying $output_file\n" if $opts->{verbose} && $opts->{verbose} > 0;
	return;
}

sub find {
	my ($pattern, $dir) = @_;
	my @result;
	File::Find::find(sub { push @result, $File::Find::name if /$pattern/ && -f }, $dir) if -d $dir;
	return @result;
}

sub contains_pod {
	my ($file) = @_;
	return unless -T $file;
	return read_file($file) =~ /^\=(?:head|pod|item)/m;
}

sub hash_merge {
	my ($left, @others) = @_;
	my %result = %{$left};
	for my $right (@others) {
		for my $key (keys %$right) {
			$result{$key} = ref($right->{$key}) eq 'HASH' ? hash_merge($result{key}, $right->{key}) : $right->{$key};
		}
	}
	return %result;
}

sub get_opts {
	my %extra_opts = @_;
	my ($env, $bargv) = @{ decode_json(read_file('_static_build_params')) };
	my %options = hash_merge($env, $bargv, \%extra_opts);
	$_ = detildefy($_) for grep { defined } @options{qw/install_base destdir prefix/}, values %{ $options{install_path} };
	$options{meta} = CPAN::Meta->load_file('MYMETA.json');
	$options{config} = ExtUtils::Config->new($options{config});
	$options{install_paths} = ExtUtils::InstallPaths->new(%options, dist_name => $options{meta}->name);
	return %options;
}

sub build {
	my %extra_opts = @_;
	my %opt = get_opts(%extra_opts);
	my %modules = map { $_ => catfile('blib', $_) } find(qr/\.pm$/, 'lib');
	my %docs    = map { $_ => catfile('blib', $_) } find(qr/\.pod$/, 'lib');
	my %scripts = map { $_ => catfile('blib', $_) } find(qr/(?:)/, 'script');
	my %sdocs   = map { $_ => delete $scripts{$_} } grep { /.pod$/ } keys %scripts;
	my %dist_shared    = map { $_ => catfile(qw/blib lib auto share dist/, $opt{meta}->name, abs2rel($_, 'share')) } find(qr/(?:)/, 'share');
	my %module_shared  = map { $_ => catfile(qw/blib lib auto share module/, abs2rel($_, 'module-share')) } find(qr/(?:)/, 'module-share');
	pm_to_blib({ %modules, %docs, %scripts, %dist_shared, %module_shared }, catdir(qw/blib lib auto/));
	make_executable($_) for values %scripts;
	mkpath(catdir(qw/blib arch/), $opt{verbose});

	if ($opt{install_paths}->is_default_installable('bindoc')) {
		my $section = $opt{config}->get('man1ext');
		for my $input (keys %scripts, keys %sdocs) {
			next unless contains_pod($input);
			my $output = catfile('blib', 'bindoc', man1_pagename($input));
			manify($input, $output, $section, \%opt);
		}
	}
	if ($opt{install_paths}->is_default_installable('libdoc')) {
		my $section = $opt{config}->get('man3ext');
		for my $input (keys %modules, keys %docs) {
			next unless contains_pod($input);
			my $output = catfile('blib', 'libdoc', man3_pagename($input));
			manify($input, $output, $section, \%opt);
		}
	}
}

sub test {
	my %extra_opts = @_;
	my %opt = get_opts(%extra_opts);
	die "Must run `./Build build` first\n" if not -d 'blib';
	require TAP::Harness::Env;
	my %test_args = (
		(verbosity => $opt{verbose}) x!! exists $opt{verbose},
		(jobs => $opt{jobs}) x!! exists $opt{jobs},
		(color => 1) x !!-t STDOUT,
		lib => [ map { rel2abs(catdir(qw/blib/, $_)) } qw/arch lib/ ],
	);
	my $tester = TAP::Harness::Env->create(\%test_args);
	$tester->runtests(sort +find(qr/\.t$/, 't'))->has_errors and die "Tests failed";
}

sub install {
	my (%extra_opts) = @_;
	my %opt = get_opts(%extra_opts);
	die "Must run `./Build build` first\n" if not -d 'blib';
	ExtUtils::Install::install($opt{install_paths}->install_map, @opt{qw/verbose dry_run uninst/});
}

1;

# ABSTRACT: static CPAN installation reference implementation

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Static::Install - static CPAN installation reference implementation

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 if (my $static = supports_static_install($meta)) {
     configure(static_version => $static);
     ... install dependencies ...
     build;
     test;
     install;
 } else {
     ...
 }

=head1 DESCRIPTION

This module provides a reference implementation of the L<CPAN::Static::Spec|static CPAN install spec>.

=head1 FUNCTIONS

=head2 supports_static_install($meta)

This returns returns the version of the CPAN::Static spec for this dist. It returns undef if no version is declared or if the declared version is not supported. C<$meta> is a L<CPAN::Meta|CPAN::Meta> object, if undefined it will be loaded from F<META.json>.

=head2 configure(%options)

This function takes the following options, whose semantics are mostly described in detail in L<CPAN::API::BuildPL|CPAN::API::BuildPL>.

=over 4

=item * static_version

The version of the CPAN::Static spec to use, as returned by C<supports_static_install>.

=item * destdir

A string containing the destination directory

=item * installdirs

The type of installdirs, one of C<'site'>, C<'vendor'> or C<'core'>.

=item * install_base

The path to the install base.

=item * install_path

A hash describing the install path for different target types.

=item * uninst

A boolean value enabling uninstalling older versions.

=item * verbose

The verbosity of the actions.

=item * config

C<%Config> entries to be override. This should either be a hash of overrides, or an L<ExtUtils::Config|ExtUtils::Config> object.

=item * jobs

Suggest a certain number of jobs to be run in parallel.

=back

=head2 build()

This will build the dist.

=head2 test()

This will run the tests for the distribution.

=head2 install()

This will install the dist.

=head2 opts_from_args_list

This turns a list of arguments into a C<%options> hash for configure, the same way a Build.PL implementation would. It takes them as an array, e.g. C<( '--install_base', '~/foo')>.

=head2 opts_from_args_string

This turns a list of arguments into a C<%options> hash for configure, the same way a Build.PL implementation would. It takes them as an string, e.g. C<'--install_base ~/foo'>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
