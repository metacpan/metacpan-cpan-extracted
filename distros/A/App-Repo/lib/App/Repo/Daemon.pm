package App::Repo::Daemon;

use strict;

=head1 NAME

App::Repo::Daemon - daemonize program

=cut

require Exporter;

our @ISA = qw<Exporter>;
our @EXPORT_OK = ( 'daemonize' );
our $VERSION = '0.01';

sub daemonize {
    no strict 'subs';
    chdir '/'               or die "Can't chdir to /: $!";
    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
   
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    setsid                  or die "Can't start a new session: $!";
    open STDERR, '>&STDOUT' or die "Can't dup stdout: $!";
}
1;

