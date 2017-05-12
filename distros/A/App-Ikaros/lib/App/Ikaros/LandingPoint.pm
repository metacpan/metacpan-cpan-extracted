package App::Ikaros::LandingPoint;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;
use Net::OpenSSH;

__PACKAGE__->mk_accessors(qw/
    hostname
    user
    plan
    runner
    workdir
    coverage
    perlbrew
    connection
    prove
    tests
    trigger_filename
    output_filename
    dot_prove_filename
    cover_db_name
/);

sub new {
    my ($class, $default, $host) = @_;
    my $options = { %$default };

    my ($hostname, $h);
    if (ref $host eq '') {
        $hostname = $host;
        $h = {};
    } else {
        $hostname = (keys %$host)[0];
        $h = $host->{$hostname};
    }
    die "unknown hostname [$hostname]" unless $hostname;

    my $user     = $h->{user}        || $default->{user} || $ENV{USER};
    my $key      = $h->{private_key} || $default->{private_key} || '';
    my $workdir  = $h->{workdir}     || $default->{workdir} || '$HOME';
    my $runner   = $h->{runner}      || $default->{runner}  || 'prove';
    my $coverage = $h->{coverage}    || $default->{coverage}|| 0;
    my $perlbrew = $h->{perlbrew}    || $default->{perlbrew}|| 0;
    die "please setup workdir for testing" unless $workdir;

    my @ssh_opt = ($key) ? (key_path => $key) : ();

    my $ssh = Net::OpenSSH->new($user . '@' . $hostname, @ssh_opt);
    $ssh->error and die 'unable to connect to remote host: ' . $ssh->error;
    my $trigger_filename = __unique_name($workdir, $hostname, 'build_kicker.pl');
    my $output_filename  = __unique_name($workdir, $hostname, 'output.xml');
    my $dot_prove_filename  = __unique_name($workdir, $hostname, 'dot_prove.yaml');
    my $cover_db_name    = __unique_name($workdir, $hostname, 'cover_db');

    return $class->SUPER::new({
        user       => $user,
        hostname   => $hostname,
        connection => $ssh,
        workdir    => $workdir,
        runner     => $runner,
        coverage   => $coverage,
        perlbrew   => $perlbrew,
        trigger_filename => $trigger_filename,
        output_filename  => $output_filename,
        dot_prove_filename => $dot_prove_filename,
        cover_db_name    => $cover_db_name
    });
}

sub __unique_name {
    my ($workdir, $hostname, $suffix) = @_;
    my $name = $workdir . '_' . $hostname . '_' . $suffix;
    $name =~ s|/|_|g;
    return $name;
}

1;
