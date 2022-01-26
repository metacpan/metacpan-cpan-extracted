package MuDu::Command::List;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'list tasks',
      description => 'Get full or partial list of tasks',
      supports    => [qw< list ls >],
      options     => [
         {
            help => 'include all tasks (including done) '
               . '(exclusion is not honored)',
            getopt => 'all|A!',
         },
         {
            help => 'include(/exclude) all active tasks '
               . '(ongoing and waiting)',
            getopt => 'active|a!',
         },
         {
            help   => 'include(/exclude) done tasks',
            getopt => 'done|d!',
         },
         {
            help   => 'include(/exclude) ongoing tasks',
            getopt => 'ongoing|o!',
         },
         {
            help   => 'include(/exclude) waiting tasks',
            getopt => 'waiting|w!',
         },
         {
            help   => 'use extended, unique identifiers',
            getopt => 'id|i!',
         },
         {
            help => 'limit up to n items for each category (0 -> inf)',
            getopt => 'n=i'
         },
      ],
      execute => \&list,
   };
}

sub list ($main, $config, $args) {
   my @active = qw< ongoing waiting >;
   my @candidates = (@active, 'done');
   my %included;

   # Add stuff
   if ($config->{all}) {
      @included{@candidates} = (1) x @candidates;
   }
   for my $option (@candidates) {
      $included{$option} = 1 if $config->{$option};
   }
   if ($config->{active} || !scalar keys %included) {
      @included{@active} = (1) x @active;
   }

   # Remove stuff
   delete @included{@active}
     if exists $config->{active} && !$config->{active};
   for my $option (@candidates) {
      delete $included{$option}
        if exists $config->{$option} && !$config->{$option};
   }

   my $basedir = path($config->{basedir});
   my (%cf, %pf);
   my $limit = $config->{n};
   for my $source (@candidates) {
      next unless $included{$source};
      for my $file (list_category($config, $source)) {
         my $title = get_title($file);
         my $sid = $config->{id} ? '-' . $file->basename : ++$cf{$source};
         my $id = substr($source, 0, 1) . $sid;
         say "$id [$source] $title";
         last if $limit && ++$pf{$source} >= $limit;
      } ## end for my $file (list_category...)
   } ## end for my $source (@candidates)

   return 0;
} ## end sub list

1;
