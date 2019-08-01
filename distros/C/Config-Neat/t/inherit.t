#!/usr/bin/perl

use strict;

BEGIN {
    use File::Spec::Functions qw(rel2abs catfile);
    use File::Basename;
    unshift(@INC, catfile(dirname(rel2abs($0)), '../lib'));
}

$| = 1; # disable output buffering;

use File::Find;
use Getopt::Long;
use Test::More 0.94;

my ($init);

GetOptions("init" => \$init);

use_ok('Config::Neat::Inheritable');
use_ok('Config::Neat::Render');

my $c = Config::Neat::Inheritable->new();
ok($c, '$cfg is defined');

my $r = Config::Neat::Render->new();
ok($r, '$r is defined');

my @nconf_files;

find(sub {
    push @nconf_files, $File::Find::name if (-f $_ && /\.nconf$/);
}, catfile(dirname(rel2abs($0)), 'data/inherit/tests'));

foreach my $test_filename (@nconf_files) {
    $test_filename =~ s|\\|/|g;
    subtest "$test_filename", sub {
        my $reference_filename = $test_filename;
        $reference_filename =~ s|/inherit/tests/|/inherit/reference/|;

        my ($text1, $data1, $error_text);

        if ($init) {

            # init mode: create reference file

            eval {
                $data1 = $c->parse_file($test_filename);
            };
            if ($@) {
                ok($@, '$@ is defined');

                $reference_filename =~ s|\.nconf$|.nconf_parse_file_error|;
                $text1 = rectify_error_string($@);
            } else {
                ok($data1, '$data1 is defined');

                $text1 = $r->render($data1);
                ok($text1, '$text1 is defined');
            }

            write_file($reference_filename, $text1);
            ok(-f $reference_filename, "$reference_filename file should exist");
        } else {
            # test mode: read and compare reference file

            eval {
                $data1 = $c->parse_file($test_filename);
            };
            if ($@) {
                ok($@, '$@ is defined');

                $reference_filename =~ s|\.nconf$|.nconf_parse_file_error|;
                $error_text = $text1 = rectify_error_string($@);
            } else {
                ok($data1, '$data1 is defined');

                $text1 = $r->render($data1);
                ok($text1, '$text1 is defined');
            }

            ok(-f $reference_filename, "$reference_filename reference file should exist");
            if (-f $reference_filename) {
                my $reference_text = read_file($reference_filename);
                is($text1, $reference_text, 'Text should be equal to reference file contents: '.$reference_filename);
            } else {
                if ($error_text) {
                    print "Reference file not found, here is the reported error:\n".
                          "=====================\n$error_text\n=====================\n";
                } else {
                    print "Reference file not found, here is the reported result:\n".
                          "=====================\n$text1\n=====================\n";
                }
            }
        }
    }
}

done_testing();

sub rectify_error_string {
    my $s = shift;
    print "\t::rectify_error_string($s)\n";

    # remove the trailing source file reference added by Perl
    $s =~ s/ at \S+? line \d+\.$//;

    # replace paths to nconf files to stabilize the output
    $s =~ s/[\S]+[\\\/]([\w\d]+\.nconf)/<\/path\/to\/>$1/sg;
    return $s;
}

sub read_file {
    my $filename = shift;
    open(IN, $filename);
    binmode(IN, ':utf8');
    my $text = join('', <IN>);
    close(IN);
    return $text;
}

sub write_file {
    my ($filename, $text) = @_;
    open(OUT, '>'.$filename);
    binmode(OUT, ':utf8');
    print OUT $text;
    close(OUT);
}