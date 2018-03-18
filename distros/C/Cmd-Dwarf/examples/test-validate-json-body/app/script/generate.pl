#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw/abs_path/;
use Data::Section::Simple;
use File::Path 'mkpath';
use FindBin;
use Getopt::Long;
use Pod::Usage 'pod2usage';
use String::CamelCase qw(decamelize);
use Text::Xslate;
use lib "${FindBin::RealBin}/../lib";
use Dwarf::Util qw(write_file);

my $opts = { output => $FindBin::RealBin . '/../lib' };
GetOptions($opts, 'name=s', 'output=s', 'help');

if (@ARGV) {
	$opts->{name} = $ARGV[0];
	$opts->{output} = $ARGV[1] if $ARGV[1];
}

if (not $opts->{name} or $opts->{help}) {
	pod2usage;
}

# App が付いてなければ補完
unless ($opts->{name} =~ /^App::/) {
	$opts->{name} = "App::" . $opts->{name};
}

my $type = 'Model.pm';
$type = 'Api.pm'   if $opts->{name} =~ /::Api/;
$type = 'Cli.pm'   if $opts->{name} =~ /::Cli/;
$type = 'Web.pm'   if $opts->{name} =~ /::Web/;

my $reader = Data::Section::Simple->new('View');
my $tmpl = $reader->get_data_section($type);

my $tx = Text::Xslate->new;
my $content = $tx->render_string($tmpl, $opts);

my $dst = $opts->{output} . "/" . find_path($opts->{name});
write_file($dst, $content);

print "created " . abs_path($dst) . "\n";

# Cli な場合はラッパーシェルスクリプトも作る
if ($opts->{name} =~ /::Cli/) {
	$opts->{name2} = find_script_name($opts->{name});
	$tmpl = $reader->get_data_section('script.sh');
	$content = $tx->render_string($tmpl, $opts);
	$dst = join "/", $FindBin::RealBin, split " ", find_path($opts->{name2}, 'sh');
	write_file($dst, $content);
	print "created $dst\n";
}

sub find_path {
	my ($name, $ext) = @_;
	$ext //= 'pm';
	$name =~ s/::/\//g;
	$name .= "." . $ext;
	return $name;
}

sub find_script_name {
	my $name = shift;
	return $name unless $name =~ /^.+::Cli::(.+)/;
	my @a = map { decamelize $_ } split "::", $1;
	return join " ", @a;
}

=head1 SYNOPSIS

./generate.pl CLASS_NAME [-o OUTPUT_DIR]

=cut

package View;

1;

__DATA__

@@ Api.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Dwarf::DSL;
use Class::Method::Modifiers;

after will_dispatch => sub {
};

sub get {
}

1;

@@ Cli.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'App::Controller::CliBase';
use Dwarf::DSL;

sub any {
}

1;

@@ script.sh

base=${0%/*}/..
lib=${base}/lib
app=${base}/cli.psgi

perl -I $lib $app cli <: $name2 :>

@@ Web.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'App::Controller::WebBase';
use Dwarf::DSL;
use Class::Method::Modifiers;

# バリデーションの実装例。validate は何度でも呼べる。
# will_dispatch 終了時にエラーがあれば receive_error が呼び出される。
# after will_dispatch => sub {
#	self->validate(
#		user_id  => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
#		password => [qw/NOT_NULL UINT/, [qw/RANGE 1 8/]],
#	);
# };

# バリデーションがエラーになった時に呼び出される（定義元: Dwarf::Module::HTMLBase）
# エラー表示に使うテンプレートと値を変更したい時はこのメソッドで実装する
# バリデーションのエラー理由は、self->error_vars->{error}->{PARAM_NAME} にハッシュリファレンスで格納される
# before receive_error => sub {
#	self->{error_template} = 'index.html';
#	self->{error_vars} = parameters->as_hashref;
# };

sub get {
	return render('index.html');
}

1;

@@ Model.pm

package <: $name :>;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::DSL;

use Dwarf::Accessor qw//;

sub init {
	my ($self, $c) = @_;
}

1;
