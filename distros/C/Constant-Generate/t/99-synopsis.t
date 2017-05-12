#!/usr/bin/perl
use strict;
use warnings;
use Test::More;


my $test = sub {
    my ($fn, @args) = @_;
    my $pkg = caller();
    no strict 'refs';
    &{$fn}(@args, $pkg);
};

#Keep this in sync with the documentation

note "Testing whether examples in the synopsis actually work";

note "First example";

package _Synopsis1;
use Constant::Generate [qw(CONST_FOO CONST_BAR) ];
$test->('ok', CONST_FOO == 0 && CONST_BAR == 1, __PACKAGE__);

package _Synopsis2;
use Constant::Generate [qw(ANNOYING STRONG LAZY)], type => 'bitflags';
my $state = (ANNOYING|LAZY);
$test->('is', $state & STRONG, 0);

package _Synopsis3;
use Constant::Generate
    [qw(CLIENT_IRSSI CLIENT_XCHAT CLIENT_PURPLE)],
    type => "bitflags",
    mapname => "client_type_to_str";
my $client_type = CLIENT_IRSSI | CLIENT_PURPLE;
my $client_str = client_type_to_str($client_type);
$test->('ok', $client_str =~ /CLIENT_IRSSI/ && $client_str =~ /CLIENT_PURPLE/);


package _Synopsis4;
use base qw(Exporter);
our @EXPORT_OK;
our %EXPORT_TAGS;

use Constant::Generate {
    O_RDONLY => 00,
    O_WRONLY => 01,
    O_RDWR	 => 02,
    O_CREAT  => 0100
}, tag => "openflags", -type => 'bits';

my $oflags = O_RDWR|O_CREAT;
my $oflag_str = openflags_to_str($oflags);

$test->('ok',$oflag_str =~ /O_RDWR/ && $oflag_str =~ /O_CREAT/);

package _Synopsis5_Exporter;
BEGIN { $INC{'_Synopsis5_Exporter.pm'} = 1; }

use base qw(Exporter);
our (@EXPORT_OK,@EXPORT,%EXPORT_TAGS);

use Constant::Generate [qw(FOO BAR BAZ)],
    tag => "my_constants",
    export_ok => 1;
    
package _Synopsis5_User;
use _Synopsis5_Exporter qw(:my_constants);
FOO == 0 && BAR == 1 && BAZ == 2 &&
$test->('ok', my_constants_to_str(FOO eq 'FOO')
        && my_constants_to_str(BAR eq 'BAR') &&
        my_constants_to_str(BAZ eq 'BAZ'));

use Test::More;
done_testing();