use strict;
use warnings;
use utf8;
use Test2::V0;
use Pod::Text;

# The documentation of Acme::PrettyCure as perldoc shows it (#7).

my $text = '';
my $parser = Pod::Text->new( utf8 => 1 );
$parser->output_string( \$text );
$parser->parse_file('lib/Acme/PrettyCure.pm');
utf8::decode($text);

my ($methods) = $text =~ /^METHODS\n(.*?)^\S/ms;
my @methods = $methods =~ /^  (\w+)\n/mg;
is( \@methods, [qw(girls members tv_series all_series now)], 'each method has its own heading' );

my ($author) = $text =~ /^AUTHOR\n(.*?)^\S/ms;
unlike( $author, qr/<gt>|E</, 'no POD escape is left in the text' );
my @authors = $author =~ /^    (\S.*)$/mg;
is(
    \@authors,
    [
        'Kan Fushihara <kan.fushihara at gmail.com>',
        'Kazuhiro Osawa <ko@yappo.ne.jp>',
        'Makamaka Hannyaharamitu <makamaka[at]cpan.org>',
    ],
    'each author is on a line of their own, with their address',
);

done_testing;
