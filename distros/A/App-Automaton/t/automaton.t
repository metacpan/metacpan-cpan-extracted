use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

require_ok( 'App::Automaton' );

my $yaml_conf = <<EOF;
sources:
  automaton email:
    type: IMAP
    server: imap.gmail.com
    port: 993
    account: notyourprimary\@email.com
    password: goodpassword
    ssl: yes
  file1:
    type: file
    path: .
  dir1:
    type: directory
    path: /var/tmp/input
EOF

my $conf = {
	'sources' => {
		'automaton email' => {
			'password' => 'goodpassword',
			'server'   => 'imap.gmail.com',
			'type'     => 'IMAP',
			'ssl'      => 'yes',
			'port'     => '993',
			'account'  => 'notyourprimary@email.com'
		},
		'file1' => {
			'path' => '.',
			'type' => 'file'
		},
		'dir1' => {
			'path' => '/var/tmp/input',
			'type' => 'directory'
		}
	}
};

# loading conf from yaml string
my $a1 = App::Automaton->new( yaml_conf => $yaml_conf );
is_deeply( $conf, $a1->conf(), 'yaml string config' );

# load config from yaml file
my ($a2_fh, $a2_filename) = tempfile();
print($a2_fh $yaml_conf);
close($a2_fh);
my $a2 = App::Automaton->new( conf_file => $a2_filename );
is_deeply( $conf, $a2->conf(), 'yaml file config');

#TODO: test bad/non-existant conf file

#dedupe
my $dedupe_input = ['one', 'two', 'two', 'three'];
my $dedupe_expect = ['one', 'two', 'three'];
$a2->{found_bits} = $dedupe_input;
$a2->dedupe();
is_deeply( [sort @{$a2->{found_bits}}], [sort @$dedupe_expect], 'dedupe queue' );



done_testing();
