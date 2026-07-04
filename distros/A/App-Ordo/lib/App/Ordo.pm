package App::Ordo;
use strict;
use warnings;
use feature qw(say);
use Moo;
use Exporter 'import';

use JSON qw(encode_json);
use File::Path qw(make_path);
use File::Copy qw(copy);
use File::ShareDir qw(dist_file);
use Term::ANSIColor qw(colored);
use Term::ReadLine::Perl5;
use Term::ReadKey qw(ReadMode ReadKey GetTerminalSize);
use Email::Valid;

use App::Ordo::API;

our @EXPORT_OK = qw(
    $CURRENT_PATH
    extract_command
    epoch_to_tminus
    epoch_to_duration
);

our $VERSION = '0.06';
our $CURRENT_PATH = '/';

has 'api' => (
    is => 'lazy',
    default => sub { App::Ordo::API->new },
);

# ------------------------------------------------------------------
# Session / Auth
# ------------------------------------------------------------------
sub ensure_session {
    my ($self) = @_;

    my $config = $self->api->config;
    my $token  = $config->{token} // '';

    my $res = $self->api->call('login_user', { token => $token });

    if ($res->{success}) {
        $CURRENT_PATH = $res->{path} // '/';
        say colored(["bold green"], "Connected to " . $self->api->config->{api} . " as $res->{email}");
        return $res;
    }

    say colored(["bold yellow"], "No valid token found");
    return $self->prompt_for_token;
}

sub prompt_for_token {
    my $self = shift;
    while (1) {
        print colored(["bold white"], "Enter API token: ");
        chomp(my $token = <STDIN>);
        $token =~ s/^\s+|\s+$//g;

        my $res = $self->api->call('login_user', { token => $token });

        if ($res->{success} && $res->{level} >= 1) {
            my $config = $self->api->config;
            $config->{token} = $token;
            open my $fh, '>', $self->api->config_file or die "Cannot save config: $!";
            print $fh encode_json($config);
            close $fh;
            $CURRENT_PATH = $res->{path} // '/';
            say colored(["bold green"], "Logged in successfully");
            return $res;
        }
        say colored(["bold red"], $res->{message} || "Invalid token");
    }
}

# ------------------------------------------------------------------
# Interactive Shell
# ------------------------------------------------------------------
sub run_interactive {
    my $self = shift;

    $self->ensure_session;

    my $term = Term::ReadLine::Perl5->new('ordo');

    say colored(["bold white"], "\nWelcome to Ordo - the hierarchical job scheduler");
    say "Type 'help' for commands, Ctrl-D to exit.\n";

    while (defined(my $line = $term->readline("ordo:$CURRENT_PATH> "))) {
        $line =~ s/^\s+|\s+$//g;
        next unless $line;
        my @args = extract_command($line);
        App::Ordo::Runner->new(api => $self->api)->run(@args);
    }

    say colored(["bold yellow"], "\nGoodbye!");
}

# ------------------------------------------------------------------
# Command line parsing
# ------------------------------------------------------------------
sub extract_command {
    my ($line) = @_;
    return () unless defined $line;
    my @args;
    my $current = '';
    my $in_quote = '';
    for my $char (split //, $line) {
        if ($in_quote) {
            $current .= $char;
            $in_quote = '' if $char eq $in_quote;
        } elsif ($char eq '"' || $char eq "'") {
            $in_quote = $char;
            $current .= $char;
        } elsif ($char =~ /\s/) {
            push @args, $current if length $current;
            $current = '';
        } else {
            $current .= $char;
        }
    }
    push @args, $current if length $current;
    # Strip surrounding quotes
    @args = map { /^['"](.*)['"]$/ ? $1 : $_ } @args;
    return @args;
}

# ------------------------------------------------------------------
# Time formatting helpers
# ------------------------------------------------------------------
sub epoch_to_tminus {
    my $epoch = shift;
    return '' unless $epoch && $epoch =~ /^\d+$/;
    my $current_epoch = time;
    my $diff = $current_epoch - $epoch;
    return $diff < 60 ? "${diff}s ago"
         : $diff < 3600 ? int($diff/60) . "m ago"
         : $diff < 86400 ? int($diff/3600) . "h ago"
         : int($diff/86400) . "d ago";
}

sub epoch_to_duration {
    my ($start, $end) = @_;
    return '' unless $start;
    $end //= time;
    my $diff_seconds = abs($end - $start);
    my $days = int($diff_seconds / (24 * 60 * 60));
    $diff_seconds %= (24 * 60 * 60);
    my $hours = int($diff_seconds / (60 * 60));
    $diff_seconds %= (60 * 60);
    my $minutes = int($diff_seconds / 60);
    my $seconds = $diff_seconds % 60;
    my $duration = sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
    if ($days) {
        $duration .= " +$days" . 'd';
    }
    return $duration;
}

# ------------------------------------------------------------------
# Pager (optional but useful)
# ------------------------------------------------------------------
sub less {
    my ($string) = @_;
    my @lines = split /\n/, $string;
    $_ .= "\n" for @lines;
    push @lines, "\n";
    my ($width, $height) = GetTerminalSize();
    $height -= 1;
    my $total_lines = @lines;
    if ($total_lines <= $height) {
        print for @lines;
        return;
    }
    my $current = 0;
    ReadMode 'cbreak';
    while (1) {
        system("clear");
        for my $i ($current .. $current + $height - 1) {
            last if $i >= $total_lines;
            print $lines[$i];
        }
        my $percent = int(($current + $height) / $total_lines * 100);
        printf "\033[7m(line %d of %d, %d%%) [q quit, space page down, b page up, j/k lines]\033[0m\n",
            $current + $height > $total_lines ? $total_lines : $current + $height,
            $total_lines, $percent;
        my $key = ReadKey(0);
        last if $key eq 'q' || $key eq 'Q';
        $current += $height if $key eq ' ';
        $current -= $height if $key eq 'b';
        $current++ if $key eq 'j' || $key eq "\n" || $key eq "\r";
        $current-- if $key eq 'k';
        $current = 0 if $current < 0;
        $current = $total_lines - $height if $current > $total_lines - $height;
    }
    ReadMode 'normal';
    print "\n";
}

1;
