package App::pepper;
use App::pepper::EPPClient;
use App::pepper::Highlighter;
use File::Temp qw(tmpnam);
use Getopt::Long;
use Mozilla::CA;
use Net::EPP::Simple;
use List::Util qw(none);
use Pod::Usage;
use Term::ANSIColor;
use Term::ReadLine;
use Text::ParseWords;
use XML::LibXML;
use strict;
use constant {
    SECURE_AUTHINFO_XMLNS => 'urn:ietf:params:xml:ns:epp:secure-authinfo-transfer-1.0',
};
use vars qw($VERSION);

our $VERSION = '1.0.0';

my $opt = {
    'port'      => 700,
    'timeout'   => 3,
    'lang'      => 'en',
};

my $result = GetOptions($opt,
    'host=s',
    'user=s',
    'pass=s',
    'newpw=s',
    'exec=s',
    'port=i',
    'timeout=i',
    'help',
    'insecure',
    'lang=s',
    'debug',
    'cert=s',
    'key=s',
    'login-security',
    'nossl',
);

if (!$result || $opt->{'help'}) {
    pod2usage(
        '-verbose'    => 99,
        '-sections'    => 'USAGE',
        '-input'    => __FILE__,
    );
    exit;
}

my $handlers = {
    'timeout'        => \&handle_timeout,
    'ssl'            => \&handle_ssl,
    'host'            => \&handle_host,
    'port'            => \&handle_port,
    'credentials'    => \&handle_credentials,
    'id'            => \&handle_id,
    'pw'            => \&handle_pw,
    'newpw'            => \&handle_newpw,
    'connect'        => \&handle_connect,
    'login'            => \&handle_login,
    'logout'        => \&handle_logout,
    'hello'            => \&handle_hello,
    'check'            => \&handle_check,
    'info'            => \&handle_info,
    'poll'            => \&handle_poll,
    'help'            => \&handle_help,
    'send'            => \&handle_send,
    'BEGIN'            => \&handle_begin,
    'exit'            => \&handle_exit,
    'transfer'        => \&handle_transfer,
    'clone'            => \&handle_clone,
    'delete'        => \&handle_delete,
    'renew'            => \&handle_renew,
    'create'        => \&handle_create,
    'edit'            => \&handle_edit,
    'cert'            => \&handle_cert,
    'key'            => \&handle_key,
    'restore'        => \&handle_restore,
    'update'        => \&handle_update,
};

our $term;
$term = Term::ReadLine->new('pepper') if (-t STDIN && -t STDOUT);

my $outfh = ($term ? \*STDOUT : \*STDERR);

my $prompt = 'pepper> ';

my $histfile = $ENV{'HOME'}.'/.pepper_history';

my $xml = XML::LibXML->new;

if ($term) {
    $term->ReadHistory($histfile) if ('Term::ReadLine::Gnu' eq $term->ReadLine);

    note('Welcome to pepper!');

    note(color('yellow').'> For best results, install Term::ReadLine::Gnu <'.color('reset')) if ($term && 'Term::ReadLine::Gnu' ne $term->ReadLine);
}

my $epp = App::pepper::EPPClient->new(
    'host'                => '',
    'connect'            => undef,
    'debug'                => $opt->{'debug'},
    'login'                => undef,
    'reconnect'            => 0,
    'verify'            => ($opt->{'insecure'} ? undef : 1),
    'ca_file'            => Mozilla::CA::SSL_ca_file(),
    'lang'                => ($opt->{'lang'} ? $opt->{'lang'} : 'en'),
    'appname'           => sprintf('Pepper %s', $VERSION),
    'login_security'    => $opt->{'login-security'},
);

execute_command('ssl off')                                                if ($opt->{'nossl'});
execute_command(sprintf('timeout %d',    $opt->{'timeout'}))                if ($opt->{'timeout'});
execute_command(sprintf('port %d',    $   opt->{'port'}))                    if ($opt->{'port'});
execute_command(sprintf('host "%s"',    quotemeta($opt->{'host'})))        if ($opt->{'host'});
execute_command(sprintf('id "%s"',        quotemeta($opt->{'user'})))        if ($opt->{'user'});
execute_command(sprintf('pw "%s"',        quotemeta($opt->{'pass'})))        if ($opt->{'pass'});
execute_command(sprintf('newpw "%s"',    quotemeta($opt->{'newpw'})))    if ($opt->{'newpw'});
execute_command(sprintf('cert "%s"',    quotemeta($opt->{'cert'})))        if ($opt->{'cert'});
execute_command(sprintf('key "%s"',        quotemeta($opt->{'key'})))        if ($opt->{'key'});

if ($epp->{'user'} ne '' && $epp->{'pass'} ne '') {
    execute_command('login');

} elsif ($epp->{'host'} ne '') {
    execute_command('connect');

}

if ($opt->{'exec'}) {
    execute_command($opt->{'exec'});
    handle_exit();

} elsif ($term) {
    note("Entering interactive mode, exit with Ctrl-D, Ctrl-C or 'exit'");

} else {
    note("Entering batch mode");

}

#
# main loop
#
my $last;
while (1) {
    $prompt = sprintf('pepper (%s@%s)> ', $epp->{'user'}, $epp->{'host'}) if ($epp->authenticated);

    my $command;
    if ($term) {
        $command = $term->readline($prompt);

    } else {
        $command = <STDIN>;
        chomp($command);

        # remove any trailing comment
        $command =~ s/\#.*//g;
    }

    if (!defined($command)) {
        last;

    } elsif ($command ne '') {
        if ($term && $command eq '!!') {
            execute_command($last) if ($last ne '');

        } else {
            $last = $command;

            note("Executing command '%s'", $command) if (!$term);
            execute_command($command);
        }
    }
}

$term->WriteHistory($histfile) if ($term && 'Term::ReadLine::Gnu' eq $term->ReadLine);

handle_logout() if ($epp->connected && $epp->authenticated);
$epp->disconnect if ($epp->connected);

note('Bye!');

exit(0);

sub execute_command {
    my $line = shift;

    return if ($line eq '');

    my @args = shellwords($line);

    my $command = shift(@args);

    my $fail;
    if (!$term && $command =~/^!/) {
        $fail = 1;
        $command = substr($command, 1);
    }

    if (!defined($handlers->{$command})) {
        error("Unknown command '$command'");
        handle_exit() if (!$term);

    } else {
        &{$handlers->{$command}}(@args);
        if (!$term && $fail) {
            note("%s%04d%s %s", color($Net::EPP::Simple::Code < 2000 ? 'green' : 'red'), $Net::EPP::Simple::Code, color('reset'), $Net::EPP::Simple::Message);
            fatal($Net::EPP::Simple::Message) if ($Net::EPP::Simple::Code > 1999);
        }
    }
}

sub handle_timeout {
    $epp->{'timeout'} = int($_[0]);
    note("Timeout set to %ds", $_[0]);
    return 1;
}

sub handle_ssl {
    if ($epp->connected) {
        return error("Already connected");

    } elsif ($_[0] eq 'on') {
        $epp->{'ssl'} = 1;
        note('SSL enabled');

    } elsif ($_[0] eq 'off') {
        $epp->{'ssl'} = 0;
        note('SSL disabled');

    } else {
        return error("Invalid SSL mode '%s'", $_[0]);

    }
    return 1;
}

sub handle_host {
    if ($epp->connected) {
        return error("Already connected");

    } else {
        $epp->{'host'} = $_[0];
        note("Host set to %s", $_[0]);
        return 1;
    }
}

sub handle_port {
    if ($epp->connected) {
        return error("Already connected");

    } else {
        $epp->{'port'} = int($_[0]);
        note("Port set to %d", $_[0]);
        return 1;
    }
}

sub handle_connect {
    if ($epp->connected) {
        return error("Already connected");

    } elsif ($epp->{'host'} eq '') {
        return error('No host specified');

    } else {
        note('Connecting to %s...', $epp->{'host'});

        $epp->{'quiet'} = 1;
        my $result = $epp->_connect(undef);
        $epp->{'quiet'} = 0;

        if ($result) {
            note("Connected OK. Type 'hello' to see the greeting frame.");

        } else {
            error("Unable to connect: %s", $Net::EPP::Simple::Message);

        }
        return $result;
    }
}

sub handle_credentials {
    if ($_[0] eq '') {
        return error('Missing client ID');

    } elsif ($_[1] eq '') {
        return error('Missing password');

    } else {
        handle_id($_[0]) && handle_pw($_[1]);
        return 1;

    }
}

sub handle_id {
    if ($epp->authenticated) {
        return error("Already authenticated");

    } else {
        $epp->{'user'} = shift;
        note("User ID set to '%s'", $epp->{'user'});
    }
}

sub handle_pw {
    if ($epp->authenticated) {
        return error("Already authenticated");

    } else {
        $epp->{'pass'} = shift;
        note("Password set to '%s'", ('*' x length($epp->{'pass'})));

    }
}

sub handle_newpw {
    if ($epp->authenticated) {
        return error("Already authenticated");

    } else {
        $epp->{'newPW'} = shift;
        note("New password set to '%s'", ('*' x length($epp->{'newPW'})));

    }
}

sub handle_login {
    my $verbose = shift;
    if (!$epp->connected) {
        return handle_connect() && handle_login();

    } elsif ($epp->authenticated) {
        return error('Already logged in');

    } elsif ($epp->{'host'} eq '') {
        return error('No host specified');

    } elsif ($epp->{'user'} eq '' || $epp->{'pass'} eq '') {
        return error('No credentials specified');

    } else {
        note("Attempting to login as '%s'...", $epp->{'user'});
        $epp->{'quiet'} = ($verbose ? 0 : 1);
        my $result = $epp->_login;
        $epp->{'quiet'} = 0;
        if ($result) {
            note('Logged in OK!');

        } else {
            error("%s%04d%s %s", color($Net::EPP::Simple::Code < 2000 ? 'green' : 'red'), $Net::EPP::Simple::Code, color('reset'), $Net::EPP::Simple::Message);

        }
        return $result;
    }
}

sub handle_logout {
    if (!$epp->authenticated) {
        return error('Not logged in');

    } else {
        note('logging out');
        $epp->{'quiet'} = 1;
        my $result = $epp->logout;
        $epp->{'quiet'} = 0;
        note("%s%04d%s %s", color($Net::EPP::Simple::Code < 2000 ? 'green' : 'red'), $Net::EPP::Simple::Code, color('reset'), $Net::EPP::Simple::Message);
        return $result;
    }
}

sub handle_hello {
    if (!$epp->connected) {
        return error('Not connected');

    } else {
        return $epp->ping;

    }
}

sub handle_check {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my ($type, $id, @extra) = @_;
        if ($type eq 'domain') {
            return $epp->check_domain($id);

        } elsif ($type eq 'claims') {
            return handle_claims_check($id);

        } elsif ($type eq 'fee') {
            return handle_fee_check($id, @extra);

        } elsif ($type eq 'host') {
            return $epp->check_host($id);

        } elsif ($type eq 'contact') {
            return $epp->check_contact($id);

        } else {
            return error("Unsupported object type '$type'");

        }
    }
}

sub handle_claims_check {
    my $domain = shift;
    my $frame = Net::EPP::Frame::Command::Check::Domain->new;
    $frame->addDomain($domain);

    my $launch_ns = 'urn:ietf:params:xml:ns:launch-1.0';

    my $phase = $frame->createElementNS($launch_ns, 'phase');
    $phase->appendChild($frame->createTextNode('claims'));

    my $launch = $frame->createElementNS($launch_ns, 'check');
    $launch->setAttribute('type', 'claims');
    $launch->appendChild($phase);

    my $extn = $frame->createElement('extension');
    $extn->appendChild($launch);

    $frame->clTRID->parentNode->insertBefore($extn, $frame->clTRID);

    return $epp->request($frame);
}

sub handle_fee_check {
    my %params;
    ($params{'name'}, $params{'command'}, $params{'currency'}, $params{'period'}) = @_;

    my $domain = shift;
    my $frame = Net::EPP::Frame::Command::Check::Domain->new;
    $frame->addDomain($params{'name'});

    my $fee_ns = 'urn:ietf:params:xml:ns:fee-0.5';
    my $ok = undef;
    foreach my $el ($epp->greeting->getElementsByTagName('extURI')) {
        $ok = 1 if ($el->textContent eq $fee_ns);
    }

    return error("Server does not support the version of the fee extension that I support!") if (!$ok);

    my $domain = $frame->createElementNS($fee_ns, 'domain');
    foreach my $name (qw(name currency command period)) {
        next if ($params{$name} eq '');
        my $el = $frame->createElementNS($fee_ns, $name);
        $el->appendChild($frame->createTextNode($params{$name}));
        $el->setAttribute('unit', 'y') if ('period' eq $name);
        $domain->appendChild($el);
    }

    my $check = $frame->createElementNS($fee_ns, 'check');
    $check->appendChild($domain);

    my $extn = $frame->createElement('extension');
    $extn->appendChild($check);

    $frame->clTRID->parentNode->insertBefore($extn, $frame->clTRID);

    return $epp->request($frame);
}

sub handle_info {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my ($type, $id, $authInfo, $opt) = @_;
        if ($type eq 'domain') {
            $opt = $opt || 'all';
            return $epp->domain_info($id, $authInfo, undef, $opt);

        } elsif ($type eq 'host') {
            return $epp->host_info($id);

        } elsif ($type eq 'contact') {
            return $epp->contact_info($id, $authInfo, $opt);

        } else {
            return error("Unsupported object type '$type'");

        }
    }
}

sub handle_poll {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my ($op, $id) = @_;
        if ($op eq 'req') {
            my $frame = Net::EPP::Frame::Command::Poll::Req->new;
            $epp->request($frame);

        } elsif ($op eq 'ack') {
            my $frame = Net::EPP::Frame::Command::Poll::Ack->new;
            $frame->setMsgID($id);
            $epp->request($frame);

        } else {
            error("Unsupported poll op '$op'");

        }
    }
}

sub handle_send {
    if (!$epp->connected) {
        return error('Not connected');

    } else {
        return send_file($_[0]);

    }
}

sub handle_begin {
    if (!$epp->connected) {
        return error('Not connected');

    } else {
        my $buffer = '';
        while (my $line = <STDIN>) {
            if ($line =~ /^END/) {
                last;

            } else {
                $buffer .= $line;

            }
        }
        my $frame;
        eval { $frame = $xml->parse_string($buffer) };
        if ($@ || !$frame) {
            $@ =~ s/[\r\n]+$//g;
            error("Unable to parse frame ($@)");

        } else {
            return $epp->request($frame);

        }
    }
}

sub handle_edit {
    if (!$epp->connected) {
        return error('Not connected');

    } else {
        my $file = tmpnam();

        open(FILE, ">$file");
        print FILE Net::EPP::Frame->new('command')->toString(2);
        close(FILE);

        my $cmd = ($ENV{'EDITOR'} || '/usr/bin/vi');
        my ($cmd, @args) = split(/[ \t]+/, $cmd);
        push(@args, $file);

        if (0 != system($cmd, @args)) {
            error("Command '$cmd' exited abnormally");

        } else {
            return send_file($file);

        }
    }
}

sub send_file {
    my $file = shift;
    my $frame;
    eval { $frame = $xml->parse_file($file) };
    if ($@ || !$frame) {
        $@ =~ s/[\r\n]+$//g;
        return error("Unable to parse '$file': $@");

    } else {
        return $epp->request($frame);

    }
}

sub handle_help {
    my $cmd = lc(shift || 'help');

    my %map = (
        'timeout'            => 'SYNTAX/Connection Management',
        'ssl'                => 'SYNTAX/Connection Management',
        'host'                => 'SYNTAX/Connection Management',
        'port'                => 'SYNTAX/Connection Management',
        'credentials'        => 'SYNTAX/Session Management',
        'id'                => 'SYNTAX/Session Management',
        'pw'                => 'SYNTAX/Session Management',
        'newpw'                => 'SYNTAX/Session Management',
        'connect'            => 'SYNTAX/Connection Management',
        'login'                => 'SYNTAX/Session Management',
        'logout'            => 'SYNTAX/Session Management',
        'hello'                => 'SYNTAX/Session Management',
        'check'                => 'SYNTAX/Query Commands/Availability Checks',
        'info'                => 'SYNTAX/Query Commands/Object Information',
        'poll'                => 'SYNTAX/Session Management',
        'help'                => 'SYNTAX/Getting Help',
        'send'                => 'SYNTAX/Miscellaneous Commands',
        'begin'                => 'SYNTAX/Miscellaneous Commands',
        'exit'                => 'SYNTAX/Connection Management',
        'transfer'            => 'SYNTAX/Object Transfers',
        'clone'                => 'SYNTAX/Creating Objects',
        'delete'            => 'SYNTAX/Transform Commands',
        'renew'                => 'SYNTAX/Transform Commands',
        'create'            => 'SYNTAX/Creating Objects',
        'create-domain'        => 'SYNTAX/Creating Objects/Creating Domain Objects',
        'create-host'        => 'SYNTAX/Creating Objects/Creating Host Objects',
        'create-contact'    => 'SYNTAX/Creating Objects/Creating Contact Objects',
        'edit'                => 'SYNTAX/Miscellaneous Commands',
        'cert'                => 'SYNTAX/Connection Management',
        'key'                => 'SYNTAX/Connection Management',
        'restore'            => 'SYNTAX/Transform Commands',
        'update'            => 'SYNTAX/Object Updates',
        'update-domain'        => 'SYNTAX/Object Updates/Domain Updates',
        'update-host'        => 'SYNTAX/Object Updates/Host Updates',
        'update-contact'    => 'SYNTAX/Object Updates/Contact Updates',
    );

    print "\n";

    pod2usage(
        '-verbose'    => 99,
        '-sections'    => $map{$cmd} || $map{'help'},
        '-exitval'    => 'NOEXIT',
        '-input'    => __FILE__,
    );
}

sub handle_exit {
    $epp->{'quiet'} = 1;
    $epp->logout if ($epp->authenticated);
    $epp->disconnect if ($epp->connected);
    note('bye!');
    exit;
}

sub handle_transfer {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my ($type, $object, $cmd, $authinfo, $period) = @_;

        return error("invalid object type '%s'", $type) if ($type ne 'domain' && $type ne 'contact');
        return error("invalid command '%s'", $cmd) if ($cmd ne 'query' && $cmd ne 'request' && $cmd ne 'cancel' && $cmd ne 'approve' && $cmd ne 'reject');

        return $epp->_transfer_request($cmd, $type, $object, $authinfo, $period);
    }
}

sub handle_clone {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my ($type, $old, $new) = @_;

        if (lc($type) eq 'contact') {
            return handle_contact_clone($old, $new);

        } elsif (lc($type) eq 'domain') {
            return handle_domain_clone($old, $new);

        } else {
            error("Unsupported object type '$type'");

        }
    }
}

sub handle_contact_clone {
    my ($old, $new) = @_;

    my $info = $epp->contact_info($old) || return;

    $info->{'id'} = $new;
    $info->{'authInfo'} = $epp->server_has_extension(SECURE_AUTHINFO_XMLNS) ? '' : generate_authinfo();

    return $epp->create_contact($info);
}

sub handle_domain_clone {
    my ($old, $new) = @_;

    my $info = $epp->domain_info($old) || return;

    $info->{'period'} = 1;
    $info->{'name'} = $new;
    $info->{'authInfo'} = $epp->server_has_extension(SECURE_AUTHINFO_XMLNS) ? '' : generate_authinfo();

    return $epp->create_domain($info);
}

sub generate_authinfo {
    my $length = shift || 16;

    my $safe = shift;

    my @upper_alpha = ('A'..'Z');
    my @lower_alpha = ('a'..'z');
    my @digits = (0..9);
    my @symbols = ('!', '#', '$', '%', '&', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '[', ']', '^', '_', '{', '|', '}', '~');

    my (@chars, @authinfo);
    if ($safe) {
        @chars = (@upper_alpha, @digits);

        @authinfo =  (
            $upper_alpha[int(scalar(@upper_alpha) * rand())-1],
            $digits[int(scalar(@digits) * rand())-1],
        );
    } else {
        @chars = (@upper_alpha, @lower_alpha, @digits, @symbols);

        @authinfo =  (
            $upper_alpha[int(scalar(@upper_alpha) * rand())-1],
            $lower_alpha[int(scalar(@lower_alpha) * rand())-1],
            $digits[int(scalar(@digits) * rand())-1],
            $symbols[int(scalar(@symbols) * rand())-1]
        );
    }

    push(@authinfo, $chars[int(scalar(@chars) * rand())-1]) while (scalar(@authinfo) < $length);

    return join('', @authinfo);
}

sub generate_contact_id {
    return generate_authinfo(16, 1);
}

sub handle_delete {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my ($type, $id) = @_;
        if ($type eq 'domain') {
            return $epp->delete_domain($id);

        } elsif ($type eq 'host') {
            return $epp->delete_host($id);

        } elsif ($type eq 'contact') {
            return $epp->delete_contact($id);

        } else {
            return error("Unsupported object type '$type'");

        }
    }
}

sub handle_renew {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my ($domain, $period, $date) = @_;
        $period = 1 if (!$period);

        if (!$date) {
            my $info = $epp->domain_info($domain, undef, undef, 'none');
            return undef if (!$info);

            ($date, undef) = split(/T/, $info->{'exDate'}, 2);
        }

        return $epp->renew_domain({
            'name'        => $domain,
            'period'    => $period,
            'cur_exp_date'    => $date,
        });
    }
}

sub handle_create {
    if (!$epp->authenticated) {
        return error('Not connected');

    } else {
        my $type = lc(shift);

        if ($type eq 'host') {
            return create_host(@_);

        } elsif ($type eq 'domain') {
            return create_domain(@_);

        } elsif ($type eq 'contact') {
            return create_contact(@_);

        } else {
            return error("invalid type '%s'", $type);

        }
    }
}

sub create_host {
    my $host = { 'name' => shift };

    if (scalar(@_) > 0) {
        $host->{'addrs'} = [];
        foreach my $addr (@_) {
            my $version = 'v'.($addr =~ /:/ ? 6 : 4);
            push(@{$host->{'addrs'}}, { 'ip' => $addr, 'version' => $version });
        }
    }
    return $epp->create_host($host);
}

sub create_domain {
    my $domain = {
        'name'        => shift,
        'contacts'    => {},
        'ns'        => [],
    };

    for (my $i = 0 ; $i < scalar(@_) ; $i++) {
        my $name = $_[$i];
        my $value = $_[++$i];

        if ($name eq 'period') {
            $domain->{'period'} = int($value);

        } elsif ($name eq 'registrant') {
            $domain->{'registrant'} = $value;

        } elsif ($name eq 'ns') {
            push(@{$domain->{'ns'}}, $epp->server_has_object(Net::EPP::Frame::ObjectSpec->xmlns('host')) ? $value : { name => $value});

        } elsif (lc($name) eq 'authinfo') {
            $domain->{'authInfo'} = $value;

        } elsif ($name =~ /^(admin|tech|billing)$/) {
            $domain->{'contacts'}->{$name} = $value;

        } else {
            return error("Invalid property name '$name'");

        }
    }

    $domain->{'period'} = 1 if ($domain->{'period'} < 1);
    $domain->{'authInfo'} = $epp->server_has_extension(SECURE_AUTHINFO_XMLNS) ? '' : generate_authinfo() if (length($domain->{'authInfo'}) < 1);

    return $epp->create_domain($domain);
}

sub create_contact {
    my $contact = {};

    my $type = 'int';

    my $postalInfo = { 'addr' => { 'street' => [] } };

    for (my $i = 0 ; $i < scalar(@_) ; $i++) {
        my $name = $_[$i];
        my $value = $_[++$i];

        if ($name eq 'type') {
            if ($value eq 'int' || $value eq 'loc') {
                $type = $value;

            } else {
                return error("Invalid postalInfo type '$value'");

            }

        } elsif ($name eq 'street') {
            push(@{$postalInfo->{'addr'}->{'street'}}, $value);

        } elsif ($name =~ /^(name|org)$/) {
            $postalInfo->{$name} = $value;

        } elsif ($name =~ /^(city|sp|pc|cc)$/) {
            $postalInfo->{'addr'}->{$name} = $value;

        } elsif (lc($name) eq 'authinfo') {
            $contact->{'authInfo'} = $value;

        } elsif ($name =~ /^(id|voice|fax|email)$/) {
            $contact->{$name} = $value;

        } else {
            return error("Invalid property name '$name'");

        }
    }

    $contact->{'postalInfo'}->{$type} = $postalInfo;
    $contact->{'id'} = generate_contact_id() if (length($contact->{'id'}) < 1);
    $contact->{'authInfo'} = $epp->server_has_extension(SECURE_AUTHINFO_XMLNS) ? '' : generate_authinfo() if (length($contact->{'authInfo'}) < 1);

    return $epp->create_contact($contact);
}

sub handle_key {
    if ($epp->connected) {
        return error('Already connected');

    } else {
        my ($key, $pass) = @_;
        $epp->{'key'} = $key;
        $epp->{'passphrase'} = $pass;
        note("Using '$key' as private key");
    }
}

sub handle_cert {
    if ($epp->connected) {
        return error('Already connected');

    } else {
        my $cert = shift;
        $epp->{'cert'} = $cert;
        note("Using '$cert' as certificate");
    }
}

sub handle_restore {
    if (!$epp->connected) {
        return error('Not connected');

    } else {
        my $domain = shift;

        my $frame = Net::EPP::Frame::Command::Update::Domain->new;
        $frame->setDomain($domain);

        my $ext = $frame->getNode('extension');
        if (!defined($ext)) {
            $ext = $frame->createElementNS(undef, 'extension');
            $frame->getNode('command')->insertBefore($ext, $frame->clTRID);
        }

        my $RGP_URN = 'urn:ietf:params:xml:ns:rgp-1.0';

        my $upd = $ext->addNewChild($RGP_URN, 'rgp:update');
        my $restore = $upd->addNewChild($RGP_URN, 'rgp:restore');
        $restore->setAttribute('op', 'request');

        return $epp->request($frame);
    }
}

sub handle_update {
    if (!$epp->connected) {
        return error('Not connected');

    } else {
        my $type = shift;
        if ($type eq 'domain') {
            return domain_update(@_);

        } elsif ($type eq 'host') {
            return host_update(@_);

        } elsif ($type eq 'contact') {
            return contact_update(@_);

        } else {
            return error("Unsupported object type '$type'");

        }
    }
}

sub domain_update {
    my $frame = Net::EPP::Frame::Command::Update::Domain->new;

    $frame->setDomain(shift(@_));

    my $changes = {
        'ns'      => [],
        'contact' => [],
        'status'  => [],
    };

    for (my $i = 0 ; $i < scalar(@_) ; $i++) {
        my $action    = lc($_[$i]);
        my $type    = lc($_[++$i]);
        my $value    = $_[++$i];

        return error("Invalid parameter '$action'") if ($action !~ /^(add|rem|chg)$/);
        return error("Missing parameter") if (!$type || !$value);
        return error("Invalid property '$type'") if ($type !~ /^(ns|admin|tech|billing|status|registrant|authinfo)$/);

        if ($type eq 'ns') {
            push(@{$changes->{'ns'}}, [ $action,  $value ]);

        } elsif ($type =~ /^(admin|tech|billing)$/) {
            push(@{$changes->{'contact'}}, [ $action,  $type, $value ]);

        } elsif ($type eq 'status') {
            push(@{$changes->{'status'}}, [ $action,  $value ]);

        } elsif ($action eq 'chg') {
            if ('registrant' eq $type) {
                $frame->chgRegistrant($value);

            } elsif ('authinfo' eq $type) {
                $frame->chgAuthInfo($value);

            } else {
                return error("Don't know how to change '$type'");

            }

        } else {
            return error("Don't know what to do with '$action $type $value'");

        }
    }

    foreach my $change (@{$changes->{'ns'}}) {
        my ($action, $value) = @{$change};
        if ($action eq 'add') {
            $frame->addNS($epp->server_has_object(Net::EPP::Frame::ObjectSpec->xmlns('host')) ? $value : { name => $value});

        } else {
            $frame->remNS($epp->server_has_object(Net::EPP::Frame::ObjectSpec->xmlns('host')) ? $value : { name => $value});

        }
    }

    foreach my $change (@{$changes->{'contact'}}) {
        my ($action, $type, $value) = @{$change};
        if ($action eq 'add') {
            $frame->addContact($type, $value);

        } else {
            $frame->remContact($type, $value);

        }
    }

    foreach my $change (@{$changes->{'status'}}) {
        my ($action, $value) = @{$change};
        if ($action eq 'add') {
            $frame->addStatus($value);

        } else {
            $frame->remStatus($value);

        }
    }

    return $epp->request($frame);
}

sub host_update {
    my $frame = Net::EPP::Frame::Command::Update::Host->new;

    $frame->setHost(shift(@_));

    my $changes = {
        'addr' => [],
        'status' => [],
    };

    for (my $i = 0 ; $i < scalar(@_) ; $i++) {
        my $action    = lc($_[$i]);
        my $type    = lc($_[++$i]);
        my $value    = $_[++$i];

        return error("Invalid parameter '$action'") if ($action !~ /^(add|rem|chg)$/);
        return error("Missing parameter") if (!$type || !$value);
        return error("Invalid property '$type'") if ($type !~ /^(addr|status|name)$/);

        if ($type eq 'addr') {
            push(@{$changes->{'addr'}}, [ $action,  $value ]);

        } elsif ($type eq 'status') {
            push(@{$changes->{'status'}}, [ $action,  $value ]);

        } elsif ($action eq 'chg') {
            if ($type ne 'name') {
                return error("You can only change the host name");

            } else {
                $frame->chgName($value);

            }

        } else {
            return error("Don't know what to do with '$action $type $value'");

        }
    }

    # we need to add <addr> elements first
    foreach my $change (@{$changes->{'addr'}}) {
        my ($action, $value) = @{$change};
        if ($action eq 'add') {
            $frame->addAddr({'ip' => $value, 'version' => ($value =~ /:/ ? 'v6' : 'v4') });

        } else {
            $frame->remAddr({'ip' => $value, 'version' => ($value =~ /:/ ? 'v6' : 'v4') });

        }
    }

    # we need to add <status> elements second
    foreach my $change (@{$changes->{'status'}}) {
        my ($action, $value) = @{$change};
        if ($action eq 'add') {
            $frame->addStatus($value);

        } else {
            $frame->remStatus($value);

        }
    }

    return $epp->request($frame);
}

sub contact_update {
    my $id = shift;

    my $frame = Net::EPP::Frame::Command::Update::Contact->new;

    $frame->setContact($id);

    $epp->{noout} = 1;
    my $info = $epp->contact_info($id);
    delete($epp->{noout});

    my $changes = {};
    my $postalInfoType = 'int';
    my $postalInfo = {};

    for (my $i = 0 ; $i < scalar(@_) ; $i++) {
        my $action    = lc($_[$i]);
        my $type    = lc($_[++$i]);
        my $value    = $_[++$i];

        return error("Missing parameter") if (!defined($type) || !defined($value));

        if ($action =~ /^(add|rem)$/) {
            if ('status' ne $type) {
                return error('only status codes can be added/removed');

            } elsif ('add' eq $action) {
                $frame->addStatus($value);

            } else {
                $frame->remStatus($value);

            }
        } elsif ($action ne 'chg') {
            return error("Invalid parameter '$action'");

        } else {
            if ($type =~ /^(voice|fax|email|authInfo)$/) {
                $changes->{$type} = $value;

            } elsif ('type' eq $type) {
                if ($type !~ /^(int|loc)$/) {
                    return error(sprintf("invalid postal info type '%s'", $type));
                }

                $postalInfoType = $value;

            } elsif ($type =~ /^street([1-3])$/) {
                $postalInfo->{$postalInfoType} = $info->{'postalInfo'}->{$postalInfoType} unless exists($postalInfo->{$postalInfoType});

                $postalInfo->{$postalInfoType}->{'addr'}->{'street'}->[$1 - 1] = $value;

            } elsif ($type =~ /^(name|org)$/) {
                $postalInfo->{$postalInfoType} = $info->{'postalInfo'}->{$postalInfoType} unless exists($postalInfo->{$postalInfoType});

                $postalInfo->{$postalInfoType}->{$type} = $value;

            } elsif ($type =~ /^(city|sp|pc|cc)$/) {
                $postalInfo->{$postalInfoType} = $info->{'postalInfo'}->{$postalInfoType} unless exists($postalInfo->{$postalInfoType});

                $postalInfo->{$postalInfoType}->{'addr'}->{$type} = $value;

            } else {
                return error(sprintf("unsupported object property '%s'", $type));

            }
        }
    }

    foreach my $type (keys(%{$postalInfo})) {
        $frame->chgPostalInfo($type, map { $postalInfo->{$type}->{$_} } qw(name org addr));
    }

    foreach (qw(voice fax email authInfo)) {
        if (exists($changes->{$_})) {
            my $method = 'chg'.ucfirst($_);
            $frame->$method($changes->{$_});
        }
    }

    #
    # remove empty elements
    #
    foreach (qw(add rem chg)) {
        my $el = $frame->getElementsByLocalName('contact:'.$_)->item(0);
        $el->parentNode->removeChild($el) if ($el && $el->childNodes->size < 1);
    }

    return $epp->request($frame);
}

sub note {
    my ($fmt, @args) = @_;
    my $msg = '*** '.sprintf($fmt, @args);
    $outfh->print($msg."\n");
}

sub error {
    my ($fmt, @args) = @_;
    if ($term) {
        note(color('red')."Error: ".color('reset').$fmt, @args);
        return undef;

    } else {
        fatal(@_);

    }
}

sub fatal {
    my ($fmt, @args) = @_;
    note(color('red')."Fatal Error: ".color('reset').$fmt, @args);
    exit(1);
}

1;

=pod

=for comment
To generate the README.md, run pod2markdown pepper | pandoc -f markdown -t markdown -s --toc > README.md

=head1 NAME

Pepper - A command-line EPP client.

=head1 DESCRIPTION

Pepper is a command-line client for the EPP protocol. It's written in Perl and uses the L<Net::EPP> module.

=head1 USAGE

    pepper [OPTIONS]

Available command-line options:

=over

=item * C<--help> - show help and exit.

=item * C<--host=HOST> - sets the host to connect to.

=item * C<--port=PORT> - sets the port. Defaults to 700.

=item * C<--timeout=TIMEOUT> - sets the timeout. Defaults to 3.

=item * C<--user=USER> - sets the client ID.

=item * C<--pass=PASS> - sets the client password.

=item * C<--newpw=PASS> - specify a new password to replace the current password.

=item * C<--login-security> - force the use of the Login Security extension (RFC 8807).

=item * C<--cert=FILE> - specify the client certificate to use to connect.

=item * C<--key=FILE> - specify the private key for the client certificate.

=item * C<--exec=COMMAND> - specify a command to execute. If not provided, pepper goes into interactive mode.

=item * C<--nossl> - disable TLS and connect over plaintext.

=item * C<--insecure> - disable TLS certificate checks.

=item * C<--lang=LANG> - set the language when logging in.

=item * C<--debug> - debug mode, makes C<Net::EPP::Simple> verbose.

=back

=head1 USAGE MODES

Pepper supports two usage modes:

=over

=item 1. B<Interactive mode:> this is the default mode. Pepper will provide a command prompt (with history and line editing capabilities) allowing you to input commands manually.

=item 2. B<Script mode:> if Pepper's C<STDIN> is fed a stream of text (ie, it's not attached to a terminal) then commands will be read from C<STDIN> and executed sequentially. Pepper will exit once EOF is reached.

=back

=head1 SYNTAX

Once running in interactive mode, Pepper provides a simple command-line interface. The available commands are listed below.

=head2 Getting Help

Use C<help COMMAND> at any time to get information about that command. Where a command supports different object types (ie domain, host, contact), use C<help command-type>, ie C<help create-domain>.

=head2 Connection Management

=over

=item * C<host HOST> - sets the host to connect to.

=item * C<port PORT> - sets the port. Defaults to 700.

=item * C<ssl on|off> - enable/disable SSL (default is on)

=item * C<key FILE> - sets the private key

=item * C<cert FILE> - sets the client certificate.

=item * C<timeout TIMEOUT> - sets the timeout

=item * C<connect> - connect to the server.

=item * C<hello> - gets the greeting from server.

=item * C<exit> - quit the program (logging out if necessary)

=back

=head2 Session Management

=over

=item * C<id USER> - sets the client ID.

=item * C<pw PASS> - sets the client password.

=item * C<login> - log in.

=item * C<logout> - log out.

=item * C<poll req> - requests the most recent poll message.

=item * C<poll ack ID> - acknowledge the poll message with ID C<ID>.

=back

=head2 Query Commands

=head3 Availability Checks

    check TYPE OBJECT

This checks the availability of an object. C<TYPE> is one of C<domain>, C<host>, C<contact>, C<claims> or C<fee>. See L<Claims and fee Checks> for more information about the latter two.

=head3 Object Information

    info TYPE OBJECT [PARAMS]

Get object information. C<TYPE> is one of C<domain>, C<host>, C<contact>. For domain objects, C<PARAMS> can be C<AUTHINFO [HOSTS]>, where C<AUTHINFO> is the domain's authInfo code, and the optional C<HOSTS> is the value of the "hosts" attribute (ie C<all>, which is the default, or C<del>, C<sub>, or C<none>). If you want to set C<HOSTS> but don't know the authInfo, use an empty quoted string (ie C<"">) as C<AUTHINFO>.

For contact objects, C<PARAMS> can be the contact's authInfo.

=head2 Transform Commands

=over

=item * C<create domain PARAMS> - create a domain object. See L<Creating Domain Objects> for more information.

=item * C<create host PARAMS> - create a host object. See L<Creating Host Objects> for more information.

=item * C<clone TYPE OLD NEW> - clone a domain or contact object C<OLD> into a new object identified by C<NEW>. C<TYPE> is one of C<domain> or C<contact>.

=item * C<update TYPE OBJECT CHANGES> - update an object. C<TYPE> is one of C<domain>, C<host>, or C<contact>. See L<Object Updates> for further information.

=item * C<renew DOMAIN PERIOD [EXDATE]> - renew a domain (1 year by default). If you do not provide the C<EXDATE> argument, pepper will perform an C<E<lt>infoE<gt>> command to get it from the server.

=item * C<transfer PARAMS> - object transfer management See L<Object Transfers> for more information.

=item * C<delete TYPE OBJECT> - delete an object. C<TYPE> is one of C<domain>, C<host>, or C<contact>.

=item * C<restore DOMAIN> - submit an RGP restore request for a domain.

=back

=head2 Miscellaneous Commands

=over

=item * C<send FILE> - send the contents of C<FILE> as an EPP command.

=item * C<BEGIN> - begin inputting a frame to send to the server, end with "C<END>".

=item * C<edit> - Invoke C<$EDITOR> and send the resulting file.

=back

=head2 Claims and fee Checks

Pepper provides limited support for the the Launch and Fee extensions:

=head3 Claims Check

The following command will extend the standard E<lt>checkE<gt> command to perform
a claims check as per Section 3.1.1. of L<draft-ietf-eppext-launchphase>.

    pepper> check claims example.xyz

=head3 Fee Check

The following command will extend the standard E<lt>checkE<gt> command to perform
a fee check as per Section 3.1.1. of L<draft-brown-epp-fees-02>.

    pepper> check fee example.xyz COMMAND [CURRENCY [PERIOD]]

C<COMMAND> must be one of: C<create>, C<renew>, C<transfer>, or C<restore>.
C<CURRENCY> is OPTIONAL but if provided, must be a three-character currency code.
C<PERIOD> is also OPTIONAL but if provided, must be an integer between 1 and 99.

=head2 Creating Objects

=head3 Creating Domain Objects

There are two ways of creating a domain:

    clone domain OLD NEW

This command creates the domain C<NEW> using the same contacts and nameservers as C<OLD>.

    create domain DOMAIN PARAMS

This command creates a domain according to the parameters specified after the domain. C<PARAMS> consists of pairs of name and (optionally quoted) value pairs as follows:

=over

=item * C<period> - the registration period. Defaults to 1 year.

=item * C<registrant> - the registrant.

=item * C<admin> - the admin contact.

=item * C<tech> - the tech contact.

=item * C<billing> - the billing contact.

=item * C<ns> - add a nameserver.

=item * C<authinfo> - authInfo code. A random string will be used if not provided.

=back

Example:

    pepper (id@host)> create domain example.xyz period 1 registrant sh8013 admin sh8013 tech sh8013 billing sh8013 ns ns0.example.com ns ns1.example.net

=head3 Creating Host Objects

Syntax:

    create host HOSTNAME [IP [IP [IP [...]]]]

Create a host object with the specified C<HOSTNAME>. IP address may also be
specified: IPv4 and IPv6 addresses are automatically detected.

=head3 Creating Contact Objects

There are two ways of creating a contact:

    clone contact OLD NEW

This command creates the contact C<NEW> using the same data as C<OLD>.

    create contact PARAMS

This command creates a contact object according to the parameters specified. C<PARAMS> consists of pairs of name and (optionally quoted) value pairs as follows:

=over

=item * C<id> - contact ID. If not provided, a random 16-charater ID will be generated

=item * C<type> - specify the "type" attribute for the postal address information. Only one type is supported. Possible values are "int" (default) and "loc".

=item * C<name> - contact name

=item * C<org> - contact organisation

=item * C<street> - street address, may be provided multiple times

=item * C<city> - city

=item * C<sp> - state/province

=item * C<pc> - postcode

=item * C<cc> - ISO-3166-alpha2 country code

=item * C<voice> - E164 voice number

=item * C<fax> - E164 fax number

=item * C<email> - email address

=item * C<authinfo> - authInfo code. A random string will be used if not provided.

=back

Example:

    pepper (id@host)> create contact id "sh8013" name "John Doe" org "Example Inc." type int street "123 Example Dr." city Dulles sp VA pc 20166-6503 cc US voice +1.7035555555 email jdoe@example.com

=head2 Object Updates

Objects may be updated using the C<update> command.

=head3 Domain Updates

    update domain DOMAIN CHANGES

The C<CHANGES> argument consists of groups of three values: an action (ie C<add>, C<rem> or C<chg>), followed by a property name (e.g. C<ns>, a contact type (such as C<admin>, C<tech> or C<billing>) or C<status>), followed by a value.

Example:

    update domain example.com add ns ns0.example.com

    update domain example.com rem ns ns0.example.com

    update domain example.com add status clientUpdateProhibited

    update domain example.com rem status clientHold

    update domain example.com add admin H12345

    update domain example.com rem tech H54321

    update domain example.com chg registrant H54321

    update domain example.cm chg authinfo foo2bar

Multiple changes can be combined in a single command:

    update domain example.com add status clientUpdateProhibited rem ns ns0.example.com chg registrant H54321

=head3 Host Updates

Syntax:

    update host HOSTNAME CHANGES

The C<CHANGES> argument consists of groups of three values: an action (ie C<add>, C<rem> or C<chg>), followed by a property name (ie C<addr>, C<status> or C<name>), followed by a value (which may be quoted).

Examples:

    update host ns0.example.com add status clientUpdateProhibited

    update host ns0.example.com rem addr 10.0.0.1

    update host ns0.example.com chg name ns0.example.net

Multiple changes can be combined in a single command:

    update host ns0.example.com add status clientUpdateProhibited rem addr 10.0.0.1 add addr 1::1 chg name ns0.example.net

=head3 Contact Updates

    update contact ID CHANGES

The C<CHANGES> argument consists of groups of three values: an action (ie C<add>, C<rem> or C<chg>), followed by a property name, followed by a value (which may be quoted, and may be empty). The property name may be one of:

=over

=item * C<status>

=item * C<name>

=item * C<type> (either "C<int>" or "C<loc>", which applies to all subsequent values, and which may appear multiple times)

=item * C<org>

=item * C<street1>, C<street2>, C<street3>

=item * C<city>

=item * C<sp>

=item * C<pc>

=item * C<cc>

=item * C<voice>

=item * C<fax>

=item * C<email>

=item * C<authInfo>

=back

If postal address information is being changed, then any values not specified in the command line will be populated from the existing object information. This is because contact information is updated atomically.

Examples:

    pepper (id@host)> create contact id "sh8013" name "John Doe" org "Example Inc." type int street "123 Example Dr." city Dulles sp VA pc 20166-6503 cc US voice  email jdoe@example.com

    update contact sh8013 chg email example@example.com

    update contact sh8013 chg voice +1.7035555555

    update contact sh8013 street1 "123 Example Dr." street2 "" street3 ""

    update contact city Dulles sp VA pc 20166-6503 cc US

    update contact authInfo foo2bar

=head2 Object Transfers

Object transfers may be managed with the C<transfer> command. Usage:

    transfer TYPE OBJECT CMD [AUTHINFO [PERIOD]]

where:

=over

=item * C<TYPE> - C<domain> or C<contact>

=item * C<OBJECT> - domain name or contact ID

=item * C<CMD> - one of (C<request>, C<query>, C<approve>, C<reject>, or C<cancel>)

=item * C<AUTHINFO> - authInfo code (used with C<request> only)

=item * C<PERIOD> - additional validity period (used with domain C<request> only)

=back

=head2 Errors

If you prefix a command with a C<!> character, then Pepper will end the session if an EPP command fails (that is, if the result code of the response is 2000 or higher).

This is mostly useful in scripting mode where you may want the script to terminate if an error occurs.

Example usage:

    !create domain example.com authinfo foo2bar
    update domain example.com add ns ns0.example.com

In the above example, Pepper will end the session if the first command fails, since there is no point in running the second command if the first has failed.

=head1 INSTALLATION

To install, run:

    cpanm --sudo App::pepper

If L<Term::ReadLine::Gnu> is available, then Pepper can provide a richer interactive command line, with support for history and rich command editing.

=head1 RUNNING VIA DOCKER

The L<git repository|https://github.com/gbxyz/pepper> contains a C<Dockerfile>
that can be used to build an image on your local system.

Alternatively, you can pull the L<image from Docker Hub|https://hub.docker.com/r/gbxyz/pepper>:

    $ docker pull gbxyz/pepper

    $ docker run -it gbxyz/pepper --help

=head1 LICENSE

Copyright 2014 - 2023 CentralNic Group plc.
Copyright 2023 - 2025 Gavin Brown.

This program is Free Software; you can use it and/or modify it under the same terms as Perl itself.

=cut
