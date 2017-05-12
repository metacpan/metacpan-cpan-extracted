package App::codefork;
BEGIN {
  $App::codefork::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Worlds dumbest code forker
$App::codefork::VERSION = '0.001';
use Moo;
use MooX::Options;
use IO::All;
use File::chdir;

option config => (
  is => 'ro',
  format => 's',
  required => 1,
  isa => sub { die "can't find config file ".$_[0] unless -f $_[0] },
  doc => 'forking instructions'
);

option debug => (
  is => 'ro',
  doc => 'show debug informations'
);

option dir => (
  is => 'lazy',
  doc => 'work directory'
);

sub _build_dir {
  my ( $self ) = @_;
  return '.';
}

has mods => (
  is => 'lazy',
);

sub _build_mods {
  my ( $self ) = @_;
  return [ map {
    chomp($_);
    if ($_ =~ /\|/) {
      [ replace => split('\|',$_) ]
    } elsif ($_ =~ /%/) {
      [ word => split('%',$_) ]
    }
  } ( io($self->config)->slurp ) ];
}

sub BUILD {
  my ( $self ) = @_;
  $self->log('Parsing config...');
  $self->log($_->[0].': '.$_->[1].' => '.$_->[2]) for (@{$self->mods});
  $self->work_on_dir(io($self->dir)->absolute);
}

sub work_on_dir {
  my ( $self, $dir ) = @_;
  my @mods = @{$self->mods};
  local $CWD = $dir;
  for my $entry (io('.')->all) {
    my $fn = $entry->filename;
    next if $fn eq '.git' || $fn eq '.svn';
    for my $mod (@mods) {
      if ($mod->[0] eq 'replace') {
        my $from = $mod->[1];
        my $to = $mod->[2];
        $fn =~ s/$from/$to/g;
        if ($fn ne $entry->filename) {
          $entry = $entry->rename($fn);
          last;
        }
      }
    }
    if ($entry->is_file) {
      my $content = $entry->slurp;
      for my $mod (@mods) {
        my $cmd = $mod->[0];
        my $from = $mod->[1];
        my $to = $mod->[2];
        if ($cmd eq 'replace') {
          $content =~ s/$from/$to/g;
        } elsif ($cmd eq 'word') {
          $content =~ s/([^A-Za-z0-9]+)$from([^A-Za-z0-9]+)/$1$to$2/g;
        }
      }
      if ($content ne $entry->slurp) {
        $entry->print($content);
      }
    } else {
      $self->work_on_dir($entry->absolute);
    }
  }
}

sub log {
  my ( $self, $text ) = @_;
  print $text."\n" if $self->debug;
}


1;

__END__

=pod

=head1 NAME

App::codefork - Worlds dumbest code forker

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Please see L<codefork>.

=encoding utf8

=head1 SUPPORT

Repository

  https://github.com/Getty/p5-app-codefork
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Getty/p5-app-codefork/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
