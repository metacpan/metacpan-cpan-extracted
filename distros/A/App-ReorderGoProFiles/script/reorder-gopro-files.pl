#!/usr/bin/env perl

use strict;
use warnings;

use Docopt;
use File::Copy ();

my $opts = docopt();

my ($files) = $opts->{'<files>'};

foreach my $file (@$files) {
    die "Can't open file '$file': $!\n" unless -f $file;
}

warn "Files are NOT really symlinked/copied/moved. "
  . "Use --force to actually rename files.\n"
  unless my $force = $opts->{'-f'} || $opts->{'--force'};

foreach my $file (@$files) {
    if ($file =~ m/GOPR(\d+?)\.(.*)$/) {
        _copy($file, "GP$1-00.$2");
    }
    elsif ($file =~ m/GP(\d{2})(\d+)\.(.*)$/) {
        _copy($file, "GP$2-$1.$3");
    }
    else {
        warn "Do not know what to do with '$file'\n";
    }
}

sub _copy {
    my ($old_file, $new_file) = @_;

    my ($text, $action) = ('Symlinking', \&_symlink);
    ($text, $action) = ('Copying', \&File::Copy::copy)
      if $opts->{'-c'} || $opts->{'--copy'};
    ($text, $action) = ('Moving', \&File::Copy::move)
      if $opts->{'-m'} || $opts->{'--move'};

    warn "$text '$old_file' to '$new_file'\n";
    $action->($old_file, $new_file) if $force;
}

sub _symlink {
    my ($from, $to) = @_;

    symlink $from, $to;
}

1;

__END__

=head1 SYNOPSIS

  reorder-gopro-files [-c | --copy]
                      [-m | --move]
                      [-f | --force]
                      <files>...

  -f, --force      Actually perform action.
  -c, --copy       Copy files (instead of symlinking).
  -m, --move       Move files (instead of symlinking).
  -h, --help       Show this screen.

