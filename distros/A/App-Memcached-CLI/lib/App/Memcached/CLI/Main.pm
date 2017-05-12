package App::Memcached::CLI::Main;

use strict;
use warnings;
use 5.008_001;

use Carp;
use File::Basename 'basename';
use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use IO::Socket::INET;
use List::Util qw(first);
use Term::ReadLine;
use Time::HiRes;

use App::Memcached::CLI;
use App::Memcached::CLI::DataSource;
use App::Memcached::CLI::Help;
use App::Memcached::CLI::Item;
use App::Memcached::CLI::Util ':all';

use version; our $VERSION = 'v0.9.4';

my $PROGRAM = basename $0;

my %COMMAND2ALIASES = (
    help         => ['\h'],
    version      => ['\v'],
    quit         => [qw(\q exit)],
    display      => [qw(\d)],
    stats        => [qw(\s)],
    settings     => [qw(\c config)],
    cachedump    => [qw(\cd)],
    detaildump   => [qw(\dd)],
    detail       => [],
    dump_all     => [],
    restore_dump => [],
    randomset    => [qw(sample)],
    get          => [],
    gets         => [],
    set          => [],
    add          => [],
    replace      => [],
    append       => [],
    prepend      => [],
    cas          => [],
    incr         => [],
    decr         => [],
    touch        => [],
    delete       => [],
    flush_all    => [qw(flush)],
    call         => [],
);
my %COMMAND_OF;
while (my ($cmd, $aliases) = each %COMMAND2ALIASES) {
    $COMMAND_OF{$cmd} = $cmd;
    $COMMAND_OF{$_}   = $cmd for @$aliases;
}

my $DEFAULT_CACHEDUMP_SIZE = 20;

sub new {
    my $class  = shift;
    my %params = @_;

    eval {
        $params{ds}
            = App::Memcached::CLI::DataSource->connect(
                $params{addr}, timeout => $params{timeout}
            );
    };
    if ($@) {
        warn "Can't connect to Memcached server! Addr=$params{addr}";
        debug "ERROR: " . $@;
        return;
    }

    bless \%params, $class;
}

sub parse_args {
    my $class = shift;

    my %params; # will be passed to new()
    if (defined $ARGV[0] and looks_like_addr($ARGV[0])) {
        $params{addr} = shift @ARGV;
    }
    GetOptions(
        \my %opts, 'addr|a=s', 'timeout|t=i',
        'debug|d', 'help|h', 'man',
    ) or return +{};

    if (defined $opts{debug}) {
        $App::Memcached::CLI::DEBUG = 1;
    }

    %params = (%opts, %params);
    $params{addr} = create_addr($params{addr});

    return \%params;
}

sub run {
    my $self = shift;
    if (@ARGV) {
        $self->run_batch;
    } else {
        $self->run_interactive;
    }
}

sub run_batch {
    my $self = shift;
    debug "Run batch mode with @ARGV" if (@ARGV);
    my ($_command, @args) = @ARGV;
    my $command = $COMMAND_OF{$_command};
    unless ($command) {
        print "Unknown command - $_command\n";
        return;
    } elsif ($command eq 'quit') {
        print "Nothing to do with $_command\n";
        return;
    }

    my $ret = $self->$command(@args);
    unless ($ret) {
        print qq[Command seems failed. Run \`$PROGRAM help\` or \`$PROGRAM help $command\` for usage.\n];
    }
}

sub run_interactive {
    my $self = shift;
    debug "Start interactive mode. $self->{addr}";
    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));
    unless ($isa_tty) {
        croak "TTY Not Found! Quit.";
    }
    my $exit_loop = 0;
    local $SIG{INT} = local $SIG{QUIT} = sub {
        $exit_loop = 1;
        warn "Caught INT or QUIT. Exiting...";
    };

    $self->{term} = Term::ReadLine->new($PROGRAM);
    print "Type '\\h' or 'help' to show help.\n\n";
    while (! $exit_loop) {
        my ($command, @args) = $self->prompt;
        next unless $command;
        if ($command eq 'quit') {
            $exit_loop = 1;
            next;
        }
        unless ($self->{ds}->ping) {
            print "Server has gone away.\n";
            $exit_loop = 1;
            next;
        }

        my $ret = $self->$command(@args);
        unless ($ret) {
            print "Command seems failed. Type \\h $command for help.\n\n";
        }
    }
    debug "Finish interactive mode. $self->{addr}";
}

sub prompt {
    my $self = shift;

    local $| = 1;
    local $\;

    my $input = $self->{term}->readline("memcached\@$self->{addr}> ");
    chomp($input);
    return unless $input;
    $self->{term}->addhistory($input) if ($input =~ m/\S/);

    my ($_command, @args) = split(m/\s+/, $input);
    my $command = $COMMAND_OF{$_command};
    print "Unknown command - $input\n" unless $command;

    return $command, @args;
}

sub help {
    my $self    = shift;
    my $command = shift || q{};

    my @command_info = @App::Memcached::CLI::Help::COMMANDS_INFO;

    my $body   = q{};
    my $space  = ' ' x 4;

    # Help for specified command
    if (my $function = $COMMAND_OF{$command}) {
        my $aliases = join(q{, }, _sorted_aliases_of($function));
        my $info = (grep { $_->{command} eq $function } @command_info)[0];
        $body .= sprintf qq{\n[Command "%s"]\n\n}, $command;
        $body .= "Summary:\n";
        $body .= sprintf "%s%s\n\n", $space, $info->{summary};
        $body .= "Aliases:\n";
        $body .= sprintf "%s%s\n\n", $space, $aliases;
        if ($info->{description}) {
            $body .= $info->{description};
            $body .= "\n";
        }
        print $body;
        return 1;
    }
    # Command not found, but continue
    elsif ($command) {
        $body .= "Unknown command: $command\n";
    }

    # General help
    $body .= "\n[Available Commands]\n";
    for my $info (@command_info) {
        my $cmd = $info->{command};
        my $commands = join(q{, }, _sorted_aliases_of($cmd));
        $body .= sprintf "%s%-20s%s%s\n",
            $space, $commands, $space x 2, $info->{summary};
    }
    $body .= "\nType \\h <command> for each.\n\n";
    print $body;
    return 1;
}

sub _sorted_aliases_of {
    my $command = shift;
    my @aliases = @{$COMMAND2ALIASES{$command}};
    return (shift @aliases, $command, @aliases) if @aliases;
    return ($command);
}

sub call {
    my $self = shift;
    my @commands = @_;
    unless (@commands) {
        print "No COMMAND given.\n";
        return;
    }
    my $response = $self->{ds}->query_any(join q{ }, @commands);
    print $response;
    return 1;
}

sub get {
    my $self = shift;
    return $self->_retrieve('get', @_);
}

sub gets {
    my $self = shift;
    return $self->_retrieve('gets', @_);
}

sub _retrieve {
    my $self = shift;
    my ($command, @keys) = @_;
    unless (@keys) {
        print "No KEY specified.\n";
        return;
    }
    my $items = App::Memcached::CLI::Item->find(
        \@keys, $self->{ds}, command => $command,
    );
    unless (@$items) {
        print "Not found - @keys\n";
        return 1;
    }
    if (@$items == 1) {
        $items->[0]->output;
        return 1;
    }
    for (my $i=0; $i < scalar(@$items); $i++) {
        my $item = $items->[$i];
        $item->output_line;
    }
    return 1;
}

sub set     { return &_store(shift, 'set', @_); }
sub add     { return &_store(shift, 'add', @_); }
sub replace { return &_store(shift, 'replace', @_); }
sub append  { return &_store(shift, 'append',  @_); }
sub prepend { return &_store(shift, 'prepend', @_); }

sub _store {
    my $self    = shift;
    my $command = shift;
    my ($key, $value, $expire, $flags) = @_;
    unless ($key and $value) {
        print "KEY or VALUE not specified.\n";
        return;
    }
    my $item = App::Memcached::CLI::Item->new(
        key    => $key,
        value  => $value,
        expire => $expire,
        flags  => $flags,
    );
    unless ($item->save($self->{ds}, command => $command)) {
        print "Failed to $command item. KEY $key, VALUE $value\n";
        return 1;
    }
    print "OK\n";
    return 1;
}

sub cas {
    my $self = shift;
    my ($key, $value, $cas, $expire, $flags) = @_;
    unless ($key and $value and $cas) {
        print "KEY or VALUE or CAS not specified.\n";
        return;
    }
    my $item = App::Memcached::CLI::Item->new(
        key    => $key,
        value  => $value,
        expire => $expire,
        flags  => $flags,
        cas    => $cas,
    );
    unless ($item->save($self->{ds}, command => 'cas')) {
        print "Failed to cas item. KEY $key, VALUE $value\n";
        return 1;
    }
    print "OK\n";
    return 1;
}

sub incr { return &_incr_decr(shift, 'incr', @_); }
sub decr { return &_incr_decr(shift, 'decr', @_); }

sub _incr_decr {
    my $self   = shift;
    my $cmd    = shift;
    my $key    = shift;
    my $number = shift;
    unless ($key and defined $number) {
        print "No KEY or VALUE specified.\n";
        return;
    }
    unless ($number =~ m/^\d+$/) {
        print "Give numeric number for $cmd VALUE.\n";
        return;
    }
    my $new_value = $self->{ds}->$cmd($key, $number);
    unless (defined $new_value) {
        print "FAILED - $cmd\n";
        return;
    }
    print "OK. New VALUE is $new_value\n";
    return 1;
}

sub touch {
    my $self   = shift;
    my $key    = shift;
    my $expire = shift;
    unless ($key and defined $expire) {
        print "No KEY or EXPIRE specified.\n";
        return;
    }
    unless ($expire =~ m/^\d+$/) {
        print "Give numeric number for EXPIRE.\n";
        return;
    }
    unless ($self->{ds}->touch($key, $expire)) {
        print "Failed to touch. KEY $key maybe missing\n";
        return;
    }
    print "OK\n";
    return 1;
}

sub delete {
    my $self = shift;
    my $key  = shift;
    unless ($key) {
        print "No KEY specified.\n";
        return;
    }
    my $item = App::Memcached::CLI::Item->new(key => $key);
    unless ($item->remove($self->{ds})) {
        warn "Failed to delete item. KEY $key";
        return;
    }
    print "OK\n";
    return 1;
}

sub version {
    my $self = shift;
    my $version = $self->{ds}->query_one('version');
    print "$version\n";
    return 1;
}

sub cachedump {
    my $self  = shift;
    my $class = shift;
    my $num   = shift || $DEFAULT_CACHEDUMP_SIZE;

    unless ($class) {
        print "No slab class specified.\n";
        return;
    }
    my $response = $self->{ds}->query("stats cachedump $class $num");
    my %expires;
    for my $line (@$response) {
        if ($line !~ m/^ITEM (\S+) \[(\d+) b; (\d+) s\]/) {
            warn "Unknown response: $line";
            next;
        }
        my %data = (key => $1, length => $2, expire => $3);
        $expires{$data{key}} = \%data;
    }
    return 1 unless %expires;

    my @keys = keys %expires;
    my $items = App::Memcached::CLI::Item->find(
        \@keys, $self->{ds}, command => 'gets',
    );
    for (my $i=0; $i < scalar(@$items); $i++) {
        my $item = $items->[$i];
        $item->{expire} = $expires{$item->{key}}{expire};
        $item->output_line;
    }
    return 1;
}

sub display {
    my $self = shift;

    my %stats;
    my $max = 1;

    my $resp_items = $self->{ds}->query('stats items');
    for my $line (@$resp_items) {
        if ($line =~ m/^STAT items:(\d+):(\w+) (\d+)/) {
            $stats{$1}{$2} = $3;
        }
    }

    my $resp_slabs = $self->{ds}->query('stats slabs');
    for my $line (@$resp_slabs) {
        if ($line =~ m/^STAT (\d+):(\w+) (\d+)/) {
            $stats{$1}{$2} = $3;
            $max = $1;
        }
    }

    print "  #  Item_Size  Max_age   Pages   Count   Full?  Evicted Evict_Time OOM\n";
    for my $class (1..$max) {
        my $slab = $stats{$class};
        next unless $slab->{total_pages};

        my $size
            = $slab->{chunk_size} < 1024 ? "$slab->{chunk_size}B"
            : sprintf("%.1fK", $slab->{chunk_size} / 1024.0) ;

        my $full = ($slab->{free_chunks_end} == 0) ? 'yes' : 'no';
        printf(
            "%3d %8s %9ds %7d %7d %7s %8d %8d %4d\n",
            $class, $size, $slab->{age} || 0, $slab->{total_pages},
            $slab->{number} || 0, $full, $slab->{evicted} || 0,
            $slab->{evicted_time} || 0, $slab->{outofmemory} || 0,
        );
    }

    return 1;
}

sub stats {
    my $self   = shift;
    my $filter = shift;
    my $response = $self->{ds}->query('stats');
    _print_stats_of_response('stats', $filter, @$response);
    return 1;
}

sub settings {
    my $self = shift;
    my $filter = shift;
    my $response = $self->{ds}->query('stats settings');
    _print_stats_of_response('stats settings', $filter, @$response);
    return 1;
}

sub _print_stats_of_response {
    my $title  = shift;
    my $filter = shift;
    my @lines  = @_;

    my %stats;
    my ($max_key_l, $max_val_l) = (0, 0);

    for my $line (@lines) {
        next if ($line !~ m/^STAT\s+(\S*)\s+(.*)/);
        my ($key, $value) = ($1, $2);
        if (length $key   > $max_key_l) { $max_key_l = length $key; }
        if (length $value > $max_val_l) { $max_val_l = length $value; }
        next if ($filter && $key !~ m/$filter/);
        $stats{$key} = $value;
    }

    print  "# $title\n";
    printf "#%${max_key_l}s  %${max_val_l}s\n", 'Field', 'Value';
    for my $field (sort {$a cmp $b} (keys %stats)) {
        printf (" %${max_key_l}s  %${max_val_l}s\n", $field, $stats{$field});
    }
}

sub detaildump {
    my $self  = shift;
    my $response = $self->{ds}->query("stats detail dump");
    print "$_\n" for @$response;
    return 1;
}

sub detail {
    my $self = shift;
    my $mode = shift || q{};
    unless (first { $_ eq $mode } qw/on off/) {
        print "Mode must be 'on' or 'off'!\n";
        return;
    }
    my $response = $self->{ds}->query_one("stats detail $mode");
    my %result = (
        on  => 'Enabled',
        off => 'Disabled',
    );
    if ($response !~ m/^OK/) {
        print "Seems failed to set detail $mode\n";
        return;
    }
    print "OK - $result{$mode} stats collection for detail dump.\n";
    return 1;
}

sub dump_all {
    my $self = shift;
    my %items;
    my $total;

    my $response = $self->{ds}->query('stats items');
    for my $line (@$response) {
        if ($line =~ m/^STAT items:(\d*):number (\d*)/) {
            $items{$1} = $2;
            $total += $2;
        }
    }

    print  STDERR "Dumping memcache contents\n";
    printf STDERR "  Number of buckets: %d\n", scalar(keys(%items));
    print  STDERR "  Number of items  : $total\n";

    for my $bucket (sort(keys %items)) {
        print STDERR "Dumping bucket $bucket - " . $items{$bucket} . " total items\n";
        $response = $self->{ds}->query("stats cachedump $bucket $items{$bucket}");

        my %expires;
        for my $line (@$response) {
            # Ex) ITEM foo [6 b; 1176415152 s]
            if ($line =~ m/^ITEM (\S+) \[.* (\d+) s\]/) {
                $expires{$1} = $2;
            }
        }

        my $now = time();
        my @keys_bucket = keys %expires;
        while (my @keys = splice(@keys_bucket, 0, 20)) {
            my $list = $self->{ds}->get(\@keys);
            for my $d (@$list) {
                my $expire = ($expires{$d->{key}} < $now) ? 0 : $expires{$d->{key}};
                print "add $d->{key} $d->{flags} $expire $d->{length}\r\n";
                print "$d->{value}\r\n";
            }
            Time::HiRes::sleep(0.01);
        }
    }

    return 1;
}

sub restore_dump {
    my $self = shift;
    my $file = shift;
    unless ($file and -r $file) {
        print "Dump FILE not found.\n";
        return;
    }

    open my $fh, '<', $file or die "Can't read $file!";
    my $i = 0;
    while (my $input = $fh->getline) {
        $i++;
        $self->{ds}->{socket}->write($input);
        if ($i%200 == 0) {
            printf "%s...loaded $i lines\n", q[ ] x 4;
            $self->{ds}->{socket}->flush;
            Time::HiRes::sleep(0.03);
        }
    }
    print "Complete.\n";
    return 1;
}

sub flush_all {
    my $self  = shift;
    my $delay = shift;
    my $query = 'flush_all';
    if ($delay) { $query .= " $delay"; }
    my $response = $self->{ds}->query_one($query);
    print "$response\n";
    return 1;
}

sub randomset {
    my $self = shift;
    my ($num, $max, $min, $namespace) = @_;
    $num    ||= 100;
    $max    ||= 1_000_000;
    $min    ||= 1;
    $namespace ||= 'memcached-cli:sample';

    local $| = 1; # disable output buffering
    print "Random Generate. [";
    my $pos = 0;
    for my $i (1..$num) {
        my $key    = $namespace . ":data$i";
        my $length = int( rand() * ($max - $min) ) + $min;
        my $value  = '.' x $length;
        unless ($self->{ds}->set($key, $value)) {
            warn "Failed to set KEY $key, length: $length B";
        }
        if ( (my $_pos = int($i*20 / $num)) > $pos ) {
            $pos = $_pos;
            print '.';
        }
        Time::HiRes::sleep(0.1) if ($i % 100 == 0);
    }
    print "]\n";
    print "Complete.\n";
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::CLI::Main - Interactive/Batch CLI for Memcached

=head1 SYNOPSIS

    use App::Memcached::CLI::Main;
    my $params = App::Memcached::CLI::Main->parse_args;
    App::Memcached::CLI::Main->new(%$params)->run;

=head1 DESCRIPTION

This module is used for CLI of Memcached.

The CLI can be both interactive one or batch script.

See L<memcached-cli> for details.

=head1 SEE ALSO

L<memcached-cli>

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

