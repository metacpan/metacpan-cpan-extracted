# Copyrights 2011-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Any::Daemon;
our $VERSION = '0.94';


use Log::Report::Optional  'any-daemon';

use POSIX         qw(setsid setuid setgid :sys_wait_h);
use English       qw/$EUID $EGID $PID/;
use File::Spec    ();

use constant
  { SLEEP_FOR_SOME_TIME   =>  10
  , ERROR_RECOVERY_SLEEP  =>   5
  , SLOW_WARN_AGAIN_AFTER => 300
  };

# One program can only run one daemon
my %childs;


sub new(@) {my $class = shift; (bless {}, $class)->init({@_})}

sub init($)
{   my ($self, $args) = @_;

    $self->{AD_pidfn} = $args->{pid_file};

    my $user = $args->{user};
    if(defined $user)
    {   if($user =~ m/[^0-9]/)
        {   my $uid = $self->{AD_uid} = getpwnam $user;
            defined $uid
                or error __x"user {name} does not exist", name => $user;
        }
        else { $self->{AD_uid} = $user }
    }

    my $group = $args->{group};
    if(defined $group)
    {   if($group =~ m/[^0-9]/)
        {   my $gid = $self->{AD_gid} = getgrnam $group;
            defined $gid
                or error __x"group {name} does not exist", name => $group;
        }
    }

    $self->{AD_wd} = $args->{workdir};
    $self;
}

#--------------------

sub workdir() {shift->{AD_wd}}

#--------------------

sub run(@)
{   my ($self, %args) = @_;

    my $wd = $self->workdir;
    if($wd)
    {   -d $wd or mkdir $wd, 0700
            or fault __x"cannot create working directory {dir}", dir => $wd;

        chdir $wd
            or fault __x"cannot change to working directory {dir}", dir => $wd;
    }

    my $bg = exists $args{background} ? $args{background} : 1;
    if($bg)
    {   my $kid = fork;
        if($kid)
        {   # starting parent is ready to leave
            exit 0;
        }
        elsif(!defined $kid)
        {   fault __x"cannot start the managing daemon";
        }

        dispatcher('list') >= 1
            or error __x"you need to have a dispatcher to send log to";
    }

    my $pidfn = $self->{AD_pidfn};
    if(defined $pidfn)
    {   local *PIDF;
        if(open PIDF, '>', $pidfn)
        {   print PIDF "$PID\n";
            close PIDF;
        }
    }

    my $gid = $self->{AD_gid} || $EGID;
    my $uid = $self->{AD_uid} || $EUID;
    if($gid!=$EGID && $uid!=$EUID)
    {   chown $uid,$gid, $wd if $wd;

        eval { if($] > 5.015007) { setgid $gid; setuid $uid }
               else
               {   # in old versions of Perl, the uid and gid gets cached
                   $EGID = $gid;
                   $EUID = $uid;
               }
             };

        $@ and error __x"cannot switch to user/group to {uid}/{gid}: {err}"
          , uid => $uid, gid => $gid, err => $@;
    }
    elsif($EUID==0)
    {   warning __"running daemon as root is dangerous: please specify user";
    }

    my $sid         = setsid;

    my $reconfig    = $args{reconfig}    || \&_reconfig_daemon;
    my $kill_childs = $args{kill_childs} || \&_kill_childs;
    my $child_died  = $args{child_died}  || \&_child_died;
    my $max_childs  = $args{max_childs}  || 10;
    my $child_task  = $args{child_task}  || \&_child_task; 

    my $run_child   = sub
      { # re-seed the random number sequence per process
        srand;

        # unhandled errors are to be treated seriously.
        my $rc = try { $child_task->(@_) };
        if(my $e = $@->wasFatal) { $e->throw(reason => 'ALERT'); $rc = 1 }
        $rc;
      };

    $SIG{CHLD} = sub { $child_died->($max_childs, $run_child) };
    $SIG{HUP}  = sub
      { notice "daemon received signal HUP";
        $reconfig->(keys %childs);
        $child_died->($max_childs, $run_child);
      };

    $SIG{TERM} = $SIG{INT} = sub
      { my $signal = shift;
        notice "daemon terminated by signal $signal";

        $SIG{TERM} = $SIG{CHLD} = 'IGNORE';
        $max_childs = 0;
        $kill_childs->(keys %childs);
        sleep 2;  # give childs some time to stop
        kill TERM => -$sid;
        unlink $pidfn if $pidfn;
        my $intrnr = $signal eq 'INT' ? 2 : 9;
        exit $intrnr+128;
      };

    if($bg)
    {   # no standard die and warn output anymore (Log::Report)
        dispatcher close => 'default';

        # to devnull to avoid write errors in third party modules
        open STDIN,  '<', File::Spec->devnull;
        open STDOUT, '>', File::Spec->devnull;
        open STDERR, '>', File::Spec->devnull;
    }

    info __x"daemon started; proc={proc} uid={uid} gid={gid} childs={max}"
      , proc => $PID, uid => $EUID, gid => $EGID, max => $max_childs;

    $child_died->($max_childs, $run_child);

    # child manager will never die
    sleep 60 while 1;
}

sub _reconfing_daemon(@)
{   my @childs = @_;
    notice "HUP: reconfigure deamon not implemented";
}

sub _child_task()
{   notice "No child_task implemented yet. I'll sleep for some time";
    sleep SLEEP_FOR_SOME_TIME;
}

sub _kill_childs(@)
{   my @childs = @_;
    notice "killing ".@childs." children";
    kill TERM => @childs;
}

# standard implementation for starting new childs.
sub _child_died($$)
{   my ($max_childs, $run_child) = @_;

    # Clean-up zombies

  ZOMBIE:
    while(1)
    {   my $kid = waitpid -1, WNOHANG;
        last ZOMBIE if $kid <= 0;

        if($? != 0)
        {   notice "$kid process died with errno $?";
            # when children start to die, do not respawn too fast,
            # because usually this means serious troubles with the
            # server (like database) or implementation.
            sleep ERROR_RECOVERY_SLEEP;
        }

        delete $childs{$kid};
    }

    # Start enough childs
    my $silence_warn = 0;

  BIRTH:
    while(keys %childs < $max_childs)
    {   my $kid = fork;
        unless(defined $kid)
        {   alert "cannot fork new children" unless $silence_warn++;
            sleep 1;     # wow, back down!  Probably too busy.
            $silence_warn = 0 if $silence_warn==SLOW_WARN_AGAIN_AFTER;
            next BIRTH;
        }

        if($kid==0)
        {   # new child
            $SIG{HUP} = $SIG{TERM} = $SIG{INT}
               = sub {info 'child says bye'; exit 0};

            # I'll not handle my parent's kids!
            $SIG{CHLD} = 'IGNORE';
            %childs    = ();

            my $rc     = $run_child->();
            exit $rc;
        }

        # parent
        $childs{$kid}++;
    }
}

1;
