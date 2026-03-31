#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(is like);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

sub _app {
	my (%p) = @_;
	App::prepare4release->new(
		config   => $p{config} // {},
		opts     => $p{opts} // {},
		identity => {
			module_name => $p{module} // 'Foo::Bar',
			dist_name   => $p{dist}   // 'Foo-Bar',
			%{ $p{identity} // {} },
		},
	);
}

is( App::prepare4release->DEFAULT_CONFIG_FILENAME, 'prepare4release.json',
	'DEFAULT_CONFIG_FILENAME' );

is( scalar keys %{ App::prepare4release->git_hash( {} ) }, 0,
	'git_hash empty' );
is( scalar keys %{ App::prepare4release->git_hash( { git => 'bad' } ) },
	0, 'git_hash non-hash git' );

is( App::prepare4release->https_base('example.com'), 'https://example.com',
	'https_base' );

is( App::prepare4release->package_to_repo_default('Foo::Bar'),
	'perl-Foo-Bar', 'package_to_repo_default' );

is( App::prepare4release->effective_git_host( { gitlab => 1 }, {} ),
	'gitlab.com', 'effective_git_host gitlab default' );
is( App::prepare4release->effective_git_host( {}, {} ),
	'github.com', 'effective_git_host github default' );
is( App::prepare4release->effective_git_host(
		{}, { git => { server => 'g.example.org' } } ),
	'g.example.org', 'effective_git_host server' );

my $seg1 = _app( config => { git => { repo => 'ns/proj' } } );
is( $seg1->repository_path_segment, 'ns/proj', 'repo segment ns/proj' );

my $seg2 = _app(
	config => { git => { author => 'me', repo => 'shortname' } } );
is( $seg2->repository_path_segment, 'me/shortname', 'author + short repo' );

my $seg3 = _app(
	config => { git => { author => 'me' } },
	module => 'Foo::Bar'
);
is( $seg3->repository_path_segment, 'me/perl-Foo-Bar',
	'author + default repo name' );

my $web = _app(
	config => { git => { author => 'u', repo => 'r' } },
	opts   => { github => 1 }
);
like( $web->repository_web_url, qr{^https://github\.com/u/r\z},
	'repository_web_url github' );
like( $web->repository_git_url, qr{\.git\z}, 'repository_git_url' );

my $bug = _app( config => { bugtracker => 'https://bt.example/issue' } );
is( $bug->bugtracker_url, 'https://bt.example/issue', 'bugtracker override' );

is( App::prepare4release->cpan_dist_name_from_identity(
		{ module_name => 'X::Y', dist_name => '' }
	),
	'X-Y',
	'cpan_dist_name from module_name'
);

like(
	App::prepare4release->repology_metacpan_badge_url('My-Dist'),
	qr/repology\.org.*metacpan/,
	'repology badge url'
);

my @unk = App::prepare4release->license_badge_info('totally_unknown');
is( $unk[0], 'License', 'unknown license label' );

is( App::prepare4release->infer_license_key_from_text('The Perl 5 License'),
	'perl', 'infer perl license text' );
is( App::prepare4release->infer_license_key_from_text('MIT License'),
	'mit', 'infer MIT' );
ok( !App::prepare4release->infer_license_key_from_text(''),
	'infer empty' );

is( App::prepare4release->_metacpan_perl_version_to_ceiling_tag('5.042002'),
	'5.42', 'ceiling from decimal version' );
is( App::prepare4release->_metacpan_perl_version_to_ceiling_tag('v5.8.1'),
	'5.8', 'ceiling from v5.8.1' );

{
	local $ENV{PREPARE4RELEASE_PERL_MAX} = '5.36';
	is( App::prepare4release->fetch_latest_perl_release_version,
		'5.36', 'fetch_latest respects env' );
	delete $ENV{PREPARE4RELEASE_PERL_MAX};
}

is( App::prepare4release->resolve_min_perl_for_badge(
		{ min_perl_version => '5.22.0' }, '', undef
	),
	'v5.22.0',
	'resolve_min_perl_for_badge from json'
);
is( App::prepare4release->resolve_min_perl_for_badge(
		{ perl_min => '5.18.0' }, '', undef
	),
	'v5.18.0',
	'resolve_min_perl_for_badge perl_min alias'
);

is( App::prepare4release->perl_min_badge_label('v5.26.0'),
	'5.26%2B', 'perl_min_badge_label' );
is( App::prepare4release->perl_min_badge_label(''),
	'5.10%2B', 'perl_min_badge_label empty' );

my $glp = _app(
	config => {
		git => {
			repo   => 'https://gitlab.example.com/g/p',
			author => 'ignored'
		}
	},
	opts => { gitlab => 1 }
);
is( App::prepare4release->gitlab_ci_badge_host($glp),
	'gitlab.example.com', 'gitlab_ci_badge_host from repo URL' );

my ( $pipe, $pipeln ) =
	App::prepare4release->gitlab_ci_badge_urls( _app(
		config => { git => { repo => 'a/b', server => 'gitlab.x.org' } },
		opts => { gitlab => 1 }
	) );
like( $pipe, qr{gitlab\.x\.org/a/b/badges/main/pipeline\.svg},
	'gitlab pipeline badge url' );
like( $pipeln, qr{/-/pipelines}, 'gitlab pipelines link' );

my $blob_gh = App::prepare4release->license_file_blob_url(
	_app( config => { git => { author => 'u', repo => 'r' } } ),
	{ github => 1 },
	'master'
);
like( $blob_gh, qr{/blob/master/LICENSE}, 'license blob github' );

my $blob_gl = App::prepare4release->license_file_blob_url(
	_app( config => { git => { repo => 'a/b' } } ),
	{ gitlab => 1 },
	'main'
);
like( $blob_gl, qr{/-/blob/main/LICENSE}, 'license blob gitlab' );

my $tmp = tempdir( CLEANUP => 1 );
{
	open my $fh, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'LICENSE' )
		or die $!;
	print {$fh} "The Perl 5 License\n";
	close $fh;
}
my $mf_sn = { license => 'perl' };
my ( $lbl, $href ) = App::prepare4release->license_badge_label_and_href(
	$tmp,
	{ github => 1 },
	_app( config => { git => { author => 'u', repo => 'r' } } ),
	$mf_sn
);
ok( length $lbl, 'license badge label from file' );
like( $href, qr{/blob/}, 'license href blob with LICENSE file + github' );

my $md = App::prepare4release->build_pod_badge_markdown(
	$tmp,
	_app( config => { git => { author => 'u', repo => 'r' } } ),
	{ github => 1, cpan => 1 },
	1,
	$mf_sn,
	{ module_name => 'Foo::Bar', dist_name => 'Foo-Bar' },
	'v5.12.0'
);
like( $md, qr/MetaCPAN package/, 'build markdown cpan flags' );
like( $md, qr/github\.com.*ci\.yml/, 'build markdown github CI' );

my $stripped = App::prepare4release->_strip_readme_badge_markdown_block(<<'MD');
[![License](img)](u)
[![Perl](img)](u)

# NAME
MD
is( index( $stripped, '[![License' ), -1, 'strip removes badge lines' );

my $insert = App::prepare4release->_insert_readme_badges_after_regen(
	"# Title\n\nbody\n", "X\n\n" );
like( $insert, qr/# Title.*X.*body/s, 'insert after title block' );

$insert = App::prepare4release->_insert_readme_badges_after_regen(
	"# NAME\n\nPod\n", "Z\n\n" );
like( $insert, qr/\AZ\n\n# NAME\n/s, 'insert before NAME' );

eval { App::prepare4release->parse_argv( [ '--github', '--gitlab' ] ) };
like( $@, qr/Use only one of/, 'parse_argv both vcs flags' );

my $po = App::prepare4release->parse_argv( ['--verbose', '--cpan'] );
ok( $po->{verbose} && $po->{cpan}, 'parse_argv verbose cpan' );

like(
	App::prepare4release->_postamble_block(
		{ github => 1, gitlab => 0, cpan => 0 }
	),
	qr/pod2github.*maint\/inject-readme-badges\.pl/s,
	'_postamble_block github + inject script'
);
like(
	App::prepare4release->_postamble_block(
		{ github => 0, gitlab => 0, cpan => 1 }
	),
	qr/pod2markdown.*maint\/inject-readme-badges\.pl/s,
	'_postamble_block markdown + inject script'
);

is( scalar App::prepare4release->ci_apt_packages(
		{ ci => { apt_packages => [qw(zlib1g-dev)] } }
	),
	1,
	'ci_apt_packages' );

my $pmf = File::Spec->catfile( $tmp, 'x.pm' );
{
	open my $fh, '>:encoding(UTF-8)', $pmf or die $!;
	print {$fh} "package X;\n__END__\n\n=head1\n\ncut\n";
	close $fh;
}
my ( $code, $pod ) = App::prepare4release->split_pm_code_and_pod($pmf);
ok( $code =~ /package X/, 'split_pm code' );
ok( $pod =~ /head1/, 'split_pm pod' );

{
	my $legacy = File::Spec->catfile( $tmp, 'legacy.t' );
	open my $fh, '>:encoding(UTF-8)', $legacy or die $!;
	print {$fh} "use Test::More;\n";
	close $fh;
	ok( App::prepare4release->file_uses_legacy_assertion_framework($legacy),
		'detect Test::More legacy' );
}

my $troot = tempdir( CLEANUP => 1 );
mkdir File::Spec->catfile( $troot, 't' );
{
	open my $fh, '>:encoding(UTF-8)',
		File::Spec->catfile( $troot, 't', 'z.t' ) or die $!;
	print {$fh} "use Test2::V1;\n";
	close $fh;
}
my @eol = App::prepare4release->list_files_for_eol_xt($troot);
ok( ( grep { $_ eq 't/z.t' } @eol ), 'list_files_for_eol_xt includes t/*.t' );

eval {
	App::prepare4release->load_config_file(
		File::Spec->catfile( $tmp, 'nope.json' ) );
};
ok( $@, 'load_config_file missing file croaks' );

done_testing;
