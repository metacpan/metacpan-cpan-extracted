use warnings;
use strict;

use Test::More tests => 2;
use App::Cmd::Tester;
use App::Rcsync;
use Test::Differences;
use File::Temp qw(tempfile);
use File::Spec;
use File::Slurp qw(write_file);
use Try::Tiny;

my ( $config_fh, $config_filename ) = tempfile();
my ( $tmpl_fh, $tmpl_filename ) = tempfile();

my ($tmpl_volume, $tmpl_path, $tmpl_basename) = File::Spec->splitpath( $tmpl_filename );
my $tmpl_parent = File::Spec->catdir( $tmpl_volume, $tmpl_path );

my $config = <<"CONFIG";
base_dir $tmpl_parent
<test1>
    template $tmpl_basename
    filename doesnt_matter
    <param>
        param1 value1
        param2 value2
    </param>
</test1>
CONFIG

my $template = <<TEMPLATE;
setting1 = [% param1 %]
setting2 = [% param2 %]
TEMPLATE

print $config_fh $config or die $!;
print $tmpl_fh $template or die $!;

close $config_fh;
close $tmpl_fh;

my $output = <<OUTPUT;
setting1 = value1
setting2 = value2
OUTPUT

my $result = test_app( 'App::Rcsync' => [ '--config', $config_filename, '--stdout', 'test1' ] );

eq_or_diff($result->stdout, $output, 'file parsed properly');
is($result->error, undef, 'threw no exceptions');

