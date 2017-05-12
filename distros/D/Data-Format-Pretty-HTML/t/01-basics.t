#!perl

use 5.010;
use strict;
use warnings;

use Data::Dump::Partial qw(dumpp);
use Data::Format::Pretty::HTML qw(format_pretty);
use Test::More 0.98;
use YAML::Any;

my @data = (
    # test encoding entities
    {
        data         => "a & b",
        struct       => "scalar",
        output       => "a &amp; b",
    },

    # test newline in text triggers <pre>
    {
        data         => "a\nb",
        struct       => "scalar",
        output       => "<pre>a\nb</pre>",
    },

    # check html table tag, class=number
    {
        data         => [1, "a"],
        struct       => "list",
        output_re    => qr!<table>\s*
                           <tbody>\s*
                           <tr><td\sclass="number">1</td></tr>\s*
                           <tr><td>a</td></tr>\s*
                          </tbody>\s*
                          </table>!sx,
    },

    # check hot rendered as table
    {
        data         => {table1=>[], table2=>[[1]]},
        struct       => "hot",
        output_re    => qr!<table>.+<table>!sx,
    },

    # check linkify_urls_in_text
    {
        name         => 'opt linkify_urls_in_text',
        data         => 'go to http://example.com/?a & click the image',
        output       => 'go to <a href="http://example.com/?a">'.
          'http://example.com/?a</a> &amp; click the image',
    },
);

sub is_yaml {
    my ($data, $test_name) = @_;
    eval { Load($data) };
    ok(!$@, $test_name);
}

sub isnt_yaml {
    my ($data, $test_name) = @_;
    eval { Load($data) };
    #XXX doesn't die?
    #ok($@, $test_name);
    #print "\$data=$data, \$@=$@\n";
}

 # detect and format
sub test_dnf {
    my ($spec) = @_;
    my $data   = $spec->{data};
    my $opts   = $spec->{opts} // {};
    my $struct = $spec->{struct};
    my $test_name = $spec->{name} //
        ($struct // "unknown") . ": " . dumpp($data);

    if (exists $spec->{struct}) {
        my $fmt = Data::Format::Pretty::HTML->new;
        my ($s, $sm) = $fmt->_detect_struct($data);
        if (!$struct) {
            ok(!$s, "$test_name: _detect_struct: structure unknown");
        } else {
            is($s, $struct, "$test_name: _detect_struct: structure is ".
                   "'$struct'");
        }
    }

    if (exists($spec->{output}) || exists($spec->{output_re}) ||
            exists($spec->{is_yaml})) {
        my $output;
        {
            $output = format_pretty($data, $opts);
        }
        if (exists($spec->{output})) {
            is($output, $spec->{output}, "$test_name: output exact match");
        }
        if (exists($spec->{output_re})) {
            like($output, $spec->{output_re}, "$test_name: output regex match");
        }
        if (exists($spec->{is_yaml})) {
            if ($spec->{is_yaml}) {
                is_yaml($output, "$test_name: is YAML");
            } else {
                isnt_yaml($output, "$test_name: is not YAML");
            }
        }
    }
}

test_dnf($_) for @data;
done_testing();
