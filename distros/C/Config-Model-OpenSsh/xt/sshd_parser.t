use strict;
use warnings;
use lib qw(contrib/lib);
use 5.22.0;

use ParseMan;

use Test::More;
use Test::Differences;
use Path::Tiny;
use experimental qw/postderef signatures/ ;

my $html = path('xt/sshd_config.html')->slurp;

my $data = parse_html_man_page($html);

subtest "man page transformation" => sub {
    # test some data items
    is($data->{element_list}[0],'AcceptEnv', "first element name");
    is($data->{element_list}[5],'AllowTcpForwarding', "5th element name");
};

subtest "test generation of model string" => sub {
    my @unilines = qw/AuthorizedKeysCommand/;
    my $boolean = sub {
        return "type=leaf value_type=boolean write_as=no,yes upstream_default=$_[0]";
    };
    my $enum = sub ($set,$def = undef) {
        my $str = "type=leaf value_type=enum choice=$set";
        $str .= " upstream_default=$def" if defined $def;
        return $str;
    };

    my %expected_load = (
        # AddKeysToAgent => $enum->('yes,confirm,ask,no', 'no'),
        AddressFamily => $enum->('any,inet,inet6', 'any'),
        AllowStreamLocalForwarding => $enum->('yes,all,no,local,remote','yes'),
        AllowGroups => 'type=list cargo type=leaf value_type=uniline',
        AllowUsers => 'type=list cargo type=leaf value_type=uniline',
        AuthorizedKeysFile => 'type=list cargo type=leaf value_type=uniline',
        MaxStartups => 'type=leaf value_type=uniline upstream_default=10',
        X11Forwarding => $boolean->('no'),
    );

    foreach my $p (@unilines) {
        $expected_load{$p} = 'type=leaf value_type=uniline';
    }

    foreach my $param ($data->{element_list}->@*) {
        my @desc = $data->{element_data}{$param}->@*;
        my $load = create_load_data(sshd => $param => @desc);

        # check only some of the parameters
        if (defined  $expected_load{$param}) {
            note("test failed with @desc") unless $load eq $expected_load{$param};
            is($load, $expected_load{$param}, "check generated load string of $param");
        }
    }
};

done_testing;
