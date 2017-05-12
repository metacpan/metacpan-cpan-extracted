# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

plan tests => 8, have_lwp;

# Basic request
for(1..2)
{
	my $response = GET '/test/module/';
	if(!$response->is_success) {
		ok(0);
		print STDERR "Received failure code: " . $response->code . "\n";
	}
	else {
		ok(1);
	}
}

# Test ##UNPACKDIR##
for(1..2)
{
	my $response = GET '/test/module/';
	if(!$response->is_success) {
		ok(0);
		print STDERR "Received failure code: " . $response->code . "\n";
	}
	else {
		my $content = $response->content;
		ok t_cmp(qr/FILE: GOT FILE/, $content);
	}
}

# Test extra_path_info
for (1..2)
{
	$response = GET '/test/path/JAPH';
	if(!$response->is_success) {
		ok(0);
		print STDERR "Received failure code: " . $response->code . "\n";
	}
	else {
		my $content = $response->content;
		ok t_cmp('/JAPH', $content);
	}
}

use Archive::Zip;
my $module_zip = Archive::Zip->new('par/module.par');
my $lib_member = $module_zip->removeMember('lib/TestMod.pm');
my $contents = $lib_member->contents();
my $contents_save = $contents;
$contents =~ s/Perl\sModule/TEST CHANGES/;
$lib_member->contents($contents);
$module_zip->addMember($lib_member);
$module_zip->overwrite();
undef $lib_member;
undef $module_zip;
sleep 2;

for(1..2)
{
	my $response = GET '/test/module/';
	if(!$response->is_success) {
		ok(0);
		print STDERR "Received failure code: " . $response->code . "\n";
	}
	else {
		my $contents_check = $response->content;
        if( $contents_check =~ /TEST\sCHANGES/ ) {
        	ok(1);
       	}
       	else {
       		ok(0);
       	}
	}
}

my $newmodule_zip = Archive::Zip->new('par/module.par');
$lib_member = $newmodule_zip->removeMember('lib/TestMod.pm');
my $contents_new = $lib_member->contents();
$lib_member->contents($contents_save);
$newmodule_zip->addMember($lib_member);
$newmodule_zip->overwrite();
undef $newmodule_zip;