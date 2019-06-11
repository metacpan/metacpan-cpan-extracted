use strict;
use warnings;
use lib qw(contrib/lib);
use 5.22.0;

use ParseMan;

use Test::More;
use Test::Differences;
use Path::Tiny;
use experimental qw/postderef signatures/ ;

use XXX;

my $html = path('xt/ssh_config.html')->slurp;

my $data = parse_html_man_page($html);

subtest "man page transformation" => sub {
    # test some data items
    is($data->{element_list}[0],'Host', "first element name");
    is($data->{element_list}[5],'BindAddress', "5th element name");

    my $param_data=$data->{element_data}{'VerifyHostKeyDNS'};
    is($param_data->[0],'B<VerifyHostKeyDNS>','check B<> transformation in parameter name');
    like($param_data->[1],qr/B<yes>/,'check B<> transformation in parameter description');
    is($param_data->[2],"See also\nI<VERIFYING HOST KEYS> in L<ssh(1)>.", "check I<> and L<> transformation");
};

subtest "test generation of model string" => sub {
    my @unilines = qw/ControlPersist GSSAPIClientIdentity IdentityAgent/;
    my $boolean = sub {
        return "type=leaf value_type=boolean write_as=no,yes upstream_default=$_[0]";
    };
    my $enum = sub ($set,$def = undef) {
        my $str = "type=leaf value_type=enum choice=$set";
        $str .= " upstream_default=$def" if defined $def;
        return $str;
    };

    my %expected_load = (
        AddKeysToAgent => $enum->('yes,confirm,ask,no', 'no'),
        AddressFamily => $enum->('any,inet,inet6', 'any'),
        BatchMode => $boolean->('no'),
        CanonicalizeFallbackLocal => $boolean->('yes'),
        CanonicalizeHostname => $enum->('no,yes,always', 'no'),
        CanonicalizeMaxDots => 'type=leaf value_type=integer upstream_default=1',
        CheckHostIP => $boolean->('yes'),
        ConnectionAttempts => 'type=leaf value_type=integer upstream_default=1',
        ConnectTimeout => 'type=leaf value_type=integer',
        ControlMaster => $enum->('auto,autoask,yes,no,ask', 'no'),
        DynamicForward => 'type=list cargo type=leaf value_type=uniline',
        ExitOnForwardFailure => $boolean->('no'),
        ForwardX11Timeout => 'type=leaf value_type=integer',
        GlobalKnownHostsFile => 'type=leaf value_type=uniline upstream_default=/etc/ssh/ssh_known_hosts',
        GSSAPIAuthentication => $boolean->('no'),
        GSSAPITrustDns => $boolean->('no'),
        Host => 'type=hash index_type=string cargo type=node config_class_name=Ssh::HostElement',
        IdentitiesOnly => $boolean->('no'),
        IdentityFile => 'type=list cargo type=leaf value_type=uniline',
        IPQoS => 'type=leaf value_type=uniline upstream_default="af21 cs1"',
        Match => 'type=hash index_type=string cargo type=node config_class_name=Ssh::HostElement',
        NumberOfPasswordPrompts => 'type=leaf value_type=integer upstream_default=3',
        RequestTTY => $enum->('no,yes,force,auto'),
        SendEnv =>  'type=list cargo type=leaf value_type=uniline',
        ServerAliveCountMax => 'type=leaf value_type=integer upstream_default=3',
        ServerAliveInterval => 'type=leaf value_type=integer upstream_default=0',
        LocalForward => 'type=list cargo type=node config_class_name="Ssh::PortForward"',
        RemoteForward => 'type=list cargo type=node config_class_name="Ssh::PortForward"',
        Tunnel => $enum->('yes,point-to-point,ethernet,no','no'),
        TunnelDevice => 'type=leaf value_type=uniline upstream_default=any:any',
        LogLevel => $enum->('QUIET,FATAL,ERROR,INFO,VERBOSE,DEBUG,DEBUG1,DEBUG2,DEBUG3', 'INFO'),
        SyslogFacility => $enum->('DAEMON,USER,AUTH,'.join(',', map { "LOCAL$_" } (0..7)), 'USER'),
        VerifyHostKeyDNS => $enum->('yes,ask,no', 'no'),
        XAuthLocation => 'type=leaf value_type=uniline upstream_default=/usr/bin/xauth',
    );

    foreach my $p (@unilines) {
        $expected_load{$p} = 'type=leaf value_type=uniline';
    }

    foreach my $param ($data->{element_list}->@*) {
        my @desc = $data->{element_data}{$param}->@*;
        my $load = create_load_data(ssh => $param => @desc);

        # check only some of the parameters
        if (defined  $expected_load{$param}) {
            note("test failed with @desc") unless $load eq $expected_load{$param};
            is($load, $expected_load{$param}, "check generated load string of $param");
        }
    }
};

done_testing;
