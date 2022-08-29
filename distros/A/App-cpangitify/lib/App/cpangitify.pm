package App::cpangitify;

use strict;
use warnings;
use autodie qw( :system );
use 5.020;
use experimental qw( signatures );
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );
use Path::Class qw( file dir );
use Git::Wrapper;
use File::Temp qw( tempdir );
use File::chdir;
use JSON::PP qw( decode_json );
use URI;
use PerlX::Maybe qw( maybe );
use File::Copy::Recursive qw( rcopy );
use File::Basename qw( basename );
use Archive::Libarchive::Extract;
use CPAN::ReleaseHistory;
use HTTP::Tiny;

# ABSTRACT: Convert cpan distribution from BackPAN to a git repository
our $VERSION = '0.19'; # VERSION


our $ua  = HTTP::Tiny->new;
our $opt_metacpan_url;

sub _rm_rf ($file)
{
  if($file->is_dir && ! -l $file)
  {
    _rm_rf($_) for $file->children;
  }

  $file->remove || die "unable to delete $file";
}

our $_run_cb = sub {};
our $original_run = \&Git::Wrapper::RUN;
our $trace = 0;

sub _run_wrapper ($self, @command)
{
  my @display;
  foreach my $arg (@command)
  {
    if(ref($arg) eq 'HASH')
    {
      foreach my $k (keys %$arg)
      {
        my $v = $arg->{$k};
        push @display, "--$k";
        push @display, $v =~ /\s/ ? "'$v'" : $v
          if $v ne '1'; # yes there is a weird exception for this :P
      }
    }
    else
    {
      push @display, $arg;
    }
  }
  $_run_cb->($self, @display);
  say "+ git @display" if $trace;
  $original_run->($self, @command);
}

sub author ($cpanid)
{
  state $cache = {};

  unless(defined $cache->{$cpanid})
  {
    my $uri = URI->new($opt_metacpan_url . "v1/author/" . $cpanid);
    my $res = $ua->get($uri);
    unless($res->{success})
    {
      say "error fetching $uri";
      say $res->{reason};
      return 2;
    }
    $cache->{$cpanid} = decode_json($res->{content})
  }

  my $email = $cache->{$cpanid}->{email};
  $email = $email->[0] if ref($email) eq 'ARRAY';
  sprintf "%s <%s>", $cache->{$cpanid}->{name}, $email;
}

sub main ($, @args)
{
  local @ARGV = @args;
  no warnings 'redefine';
  local *Git::Wrapper::RUN = \&_run_wrapper;
  use warnings;

  my %skip;
  my $opt_backpan_index_url;
  my $opt_backpan_url = "http://backpan.perl.org/authors/id";
  $opt_metacpan_url   = "http://fastapi.metacpan.org/";
  my $opt_trace = 0;
  my $opt_output;
  my $opt_resume;
  my $opt_branch = 'main';

  GetOptions(
    'backpan_index_url=s' => \$opt_backpan_index_url,
    'backpan_url=s'       => \$opt_backpan_url,
    'metacpan_url=s'      => \$opt_metacpan_url,
    'trace'               => \$opt_trace,
    'skip=s'              => sub ($version) { $skip{$_} = 1 for split /,/, $version },
    'resume'              => \$opt_resume,
    'output|o=s'          => \$opt_output,
    'help|h'              => sub { pod2usage({ -verbose => 2}) },
    'branch|b=s'          => \$opt_branch,
    'version'             => sub {
      say 'cpangitify version ', ($App::cpangitify::VERSION // 'dev');
      exit 1;
    },
  ) || pod2usage(1);

  local $trace = $opt_trace;

  my @names = @ARGV;
  s/::/-/g for @names;
  my %names = map { $_ => 1 } @names;
  my $name = $names[0];

  pod2usage(1) unless $name;

  my $dest = $opt_output ? dir($opt_output)->absolute : dir()->absolute->subdir($name);

  if(-e $dest && ! $opt_resume)
  {
    say "already exists: $dest";
    say "you may be able to update with the --resume option";
    say "but any local changes to your repository will be overwritten by upstream";
    return 2;
  }

  say "creating/updating index...";
  my $history = CPAN::ReleaseHistory->new(
    maybe url => $opt_backpan_index_url
  )->release_iterator;

  say "searching...";
  my @rel;
  while(my $release = $history->next_release)
  {
    next unless defined $release->distinfo->dist;
    next unless $names{$release->distinfo->dist};
    push @rel, $release;
  }

  if($@ || @rel == 0)
  {
    say "no releases found for $name";
    return 2;
  }

  say "mkdir $dest";
  $dest->mkpath(0,0700);

  my $git = Git::Wrapper->new($dest->stringify);

  if($opt_resume)
  {
    if($git->status->is_dirty)
    {
      die "the appear to be uncommited changes";
    }
    $skip{$_} = 1 for $git->tag;
  }
  else
  {
    $git->init;
    $git->checkout( -b => $opt_branch );
  }

  foreach my $rel (@rel)
  {
    my $path    = $rel->path;
    my $version = $rel->distinfo->version;
    my $time    = $rel->timestamp;
    my $cpanid  = $rel->distinfo->cpanid;

    say "$path [ $version ]";

    if($skip{$version})
    {
      say "skipping ...";
      next;
    }

    my $tmp = dir( tempdir( CLEANUP => 1 ) );

    local $CWD = $tmp->stringify;

    my $uri = URI->new(join('/', $opt_backpan_url, $path));
    say "fetch ... $uri";
    my $res = $ua->get($uri);
    unless($res->{success})
    {
      say "error fetching $uri";
      say $res->{reason};
      return 2;
    }

    say "unpack... @{[ basename $uri->path ]}";
    my $extract = Archive::Libarchive::Extract->new(
      memory => \$res->{content},
      entry => sub ($e) {
        say "- extract @{[ $e->pathname ]}" if $trace;
        1;
      },
    );
    $extract->extract( to => $CWD );

    my $source = do {
      my @children = map { $_->absolute } dir()->children;
      if(@children != 1)
      {
        say "archive doesn't contain exactly one child: @children";
      }

      $CWD = $children[0]->stringify;
      $children[0];
    };

    say "merge...";

    foreach my $child ($dest->children)
    {
      next if $child->basename eq '.git';
      _rm_rf($child);
    }

    foreach my $child ($source->children)
    {
      next if $child->basename eq '.git';
      if(-d  $child)
      {
        rcopy($child, $dest->subdir($child->basename)) || die "unable to copy $child $!";
      }
      else
      {
        rcopy($child, $dest->file($child->basename)) || die "unable to copy $child $!";
      }
    }

    say "commit and tag...";
    $git->add('.');
    $git->add('-u');
    $git->commit({
      message       => "version $version",
      date          => "$time +0000",
      author        => author($cpanid),
      'allow-empty' => 1,
    });
    eval { $git->tag($version) };
    warn $@ if $@;
  }

  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpangitify - Convert cpan distribution from BackPAN to a git repository

=head1 VERSION

version 0.19

=head1 DESCRIPTION

This is the module for the L<cpangitify> script.  See L<cpangitify> for details.

=head1 SEE ALSO

L<cpangitify>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Mohammad S Anwar (MANWAR)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
