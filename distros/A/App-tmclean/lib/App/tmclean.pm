package App::tmclean;
use 5.010;
use warnings;

use version 0.77; our $VERSION = version->declare("v0.0.3");

use Getopt::Long qw/GetOptions :config posix_default no_ignore_case bundling auto_help/;
use Pod::Usage qw/pod2usage/;
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/before days dry_run/],
);
use HTTP::Date qw/str2time/;
use Time::Piece ();
use Time::Seconds ();

sub logf {
    my $msg = shift;
       $msg = sprintf($msg, @_);
    my $prefix = '[tmclean]' . Time::Piece->localtime->strftime('[%Y-%m-%d %H:%M:%S] ');
    $msg .= "\n" if $msg !~ /\n$/;
    print STDERR $prefix . $msg;
}

sub new_with_options {
    my ($class, @argv) = @_;

    my ($opt) = $class->parse_options(@argv);
    $class->new($opt);
}

sub parse_options {
    my ($class, @argv) = @_;

    local @ARGV = @argv;
    GetOptions(\my %opt, qw/
        days=i
        before=s
        dry-run
    /) or pod2usage(2);

    $opt{dry_run} = delete $opt{'dry-run'};
    return (\%opt, \@ARGV);
}

sub run {
    my $self = shift;

    if (!$self->dry_run && $ENV{USER} ne 'root') {
        die "tmutil requires root privileges\n";
    }
    $self->cmd(qw/tmutil stopbackup/);
    $self->cmd(qw/tmutil disable/); # need sudo

    my @targets = $self->backups2delete;
    unless (@targets) {
        logf 'no deletion targets found';
        return 0;
    }
    my $mount_point = $self->mount_point;

    logf "following backups to be deleted:\n  %s", join("\n  ", @targets);
    for my $bak (@targets) {
        $self->cmd(qw/tmutil delete/, $bak); # need sudo
    }
    my $dev_name = dev_name($targets[0]);
    $self->cmd(qw/hdiutil detach/, $dev_name);

    my $sparsebundle_path = sprintf '%s/%s.sparsebundle', $mount_point, $self->machine_name;
    $self->cmd(qw/hdiutil compact/, $sparsebundle_path); # need sudo
    $self->cmd(qw/tmutil enable/); # need sudo
}

sub backups2delete {
    my $self = shift;
    my @backups = `tmutil listbackups`;
    if ($? != 0) {
        die "failed to execute `tmutil listbackups`: $?\n";
    }
    # e.g. /Volumes/Time Machine Backup/Backups.backupdb/$machine/2018-01-07-033608
    return grep {
        chomp;
        my @paths = split m!/!, $_;
        my $backup_date = eval { Time::Piece->strptime($paths[-1], '%Y-%m-%d-%H%M%S') };
        $backup_date && $self->before_tp > $backup_date;
    } @backups;
}

sub mount_point {
    my $self = shift;

    $self->{mount_point} ||= sub {
        my @lines = `tmutil destinationinfo`;
        if ($? != 0) {
            die "failed to execute `tmutil destinationinfo`: $?\n";
        }
        for my $line (@lines) {
            chomp $line;
            my ($key, $val) = split /\s+:\s+/, $line, 2;
            if ($key eq 'Mount Point') {
                return $val;
            }
        }
        die "no mount points found\n";
    }->();
}

sub dev_name {
    my $path = shift;
    my @paths = split m!/!, $path;
    join '/', @paths[0..2];
}

sub machine_name {
    my $self = shift;

    $self->{machine_name} ||= do {
        chomp(my $hostname = `hostname`);
        if ($? != 0) {
            die "failed to execute `hostname`: $?\n";
        }
        $hostname =~ s/\.local$//;
        $hostname;
    };
}

sub before_tp {
    my $self = shift;

    $self->{before_tp} ||= sub {
        if ($self->before) {
            my $time = str2time $self->before; # str2time parses the time as localtime
            die "unrecognized date format @{[$self->before]}" unless $time;
            return Time::Piece->localtime($time);
        }
        my $days = $self->days || 366;
        return Time::Piece->localtime() - Time::Seconds::ONE_DAY() * $days;
    }->();
}

sub cmd {
    my ($self, @command) = @_;

    my $cmd_str = join(' ', @command);
    logf 'execute%s: `%s`', $self->dry_run ? '(dry-run)' : '', $cmd_str;
    if (!$self->dry_run) {
        !system(@command) or die "failed to execute command: $cmd_str: $?\n";
    }
}

1;
__END__
=for stopwords tmclean

=encoding utf-8

=head1 NAME

App::tmclean - backend class of tmclean

=head1 SYNOPSIS

    use App::tmclean;

=head1 DESCRIPTION

App::tmclean is backend module of L<tmclean>.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

