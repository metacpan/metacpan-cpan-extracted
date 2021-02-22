package Command::Template::Runner;
use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

use Storable 'dclone';
use Command::Template::Runner::Record;

# attributes
sub instance ($self) { $self->{instance} }
sub last_run ($self) { $self->{last_run} }
sub options ($self, @new) {
   return dclone($self->{options}) unless @new;
   $self->{options} = $new[0];
   return $self;
}

use IPC::Run ();
sub __ipc_run ($command, %options) {
   my $in = $options{stdin} // '';
   my $out = '';
   my $err = '';
   my $timeout = $options{timeout} // 0;

   my @args = ($command, \$in, \$out, \$err);
   push @args, IPC::Run::timeout($timeout) if $timeout;

   eval {
      IPC::Run::run(@args);
      $timeout = 0;
      1;
   } or do { die $@ if $@ !~ m{^IPC::Run:\s*timeout} };

   return {
      command => $command,
      ec      => $?,
      options => \%options,
      stderr  => $err,
      stdout  => $out,
      timeout => $timeout,
   };
}

sub new ($p, $i) { return bless { instance => $i, options => {} }, $p }

sub run ($self, %bindopts) {
   my (%bindings, %options); # split %bindopts into these hashes
   while (my ($key, $value) = each %bindopts) {
      if (substr($key, 0, 1) eq '-') {
         $options{substr $key, 1} = $value;
      }
      else {
         $bindings{$key} = $value;
      }
   }
   my $cmd = $self->instance->generate(%bindings);
   %options = (%{$self->options}, %options);
   my $run = $self->{last_run}
      = Command::Template::Runner::Record->new(__ipc_run($cmd, %options));
   return $run;
}

1;
