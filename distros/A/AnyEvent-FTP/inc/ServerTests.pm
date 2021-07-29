package inc::ServerTests;

use Moose;
use namespace::autoclean;
use 5.010;
use Path::Class qw( file dir );
use YAML qw( LoadFile DumpFile );
use File::Glob qw( bsd_glob );

with 'Dist::Zilla::Role::TestRunner';

sub test
{
  my($self, $target) = @_;

  my $test_root = dir('.')->absolute;

  my @services = do {
    open my $fh, '<', '/etc/services';
    map { [split /\s+/]->[0] } grep /^(..)?ftp\s/, <$fh>;
  };

  foreach my $service (@services)
  {
    my $dir = $test_root->subdir('t', 'server', $service);
    $dir->mkpath(0,0700);
    my $old = $test_root->file('t', 'lib.pl');
    my $new = $dir->file('lib.pl');
    symlink $old, $new;

    $old = file( bsd_glob '~/etc/localhost/yml');
    $new = $dir->file('config.yml');

    my $config = LoadFile($old);
    $config->{port} = $service;
    DumpFile($new, $config);
  }

  my @remotes;

  foreach my $remote_config (grep { $_->basename =~ /\.yml$/ } dir(bsd_glob '~/etc')->children)
  {
    next if $remote_config->basename eq 'localhost.yml';
    #$self->zilla->log($remote_config->basename);

    my $name = $remote_config->basename;
    $name =~ s/\.yml$//;
    push @remotes, $name;

    my $dir = $test_root->subdir('t','server',$name);
    $dir->mkpath(0,0700);

    my $old = $test_root->file('t', 'lib.pl');
    my $new = $dir->file('lib.pl');
    symlink $old, $new;

    $old = $remote_config;
    $new = $dir->file('config.yml');

    my $config = LoadFile($old);
    DumpFile($new, $config);

  }

  foreach my $test_file (grep { $_->basename =~ /^client_/ } sort { $a->basename cmp $b->basename } $test_root->subdir('t')->children)
  {
    foreach my $service (@services, @remotes)
    {
      my $link = $test_root->file('t', 'server', $service, $test_file->basename);
      symlink $test_file, $link;
    }
  }

  local $ENV{AEF_PORT} = 'from_config';
  system 'prove', '-br', ($ENV{AEF_JOBS} ? ('-j' => $ENV{AEF_JOBS}, '-s') : ()), 't/server';
  $self->log_fatal('server test failure') unless $? == 0;
}

1;
