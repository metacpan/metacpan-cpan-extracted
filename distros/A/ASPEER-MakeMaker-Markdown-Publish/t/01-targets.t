#!perl

use strict;
use warnings;
use lib 'lib';

use Config;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use JSON::PP qw(decode_json);
use MIME::Base64 qw(decode_base64);
use Test::More;

use ASPEER::MakeMaker::Markdown::Publish::MM;


sub blurp {

    my ($fn, $text)=@_;
    open(my $output_fh, '>', $fn) || die "unable to write $fn: $!";
    print {$output_fh} $text;
    close($output_fh) || die "unable to close $fn: $!";
    return 1;

}


sub slurp {

    my ($fn)=@_;
    open(my $input_fh, '<', $fn) || die "unable to read $fn: $!";
    local $/=undef;
    my $text=<$input_fh>;
    close($input_fh) || die "unable to close $fn: $!";
    return $text;

}


#  Locate the adapter and shared parent before entering a disposable project
#
my $cwd=getcwd();
my $adapter_lib_dn=abs_path('lib');
my $common_pm_fn=abs_path($INC{'ASPEER/MakeMaker/MM.pm'});
$common_pm_fn=~s{[/\\]ASPEER[/\\]MakeMaker[/\\]MM\.pm$}{};
my $temporary_dn=tempdir(CLEANUP => 1);
chdir($temporary_dn) || die "unable to chdir $temporary_dn: $!";
make_path('lib/Sample', 'doc', 'local lib/Markdown');
my $local_lib_dn=abs_path('local lib');


#  The runtime publisher stub records exactly what the generated target passes
#
blurp('local lib/Markdown/Publish.pm', <<'PUBLISH_STUB');
package Markdown::Publish;
use JSON::PP qw(encode_json);
sub new {my ($class, $config_hr)=@_; return bless({config => $config_hr}, $class)}
sub run {
    my ($self, $action)=@_;
    open(my $output_fh, '>>', 'target.log') || die "unable to write target log: $!";
    print {$output_fh} encode_json({config => $self->{'config'}, action => $action}), "\n";
    close($output_fh) || die "unable to close target log: $!";
    return 1;
}
1;
PUBLISH_STUB
blurp('lib/Sample.pm', "package Sample;\nour \$VERSION='0.001';\n1;\n");
blurp('lib/Sample.pm.md', "# NAME\n\nSample - generated documentation target fixture\n");
blurp('README.md', "# Sample\n\nGenerated documentation target fixture.\n");
blurp('MANIFEST', "lib/Sample.pm\nlib/Sample.pm.md\nREADME.md\ndoc/guide.md\n");
blurp('doc/guide.md', "# Guide\n\nText.\n");
blurp('Makefile.PL', <<'MAKEFILE_PL');
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sample',
    VERSION_FROM => 'lib/Sample.pm',
    META_MERGE   => {
        'meta-spec' => {version => 2},
        x_documentation => {
            publish => {
                module  => 'Markdown::Publish::MkDocs',
                sources => ['doc'],
                base    => '/sample-docs/',
                output  => 'public',
                config  => 'doc/mkdocs/custom.yml',
                address => '127.0.0.1:8123',
                cloudflare => {config => 'doc/wrangler.jsonc'},
            },
        },
    },
);
MAKEFILE_PL


#  Generate a real Makefile through the public plugin import
#
local $ENV{'PERL5LIB'}=join(
    $Config{'path_sep'},
    grep {defined($_) && length($_)}
        ($local_lib_dn, $adapter_lib_dn, $common_pm_fn, $ENV{'PERL5LIB'})
);
is(system($^X, '-MASPEER::MakeMaker::Markdown::Publish', 'Makefile.PL'), 0,
    'Makefile.PL succeeds with publication plugin');
my $makefile=slurp('Makefile');
like($makefile, qr/^PERLRUN\s*=.*-MASPEER::MakeMaker::Markdown::Pod.*-MASPEER::MakeMaker::Markdown::Publish/m,
    'generated commands reload documentation before publication integration');
like($makefile, qr/^PUBLISH_PM_TARGET=\$\(PERLRUN\) -M\$\(PUBLISH_PM\).*-e /m,
    'target command explicitly reloads the publication dispatcher');
unlike($makefile, qr/^MM_PREFIX\s*=/m,
    'private Makefile prefix is not emitted');

foreach my $target_ar (
    [build => 'publish_build'], [serve => 'publish_serve'],
    [gh => 'publish_gh'], ['gh-push' => 'publish_gh-push'],
    [cloudflare => 'publish_cloudflare']
) {
    my ($action, $target)=@{$target_ar};
    like($makefile, qr/^\Q$target\E ::$/m,
        "$target target generated");
    like($makefile,
        qr/^\s*\@\$\(PUBLISH_PM_TARGET\) publish $action$/m,
        "$action target delegates explicitly");
}
unlike($makefile, qr/^mkdocs_build ::$/m, 'backend-specific targets are absent');
my @doc_target=($makefile=~/^doc :: readme$/mg);
is(scalar(@doc_target), 1, 'publication import generates one doc target');


#  Decode the private macro to prove values came from live META_MERGE input
#
my ($encoded)=$makefile=~/^PUBLISH_CONFIG\s*=\s*(\S+)$/m;
ok(defined($encoded) && length($encoded), 'publication configuration macro generated');
my $config_hr=decode_json(decode_base64($encoded));
is_deeply($config_hr->{'sources'}, ['doc'], 'source directories encoded');
is($config_hr->{'base'}, '/sample-docs/', 'publication base encoded');
is($config_hr->{'module'}, 'Markdown::Publish::MkDocs',
    'selected module encoded');
is($config_hr->{'config'}, 'doc/mkdocs/custom.yml',
    'MkDocs configuration location encoded');
is($config_hr->{'address'}, '127.0.0.1:8123',
    'MkDocs customization encoded');
is_deeply($config_hr->{'cloudflare'}, {config => 'doc/wrangler.jsonc'},
    'Cloudflare Worker configuration encoded');
ok(!exists($config_hr->{'name'}),
    'generated Makefile retains the user publication settings');


#  Execute generated targets through make and inspect the delegated calls
#
my $make=$Config{'make'} || 'make';
is(system($make, 'doc'), 0, 'generated documentation target succeeds');
like(slurp('lib/Sample.pm'), qr/^=head1 NAME$/m,
    'generated documentation target processes the sidecar');
is(system($^X, '-MASPEER::MakeMaker::Markdown::Publish', 'Makefile.PL'), 0,
    'Makefile regenerates after documentation updates VERSION_FROM');
is(system($make, 'publish_build'), 0, 'generated build target succeeds');
is(system($make, 'publish_serve'), 0, 'generated local server target delegates');
is(system($make, 'publish_gh'), 0,
    'generated local publication target delegates');
is(system($make, 'publish_gh-push'), 0,
    'generated publication push target delegates');
is(system($make, 'publish_cloudflare'), 0,
    'generated static-assets deployment target delegates');
my @target=map {decode_json($_)} grep {length($_)} split(/\n/, slurp('target.log'));
is_deeply(
    [map {$_->{'action'}} @target],
    ['build', 'serve', 'gh', 'gh-push', 'cloudflare'],
    'generated targets dispatch the selected action'
);
my $default_config_hr={%{$config_hr}, name => 'Sample'};
is_deeply($target[0]{'config'}, $default_config_hr,
    'distribution module name supplies the default site title');


#  An explicit publication name overrides the distribution module name
#
my $configured=slurp('Makefile.PL');
$configured=~s/(publish\s*=>\s*\{\n)/$1                name    => 'Sample documentation',\n/ ||
    die "unable to construct named publication fixture";
blurp('Makefile.PL', $configured);
is(system($^X, '-MASPEER::MakeMaker::Markdown::Publish', 'Makefile.PL'), 0,
    'Makefile.PL accepts an explicit publication name');
is(system($make, 'publish_build'), 0,
    'generated build target accepts the explicit publication name');
@target=map {decode_json($_)} grep {length($_)} split(/\n/, slurp('target.log'));
is($target[-1]{'config'}{'name'}, 'Sample documentation',
    'explicit publication name overrides the default');


#  Explicit and composed Pod imports remain idempotent
#
my $explicit=slurp('Makefile.PL');
$explicit=~s/(use ExtUtils::MakeMaker;\n)/$1use ASPEER::MakeMaker::Markdown::Pod;\n/ ||
    die "unable to construct explicit Pod import fixture";
blurp('Makefile.PL', $explicit);
is(system($^X, '-MASPEER::MakeMaker::Markdown::Publish', 'Makefile.PL'), 0,
    'explicit Pod and command-line publication imports succeed together');
$makefile=slurp('Makefile');
@doc_target=($makefile=~/^doc :: readme$/mg);
is(scalar(@doc_target), 1, 'combined imports generate one doc target');


#  Invalid custom metadata is rejected while generating the Makefile
#
my $invalid=slurp('Makefile.PL');
$invalid=~s/x_documentation\s*=>\s*\{/x_documentation => 'invalid', disabled => {/ ||
    die "unable to construct invalid metadata fixture";
blurp('Makefile.PL', $invalid);
isnt(system($^X, '-MASPEER::MakeMaker::Markdown::Publish', 'Makefile.PL'), 0,
    'invalid x_documentation metadata rejected');

chdir($cwd) || die "unable to restore cwd $cwd: $!";
done_testing();
