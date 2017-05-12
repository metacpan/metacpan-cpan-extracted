package Data::Checker;
# Copyright (c) 2013-2016 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

require 5.008;
use warnings 'all';
use strict;
use Module::Loaded;
use Parallel::ForkManager 0.7.6;

our($VERSION);
$VERSION='1.08';

###############################################################################
# BASE METHODS
###############################################################################

sub version {
   my($self) = @_;

   return $VERSION;
}

sub new {
   my($class,@args) = @_;

   my $self = {
               'parallel'     => 1,
              };

   bless $self, $class;

   return $self;
}

# Some checks can be run in parallel.  For these, passing in $n
# has the following effect:
#   $n = 0  : all of them will run simultaneously
#   $n = 1  : only one check at a time
#   $n > 1  : $n checks at a time
#
sub parallel {
   my($self,$n) = @_;

   if (defined($n)  &&  $n =~ /^\d+$/) {
      $n += 0;
   } else {
      warn "WARNING: Invalid argument to Data::Checker::parallel\n";
      return;
   }

   $$self{'parallel'} = $n + 0;
}

###############################################################################

sub check {
   my($self,$data,$type,$opts) = @_;

   # Check for data

   my (%data,$wantlist);
   if      (ref($data) eq 'ARRAY') {
      %data     = (map { $_,undef } @$data);
      $wantlist = 1;
   } elsif (ref($data) eq 'HASH') {
      %data     = %$data;
      $wantlist = 0;
   } else {
      die "ERROR: invalid data passed to Data::Checker::check\n";
   }

   # Find the check function

   my $func;
   if (! defined($type)) {
      die "ERROR: invalid check function passed to Data::Checker::check\n";

   } elsif (ref($type) eq 'CODE') {
      $func = $type;

   } else {
      my $caller = ( caller() )[0];

      TRY:
      foreach my $name ("${type}",
                        "${type}::check",
                        "${caller}::${type}",
                        "${caller}::${type}::check",
                        "Data::Checker::${type}",
                        "Data::Checker::${type}::check",
                       ) {

         # Ignore the case where $name does not have '::' because that means
         # we called it with the name of a function in the CALLER namespace
         # (so it'll get handled by one of the "${caller}::" cases, or $type
         # is a sub-namespace of Data::Checker.

         next  if ($name !~ /^(.*)::(.+)$/);
         my($mod) = ($1);
         $mod = "main"  if (! defined $mod);

         # Try loading the module (but not main:: or CALLER::

         if ($mod ne 'main'  &&
             $mod ne $caller  &&
             ! is_loaded($mod)) {
            next TRY  if (! eval "require $mod");
         }

         # Look for the function

         no strict 'refs';
         if (defined &{$name}) {
            $func = \&{$name};
            last TRY;
         }
      }

      die "ERROR: no valid check function passed to Data::Checker::check\n"
        if (! defined $func);
   }

   # Call parallel or serial check

   if ($$self{'parallel'} != 1) {
      return $self->_check_parallel(\%data,$wantlist,$func,$opts);
   } else {
      return $self->_check_serial(\%data,$wantlist,$func,$opts);
   }
}

sub _check_parallel {
   my($self,$data,$wantlist,$func,$opts) = @_;
   my(%pass,%fail,%info,%warn);
   my @ele      = keys %$data;
   my $max_proc = ($$self{'parallel'} > 1 ? $$self{'parallel'} : @ele);

   my $manager = Parallel::ForkManager->new($max_proc);
   $manager->run_on_finish
     (
      sub {
         my($pid,$exit_code,$id,$signal,$core_dump,$funcdata) = @_;
         my($ele,$err,$warn,$info) = @$funcdata;

         if (defined($err)  &&  @$err) {
            $fail{$ele} = $err;
         } else {
            $pass{$ele} = $$data{$ele};
         }

         if (defined($warn)  &&  @$warn) {
            $warn{$ele} = $warn;
         }
         if (defined($info)  &&  @$info) {
            $info{$ele} = $info;
         }
      });

   ELE:
   foreach my $ele (sort keys %$data) {
      $manager->start and next;

      my($element,$err,$warn,$info) = &$func($self,$ele,$$data{$ele},$opts);

      $manager->finish(0,[$element,$err,$warn,$info]);
   }

   $manager->wait_all_children();

   if ($wantlist) {
      my @pass = sort keys %pass;
      return (\@pass,\%fail,\%warn,\%info);
   } else {
      return (\%pass,\%fail,\%warn,\%info);
   }
}

sub _check_serial {
   my($self,$data,$wantlist,$func,$opts) = @_;
   my(%pass,%fail,%info,%warn);

   ELE:
   foreach my $ele (sort keys %{ $data }) {
      my($element,$err,$warn,$info) = &$func($self,$ele,$$data{$ele},$opts);

      if (defined($err)  &&  @$err) {
         $fail{$ele} = $err;
      } else {
         $pass{$ele} = $$data{$ele};
      }

      if (defined($warn)  &&  @$warn) {
         $warn{$ele} = $warn;
      }
      if (defined($info)  &&  @$info) {
         $info{$ele} = $info;
      }
   }

   if ($wantlist) {
      my @pass = sort keys %pass;
      return (\@pass,\%fail,\%warn,\%info);
   } else {
      return (\%pass,\%fail,\%warn,\%info);
   }
}

###############################################################################
# CHECK OPTIONS METHODS
###############################################################################

sub check_performed {
   my($self,$check_opts,$label) = @_;

   return 1  if (exists $$check_opts{$label});
   return 0;
}

sub check_option {
   my($self,$check_opts,$opt,$default,$label) = @_;

   if (defined $label  &&
       exists $$check_opts{$label}  &&
       exists $$check_opts{$label}{$opt}) {
      return $$check_opts{$label}{$opt};

   } elsif (exists $$check_opts{$opt}) {
      return $$check_opts{$opt};

   } else {
      return $default;
   }
}

sub check_level {
   my($self,$check_opts,$label) = @_;
   return $self->check_option($check_opts,'level','err',$label);
}

sub check_message {
   my($self,$check_opts,$label,$element,$message,$level,$err,$warn,$info) = @_;

   my $mess = $self->check_option($check_opts,'message',$message,$label);
   my @mess;
   if (ref($mess) eq 'ARRAY') {
      @mess = @$mess;
   } else {
      @mess = ($mess);
   }
   foreach my $m (@mess) {
      $m =~ s/__ELEMENT__/$element/g;
   }

   if ($level eq 'info') {
      push(@$info,@mess);
   } elsif ($level eq 'warn') {
      push(@$warn,@mess);
   } else {
      push(@$err,@mess);
   }
}

sub check_value {
   my($self,$check_opts,$label,$element,$value,$std_fail,$negate_fail,
      $err,$warn,$info) = @_;

   while (1) {

      # We perform the check if the $label check is performed, or if
      # there is no label.

      my $do_check = 1  if (! $label  ||
                            $self->check_performed($check_opts,$label));
      last  if (! $do_check);

      # Find the severity level and negate options (negate will never
      # occur if we didn't pass in a negate_fail message).

      my $level  = $self->check_level($check_opts,$label);
      my $negate = $self->check_option($check_opts,'negate',0,$label);
      $negate    = 0  if (! defined($negate_fail));

      # Check the value.

      if (! $negate  &&  ! $value) {
         $self->check_message($check_opts,$label,$element,$std_fail,
                              $level,$err,$warn,$info);
      } elsif ($negate  &&  $value) {
         $self->check_message($check_opts,$label,$element,$negate_fail,
                              $level,$err,$warn,$info);
      }

      last;
   }

   return ($element,$err,$warn,$info);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
