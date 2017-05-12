use strict;
use warnings;

package AnyEvent::GnuPG;

# ABSTRACT: AnyEvent-based interface to the GNU Privacy Guard

use Exporter 'import';
use AnyEvent;
use AnyEvent::Proc 0.104;
use Email::Address;
use Async::Chain;
use Try::Tiny;
use Carp qw(confess);

use constant RSA_RSA     => 1;
use constant DSA_ELGAMAL => 2;
use constant DSA         => 3;
use constant RSA         => 4;

use constant TRUST_UNDEFINED => -1;
use constant TRUST_NEVER     => 0;
use constant TRUST_MARGINAL  => 1;
use constant TRUST_FULLY     => 2;
use constant TRUST_ULTIMATE  => 3;

our $VERSION = '1.001';    # VERSION

our @EXPORT = qw();

our %EXPORT_TAGS = (
    algo  => [qw[ RSA_RSA DSA_ELGAMAL DSA RSA ]],
    trust => [
        qw[ TRUST_UNDEFINED TRUST_NEVER TRUST_MARGINAL TRUST_FULLY TRUST_ULTIMATE ]
    ],
);

Exporter::export_ok_tags(qw( algo trust ));

sub _options {
    my $self = shift;
    $self->{cmd_options} = shift if ( $_[0] );
    $self->{cmd_options};
}

sub _command {
    my $self = shift;
    $self->{command} = shift if ( $_[0] );
    $self->{command};
}

sub _args {
    my $self = shift;
    $self->{args} = shift if ( $_[0] );
    $self->{args};
}

sub _cmdline {
    my $self = shift;
    my $args = [ $self->{gnupg_path} ];

    # Default options
    push @$args, "--no-tty", "--no-greeting", "--yes";

    # Check for homedir and options file
    push @$args, "--homedir", $self->{homedir} if $self->{homedir};
    push @$args, "--options", $self->{options} if $self->{options};

    # Command options
    push @$args, @{ $self->_options };

    # Command and arguments
    push @$args, "--" . $self->_command;
    push @$args, @{ $self->_args };

    return $args;
}

sub _condvar {
    my $cb = shift;
    return $cb if ref $cb eq 'AnyEvent::CondVar';
    my $cv = AE::cv;
    $cv->cb($cb) if ref $cb eq 'CODE';
    $cb ||= '';
    $cv;
}

sub _croak {
    my ( $cv, $msg ) = @_;
    AE::log error => $msg;
    $cv->croak($msg);
    $cv;
}

sub _catch {
    my ( $cv1, $cb ) = @_;
    AE::cv {
        my $cv2 = shift;
        try {
            $cb->( $cv2->recv );
        }
        catch {
            s{ at \S+ line \d+\.\s+$}{};
            $cv1->croak($_)
        };
    }
}

sub _eq($_) { shift eq pop }    ## no critic

sub _parse_status {
    my ( $self, $cv, %actions ) = @_;
    my $commands;
    $self->{status_fd}->readlines_cb(
        sub {
            my $line = shift;
            unless ( defined $line ) {
                AE::log debug => "end of status parsing";
                $cv->send($commands);
            }
            if ( my ( $cmd, $arg ) =
                $line =~ m{^\[gnupg:\]\s+(\w+)\s*(.+)?\s*$}i )
            {
                $arg ||= '';
                my @args = $arg ? ( split /\s+/, $arg ) : ();
                AE::log debug => "got command: $cmd ($arg)";
                try {
                    for ( lc $cmd ) {
                        _eq('newsig')  && do { last };
                        _eq('goodsig') && do { last };
                        _eq('expsig')
                          && do { die "the signature is expired ($arg)" };
                        _eq('expkeysig') && do {
                            die
                              "the signature was made by an expired key ($arg)";
                        };
                        _eq('revkeysig') && do {
                            die
                              "the signature was made by an revoked key ($arg)";
                        };
                        _eq('badsig') && do {
                            die
                              "the signature has not been verified okay ($arg)";
                        };
                        _eq('errsig') && do {
                            die "the signature could not be verified ($arg)";
                        };
                        _eq('validsig') && do { last };
                        _eq('sig_id')   && do { last };
                        _eq('enc_to')   && do { last };
                        _eq('nodata')   && do {
                            for ($arg) {
                                _eq('1') && die "no armored data";
                                _eq('2')
                                  && die
                                  "expected a packet but did not found one";
                                _eq('3') && die "invalid packet found";
                                _eq('4')
                                  && die "signature expected but not found";
                                die "no data has been found";
                            }
                        };
                        _eq('unexpected')
                          && do { die "unexpected data has been encountered" };
                        _eq('trust_undefined')
                          && do { die "signature trust undefined: $arg" };
                        _eq('trust_never')
                          && do { die "signature trust is never: $arg" };
                        _eq('trust_marginal') && do { last };
                        _eq('trust_fully')    && do { last };
                        _eq('trust_ultimate') && do { last };
                        _eq('pka_trust_good') && do { last };
                        _eq('pka_trust_bad')  && do { last };
                        _eq('sigexpired')
                          or _eq('keyexpired') && do {
                            die "the key has expired since "
                              . ( scalar localtime $arg );
                          };
                        _eq('keyrevoked') && do {
                            die "the used key has been revoked by its owner";
                        };
                        _eq('badarmor')
                          && do { die "the ASCII armor is corrupted" };
                        _eq('rsa_or_idea')         && do { last };
                        _eq('shm_info')            && do { last };
                        _eq('shm_get')             && do { last };
                        _eq('shm_get_bool')        && do { last };
                        _eq('shm_get_hidden')      && do { last };
                        _eq('get_bool')            && do { last };
                        _eq('get_line')            && do { last };
                        _eq('get_hidden')          && do { last };
                        _eq('got_it')              && do { last };
                        _eq('need_passphrase')     && do { last };
                        _eq('need_passphrase_sym') && do { last };
                        _eq('need_passphrase_pin') && do { last };
                        _eq('missing_passphrase')
                          && do { die "no passphrase was supplied" };
                        _eq('bad_passphrase') && do {
                            die
                              "the supplied passphrase was wrong or not given";
                        };
                        _eq('good_passphrase') && do { last };
                        _eq('decryption_failed')
                          && do { die "the symmetric decryption failed" };
                        _eq('decryption_okay') && do { last };
                        _eq('decryption_info') && do { last };
                        _eq('no_pubkey')
                          && do { die "the public key is not available" };
                        _eq('no_seckey')
                          && do { die "the private key is not available" };
                        _eq('import_check') && do { last };
                        _eq('imported')
                          && do { @args = split /\s+/, $arg, 2; last };
                        _eq('import_ok') && do { last };
                        _eq('import_problem') && do {

                            for ($arg) {
                                _eq('0')
                                  && die
                                  "import failed with no specific reason";
                                _eq('1') && die "invalid certificate";
                                _eq('2') && die "issuer certificate missing";
                                _eq('3') && die "certificate chain too long";
                                _eq('4') && die "error storing certificate";
                                die "import failed";
                            }
                        };
                        _eq('import_res')       && do { last };
                        _eq('file_start')       && do { last };
                        _eq('file_done')        && do { last };
                        _eq('begin_decryption') && do { last };
                        _eq('end_decryption')   && do { last };
                        _eq('begin_encryption') && do { last };
                        _eq('end_encryption')   && do { last };
                        _eq('begin_signing')    && do { last };
                        _eq('delete_problem')   && do {

                            for ($arg) {
                                _eq('1') && die "delete failed: no such key";
                                _eq('2')
                                  && die
                                  "delete failed: must delete secret key first";
                                _eq('3')
                                  && die
                                  "delete failed: ambigious specification";
                                die "delete failed";
                            }
                        };
                        _eq('progress')    && do { last };
                        _eq('sig_created') && do { last };
                        _eq('key_created') && do { last };
                        _eq('key_not_created') && do {
                            die "the key from batch run has not been created";
                        };
                        _eq('session_key')   && do { last };
                        _eq('notation_name') && do { last };
                        _eq('notation_data') && do { last };
                        _eq('userid_hint')   && do { last };
                        _eq('policy_url')    && do { last };
                        _eq('begin_stream')  && do { last };
                        _eq('end_stream')    && do { last };
                        ( _eq('inv_recp') or _eq('inc_sgnr') ) && do {
                            my $prefix = 'invalid';
                            for ($cmd) {
                                _eq('inv_recp')
                                  && do { $prefix .= ' recipient' };
                                _eq('inv_sgnr') && do { $prefix .= ' sender' };
                            }
                            $prefix .= ': ';
                            for ( shift(@args) ) {
                                _eq('0') && die $prefix . "no specific reason";
                                _eq('1') && die $prefix . "not found";
                                _eq('2')
                                  && die $prefix . "ambigious specification";
                                _eq('3')  && die $prefix . "wrong key usage";
                                _eq('4')  && die $prefix . "key revoked";
                                _eq('5')  && die $prefix . "key expired";
                                _eq('6')  && die $prefix . "no CRL known";
                                _eq('7')  && die $prefix . "CRL too old";
                                _eq('8')  && die $prefix . "policy mismatch";
                                _eq('9')  && die $prefix . "not a secret key";
                                _eq('10') && die $prefix . "key not trusted";
                                _eq('11')
                                  && die $prefix . "missing certificate";
                                _eq('12')
                                  && die $prefix . "missing issuer certificate";
                                die $prefix . '???';
                            }
                        };
                        _eq('no_recp') && do { die "no recipients are usable" };
                        _eq('no_sgnr') && do { die "no senders are usable" };
                        _eq('already_signed')   && do { last };
                        _eq('truncated')        && do { last };
                        _eq('error')            && do { die $arg };
                        _eq('success')          && do { last };
                        _eq('attribute')        && do { last };
                        _eq('cardctrl')         && do { last };
                        _eq('plaintext')        && do { last };
                        _eq('plaintext_length') && do { last };
                        _eq('sig_subpacket')    && do { last };
                        _eq('sc_op_failure')
                          && do { die "smartcard failure ($arg)" };
                        _eq('sc_op_success')      && do { last };
                        _eq('backup_key_created') && do { last };
                        _eq('mountpoint')         && do { last };
                        AE::log note => "unknown command: $cmd";
                    }
                    my $result;
                    if ( $actions{ lc($cmd) } ) {
                        $result = $actions{ lc($cmd) }->(@args);
                    }
                    push @$commands => {
                        cmd    => $cmd,
                        arg    => $arg,
                        args   => \@args,
                        result => $result
                    };
                }
                catch {
                    s{\s+$}{};
                    $self->_abort_gnupg( $_, $cv );
                }
                finally {
                    AE::log debug => "arguments parsed as: ["
                      . ( join ', ', map { "'$_'" } @args ) . "]";
                }
            }
            else {
                return $self->_abort_gnupg(
                    "error communicating with gnupg: bad status line: $line",
                    $cv );
            }
        }
    );
    $cv;
}

sub _abort_gnupg {
    my ( $self, $msg, $cb ) = @_;
    my $cv = _condvar($cb);
    AE::log error => $msg if $msg;
    if ( $self->{gnupg_proc} ) {
        $self->{gnupg_proc}->fire_and_kill(
            10,
            sub {
                AE::log debug => "fired and killed";
                $self->_end_gnupg(
                    sub {
                        AE::log debug => "gnupg aborted";
                        $cv->croak($msg);
                    }
                );
            }
        );
    }
    $cv;
}

sub _end_gnupg {
    my ( $self, $cb ) = @_;
    my $cv = _condvar($cb);

    if ( ref $self->{input} eq 'GLOB' ) {
        close $self->{input};
    }

    if ( $self->{command_fd} ) {
        $self->{command_fd}->finish;
    }

    if ( 0 && $self->{status_fd} ) {
        $self->{status_fd}->A->destroy;
    }

    if ( $self->{gnupg_proc} ) {

        $self->{gnupg_proc}->wait(
            sub {
                if ( ref $self->{output} eq 'GLOB' ) {
                    close $self->{output};
                }

                for (
                    qw(protocol proc command options args status_fd command_fd input output next_status )
                  )
                {
                    delete $self->{$_};
                }

                AE::log debug => "gnupg exited";
                $cv->send;
            }
        );

    }
    else {
        $cv->send;
    }
    $cv;
}

sub _run_gnupg {
    my ( $self, $cv ) = @_;

    if ( defined $self->{input} and not ref $self->{input} ) {
        my $file = $self->{input};
        open( my $fh, '<', $file ) or die "cannot open file $file: $!";
        AE::log info => "input file $file opened at $fh";
        $self->{input} = $fh;
    }

    if ( defined $self->{output} and not ref $self->{output} ) {
        my $file = $self->{output};
        open( my $fh, '>', $file ) or die "cannot open file $file: $!";
        AE::log info => "output file $file opened at $fh";
        $self->{output} = $fh;
    }

    my $cmdline = $self->_cmdline;

    my $gpg = shift @$cmdline;

    my $status  = AnyEvent::Proc::reader();
    my $command = AnyEvent::Proc::writer();

    unshift @$cmdline, '--status-fd'  => $status;
    unshift @$cmdline, '--command-fd' => $command;

    my $err;

    AE::log debug => "running $gpg " . join( ' ' => @$cmdline );
    my $proc = AnyEvent::Proc->new(
        bin           => $gpg,
        args          => $cmdline,
        extras        => [ $status, $command ],
        ttl           => 600,
        on_ttl_exceed => sub { $self->_abort_gnupg( 'ttl exceeded', $cv ) },
        errstr        => \$err,
    );

    if ( defined $self->{input} ) {
        $proc->pull( $self->{input} );
    }

    if ( defined $self->{output} ) {
        $proc->pipe( out => $self->{output} );
    }

    $self->{command_fd} = $command;
    $self->{status_fd}  = $status;
    $self->{gnupg_proc} = $proc;

    AE::log debug => "gnupg ready";

    $proc;
}

sub _send_command {
    shift->{command_fd}->writeln(pop);
}

sub DESTROY {
    my $self = shift;

    $self->{gnupg_proc}->kill if $self->{gnupg_proc};
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %args = @_;

    my $self = {};
    if ( $args{homedir} ) {
        confess("Invalid home directory: $args{homedir}")
          unless -d $args{homedir} && -x _;
        $self->{homedir} = $args{homedir};
    }
    if ( $args{options} ) {
        confess("Invalid options file: $args{options}")
          unless -r $args{options};
        $self->{options} = $args{options};
    }
    if ( $args{gnupg_path} ) {
        confess("Invalid gpg path: $args{gnupg_path}")
          unless -x $args{gnupg_path};
        $self->{gnupg_path} = $args{gnupg_path};
    }
    else {
        my ($path) = grep { -x "$_/gpg" } split /:/, $ENV{PATH};
        confess("Couldn't find gpg in PATH ($ENV{PATH})") unless $path;
        $self->{gnupg_path} = "$path/gpg";
    }

    bless $self, $class;
}

sub version {
    shift->version_cb(@_)->recv;
}

sub version_cb {
    my ( $self, $cb ) = @_;
    my $cv = _condvar($cb);

    $self->_command("version");
    $self->_options( [] );
    $self->_args(    [] );

    my $version;

    my $proc = $self->_run_gnupg($cv);

    $proc->pipe( \$version );

    $proc->finish;

    $self->_end_gnupg(
        sub {
            if ( $version =~ m{\d(?:\.\d)*} ) {
                $cv->send( split m{\.} => $& );
            }
            else {
                $cv->croak(
                    "cannot obtain version number from string: '$version'");
            }
        }
    );

    $cv;
}

sub gen_key {
    shift->gen_key_cb(@_)->recv;
}

sub gen_key_cb {
    my ( $self, %args ) = @_;
    my $cv = _condvar( delete $args{cb} );
    my $cmd;
    my $arg;

    my $algo = $args{algo};
    $algo ||= RSA_RSA;

    my $size = $args{size};
    $size ||= 1024;
    return _croak( $cv, "Keysize is too small: $size" ) if $size < 768;
    return _croak( $cv, "Keysize is too big: $size" )   if $size > 2048;

    my $expire = $args{valid};
    $expire ||= 0;

    my $passphrase = $args{passphrase} || "";
    my $name = $args{name};

    return _croak( $cv, "Missing key name" ) unless $name;
    return _croak( $cv, "Invalid name: $name" )
      unless $name =~ /^\s*[^0-9\<\(\[\]\)\>][^\<\(\[\]\)\>]+$/;

    my $email = $args{email};
    if ($email) {
        ($email) = Email::Address->parse($email)
          or _croak( $cv, "Invalid email address: $email" );
    }
    else {
        $email = "";
    }

    my $comment = $args{comment};
    if ($comment) {
        _croak( $cv, "Invalid characters in comment" ) if $comment =~ /[\(\)]/;
    }
    else {
        $comment = "";
    }

    $self->_command("gen-key");
    $self->_options( [] );
    $self->_args(    [] );

    my $proc = $self->_run_gnupg($cv);
    $proc->finish unless $self->{input};

    $self->_parse_status(
        $cv,
        progress => $args{progress},
        get_line => sub {
            my ($key) = @_;
            for ($key) {
                _eq('keygen.algo')
                  && $self->_send_command($algo)
                  && last;
                _eq('keygen.size')
                  && $self->_send_command($size)
                  && last;
                _eq('keygen.valid')
                  && $self->_send_command($expire)
                  && last;
                _eq('keygen.name')
                  && $self->_send_command($name)
                  && last;
                _eq('keygen.email')
                  && $self->_send_command($email)
                  && last;
                _eq('keygen.comment')
                  && $self->_send_command($comment)
                  && last;
                $self->_abort_gnupg( "unknown key: $key", $cv );
            }
        },
        need_passphrase_sym => sub {
            unless ( defined $passphrase ) {
                return $self->_abort_gnupg( "passphrase required", $cv );
            }
        },
        get_hidden => sub {
            $self->_send_command($passphrase);
        },
        key_created => sub {
            my $fingerprint = $_[1];
            $self->_end_gnupg( sub { $cv->send($fingerprint) } );
        }
    );

    $cv;
}

sub import_keys {
    shift->import_keys_cb(@_)->recv->{count};
}

sub import_keys_cb {
    my ( $self, %args ) = @_;
    my $cv = _condvar( delete $args{cb} );

    $self->_command("import");
    $self->_options( [] );

    my $count = 0;
    if ( ref $args{keys} eq 'ARRAY' ) {
        $self->_args( $args{keys} );
    }
    else {
        $self->{input} = $args{keys};
        $self->_args( [] );
    }

    my $proc = $self->_run_gnupg($cv);
    $proc->finish unless $self->{input};

    my $num_files = ref $args{keys} ? @{ $args{keys} } : 1;

    $self->_parse_status(
        $cv,
        imported   => sub { $count++ },
        import_res => sub {
            $self->_end_gnupg(
                _catch(
                    $cv,
                    sub {
                        $cv->send( { count => $count } );
                    }
                )
            );
        }
    );

    $cv;
}

sub import_key {
    shift->import_key_cb(@_)->recv;
}

sub import_key_cb {
    my ( $self, $keystr, $cb ) = @_;
    $self->import_keys_cb( keys => \"$keystr", cb => $cb );
}

sub export_keys {
    shift->export_keys_cb(@_)->recv;
}

sub export_keys_cb {
    my ( $self, %args ) = @_;
    my $cv = _condvar( delete $args{cb} );

    my $options = [];
    push @$options, "--armor" if $args{armor};

    $self->{output} = $args{output};

    my $keys = [];
    if ( $args{keys} ) {
        push @$keys, ref $args{keys} ? @{ $args{keys} } : $args{keys};
    }

    if ( $args{secret} ) {
        $self->_command("export-secret-keys");
    }
    elsif ( $args{all} ) {
        $self->_command("export-all");
    }
    else {
        $self->_command("export");
    }

    $self->_options($options);
    $self->_args($keys);

    my $proc = $self->_run_gnupg($cv);

    $proc->finish unless $self->{input};

    $self->_end_gnupg( _catch( $cv, sub { $cv->send( {} ) } ) );

    $cv;
}

sub encrypt {
    shift->encrypt_cb(@_)->recv;
}

sub encrypt_cb {
    my ( $self, %args ) = @_;
    my $cv = _condvar( delete $args{cb} );

    my $options = [];
    croak("no recipient specified")
      unless $args{recipient} or $args{symmetric};

    for my $recipient (
        grep defined,
        (
            ref $args{recipient} eq 'ARRAY'
            ? @{ $args{recipient} }
            : $args{recipient}
        )
      )
    {
        # Escape spaces in the recipient. This fills some strange edge case
        $recipient =~ s/ /\ /g;
        push @$options, "--recipient" => $recipient;
    }

    push @$options, "--sign" if $args{sign};
    croak("can't sign an symmetric encrypted message")
      if $args{sign} and $args{symmetric};

    my $passphrase = $args{passphrase} || "";

    push @$options, "--armor" if $args{armor};
    push @$options, "--local-user", $args{"local-user"}
      if defined $args{"local-user"};

    push @$options, "--auto-key-locate", $args{"auto-key-locate"}
      if defined $args{"auto-key-locate"};

    push @$options, "--keyserver", $args{"keyserver"}
      if defined $args{"keyserver"};

    $self->{input} = $args{plaintext} || $args{input};
    $self->{output} = $args{output};
    if ( $args{symmetric} ) {
        $self->_command("symmetric");
    }
    else {
        $self->_command("encrypt");
    }
    $self->_options($options);
    $self->_args( [] );

    my $proc = $self->_run_gnupg($cv);
    $proc->finish unless $self->{input};

    $self->_parse_status(
        $cv,
        end_encryption => sub {
            $self->_end_gnupg(
                sub {
                    $cv->send;
                }
            );
        },
        need_passphrase => sub {
            unless ( defined $passphrase ) {
                return $self->_abort_gnupg( "passphrase required", $cv );
            }
        },
        get_hidden => sub {
            $self->_send_command($passphrase);
        },
        get_bool => sub {
            for (shift) {
                _eq('untrusted_key.override')
                  && do { $self->_send_command('y'); last }
            }
        },
    );

    $cv;
}

sub sign {
    shift->sign_cb(@_)->recv;
}

sub sign_cb {
    my ( $self, %args ) = @_;
    my $cv = _condvar( delete $args{cb} );

    my $options = [];
    my $passphrase = $args{passphrase} || "";

    push @$options, "--armor" if $args{armor};
    push @$options, "--local-user", $args{"local-user"}
      if defined $args{"local-user"};

    $self->{input} = $args{plaintext} || $args{input};
    $self->{output} = $args{output};
    if ( $args{clearsign} ) {
        $self->_command("clearsign");
    }
    elsif ( $args{"detach-sign"} ) {
        $self->_command("detach-sign");
    }
    else {
        $self->_command("sign");
    }
    $self->_options($options);
    $self->_args( [] );

    my $proc = $self->_run_gnupg($cv);
    $proc->finish unless $self->{input};

    $self->_parse_status(
        $cv,
        need_passphrase => sub {
            unless ( defined $passphrase ) {
                return $self->_abort_gnupg( "passphrase required", $cv );
            }
        },
        get_hidden => sub {
            $self->_send_command($passphrase);
        },
        sig_created => sub {
            $self->_end_gnupg( sub { $cv->send } );
        },
    );

    $cv;
}

sub clearsign {
    my $self = shift;
    $self->sign( @_, clearsign => 1 );
}

sub clearsign_cb {
    my $self = shift;
    $self->sign_cb( @_, clearsign => 1 );
}

sub verify {
    shift->verify_cb(@_)->recv;
}

sub verify_cb {
    my ( $self, %args ) = @_;
    my $cv = _condvar( delete $args{cb} );

    return _croak( $cv, "missing signature argument" ) unless $args{signature};
    my $files = [];
    if ( $args{file} ) {
        $args{file} = [ $args{file} ] unless ref $args{file};
        @$files = ( $args{signature}, @{ $args{file} } );
    }
    else {
        $self->{input} = $args{signature};
    }

    my $options = [];

    push @$options, "--auto-key-locate", $args{"auto-key-locate"}
      if defined $args{"auto-key-locate"};

    push @$options, "--keyserver", $args{"keyserver"}
      if defined $args{"keyserver"};

    my @verify_options = ();

    push @verify_options => 'pka-lookups'        if $args{'pka-loopups'};
    push @verify_options => 'pka-trust-increase' if $args{'pka-trust-increase'};

    push @$options => ( '--verify-options' => join( ',' => @verify_options ) )
      if @verify_options;

    $self->_command("verify");
    $self->_options($options);
    $self->_args($files);

    my $proc = $self->_run_gnupg($cv);
    $proc->finish unless $self->{input};

    my $sig = { trust => TRUST_UNDEFINED, };

    $self->_parse_status(
        $cv,
        sig_id => sub {
            ( $sig->{sigid}, $sig->{data}, $sig->{timestamp} ) = @_;
        },
        goodsig => sub {
            ( $sig->{keyid}, $sig->{user} ) = @_;
        },
        validsig => sub {
            ( $sig->{fingerprint} ) = @_;
            $self->_end_gnupg( sub { $cv->send } );
        },
        policy_url => sub {
            ( $sig->{policy_url} ) = @_;
        },
        trust_never => sub {
            $sig->{trust} = TRUST_NEVER;
        },
        trust_marginal => sub {
            $sig->{trust} = TRUST_MARGINAL;
        },
        trust_fully => sub {
            $sig->{trust} = TRUST_FULLY;
        },
        trust_ultimate => sub {
            $sig->{trust} = TRUST_ULTIMATE;
        },
    );

    $cv;
}

sub decrypt {
    shift->decrypt_cb(@_)->recv;
}

sub decrypt_cb {
    my ( $self, %args ) = @_;
    my $cv = _condvar( delete $args{cb} );

    $self->{input} = $args{ciphertext} || $args{input};
    $self->{output} = $args{output};
    $self->_command("decrypt");
    $self->_options( [] );
    $self->_args(    [] );

    my $proc = $self->_run_gnupg($cv);
    $proc->finish unless $self->{input};

    my $passphrase = $args{passphrase} || "";

    my $sig = { trust => TRUST_UNDEFINED, };

    $self->_parse_status(
        $cv,
        need_passphrase => sub {
            unless ( defined $passphrase ) {
                return $self->_abort_gnupg( "passphrase required", $cv );
            }
        },
        get_hidden => sub {
            $self->_send_command($passphrase);
        },
        end_decryption => sub {
            $self->_end_gnupg( sub { $cv->send } );
        },
        sig_id => sub {
            ( $sig->{sigid}, $sig->{data}, $sig->{timestamp} ) = @_;
        },
        goodsig => sub {
            ( $sig->{keyid}, $sig->{user} ) = @_;
        },
        validsig => sub {
            ( $sig->{fingerprint} ) = @_;
        },
        policy_url => sub {
            ( $sig->{policy_url} ) = @_;
        },
        trust_never => sub {
            $sig->{trust} = TRUST_NEVER;
        },
        trust_marginal => sub {
            $sig->{trust} = TRUST_MARGINAL;
        },
        trust_fully => sub {
            $sig->{trust} = TRUST_FULLY;
        },
        trust_ultimate => sub {
            $sig->{trust} = TRUST_ULTIMATE;
        },
    );

    $cv;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::GnuPG - AnyEvent-based interface to the GNU Privacy Guard

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use AnyEvent::GnuPG qw( :algo );

    my $gpg = AnyEvent::GnuPG->new();

    $gpg->encrypt(
        plaintext   => "file.txt",
        output      => "file.gpg",
        armor       => 1,
        sign        => 1,
        passphrase  => $secret
    );
    
    $gpg->decrypt(
        ciphertext    => "file.gpg",
        output        => "file.txt"
    );
    
    $gpg->clearsign(
        plaintext => "file.txt",
        output => "file.txt.asc",
        passphrase => $secret,
        armor => 1,
    );
    
    $gpg->verify(
        signature => "file.txt.asc",
        file => "file.txt"
    );
    
    $gpg->gen_key(
        name => "Joe Blow",
        comment => "My GnuPG key",
        passphrase => $secret,
    );

=head1 DESCRIPTION

AnyEvent::GnuPG is a perl interface to the GNU Privacy Guard. It uses the shared memory coprocess interface that gpg provides for its wrappers. It tries its best to map the interactive interface of the gpg to a more programmatic model.

=head1 METHODS

=head2 new(%params)

You create a new AnyEvent::GnuPG wrapper object by invoking its new method. (How original!). The module will try to finds the B<gpg> program in your path and will croak if it can't find it. Here are the parameters that it accepts:

=over 4

=item * gnupg_path

Path to the B<gpg> program.

=item * options

Path to the options file for B<gpg>. If not specified, it will use the default one (usually F<~/.gnupg/options>).

=item * homedir

Path to the B<gpg> home directory. This is the directory that contains the default F<options> file, the public and private key rings as well as the trust database.

=back

Example:

    my $gpg = AnyEvent::GnuPG->new();

=head2 version

This method returns the current gpg version as list.

    my @version = $gpg->version;
    # returns ( 1, 4, 18 ) for example

=head2 version_cb

Asynchronous variant of L</version>.

=head2 gen_key(%params)

This methods is used to create a new gpg key pair. The methods croaks if there is an error. It is a good idea to press random keys on the keyboard while running this methods because it consumes a lot of entropy from the computer. Here are the parameters it accepts:

=over 4

=item * algo

This is the algorithm use to create the key. Can be I<DSA_ELGAMAL>, I<DSA>, I<RSA_RSA> or I<RSA>. It defaults to I<DSA_ELGAMAL>. To import those constant in your name space, use the I<:algo> tag.

=item * size

The size of the public key. Defaults to 1024. Cannot be less than 768 bits, and keys longer than 2048 are also discouraged. (You *DO* know that your monitor may be leaking sensitive information ;-).

=item * valid

How long the key is valid. Defaults to 0 or never expire.

=item * name

This is the only mandatory argument. This is the name that will used to construct the user id.

=item * email

Optional email portion of the user id.

=item * comment

Optional comment portion of the user id.

=item * passphrase

The passphrase that will be used to encrypt the private key. Optional but strongly recommended.

=back

Example:

    $gpg->gen_key(
        algo => DSA_ELGAMAL,
        size => 1024,
        name => "My name"
    );

=head2 gen_key_cb(%params[, cb => $callback|$condvar])

Asynchronous variant of L</gen_key>.

=head2 import_keys(%params)

Import keys into the GnuPG private or public keyring. The method croaks if it encounters an error. Parameters:

=over 4

=item * keys

Only parameter and mandatory. It can either be an ArrayRef containing a list of files that will be imported or a single file name or anything else that L<AnyEvent::Proc/pull> accepts.

=back

Example:

    $gpg->import_keys(
        keys => [qw[ key.pub key.sec ]]
    );

=head2 import_keys_cb(%args[, cb => $callback|$condvar])

Asynchronous variant of L</import_keys>. It returns the number of keys imported.

=head2 import_key($string)

Import one single key into the GnuPG private or public keyring. The method croaks if it encounters an error.

Example:

    $gpg->import_keys($string);

=head2 import_key_cb($string[, $callback|$condvar])

Asynchronous variant of L</import_key>.

=head2 export_keys(%params)

Exports keys from the GnuPG keyrings. The method croaks if it encounters an error. Parameters:

=over 4

=item * keys

Optional argument that restricts the keys that will be exported. Can either be a user id or a reference to an array of userid that specifies the keys to be exported. If left unspecified, all keys will be exported.

=item * secret

If this argument is to true, the secret keys rather than the public ones will be exported.

=item * all

If this argument is set to true, all keys (even those that aren't OpenPGP compliant) will be exported.

=item * output

This argument specifies where the keys will be exported. Can be either a file name or anything else that L<AnyEvent::Proc/pipe> accepts.

=item * armor

Set this parameter to true, if you want the exported keys to be ASCII armored.

=back

Example:

    $gpg->export_keys(
        armor => 1,
        output => "keyring.pub"
    );

=head2 export_keys_cb(%params[, cb => $callback|$condvar])

Asynchronous variant of L</export_keys>.

=head2 encrypt(%params)

This method is used to encrypt a message, either using assymetric or symmetric cryptography. The methods croaks if an error is encountered. Parameters:

=over

=item * plaintext

This argument specifies what to encrypt. It can be either a file name or anything else that L<AnyEvent::Proc/pull> accepts.

=item * output

This optional argument specifies where the ciphertext will be output. It can be either a file name or anything else that L<AnyEvent::Proc/pipe> acceptse.

=item * armor

If this parameter is set to true, the ciphertext will be ASCII armored.

=item * symmetric

If this parameter is set to true, symmetric cryptography will be used to encrypt the message. You will need to provide a I<passphrase> parameter.

=item * recipient

If not using symmetric cryptography, you will have to provide this parameter. It should contains the userid of the intended recipient of the message. It will be used to look up the key to use to encrypt the message. The parameter can also take an array ref, if you want to encrypt the message for a group of recipients.

=item * sign

If this parameter is set to true, the message will also be signed. You will probably have to use the I<passphrase> parameter to unlock the private key used to sign message. This option is incompatible with the I<symmetric> one.

=item * local-user

This parameter is used to specified the private key that will be used to sign the message. If left unspecified, the default user will be used. This option only makes sense when using the I<sign> option.

=item * passphrase

This parameter contains either the secret passphrase for the symmetric algorithm or the passphrase that should be used to decrypt the private key.

=back

Example:

    $gpg->encrypt(
        plaintext => file.txt,
        output => "file.gpg",
        sign => 1,
        passphrase => $secret
    );

=head2 encrypt_cb(%params[, cb => $callback|$condvar])

Asynchronous variant of L</encrypt>.

=head2 sign(%params)

This method is used create a signature for a file or stream of data.

This method croaks on errors. Parameters:

=over 4

=item * plaintext

This argument specifies what to sign. It can be either a file name or anything else that L<AnyEvent::Proc/pull> accepts.

=item * output

This optional argument specifies where the signature will be output. It can be either a file name or anything else that L<AnyEvent::Proc/pipe> accepts.

=item * armor

If this parameter is set to true, the signature will be ASCII armored.

=item * passphrase

This parameter contains the secret that should be used to decrypt the private key.

=item * local-user

This parameter is used to specified the private key that will be used to make the signature. If left unspecified, the default user will be used.

=item * detach-sign

If set to true, a digest of the data will be signed rather than the whole file.

=back

Example:

    $gpg->sign(
        plaintext => "file.txt",
        output => "file.txt.asc",
        armor => 1
    );

=head2 sign_cb(%params[, cb => $callback|$condvar])

Asynchronous variant of L</sign>.

=head2 clearsign(%params)

This methods clearsign a message. The output will contains the original message with a signature appended. It takes the same parameters as the L</sign> method.

=head2 clearsign_cb(%params[, cb => $callback|$condvar])

Asynchronous variant of L</clearsign>.

=head2 verify(%params)

This method verifies a signature against the signed message. The methods croaks if the signature is invalid or an error is encountered. If the signature is valid, it returns an hash with the signature parameters. Here are the method's parameters:

=over 4

=item * signature

If the message and the signature are in the same file (i.e. a clearsigned message), this parameter can be either a file name or anything else that L<AnyEvent::Proc/pull> accepts.

If the signature doesn't follows the message, than it must be the name of the file that contains the signature and the parameter I<file> must be used to name the signed data.

=item * file

This is the name of a file or an ArrayRef of file names that contains the signed data.

=back

When the signature is valid, here are the elements of the hash that is returned by the method:

=over 4

=item * sigid

The signature id. This can be used to protect against replay attack.

=item * date

The data at which the signature has been made.

=item * timestamp

The epoch timestamp of the signature.

=item * keyid

The key id used to make the signature.

=item * user

The userid of the signer.

=item * fingerprint

The fingerprint of the signature.

=item * trust

The trust value of the public key of the signer. Those are values that can be imported in your namespace with the :trust tag. They are (TRUST_UNDEFINED, TRUST_NEVER, TRUST_MARGINAL, TRUST_FULLY, TRUST_ULTIMATE).

=back

Example:

    my $sig = $gpg->verify(
        signature => "file.txt.asc",
        file => "file.txt"
    );

=head2 verify_cb(%params[, cb => $callback|$condvar])

Asynchronous variant of L</verify>.

=head2 decrypt(%params)

This method decrypts an encrypted message. It croaks, if there is an error while decrypting the message. If the message was signed, this method also verifies the signature. If decryption is sucessful, the method either returns the valid signature parameters if present, or true. Method parameters:

=over 4

=item * ciphertext

This optional parameter contains either the name of the file containing the ciphertext or a reference to a file handle containing the ciphertext.

=item * output

This optional parameter determines where the plaintext will be stored. It can be either a file name or anything else that L<AnyEvent::Proc/pipe> accepts.

=item * symmetric

This should be set to true, if the message is encrypted using symmetric cryptography.

=item * passphrase

The passphrase that should be used to decrypt the message (in the case of a message encrypted using a symmetric cipher) or the secret that will unlock the private key that should be used to decrypt the message.

=back

Example:

    $gpg->decrypt(
        ciphertext => "file.gpg",
        output => "file.txt",
        passphrase => $secret
    );

=head2 decrypt_cb(%params[, cb => $callback|$condvar])

Asynchronous variant of L</decrypt>.

=head1 API OVERVIEW

The API is accessed through methods on a AnyEvent::GnuPG object which is a wrapper around the B<gpg> program. All methods takes their argument using named parameters, and errors are returned by throwing an exception (using croak). If you wan't to catch errors you will have to use eval or L<Try::Tiny>.

This modules uses L<AnyEvent::Proc>. For input data, all of L<AnyEvent::Proc/pull> and for output data, all of L<AnyEvent::Proc/pipe> possible handle types are allowed.

The code is based on L<GnuPG> with API compatibility except that L<GnuPG::Tie> is B<not> ported.

=head2 CALLBACKS AND CONDITION VARIABLES

Every method has a callback variant, suffixed with I<_cb>. These methods accept an optional parameter called I<cb>, which can be a CodeRef or an L<AnyEvent>::CondVar and returns a condvar.

    $gpg->method_cb(%params, cb => sub {
        my $result = shift->recv; # croaks on error
        ...
    });

    my $cv = $gpg->method_cb(%params);
    my $result = $cv->recv; # croaks on error
    ...

The non-callback variants are all wrapper methods, looking something like this:

    sub method {
        shift->method_cb(@_)->recv
    }

=head1 EXPORTS

Nothing by default. Available tags:

=over 4

=item * :algo

RSA_RSA DSA_ELGAMAL DSA RSA

=item * :trust

TRUST_UNDEFINED TRUST_NEVER TRUST_MARGINAL TRUST_FULLY TRUST_ULTIMATE

=back

=head1 BUGS AND LIMITATIONS

This module doesn't work (yet) with the v2 branch of GnuPG.

=head1 SEE ALSO

=over 4

=item * L<GnuPG>

=item * L<gpg(1)>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libanyevent-gnupg-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Francis J. Lacoste <francis.lacoste@Contre.COM>

=item *

David Zurborg <zurborg@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
