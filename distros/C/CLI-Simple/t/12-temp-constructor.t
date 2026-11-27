use strict;
use warnings;

use Test::More;
use File::Spec;
use CLI::Simple;

{
  package Local::TempConstructor;
  use parent qw(CLI::Simple);
  our @SEEN;
  sub init {
    my ($self) = @_;
    push @SEEN, [ $self->get_workspace, $self->get_report ];
    return $self;
  }
  sub cmd_run { return 0; }
}

subtest 'resources exist before application init' => sub {
  local @ARGV = ('run');
  my $app = Local::TempConstructor->new(
    commands  => { run => \&Local::TempConstructor::cmd_run },
    temp_dir  => { accessor => 'workspace' },
    temp_file => { accessor => 'report', suffix => '.txt' },
  );
  my ($dir, $file) = @{ $Local::TempConstructor::SEEN[-1] };
  ok(-d $dir, 'directory was created before init');
  ok(-f $file, 'file was created before init');
  is($app->get_workspace, $dir, 'directory accessor');
  is($app->get_report, $file, 'file accessor');
  undef $app;
  ok(!-e $file, 'file cleaned');
  ok(!-e $dir, 'directory cleaned');
};

subtest 'second instance may reuse generated accessor methods' => sub {
  local @ARGV = ('run');
  my $app = Local::TempConstructor->new(
    commands  => { run => \&Local::TempConstructor::cmd_run },
    temp_dir  => { accessor => 'workspace' },
    temp_file => { accessor => 'report' },
  );
  ok(-d $app->get_workspace, 'repeated constructor works');
  undef $app;
};

{
  package Local::TempCollision;
  use parent qw(CLI::Simple);
  sub cmd_run { return 0; }
}

subtest 'CLI option accessor collision rejected before allocation' => sub {
  local @ARGV = ('run');
  eval {
    Local::TempCollision->new(
      commands => { run => \&Local::TempCollision::cmd_run },
      option_specs => ['report=s'],
      temp_file => { accessor => 'report' },
    );
  };
  like($@, qr/Temporary resource accessor already exists/, 'collision detected');
};

{
  package Local::TempMultiple;
  use parent qw(CLI::Simple);
  sub cmd_run { return 0; }
}

subtest 'multiple resources and no accessors' => sub {
  local @ARGV = ('run');
  my $app = Local::TempMultiple->new(
    commands => { run => \&Local::TempMultiple::cmd_run },
    temp_file => [
      { accessor => 'first' },
      { accessor => 'second' },
      { no_accessors => 1 },
    ],
    temp_dir => 1,
  );
  ok(-f $app->get_first, 'first temporary file');
  ok(-f $app->get_second, 'second temporary file');
  ok(-d $app->get_temp_dir, 'default temporary directory');
  ok(!$app->can('get_temp_file'), 'unnamed file has no accessor');
  undef $app;
};

done_testing;
1;
