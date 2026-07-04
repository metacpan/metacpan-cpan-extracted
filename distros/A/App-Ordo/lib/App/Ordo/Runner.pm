package App::Ordo::Runner;
use Moo;
use feature qw(say);
use utf8;
use open ':std', ':utf8';
use Term::ANSIColor qw(colored);

use App::Ordo qw($CURRENT_PATH extract_command);

# Pre-load all command classes to avoid "Can't locate object method 'new'"
use App::Ordo::Command::Ls;
use App::Ordo::Command::Cd;
use App::Ordo::Command::Help;
use App::Ordo::Command::Sync;
use App::Ordo::Command::User::Show;
use App::Ordo::Command::Job::Create;
use App::Ordo::Command::Job::Update;
use App::Ordo::Command::Job::Hold;
use App::Ordo::Command::Job::Release;
use App::Ordo::Command::Job::Ice;
use App::Ordo::Command::Job::Melt;
use App::Ordo::Command::Job::Run;
use App::Ordo::Command::Job::Show;
use App::Ordo::Command::Job::Log;
use App::Ordo::Command::Job::Logs;
use App::Ordo::Command::Job::Delete;
use App::Ordo::Command::Job::Kill;
use App::Ordo::Command::Job::Complete;
use App::Ordo::Command::Job::Watch;
use App::Ordo::Command::Cluster::Create;
use App::Ordo::Command::Cluster::Update;
use App::Ordo::Command::Cluster::Hold;
use App::Ordo::Command::Cluster::Release;
use App::Ordo::Command::Cluster::Ice;
use App::Ordo::Command::Cluster::Melt;
use App::Ordo::Command::Cluster::Run;
use App::Ordo::Command::Cluster::Delete;
use App::Ordo::Command::Cluster::Show;
use App::Ordo::Command::Cluster::Kill;
use App::Ordo::Command::Cluster::Complete;
use App::Ordo::Command::Cluster::Reset;
use App::Ordo::Command::Cal::List;
use App::Ordo::Command::Cal::Create;
use App::Ordo::Command::Cal::Delete;
use App::Ordo::Command::Cal::Show;
use App::Ordo::Command::Cal::Attach;
use App::Ordo::Command::Cal::Detach;
use App::Ordo::Command::Server::List;
use App::Ordo::Command::Server::Add;
use App::Ordo::Command::Server::Delete;

has 'api' => (is => 'lazy');

sub _build_api {
    App::Ordo::API->new;
}

# Full command tree
my %COMMANDS = (
   ls => 'App::Ordo::Command::Ls',
   cd => 'App::Ordo::Command::Cd',

   help => 'App::Ordo::Command::Help',
   sync => 'App::Ordo::Command::Sync',

   user => {
      show => 'App::Ordo::Command::User::Show',
   },

   job => {
      create   => 'App::Ordo::Command::Job::Create',
      update   => 'App::Ordo::Command::Job::Update',
      hold     => 'App::Ordo::Command::Job::Hold',
      release  => 'App::Ordo::Command::Job::Release',
      ice      => 'App::Ordo::Command::Job::Ice',
      melt     => 'App::Ordo::Command::Job::Melt',
      run      => 'App::Ordo::Command::Job::Run',
      show     => 'App::Ordo::Command::Job::Show',
      log      => 'App::Ordo::Command::Job::Log',
      logs     => 'App::Ordo::Command::Job::Logs',
      delete   => 'App::Ordo::Command::Job::Delete',
      kill     => 'App::Ordo::Command::Job::Kill',
      complete => 'App::Ordo::Command::Job::Complete',
      watch    => 'App::Ordo::Command::Job::Watch',
   },

   cluster => {
      create   => 'App::Ordo::Command::Cluster::Create',
      update   => 'App::Ordo::Command::Cluster::Update',
      hold     => 'App::Ordo::Command::Cluster::Hold',
      release  => 'App::Ordo::Command::Cluster::Release',
      ice      => 'App::Ordo::Command::Cluster::Ice',
      melt     => 'App::Ordo::Command::Cluster::Melt',
      run      => 'App::Ordo::Command::Cluster::Run',
      delete   => 'App::Ordo::Command::Cluster::Delete',
      show     => 'App::Ordo::Command::Cluster::Show',
      kill     => 'App::Ordo::Command::Cluster::Kill',
      complete => 'App::Ordo::Command::Cluster::Complete',
      reset    => 'App::Ordo::Command::Cluster::Reset',
   },

   cal => {
      list   => 'App::Ordo::Command::Cal::List',
      create => 'App::Ordo::Command::Cal::Create',
      delete => 'App::Ordo::Command::Cal::Delete',
      show   => 'App::Ordo::Command::Cal::Show',
      attach => 'App::Ordo::Command::Cal::Attach',
      detach => 'App::Ordo::Command::Cal::Detach',
      cron   => {
         add    => 'App::Ordo::Command::Cal::Cron::Add',
         delete => 'App::Ordo::Command::Cal::Cron::Delete',
      },
   },

   server => {
      list   => 'App::Ordo::Command::Server::List',
      add    => 'App::Ordo::Command::Server::Add',
      delete => 'App::Ordo::Command::Server::Delete',
   },
);

sub run {
   my ($self, @args) = @_;

   my $first = $args[0];

   if ($first && $first eq 'help') {
      App::Ordo::Command::Help->new(
         api      => $self->api,
         commands => \%COMMANDS,
      )->run(@args);
      return;
   }

   my $node = \%COMMANDS;
   my @path;

   while (@args && ref($node) eq 'HASH' && exists $node->{$args[0]}) {
      push @path, shift @args;
      $node = $node->{$path[-1]};
   }

   my $cmd_class = ref($node) eq '' ? $node : undef;

   unless ($cmd_class) {
      say colored(["bold red"], "Unknown command");
      say "Try 'help' for available commands";
      return;
   }

   eval {
      eval "require $cmd_class; 1" or die "Failed to load $cmd_class: $@";
      $cmd_class->new(api => $self->api)->run(@args);
   };
   if ($@) {
      chomp $@;
      say colored(["bold red"], "Error: $@");
   }
}

sub run_interactive {
   my $self = shift;
   App::Ordo->new(api => $self->api)->run_interactive;
}

1;
