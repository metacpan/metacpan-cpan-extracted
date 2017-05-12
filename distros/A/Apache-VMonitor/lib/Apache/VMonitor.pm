package Apache::VMonitor;

$Apache::VMonitor::VERSION = '2.07';

require 5.006;

use strict;
use warnings;

use Template ();

BEGIN {
    use constant MP2 => eval { require mod_perl2; $mod_perl2::VERSION >= 2.0 };
    eval {require mod_perl} unless MP2;
    die "mod_perl is required to run this module: $@" if $@;

    if (MP2) {
        require Apache2::ServerUtil;
        require Apache2::RequestRec;
        require Apache2::RequestIO;
        require APR::Table;
        require APR::Pool;
        require Apache2::Const;
        Apache2::Const->import('OK');
    } else {
        require Apache;
        require Apache::Constants;
        Apache::Constants->import('OK');
    }
    require Apache::Scoreboard;
    require Time::HiRes;
}

# once 2.0 is released drop the Apache::MPM_IS_THREADED case
use constant APACHE_IS_THREADED => MP2 && 
    require Apache2::MPM && Apache2::MPM->is_threaded();

# Apache::Scoreboard for 1.3 scoreboard has the vhost accessor only
# starting from version 0.12
use constant HAS_VHOSTS => (MP2 || $Apache::Scoreboard::VERSION > 0.11);

#use constant THREAD_LIMIT => MP2
#    ? Apache::Const::THREAD_LIMIT
#    : 0; # no threads in mp1

use constant SINGLE_PROCESS_MODE => MP2
    ? Apache2::ServerUtil::exists_config_define('ONE_PROCESS')
    : Apache->define('X');

my $gtop;

eval {
    require GTop;
    $gtop = GTop->new;
};

my $tt;

%Apache::VMonitor::longflags = (
  "_" => "Waiting for Connection",
  "S" => "Starting up",
  "R" => "Reading Request",
  "W" => "Sending Reply",
  "K" => "Keepalive (read)",
  "D" => "DNS Lookup",
  "C" => "Closing connection",
  "L" => "Logging",
  "G" => "Gracefully finishing",
  "I" => "Idle cleanup of worker",
  "." => "Open slot with no current process",
);

########################
# default config values
########################
%Apache::VMonitor::Config = (
   # behavior
   refresh  => 0,
   verbose  => 0,

   # sections to show
   system   => 1,
   apache   => 1,
   procs    => 0,
   mount    => 0,
   fs_usage => 1,

   # sorting
   apache_sort_by        => 'size',
   apache_sort_by_ascend => 0,
);

my @sects = qw(system apache procs mount fs_usage verbose);

my %cfg = ();

sub handler_mp1 ($$)     { &run }
sub handler_mp2 : method { &run }
*handler = MP2 ? \&handler_mp2 : \&handler_mp1;
my $counter = 0;

sub run {
    my ($class, $r) = @_;
    $class = ref($class)||$class;
    #$tt = Template->new({});

    my %params = MP2 
        ? map({ split('=', $_, 2) } split /[&]/, $r->args)
        : $r->args;
    # modify the default args if requested
    for (keys %Apache::VMonitor::Config) {
        $cfg{$_} = exists $params{$_}
            ? $params{$_}
            : $Apache::VMonitor::Config{$_};
    }

    my $pid = $params{pid} || 0;

    # really just a worker index (in threaded mpm)
    my $tid = $params{thread_num} || '';

    # build the updated URL (append the pid k/v pair)
    my $url = $r->uri . "?pid=$pid&" . join "&", map {"$_=$cfg{$_}"} keys %cfg;

    # if refresh is non-null, set the refresh header
    $r->headers_out->set(Refresh => "$cfg{refresh}; URL=$url") 
        if $cfg{refresh};

    MP2 ? $r->content_type('text/html') : $r->send_http_header('text/html');

    my $self = $class->new(
        r     => $r,
        tt    => $tt,
        gtop  => $gtop,
        cfg   => \%cfg,
        url   => $url,
        pid   => $pid,
        tid   => $tid,
    );

    $self->{tt} ||= Template->new({
        BLOCKS => {
            tmpl_start_html    => $self->tmpl_start_html(),
            tmpl_end_html      => $self->tmpl_end_html(),
            tmpl_procs         => $self->tmpl_procs(),
            tmpl_nav_bar       => $self->tmpl_nav_bar(),
            tmpl_fs_usage      => $self->tmpl_fs_usage(),
            tmpl_mount         => $self->tmpl_mount(),
            tmpl_apache        => $self->tmpl_apache(),
            tmpl_apache_single => $self->tmpl_apache_single(),
            tmpl_system        => $self->tmpl_system(),
            tmpl_verbose       => $self->tmpl_verbose(),
        },
    });

    $self->generate;

    return OK;
}

sub new {
    my $class = shift;
    my $self = bless {@_}, ref($class)||$class;
    return $self;
}

sub generate {
    my $self = shift;
    my $cfg = $self->{cfg};
    my $tt = $self->{tt};

    my @items = 'start_html';

    if ($self->{pid}) {
        push @items, qw(apache_single);
    }
    else {
        my @sects = qw(system apache procs fs_usage mount);
        $cfg->{$_} && push @items, $_ for @sects;
        push @items, qw(nav_bar);
        $cfg->{$_} && push @items, $_ for qw(verbose);

    }

    push @items, qw(end_html);

    for my $item (@items) {
        my $tmpl_block = "tmpl_$item";
        my $data_sub = $self->can("data_$item");
        my $data = $data_sub ? $self->$data_sub : {};
        if (MP2 || $] >= 5.008) {
            $tt->process($tmpl_block, $data) or warn $tt->error();
        }
        else {
            # mp1 && perl < 5.008 can't handle the above
            my $x;
            $tt->process($tmpl_block, $data, \$x) or warn $tt->error();
            print $x;
        }
    }
}







### start_html ###

sub data_start_html {
    my $self = shift;
   # return {};

    my $url = $self->{url};
    my $cfg = $self->{cfg};

    my @rates = map {
        [$_, ($cfg->{refresh} == $_ ? '' : fixup_url($url, 'refresh', $_)) ];
    } qw(0 1 5 10 20 30 60);

    return {
        rate  => $cfg->{refresh},
        rates => \@rates,
    };

}

sub tmpl_start_html {

    return \ <<'EOT';
<html>
<head>
  <title>Apache::VMonitor</title>
  <style type="text/css">
  body {
    color: #000;
    background-color: #fff;
    border: 0px;
    padding: 0px 0px 0px 0px;
    margin: 5px 5px 5px 5px;
    font-size: 0.8em;
  }
  p.hdr {
    background-color: #ddd;
    border: 2px outset;
    padding: 3px;
    width: 99%;
  }
  span.item_even {
    background-color: #dddddd;
    color: #000000;
  }
  span.item_odd {
    background-color: #ffffff;
    color: #000000;
  }
  span.normal {
    color: #000000;
  }
  span.warn {
    color: #ff99cc;
  }
  span.alert {
    color: #ff0000;
  }
  </style>
</head>
<body bgcolor="white">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<b><font size=+1 color="#339966">Apache::VMonitor</font></b>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Refresh rate:&nbsp;&nbsp;
[%-
  IF rates.size;
    FOREACH item = rates;
      IF item.1;
        "<a href=\"${item.1}\">[ ${item.0} ]</a>&nbsp;&nbsp;";
      ELSE;
        "[ ${item.0} ]&nbsp;&nbsp;";
      END;
    END;
  END;
-%]
<br>
EOT

}






### end_html ###

# not needed
sub data_end_html { {} }

sub tmpl_end_html {
    return \ <<'EOT';
</body>
</html>
EOT
}




### nav_bar ###

sub data_nav_bar {
    my $self = shift;

    my $url = $self->{url};
    my $cfg = $self->{cfg};
    my %hide = ();
    my %show = ();

    for (@sects) {
        if ($cfg->{$_}) {
            $hide{$_} = fixup_url($url, $_, 0);
        }
        else {
            $show{$_} = fixup_url($url, $_, 1);
        }
    }

    return {
        show => \%show,
        hide => \%hide,
    };
}

sub tmpl_nav_bar {

    return \ <<'EOT';
<hr>
   <font size=-1>
[% IF show.size %]
Show: 
    [%- FOREACH item = show -%]
        [ <a href="[% item.value %]">[% item.key %]</a> ]
    [%- END -%]
<br>
[% END %]

[% IF hide.size %]
Hide: 
    [%- FOREACH item = hide -%]
        [ <a href="[% item.value %]">[% item.key %]</a> ]
    [%- END -%]
<br>
[% END %]
   </font><hr>
EOT
}



### system ###

sub data_system {
    my $self = shift;

    # uptime and etc...
    my($min, $hour, $day, $mon, $year) = (localtime)[1..5];
    my %date = (
        min   => $min,
        hour  => $hour,
        day   => $day,
        month => $mon + 1,
        year  => $year + 1900,
    );

    unless ($gtop)
    {
        return { date    => \%date, };
    }

    my $loadavg = $gtop->loadavg;

    my $data = {
        date    => \%date,
        uptime  => format_time($gtop->uptime->uptime),
        loadavg => \@{ $loadavg->loadavg },
    };

    if ($^O eq 'linux') {
        $data->{tasks} = [ $loadavg->nr_tasks, $loadavg->nr_running ];
    }

    # total CPU stats
    my $cpu   = $gtop->cpu;
    my $total = $cpu->total;
    $data->{cpu} = {
        map { $_ => ( $total ? ($cpu->$_() * 100 / $total) : 0 ) }
            qw(user nice sys idle)
    };

    # total mem stats
    my $mem = $gtop->mem;
    $data->{mem} = {
        map { $_ => size_string($mem->$_()) }
            qw(total used free shared buffer)
    };

    # total swap stats
    my $swap       = $gtop->swap();
    my $swap_total = $swap->total();
    my $swap_used  = $swap->used();
    $data->{swap} = {
        usage => ($swap_total ? ($swap_used * 100 / $swap_total) : 0),
        used  => $swap_used,
        map({ ("f$_" => size_string($swap->$_)) }
            qw(total used free)),
        map({ ("f$_" => format_counts($swap->$_)) }
            qw(pagein pageout)),
    };

    return $data;
}



sub tmpl_system {

    return \ <<'EOT';
<hr>
<pre>
[%-

  # date/time/load
  USE format_date = format("%d/%.2d/%d");
  fdate = format_date(date.month, date.day, date.year);

  USE format_time = format("%d:%.2d%s");
  pam = date.hour > 11 ? "pm" : "am";
  date.hour = date.hour - 12 IF date.hour > 11;
  ftime = format_time(date.hour, date.min, pam);

  USE format_load = format("%.2f %.2f %.2f");
  floadavg = format_load(loadavg.0, loadavg.1, loadavg.2,);

  USE format_run_procs = format(", %d processes/threads: %d running");
  frun_procs = tasks
      ? format_run_procs(tasks.0, tasks.1)
      : "";

  USE format_line_time_load =
      format("<b>%s %s  up %s, load average: %s%s</b>\n");
  format_line_time_load(fdate, ftime, uptime, floadavg, frun_procs);


  # CPU
  USE format_line_cpu =
      format("<b>CPU:   %2.1f%% user, %2.1f%% nice, %2.1f%% sys, %2.1f%% idle</b>\n");
  format_line_cpu(cpu.user, cpu.nice, cpu.sys, cpu.idle);


  # Memory
  USE format_line_mem =
      format("<b>Mem:  %5s av, %5s used, %5s free, %5s shared, %5s buff</b>\n");
  format_line_mem(mem.total, mem.used, mem.free, mem.shared, mem.buffer);


  # Swap
    # visual alert on swap usage:
    # 1) 5Mb < swap < 10 MB             color: light red
    # 2) 20% < swap (swapping is bad!)  color: red
    # 3) 70% < swap (swap almost used!) color: red

  format_swap_data = "%5s av, %5s used, %5s free, %5s pagein, %5s pageout";
  IF 5000 < swap.used AND swap.used < 10000;
      USE format_line_swap = format("<b>Swap: <font color=\"#ff99cc\">$format_swap_data</font></b>\n");
  ELSIF swap.usage >= 20;
      USE format_line_swap = format("<b>Swap: <font color=\"#ff0000\">$format_swap_data</font></b>\n");
  ELSIF swap.usage >= 70;
      # swap on fire!
      USE format_line_swap = format("<b>Swap: <font color=\"#ff0000\">$format_swap_data</font></b>\n");
  ELSE;
      USE format_line_swap = format("<b>Swap: $format_swap_data</b>\n");
  END;

  format_line_swap(swap.ftotal, swap.fused, swap.ffree, swap.fpagein, swap.fpageout);

-%]
</pre>
EOT

}



### apache ###

sub scoreboard_image {
    MP2 ? Apache::Scoreboard->image(shift->{r}->pool)
        : Apache::Scoreboard->image();
}

sub data_apache {
    my $self = shift;

    if (MP2 && $Apache::Scoreboard::VERSION < 2.0) {
        die "Apache::Scoreboard 2.0 or higher is wanted, " .
            "this is only version $Apache::Scoreboard::VERSION";
    }

    my $image = $self->scoreboard_image();

    # total memory usage stats
    my %mem_total = map { $_ => 0 } qw(size real max_shared);

    my %cols = (
                 # WIDTH # LABEL                   # SORT
        pid     => [ 3, 'PID'                     , 'd'],
        size    => [ 5, 'Size'                    , 'd'],
        share   => [ 5, 'Share'                   , 'd'],
        vsize   => [ 5, 'VSize'                   , 'd'],
        rss     => [ 5, 'Rss'                     , 'd'],
        mode    => [ 1, 'M'                       , 's'],
        elapsed => [ 7, 'Elapsed'                 , 'd'],
        lastreq => [ 7, 'LastReq'                 , 'd'],
        served  => [ 4, 'Srvd'                    , 'd'],
        client  => [15, 'Client'                  , 's'],
        vhost   => [15, 'Virtual Host'            , 's'],
        request => [27, 'Request (first 64 chars)', 's'],
    );

    my @cols_sorted = qw(pid size share vsize rss mode elapsed lastreq served
                         client);
    push @cols_sorted, "vhost" if HAS_VHOSTS;
    push @cols_sorted, "request";

    my $sort_field = lc($cfg{apache_sort_by}) || 'size';
    $sort_field = 'size' unless $cols{$sort_field};
    my $sort_ascend = $Apache::VMonitor::Config{apache_sort_by_ascend} || 0;
    #warn "SORT field: $sort_field, ascending $sort_ascend\n";

    for (@cols_sorted) {
        if ($sort_field eq $_) {
            $sort_ascend = $cfg{apache_sort_by_ascend} + 1;
            $sort_ascend %= 2; # reverse sorting order
        }

        # add a link to sort by that field
        $cols{$_}[3] = fixup_url($self->{url},
                                 apache_sort_by        => $cols{$_}[1],
                                 apache_sort_by_ascend => $sort_ascend);
    }

    my %data = ();
    # in a non-single server mode we want to show the parent process
    # (so we can tell its memory usage)
    unless (SINGLE_PROCESS_MODE) {

        my $ppid = getppid();
        #warn "ppid: $ppid\n";
        my $pmem = $self->pid2mem($ppid, \%mem_total);

        # XXX: mp1 gives us a wrong getppid (proc that has died
        # already, is there another way to get to the parent proc?)
        # handle the parent case
        if ($pmem && $pmem->{size}) {
            my $prec = {
                id        => 0,
                pid       => $ppid,
                pid_link  => fixup_url($self->{url}, pid => $ppid),
                %$pmem,
            };
            $data{ $ppid }{process} = $prec;
            # this parent has no worker threads
            $data{ $ppid }{workers} = [];
        }
    }

    my $SERVER_LIMIT = MP2 ? $image->server_limit : $Apache::Constants::HARD_SERVER_LIMIT;

    my $i;
    my $parent_count = 0;
    my ($parent_score, $worker_score, $pid);
    for ($i=0; $i < $SERVER_LIMIT; $i++) {
        last if SINGLE_PROCESS_MODE && $i > 0;

        $parent_score = MP2 ? $image->parent_score($i) : $image->servers($i);
        next unless $parent_score;

        $pid = SINGLE_PROCESS_MODE
            ? $$
            : MP2 ? $parent_score->pid : $image->parent($i)->pid;

        next unless $pid;

        $worker_score = MP2 ? $parent_score->worker_score : $parent_score;
        next unless $worker_score;

        my $mem = $self->pid2mem($pid, \%mem_total);
        next unless $mem && $mem->{size};

        # good record
        $parent_count++;

        my %record = %$mem;

        $record{pid} = $pid;
        $record{id}  = $parent_count;

        $data{ $pid }{process} = \%record;

        if (APACHE_IS_THREADED) {
            do {
                my $record = $self->score2record($worker_score);
                my $thread_num = $worker_score->thread_num;
                $record->{pid}      = $thread_num;
                $record->{pid_link} = fixup_url($self->{url}, pid => $pid);
                $record->{pid_link} .= "&thread_num=$thread_num";
                push @{ $data{$pid}{workers} }, $record;
                $worker_score = 
                    $parent_score->next_live_worker_score($worker_score);
            } while $worker_score
        }
        else {
            push @{ $data{$pid}{workers} },
                $self->score2record($worker_score);
        }
    }

    my @records = ();
    my $count = 0;
    my $max_client_len  =  9;
    my $max_vhost_len   =  5;
    my $max_request_len = 10;
    my $max_pid_len     =  0;

    # sort strings alphabetically, numbers numerically reversed
    my $sort_sub;
    #warn "sort_field: $sort_field $cols{$sort_field}[2]\n";
    # XXX: need to sort {workers} as well
    if ($cols{$sort_field}[2] eq 's') {
        $sort_sub = $sort_ascend
            ? sub { $data{$a}{process}{$sort_field} cmp $data{$b}{process}{$sort_field} }
            : sub { $data{$b}{process}{$sort_field} cmp $data{$a}{process}{$sort_field} };
    }
    else {
        $sort_sub = $sort_ascend
            ? sub { $data{$a}{process}{$sort_field} <=> $data{$b}{process}{$sort_field} }
            : sub { $data{$b}{process}{$sort_field} <=> $data{$a}{process}{$sort_field} };
    }

    # it's a pity to waste display space on vhosts if none is configured
    my $has_vhosts_entries = 0;
    for my $pid (sort $sort_sub keys %data) {

        my $rec = $data{$pid}{process};

        # threads 
        my @workers = ();
        my $tcount = 0;
        for my $trec (@{ $data{$pid}{workers} || []}) {
            $tcount++;

            my $lastreq = $trec->{lastreq} ? $trec->{lastreq}/1000 : 0;
            $has_vhosts_entries++ if exists $trec->{vhost} && length $trec->{vhost};

            push @workers, {
                id        => sprintf("%03d", $tcount),
                pid       => $trec->{pid},
                pid_link  => $trec->{pid_link},
                mode      => $trec->{mode},
                elapsed   => $trec->{elapsed},
                felapsed  => format_time($trec->{elapsed}),
                lastreq   => $lastreq,
                flastreq  => format_time($lastreq),
                fserved   => format_counts($trec->{served}),
                client    => $trec->{client},
                vhost     => $trec->{vhost},
                request   => $trec->{request},
            };
            $max_client_len = length $trec->{client}
                if $trec->{client} && length($trec->{client}) > $max_client_len;
            $max_request_len = length $trec->{request}
                if $trec->{request} && length($trec->{request}) > $max_request_len;
            $max_vhost_len = length $trec->{vhost}
                if exists $trec->{vhost} && length($trec->{vhost}) > $max_vhost_len;
            # XXX: s/pid/tid/;
            $max_pid_len = length $pid if length($pid) > $max_pid_len;
        }

        my $lastreq = $rec->{lastreq} ? $rec->{lastreq}/1000 : 0;
        # print sorted
        push @records, {
            id        => sprintf("%3d", $rec->{id}),
            pid       => $rec->{pid},
            pid_link  => $rec->{pid_link},
            mode      => $rec->{mode},
            elapsed   => $rec->{elapsed},
            felapsed  => format_time($rec->{elapsed}),
            lastreq   => $lastreq,
            flastreq  => format_time($lastreq),
            fserved   => format_counts($rec->{served}),
            fsize     => size_string($rec->{size}),
            fshare    => size_string($rec->{share}),
            fvsize    => size_string($rec->{vsize}),
            frss      => size_string($rec->{rss}),
            client    => $rec->{client},
            vhost     => $rec->{vhost},
            request   => $rec->{request},
            workers   => \@workers,
        };

        $has_vhosts_entries++ if exists $rec->{vhost} && length $rec->{vhost};
        $max_client_len = length $rec->{client}
            if $rec->{client} && length($rec->{client}) > $max_client_len;
        $max_request_len = length $rec->{request}
            if $rec->{request} && length($rec->{request}) > $max_request_len;
        $max_vhost_len = length $rec->{vhost}
            if $rec->{vhost} && length($rec->{vhost}) > $max_vhost_len;
        $max_pid_len = length $pid if length($pid) > $max_pid_len;
    }

    $cols{client}[0]  = $max_client_len;
    $cols{request}[0] = $max_request_len;
    $cols{vhost}[0]   = $max_vhost_len;
    $cols{pid}[0]     = $max_pid_len;

    # Summary of memory usage
    #  Note how do I calculate the approximate real usage of the memory:
    #  1. For each process sum up the difference between shared and system
    #  memory 2. Now if we add the share size of the process with maximum
    #  shared memory, we will get all the memory that actually is being
    #  used by all httpd processes but the parent process.
    my $total = {
        size    => $mem_total{size}/1000,
        fsize   => size_string($mem_total{size}),
        shared  => ($mem_total{real} + $mem_total{max_shared})/1000,
        fshared => size_string($mem_total{real} + $mem_total{max_shared}),
    };

    # remove the vhost col if there are no vhosts to display
    @cols_sorted = grep { $_ ne 'vhost' } @cols_sorted 
        unless $has_vhosts_entries;

    return {
        total       => $total,
        records     => \@records,
        cols_sorted => \@cols_sorted,
        cols        => \%cols,
        has_vhosts_entries  => $has_vhosts_entries,
        threaded    => (APACHE_IS_THREADED ? 1 : 0),
    };
}

sub pid2mem {
    my($self, $pid, $total) = @_;

    return {} unless $gtop;

    my $proc_mem = $gtop->proc_mem($pid);
    my $size  = $proc_mem ? $proc_mem->size($pid) : 0;
    # dead process?
    return {} unless $size;

    my $share = $proc_mem->share($pid);
    my $vsize = $proc_mem->vsize($pid);
    my $rss   = $proc_mem->rss($pid);

    #  total http size update
    if ($total) {
        $total->{size}  += $size;
        $total->{real}  += $size-$share;
        $total->{max_shared} = $share if $total->{max_shared} < $share;
    }

    return {
        size       => $size,
        share      => $share,
        vsize      => $vsize,
        rss        => $rss,
        pid        => $pid,
        pid_link   => fixup_url($self->{url}, pid => $pid),
    };
}

sub score2record {
    my($self, $worker_score) = @_;

    # get absolute start and stop times in usecs since epoch
    my ($start_sec, $start_usec) = $worker_score->start_time;
    my $start = $start_sec * 1000000 + $start_usec;

    my($stop_sec, $stop_usec) = $worker_score->stop_time;
    my $stop = $stop_sec * 1000000 + $stop_usec;
    #warn "time: $start_sec, $start_usec, $stop_sec, $stop_usec\n";

    # measure running time till now if not idle
    my $elapsed = $stop < $start
        ? Time::HiRes::tv_interval([$start_sec, $start_usec],
                                   [Time::HiRes::gettimeofday()])
        : 0;

    my $vhost = HAS_VHOSTS ? $worker_score->vhost : '';

    return {
        mode       => $worker_score->status,
        elapsed    => $elapsed,
        lastreq    => $worker_score->req_time || 0,
        served     => $worker_score->my_access_count,
        client     => $worker_score->client,
        vhost      => $vhost,
        request    => $worker_score->request,
    };
}

sub tmpl_apache {

    return \ <<'EOT';
<hr>
<pre>
[%-
  USE HTML;

  # header
  space = "&nbsp;";
  "<b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
  width     = 0;
  label     = 1;
  sort_link = 3;
  FOR key = cols_sorted;
      col = cols.$key;
      times = col.$width - col.$label.length;
      spacing = times > 0 ? space.repeat(times) : "";
      "$spacing<a href=\"${col.$sort_link}\">${col.$label}</a>$space";
  END;
  "</b>\n";

  # records
  max_pid_len     = cols.pid.$width;
  max_client_len  = cols.client.$width;
  max_vhost_len   = cols.vhost.$width;
  max_request_len = cols.request.$width;

  # parent rec
  spacing_len = cols.mode.$width + cols.elapsed.$width + cols.lastreq.$width +
                cols.served.$width + max_client_len + max_vhost_len + 
                max_request_len + 11;

  USE format_parent =
      format("%s: %s %5s %5s %5s %5s %${spacing_len}s");

  BLOCK present_parent_record;
      times = max_pid_len - prec.pid.length;
      spacing = times > 0 ? space.repeat(times) : "";
      pid_link = "$spacing<a href=\"${prec.pid_link}\">${prec.pid}</a>";

      format_parent(prec.id, pid_link, prec.fsize, prec.fshare, prec.fvsize,
                    prec.frss, space);
  END;

  fvhost = has_vhosts_entries 
         ? " %${max_vhost_len}.${max_vhost_len}s" 
         : "%0.0s";
  USE format_child =
      format("%s: %s %5s %5s %5s %5s %1s %s %s %4s %${max_client_len}.${max_client_len}s${fvhost} %s%s");

  # if prec is passed, that means that the parent process is also a worker
  # so present the process data on the same line with the worker data
  BLOCK present_worker_record;
      IF prec;
          wrec.id       = prec.id;
          wrec.pid      = prec.pid;
          wrec.pid_link = prec.pid_link;
          wrec.fsize    = prec.fsize;
          wrec.fshare   = prec.fshare;
          wrec.fvsize   = prec.fvsize;
          wrec.frss     = prec.frss;
      END;

      # alert on workers that are still at work for a single request
      # for more than 15 secs
      elapsed_class = wrec.elapsed > 15 ? "alert" : "normal";
      wrec.felapsed = "<span class=\"$elapsed_class\">${wrec.felapsed}</span>";

      # alert on workers that worked for a single request for more
      # than 15 secs
      lastreq_class = wrec.lastreq > 15 ? "alert" : "normal";
      wrec.flastreq = "<span class=\"$lastreq_class\">${wrec.flastreq}</span>";

      # escape HTML in request URI to prevent cross-site scripting attack
      wrec.frequest = HTML.escape(wrec.request);

      # line fill spacing (needed for coloured areas)
      times = max_request_len - wrec.frequest.length;
      line_fill = times > 0 ? space.repeat(times) : "";

      # pid linked
      times = max_pid_len - wrec.pid.length;
      spacing = times > 0 ? space.repeat(times) : "";
      pid_link = "$spacing<a href=\"${wrec.pid_link}\">${wrec.pid}</a>";

      format_child(wrec.id, pid_link, wrec.fsize, wrec.fshare, wrec.fvsize,
                   wrec.frss, wrec.mode, wrec.felapsed, wrec.flastreq,
                   wrec.fserved, wrec.client, wrec.vhost, wrec.frequest, line_fill);
  END;


  IF threaded;
      FOR rec = records;
          item_class = loop.count % 2 ? "item_odd" : "item_even";
          "<span class=\"$item_class\">";
          IF rec.workers.size;
              PROCESS present_parent_record prec = rec;
              "\n";
              FOR wrec = rec.workers;
                  PROCESS present_worker_record prec = 0, wrec = wrec;
                  "\n";
              END;
          ELSE;
              PROCESS present_parent_record prec = rec;
          END;
          "</span>\n";
      END;
  ELSE;
      FOR rec = records;
          item_class = loop.count % 2 ? "item_odd" : "item_even";
          "<span class=\"$item_class\">";
          IF rec.workers.size;
              PROCESS present_worker_record prec = rec, wrec => rec.workers.0;
          ELSE;
              PROCESS present_parent_record prec = rec;
          END;
          "</span>\n";
      END;
  END;

  # total apache proc memory usage
  USE format_total =
      format("\n<b>Total:     %5dK (%s) size, %6dK (%s) approx real size (-shared)</b>\n");
      format_total(total.size, total.fsize, total.shared, total.fshared);

-%]
</pre>
EOT

}

### procs ###

sub data_procs {
    my $self = shift;

    unless ($Apache::VMonitor::PROC_REGEX) {
        warn "Don't know what processes to display..." .
            'int: set $Apache::VMonitor::PROC_REGEX' .
            'e.g. \$Apache::VMonitor::PROC_REGEX = join "\|", qw(httpd mysql);';
        return {};
    }

    my $gtop = $self->{gtop};

    unless ($gtop) {
        warn "GTop not installed, not displaying process data";
        return {};
    }


    my($proclist, $entries) = $gtop->proclist;

    my %procs = ();
    for my $pid ( @$entries ) {
        my $cmd = $gtop->proc_state($pid)->cmd;
        push @{ $procs{$cmd} }, $pid
            if $cmd =~ /$Apache::VMonitor::PROC_REGEX/o;
    }

    # finding out various max lenthgs for a proper column formatting
    # set the minimum width here
    my %max_len = (
        pid => 3,
        cmd => 3,
        tty => 3,
        uid => 3,
    );
    my @recs = ();

    my $cat_id = 0;
    for my $cat (sort keys %procs) {

        my $cnt = 0;
        $cat_id++;
        for my $pid ( @{ $procs{$cat} } ) {
            $cnt++;
            my $state = $gtop->proc_state($pid);
            my $uid   = $gtop->proc_uid($pid);
            my $mem   = $gtop->proc_mem($pid);
            my $tty   = $uid->tty;
            $tty = ' ' if $tty == -1;

            push @recs, {
                cat_id    => $cat_id,
                count     => $cnt,
                pid       => $pid,
                pid_link  => fixup_url($self->{url}, pid => $pid),
                uid       => scalar(getpwuid($state->uid)),
                fsize     => size_string($mem->size($pid)),
                fshare    => size_string($mem->share($pid)),
                fvsize    => size_string($mem->vsize($pid)),
                frss      => size_string($mem->rss($pid)),
                tty       => $tty,
                state     => $state->state,
                cmd       => $state->cmd,
            };

            my $len       = length $pid;
            $max_len{pid} = $len if $len > $max_len{pid};
            $len          = length $state->cmd;
            $max_len{cmd} = $len if $len > $max_len{cmd};
            $len          = length $uid->tty;
            $max_len{tty} = $len if $len > $max_len{tty};
            $len          = length scalar getpwuid $state->uid;
            $max_len{uid} = $len if $len > $max_len{uid};
        }
    }

    return {
        max_len => \%max_len,
        records => \@recs,
    };
}

sub tmpl_procs {

    return \ <<'EOT';
<hr>
<pre>
[%-

  USE format_procs =
      format("%4s %${max_len.pid}s %-${max_len.uid}s %5s %5s %5s %5s %${max_len.tty}s  %-2s  %-${max_len.cmd}s");
  "<b>";
  format_procs('##', "PID", "UID", "Size", "Share", "VSize", "Rss", "TTY", "St", "Command");
  "</b>\n";

  space = "&nbsp;";
  FOR rec = records;
      times = max_len.pid - rec.pid.length;
      spacing = times > 0 ? space.repeat(times) : "";
      pid_link = "$spacing<a href=\"${rec.pid_link}\">${rec.pid}</a>";

      item_class = rec.cat_id % 2 ? "item_odd" : "item_even";
      "<span class=\"$item_class\">";
      format_procs(rec.count, pid_link, rec.uid, rec.fsize, rec.fshare, rec.fvsize, rec.frss, rec.tty, rec.state, rec.cmd);
      "</span>\n";
  END;

-%]
</pre>
EOT

}

### apache_single ###

sub data_apache_single {
    my $self = shift;

    # XXX:
    # worker == 0, no worker data to display
    # consider showing workers under control of this pid

    if (MP2 && $Apache::Scoreboard::VERSION < 2.0) {
        die "Apache::Scoreboard 2.0 or higher is wanted, " .
            "this is only version $Apache::Scoreboard::VERSION";
    }

    my $pid = $self->{pid};
    my $data;

    ### proc command name/args
    my($proclist, $entries) = $gtop->proclist;
    my $cmd = '';
    for my $proc_pid ( @$entries ){
        $cmd = $gtop->proc_state($pid)->cmd, last if $pid == $proc_pid;
    }

    $data->{link_back} = fixup_url($self->{url}, pid => 0);
    $data->{pid} = $pid;
    $data->{cmd} = $cmd;

    ### memory usage
    my $mem = $self->pid2mem($pid);
    # the process might be dead already by the time you click on it.
    unless ($mem) {
        $data->{proc_is_dead} = 1;
        return $data;
    }
    $data->{mem} = {
            size   => $mem->{size},
            share  => $mem->{share},
            vsize  => $mem->{vsize},
            rss    => $mem->{rss},
            fsize  => size_string($mem->{size}),
            fshare => size_string($mem->{share}),
            fvsize => size_string($mem->{vsize}),
            frss   => size_string($mem->{rss}),
    };

    if (my $parent_score = $self->pid2parent_score($pid)) {

        my $worker_score;
        if ($self->{tid}) {
            warn "tid: $self->{tid}\n";
            my $image = $self->scoreboard_image();
            my $parent_idx = $image->parent_idx_by_pid($pid);
            $worker_score = $image->worker_score($parent_idx, $self->{tid});
        }
        else {
            $worker_score = MP2 ? $parent_score->worker_score : $parent_score;
        }

        my $rec = $self->score2record($worker_score);
        my $lastreq = $rec->{lastreq} ? $rec->{lastreq}/1000 : 0;
        $data->{rec} = {
            is_httpd_proc => 1,
            proc_type => ($pid == getppid ? "Parent" : "Child"),
            mode_long => $Apache::VMonitor::longflags{$rec->{mode}},
            elapsed   => $rec->{elapsed},
            felapsed  => format_time($rec->{elapsed}),
            lastreq   => $lastreq,
            flastreq  => format_time($lastreq),
            fserved   => format_counts($rec->{served}),
            client    => $rec->{client},
            vhost     => $rec->{vhost},
            request   => $rec->{request},
            access_count     => $worker_score->access_count,
            my_access_count  => $worker_score->my_access_count,
            bytes_served     => $worker_score->bytes_served,
            fbytes_served    => size_string($worker_score->bytes_served),
            my_bytes_served  => $worker_score->my_bytes_served,
            fmy_bytes_served => size_string($worker_score->my_bytes_served),
        };

        my @cpu_cols  = qw(total utime stime cutime cstime);
        my @cpu_times = $worker_score->times();
        my $cpu_total = eval join "+", @cpu_times;
        for ($cpu_total, @cpu_times) {
            my $key = "cpu_" . shift @cpu_cols;
            $data->{rec}->{$key} = $_/100;
        }
    }

    ### generic process info
    my $proc_info;
    # UID and STATE
    my $state = $gtop->proc_state($pid);
    $proc_info->{uid} = scalar getpwuid $state->uid;
    $proc_info->{gid} = scalar getgrgid $state->gid;
    $proc_info->{state} = $state->state;
    # TTY
    my $proc_uid  = $gtop->proc_uid($pid);
    my $tty = $proc_uid->tty;
    $tty = 'None' if $tty == -1;
    $proc_info->{tty} = $tty;
    # ARGV
    $proc_info->{argv} = join " ", @{($gtop->proc_args($pid))[1]};
    $data->{proc} = $proc_info;

    ### memory segments usage
    my $proc_segment = $gtop->proc_segment($pid);
    no strict 'refs';
    for (qw(text_rss shlib_rss data_rss stack_rss)) {
        my $size = $proc_segment->$_($pid);
        $data->{mem_segm}->{$_} = $size;
        $data->{mem_segm}->{"f$_"} = size_string($size);
    }

    ### memory maps
    my($procmap, $maps) = $gtop->proc_map($pid);
    my $number = $procmap->number;
    my %libpaths = ();

    my @maps = ();
    for (my $i = 0; $i < $number; $i++) {
        my $filename = $maps->filename($i) || "-";
        $libpaths{$filename}++;
        my $device = $maps->device($i);
        push @maps, {
                start        => $maps->start($i),
                end          => $maps->end($i),
                offset       => $maps->offset($i),
                device_major => (($device >> 8) & 255),
                device_minor => ($device & 255),
                inode        => $maps->inode($i),
                perm         => $maps->perm_string($i),
                filename     => $filename,
            };

    }

    $data->{mem_maps} = {
        records  => \@maps,
        ptr_size => (length(pack("p", 0)) == 8 ? 16 : 8),
    };

    ### loaded shared libs sizes
    my %libsizes = map { $_  => -s $_ } 
        grep { -e $_} grep !/^-$/, keys %libpaths;

    my @lib_sizes = ();
    my $total = 0;
    for (sort { $libsizes{$b} <=> $libsizes{$a} } keys %libsizes) {
        $total +=  $libsizes{$_};
        push @lib_sizes, {
            size     => $libsizes{$_},
            fsize    => size_string($libsizes{$_}),
            filename => $_,
        };
    }

    $data->{libs} = {
        records  => \@lib_sizes,
        total    => $total,
        ftotal   => size_string($total),
    };

    return $data;
}

# given the pid return the corresponding parent score object or undef
# if it's not an httpd proc.
sub pid2parent_score {
    my($self, $pid) = @_;

    my $image = $self->scoreboard_image();
    if (MP2) {
        my $parent_idx = $image->parent_idx_by_pid($pid);
        return $parent_idx == -1 ? undef : $image->parent_score($parent_idx);
    }
    else {
        # XXX: mp1 untested
        my $i;
        my $is_httpd_child = 0;
        for ($i = 0; $i < $Apache::Constants::HARD_SERVER_LIMIT; $i++) {
            $is_httpd_child = 1, last if $pid == $image->parent($i)->pid;
        }
        $i = -1 if $pid == getppid();
        if ($is_httpd_child || $i == -1) {
            return $image->servers($i);
        }
    }
}


sub tmpl_apache_single {
#return \'';
    return \ <<'EOT';
<hr>
[%-

   "[ <a href=\"$link_back\">Back to multiproc mode</a> ]";
   IF proc_is_dead;
       "Sorry, the process $pid ($cmd) doesn't exist anymore!";
   ELSE;
       "<h3 align='middle'>Extensive Status for PID $pid ($cmd)&nbsp; &nbsp;</h3>";
       PROCESS single_process;
   END;
-%]

[% BLOCK single_process %]
<pre>
[%-

  PROCESS single_httpd_process IF rec.is_httpd_proc;

  "<hr><b>General process info:</b>\n";
  USE format_proc_item = format("  <b>%-25s</b> : %s\n");
  format_proc_item("UID",   proc.uid);
  format_proc_item("GID",   proc.gid);
  format_proc_item("State", proc.state);
  format_proc_item("TTY",   proc.tty);
  format_proc_item("Command line arguments", proc.argv);

  # memory usage
  "\n<hr><b>Memory Usage</b> (in bytes):\n\n";
  USE format_mem_item = format("  %-10.10s : %10d (%s)\n");
  format_mem_item("Size",  mem.size,  mem.fsize);
  format_mem_item("Share", mem.share, mem.fshare);
  format_mem_item("VSize", mem.vsize, mem.fvsize);
  format_mem_item("RSS",   mem.rss,   mem.frss);

  # memory segments usage
  "\n<HR><B>Memory Segments Usage</B> (in bytes):\n\n";
  USE format_mem_segment_item = format("  %-10.10s : %10d (%s)\n");
  format_mem_segment_item("Text",  mem_segm.text_rss,  mem_segm.ftext_rss);
  format_mem_segment_item("Shlib", mem_segm.shlib_rss, mem_segm.fshlib_rss);
  format_mem_segment_item("Data",  mem_segm.data_rss,  mem_segm.fdata_rss);
  format_mem_segment_item("Stack", mem_segm.stack_rss, mem_segm.fstack_rss);

  # memory maps
  "<hr><b>Memory Maps:</b>\n\n";
   ptr_size = mem_maps.ptr_size;
   USE format_map_header = format("  <b>%${ptr_size}s-%-${ptr_size}s %${ptr_size}s  %3s:%3s %7s - %4s  - %s</b>\n");
   format_map_header("start", "end", "offset", "maj", "min", "inode", "perm", "filename");
   USE format_map_item = 
       format("  %0${ptr_size}lx-%0${ptr_size}lx %0${ptr_size}lx - %02x:%02x %08lu - %4s - %s\n");
   FOR rec = mem_maps.records.sort('filename');
       format_map_item(rec.start, rec.end, rec.offset, rec.device_major, rec.device_minor, rec.inode, rec.perm, rec.filename);
   END;

  # loaded shared libs sizes
  "<hr><b>Loaded Libs Sizes:</b> (in bytes)\n\n";
   USE format_shared_lib = format("%10d (%s): %s\n");
   FOR rec = libs.records.sort('filename');
       format_shared_lib(rec.size, rec.fsize, rec.filename);
   END;
   USE format_shared_lib_total = format("\n<b>%10d (%s): %s</b>\n");
   format_shared_lib_total(libs.total, libs.ftotal, "Total");

-%]
</pre>
[% END %]

[% BLOCK single_httpd_process %]
[%-
  USE HTML;

  "<hr><b>httpd-specific Info:</b>\n\n";

  USE format_item = format("  <b>%-25s</b> : %s\n");
  format_item("Process type", rec.proc_type);

  format_item("Status", rec.mode_long);

  IF rec.elapsed;
      elapsed_class = rec.elapsed > 15 ? "alert" : "normal";
      rec.felapsed = "<span class=\"$elapsed_class\"><b>${rec.felapsed}</b></span>";
      format_item("Cur. req. is running for", rec.felapsed);
  ELSE;
      lastreq_class = rec.lastreq > 15 ? "alert" : "normal";
      rec.flastreq = "<span class=\"$lastreq_class\">${rec.flastreq}</span>";
      format_item("Last request processed in", rec.flastreq);
  END;

  format_item("", "");

  USE format_slot_header = format("<b>%16s</b>   <b>%16s</b>");
  slot_header = format_slot_header("This slot", "This child");
  format_item("", slot_header);

  USE format_slot_entry = format("%16s   %16s");
  slot_entry = format_slot_entry(rec.access_count, rec.my_access_count);
  format_item("Requests Served", slot_entry);

  USE format_slot_entry = format("(%8s) %5s   (%8s) %5s");
  slot_entry = format_slot_entry(rec.bytes_served,    rec.fbytes_served, 
                                 rec.my_bytes_served, rec.fmy_bytes_served);
  format_item("Bytes Transferred", slot_entry);

  format_item("", "");

  format_item("Client IP or DNS", rec.client);

  format_item("Virtual Host", rec.vhost) IF rec.vhost.length;

  # escape HTML in request URI to prevent cross-site scripting attack
  rec.frequest = HTML.escape(rec.request);
  format_item("Request (first 64 chars)", rec.frequest);

  format_item("", "");

  USE format_cpu_header = format("%8s  %8s  %8s  %8s  %8s");
  cpu_header = format_cpu_header("total", "utime", "stime", "cutime", "cstime");
  format_item("CPU times (secs)", cpu_header);
  USE format_cpu_data = format("%8d  %8d  %8d  %8d  %8d");
  cpu_data = format_cpu_data(rec.cpu_total, rec.cpu_utime, rec.cpu_stime, rec.cpu_cutime, rec.cpu_cstime);
  format_item("", cpu_data);

-%]
[% END %]
EOT

}



### fs_usage ###

sub data_fs_usage {
    my $self = shift;

    my($mountlist, $entries) = $gtop->mountlist(1);
    my $fs_number = $mountlist->number;

    # for formatting purpose find out the max length of the filesystems
    my $max_fs_name_len = 0;
    my %fs = ();
    for (my $i = 0; $i < $fs_number; $i++) {
        my $path = $entries->mountdir($i);
        $fs{$path} = $i;
        my $len = length $path;
        $max_fs_name_len = $len if $len > $max_fs_name_len;
    }

    $max_fs_name_len = 12 if $max_fs_name_len < 12;

    # the filesystems
    my @items = ();
    for my $path (sort keys %fs){
        my $i = $fs{$path};
        my $fsusage = $gtop->fsusage($entries->mountdir($i));

        my $total_blocks      = $fsusage->blocks / 2;
        my $su_avail_blocks   = $fsusage->bfree  / 2 ;
        my $user_avail_blocks = $fsusage->bavail / 2;
        my $used_blocks       = $total_blocks - $su_avail_blocks;
        my $usage_blocks      = $total_blocks 
            ? ($total_blocks - $user_avail_blocks)* 100 / $total_blocks
            : 0;
        my $total_files       = $fsusage->files;
        my $free_files        = $fsusage->ffree;
        my $usage_files       = $total_files 
            ? ($total_files - $free_files) * 100 / $total_files
            : 0;

        push @items, {
            path => $path,

            blocks => {
                total      => $total_blocks,
                used       => $used_blocks,
                user_avail => $user_avail_blocks,
                usage      => $usage_blocks,
            },

            files => {
                total => $total_files,
                free  => $free_files,
                usage => $usage_files,
            },
        };
    }

    return {
        max_fs_name_len => $max_fs_name_len,
        items           => \@items,
    };
}

sub tmpl_fs_usage {

    return \ <<'EOT';
<hr>
<pre>
[%-
  fs_name_len = max_fs_name_len - 4;
  USE format_header = format("%-${fs_name_len}s %14s %9s %9s %3s %12s %7s %5s\n");

  format_header("FS", "1k Blks: Total", "SU Avail", "User Avail", "Usage",
    "   Files: Total", "Avail", "Usage");


  format_blocks = "%9d %9d %10d %4d%% ";
  format_files  = "       %7d %7d %4d%%";
  format_fs     = "%-${max_fs_name_len}s ";

  FOR item = items;
      # visual alert on filesystems of 90% usage!
      IF item.blocks.usage >= 90 AND item.files.usage >= 90;
          USE format_item = format("<b><font color=\"#ff0000\">$format_fs $format_blocks $format_files</font></b>\n");
      ELSIF item.blocks.usage >= 90;
          USE format_item = format("<b><font color=\"#ff0000\">$format_fs $format_blocks</font></b> $format_files\n");
      ELSIF item.files.usage >= 90;
          USE format_item = format("<b><font color=\"#ff0000\">$format_fs</font></b> $format_blocks <b><font color=\"#ff0000\">$format_files</font></b>\n");
      ELSE;
          USE format_item = format("$format_fs $format_blocks $format_files\n");
      END;

      format_item(item.path,
                  item.blocks.total,
                  item.blocks.used,
                  item.blocks.user_avail,
                  item.blocks.usage,
                  item.files.total,
                  item.files.free,
                  item.files.usage
      );
  END;
-%]
</pre>
EOT
}





### mount ###

sub data_mount {
    my $self = shift;
    #return {};

    my @records = qw(devname mountdir type);
    my($mountlist, $entries) = $gtop->mountlist(1);

    my $fs_number = $mountlist->number;
    my %len = map { $_ => 0 } @records;
    my @items = ();
    for (my $i=0; $i < $fs_number; $i++) {
        push @items, {
            map {
                my $val = $entries->$_($i);
                $len{$_} = length $val if length $val > $len{$_};
                $_ => $val;
            } @records
        };
    }

    # sort by device name
    @items = sort { $a->{devname} cmp $b->{devname} } @items;
    return {
        items => \@items,
        len   => \%len,
    };
}

sub tmpl_mount {

    return \ <<'EOT';
<hr>
<pre>
[%-
  header = "%-${len.devname}s   %-${len.mountdir}s   %-${len.type}s";
  USE format_header = format("<b>$header</b>\n");

  format_header("DEVICE", "MOUNTED ON", "FS TYPE");

  USE format_item =
      format("$header\n");
  FOREACH item = items;
      format_item(item.devname,
                  item.mountdir,
                  item.type
      );
  END;
-%]
</pre>
EOT

}

### verbose ###

%Apache::VMonitor::abbreviations = 
  (

   verbose =>
   qq{
     <B>Verbose option</B>

     Enables Verbose mode - displays an explanation and abbreviation
     table for each enabled section.

   },

   refresh  =>
   qq{
     <B>Refresh Section</B>

       You can tune the automatic refresh rate by clicking on the
       number of desired rate (in seconds). 0 (zero) means "no
       automatic refresh".
   },


   system =>
   qq{
     <B>Top section</B>

       Represents the emulation of top utility, while individually
       reporting only on httpd processes, and provides information
       specific to these processes.

       <B>1st</B>: current date/time, uptime, load average: last 1, 5 and 15
       minutes, total number of processes and how many are in the
       running state.

       <B>2nd</B>: CPU utilization in percents: by processes in user, nice,
       sys and idle state

       <B>3rd</B>: RAM utilization: total available, total used, free, shared
       and buffered

       <B>4th</B>: SWAP utilization: total available, total used, free, how
       many paged in and out
     },

   apache =>
   qq{
       <B>Apache/mod_perl processes:</B>

       The first row reports the status of parent process (mnemonic 'par').

       Columns:
         <pre>
         <span class="item_even">Column  Purpose</span>
	 <b>PID</b>     Id (or Thread index for threaded httpd)
	 <b>Size</b>    Total Size
	 <b>Share</b>   Shared Size
	 <b>VSize</b>   Virtual Size
	 <b>RSS</b>     Resident Size
	 <b>M</b>       Apache mode (See below a full table of abbreviations)
	 <b>Elapsed</b> Time since request was started if still in process (0 otherwise)
	 <b>LastReq</b> Time last request was served if idle now (0 otherwise)
	 <b>Srvd</b>    How many requests were processed by this child
	 <b>Client</b>  Client IP
	 <b>VHost</b>   Virtual Hosts (httpd 2.0, if any configured)
	 <b>Request</b> Request (first 64 chars)
         </pre>

        <p> You can sort the report by clicking on any column (only
        the parent process is outstanding and is not sorted)</p>

	 Last row reports:

	 <B>Total</B> = a total size of the httpd processes (by
	 summing the SIZE value of each process)

         <B>Approximate real size (-shared)</B> = 

1. For each process sum up the difference between shared and system
memory.

2. Now if we add the share size of the process with maximum
shared memory, we will get all the memory that actually is being
used by all httpd processes but the parent process.

Please note that this might be incorrect for your system, so you use
this number on your own risk. I have verified this number, by writing
it down and then killing all the servers. The system memory went down
by approximately this number. Again, use this number wisely!

The <B>modes</B> a process can be in:

<code><b>_</b></code> = Waiting for Connection<BR>
<code><b>S</b></code> = Starting up<BR>
<code><b>R</b></code> = Reading Request<BR>
<code><b>W</b></code> = Sending Reply<BR>
<code><b>K</b></code> = Keepalive (read)<BR>
<code><b>D</b></code> = DNS Lookup<BR>
<code><b>C</b></code> = Closing connection<BR>
<code><b>L</b></code> = Logging<BR>
<code><b>G</b></code> = Gracefully finishing<BR>
<code><b>I</b></code> = Idle cleanup of worker<BR>
<code><b>.</b></code> = Open slot with no current process<BR>

   },

   procs    =>
   qq{
     <B>  Processes matched by <CODE>\$Apache::VMonitor::PROC_REGEX</CODE> (PROCS)</B>

Setting:
<PRE>\$Apache::VMonitor::PROC_REGEX = join "\|", qw(httpd mysql squid);</PRE> 

will display the processes that match /httpd|mysql|squid/ regex in a
top(1) fashion in groups of processes. After each group the report of
total size and approximate real size is reported (approximate == size
calculated with shared memory reducing)

At the end there is a report of total size and approximate real size.

   },

   mount    =>
   qq{
<B>Mount section</B>

Reports about all mounted filesystems

<B>DEVICE</B>  = The name of the device<BR>
<B>MOUNTED ON</B>  = Mount point of the mounted filesystem<BR>
<B>FS TYPE</B> = The type of the mounted filesystem<BR>

   },

   fs_usage =>
   qq{
<B>File System usage</B>

Reports the utilization of all mounted filesystems:

<B>FS</B>  = the mount point of filesystem<BR>

<B>Blocks (1k)</B> = Space usage in blocks of 1k bytes<BR>

<B>Total</B>  = Total existing<BR>
<B>SU Avail</B> = Available to superuser (root) (tells how much space let for real)<BR>
<B>User Avail</B> = Available to user (non-root) (user cannot use last 5% of each filesystem)

<B>Usage</B> = utilization in percents (from user perspective, when it reaches
100%, there are still 5% but only for root processes)

<B>Files</B>: = File nodes usage<BR>
<B>Total</B>   = Total nodes possible <BR>
<B>Avail</B> = Free nodes<BR>
<B>Usage</B> = utilization in percents<BR>

   },

);

sub data_verbose {
    my $self = shift;

    return {
        abbr => \%Apache::VMonitor::abbreviations,
        cfg  => \%cfg,
    };

}

sub tmpl_verbose {

    return \ <<'EOT';
[%-

  FOR item = cfg.keys.sort;
      NEXT UNLESS abbr.$item;
      NEXT UNLESS cfg.$item OR $item == "refresh";
      note = abbr.$item;
      note = note.replace('^',"<p>");
      note = note.replace("\n\n","</p>\n");
      note = note.replace('$',"<hr>");
      note;
  END;

-%]
EOT

}


### helpers ###

# Takes seconds as int or float as an argument 
#
# Returns string of time in days (12d) or
# hours/minutes (11:13) if less then one day, 
# and secs.millisec (12.234s) if less than a minute
#
# The returned sting is always of 6 digits length (taken that
# length(int days)<4) so you can ensure the column with 
# printf "%7s", format_time($secs)
###############
sub format_time {
  my $secs = shift || 0;
  return sprintf "%6.3fs", $secs if $secs < 60;
  my $hours = $secs / 3600;
  return sprintf "%6.2fd", $hours / 24 if $hours > 24;
  return sprintf " %02d:%2.2dm", int $hours,
      int $secs%3600 ?  int (($secs%3600)/60) : 0;
}


# XXX: a faster C equivalent?
#
sub size_string {
    my($size) = @_;

    if (!$size) {
        $size = "   0K";
    }
    elsif ($size == -1) {
        $size = "    -";
    }
    elsif ($size < 1024) {
        $size = "   1K";
    }
    elsif ($size < 1048576) {
        $size = sprintf "%4dK", ($size + 512) / 1024;
    }
    elsif ($size < 103809024) {
        $size = sprintf "%4.1fM", $size / 1048576.0;
    }
    else {
        $size = sprintf "%4dM", ($size + 524288) / 1048576;
    }

    return $size;
}

# XXX: a faster C equivalent?
#
# any number that enters we return its compacted version of max 4
# chars in length (5, 123, 1.2M, 12M, 157G)
# note that here 1K is 1000 and not 1024!!!
############
sub format_counts {
  local $_ = shift || 0;

  my $digits = tr/0-9//;
  return $_
      if $digits < 4;
  return sprintf "%.@{[$digits%3 == 1 ? 1 : 0]}fK", $_/1000
      if $digits < 7;
  return sprintf "%.@{[$digits%3 == 1 ? 1 : 0]}fM", $_/1000000
      if $digits < 10;
  return sprintf "%.@{[$digits%3 == 1 ? 1 : 0]}fG", $_/1000000000
      if $digits < 13;
  return sprintf "%.@{[$digits%3 == 1 ? 1 : 0]}fT", $_/1000000000000
      if $digits < 16;

} # end of sub format_counts

# XXX: could make it a method
#
# my $newurl = fixup_url($url, $key => $val)
# my $newurl = fixup_url($url, $key => $val, $key2 => $val2)
# update key/val of the query and return
############
sub fixup_url {
    my($url, %pairs) = @_;

    while (my($k, $v) = each %pairs) {
        $url =~ s/$k=([^&]+)?/$k=$v/;
    }

    return $url;
}



1;
__END__


=pod

=head1 NAME

Apache::VMonitor - Visual System and Apache Server Monitor

=head1 SYNOPSIS

  # mod_status should be compiled in (it is by default)
  ExtendedStatus On

  # Configuration in httpd.conf
  <Location /system/vmonitor>
    SetHandler perl-script
    PerlHandler Apache::VMonitor
  </Location>

  # startup file or <Perl> section:
  use Apache::VMonitor();
  $Apache::VMonitor::Config{refresh}  = 0;
  $Apache::VMonitor::Config{verbose}  = 0;
  $Apache::VMonitor::Config{system}   = 1;
  $Apache::VMonitor::Config{apache}   = 1;
  $Apache::VMonitor::Config{procs}    = 1;
  $Apache::VMonitor::Config{mount}    = 1;
  $Apache::VMonitor::Config{fs_usage} = 1;
  $Apache::VMonitor::Config{apache_sort_by}  = 'size';
  
  $Apache::VMonitor::PROC_REGEX = join "\|", qw(httpd mysql squid);

=head1 DESCRIPTION

This module emulates the reporting functionalities of top(1), extended
for mod_perl processes, mount(1), and df(1) utilities. It has a visual
alerting capabilities and configurable automatic refresh mode. All the
sections can be shown/hidden dynamically through the web interface.

The are two main modes: 

=over 

=item * Multi processes mode

All system processes and information are shown. See the detailed
description of the sub-modes below.

=item * Single process mode


If you need to get an indepth information about a single process, you
just need to click on its PID.

If the chosen process is a mod_perl process, the following info is
displayed:

=over

=item *

Process type (child or parent), status of the process (I<Starting>,
I<Reading>, I<Sending>, I<Waiting>, etc.), how long the current
request is processed or the last one was processed if the process is
inactive at the moment of the report take.

=item *

How many bytes transferred so far. How many requests served per child
and per slot.

=item *

CPU times used by process: C<total>, C<utime>, C<stime>, C<cutime>,
C<cstime>.

=back

For all (mod_perl and non-mod_perl) processes the following
information is reported:

=over

=item *

General process info: UID, GID, State, TTY, Command line arguments

=item *

Memory Usage: Size, Share, VSize, RSS

=item *

Memory Segments Usage: text, shared lib, date and stack.

=item *

Memory Maps: start-end, offset, device_major:device_minor, inode,
perm, library path.

=item *

Loaded libraries sizes.

=back

Just like the multi-process mode, this mode allows you to
automatically refresh the page on the desired intervals.

=back

Other available modes within 'Multi processes mode'.

=over

=item refresh mode

From within a displayed monitor (by clicking on a desired refresh
value) or by setting of B<$Apache::VMonitor::Config{refresh}> to a number of
seconds between refreshes you can control the refresh rate. e.g:

  $Apache::VMonitor::Config{refresh} = 60;

will cause the report to be refreshed every single minute.

Note that 0 (zero) turns automatic refreshing off.

=item top(1) emulation (system)

Just like top(1) it shows current date/time, machine uptime, average
load, all the system CPU and memory usage: CPU load, Real memory and
swap partition usage.

The top(1) section includes a swap space usage visual alert
capability. The color of the swap report will be changed:

         swap usage               report color
   ---------------------------------------------------------
   5Mb < swap < 10 MB             light red
   20% < swap (swapping is bad!)  red
   70% < swap (almost all used!)  red 


The module doesn't alert when swap is being used just a little (<5Mb),
since it happens most of the time, even when there is plenty of free
RAM.

If you don't want the system section to be displayed set:

  $Apache::VMonitor::Config{system} = 0;

The default is to display this section.

=item top(1) emulation (Apache/mod_perl processes)

Then just like in real top(1) there is a report of the processes, but
it shows all the relevant information about mod_perl processes only!

The report includes the status of the process (I<Starting>,
I<Reading>, I<Sending>, I<Waiting>, etc.), process' ID, time since
current request was started, last request processing time, size,
shared, virtual and resident size.  It shows the last client's IP and
Request URI (only 64 chars, as this is the maximum length stored by
underlying Apache core library).

You can sort the report by any column, see the
L<CONFIGURATION|/CONFIGURATION> section for details.

The section is concluded with a report about the total memory being
used by all mod_perl processes as reported by kernel, plus extra
number, which results from an attempt to approximately calculate the
real memory usage when memory sharing is taking place. The calculation
is performed by using the following logic:

=over

=item 1

For each process sum up the difference between shared and total
memory.

=item 2

Now if we add the share size of the process with maximum shared
memory, we will get all the memory that is actually used by all
mod_perl processes, but the parent process.

=back

Please note that this might be incorrect for your system, so you
should use this number on your own risk. We have verified this number
on the Linux OS, by taken the number reported by C<Apache::VMonitor>,
then stopping mod_perl and looking at the system memory usage. The
system memory went down approximately by the number reported by the
tool. Again, use this number wisely!

If you don't want the mod_perl processes section to be displayed set:

  $Apache::VMonitor::Config{apache} = 0;

The default is to display this section.

=item top(1) emulation (any processes)


This section, just like the mod_perl processes section, displays the
information in a top(1) fashion. To enable this section you have to
set:

  $Apache::VMonitor::Config{procs} = 1;

The default is not to display this section.

Now you need to specify which processes are to be monitored. The
regular expression that will match the desired processes is required
for this section to work. For example if you want to see all the
processes whose name include any of these strings: I<http>, I<mysql>
and I<squid>, the following regular expression is to be used:

  $Apache::VMonitor::PROC_REGEX = join "\|", qw(httpd mysql squid);

=item mount(1) emulation

This section reports about mounted filesystems, the same way as if you
have called mount(1) with no parameters.

If you want the mount(1) section to be displayed set:

  $Apache::VMonitor::Config{mount} = 1;

The default is NOT to display this section.

=item df(1) emulation 

This section completely reproduces the df(1) utility. For each mounted
filesystem it reports the number of total and available blocks (for
both superuser and user), and usage in percents.

In addition it reports about available and used file inodes in numbers
and percents.

This section has a capability of visual alert which is being triggered
when either some filesystem becomes more than 90% full or there are
less than 10% of free file inodes left. When this event happens the
filesystem related report row will be displayed in the bold font and
in the red color. 

If you don't want the df(1) section to be displayed set:

  $Apache::VMonitor::Config{fs_usage} = 0;

The default is to display this section.

=item abbreviations and hints

The monitor uses many abbreviations, which might be knew for you. If
you enable the VERBOSE mode with:

  $Apache::VMonitor::Config{verbose} = 1;

this section will reveal all the full names of the abbreviations at
the bottom of the report.

The default is NOT to display this section.

=back

=head1 CONFIGURATION


To enable this module you should modify a configuration in
B<httpd.conf>, if you add the following configuration:

  <Location /system/vmonitor>
    SetHandler perl-script
    PerlHandler Apache::VMonitor
  </Location>

The monitor will be displayed when you request
http://localhost/system/vmonitor or alike.

You probably want to protect this location, from unwanted visitors. If
you are accessing this location from the same IP address, you can use
a simple host based authentication:

  <Location /system/vmonitor>
    SetHandler perl-script
    PerlHandler Apache::VMonitor
    order deny, allow
    deny  from all
    allow from 132.123.123.3
  </Location>

Alternatively you may use the Basic or other authentication schemes
provided by Apache and various extensions.

You can control the behavior of this module by configuring the
following variables in the startup file or inside the
C<E<lt>PerlE<gt>> section. 

Module loading:

  use Apache::VMonitor();

Monitor reporting behavior:

  $Apache::VMonitor::Config{refresh}  = 0;
  $Apache::VMonitor::Config{verbose}  = 0;

Control over what sections to display:

  $Apache::VMonitor::Config{system}   = 1;
  $Apache::VMonitor::Config{apache}   = 1;
  $Apache::VMonitor::Config{procs}    = 1;
  $Apache::VMonitor::Config{mount}    = 1;
  $Apache::VMonitor::Config{fs_usage} = 1;

Control the sorting of the mod_perl processes report. You can sort
them by one of the following columns: I<"pid">, I<"mode">,
I<"elapsed">, I<"lastreq">, I<"served">, I<"size">, I<"share">,
I<"vsize">, I<"rss">, I<"client">, I<"request">. For example to sort
by the process size the following setting will do:

  $Apache::VMonitor::Config{apache_sort_by}  = 'size';

A regex to match processes for 'PROCS' section:

  $Apache::VMonitor::PROC_REGEX = join "\|", qw(httpd mysql squid);

Read the L<DESCRIPTION|/DESCRIPTION> section for a complete
explanation of each of these variables.

=head1 DYNAMIC RECONFIGURATION

C<Apache::VMonitor> allows you to dynamically turn on and off all the
sections and enter a verbose mode that explains each section and the
used abbreviations. These dynamic settings stored in the URI and not
on the server side.


=head1 PREREQUISITES

Perl 5.6 or higher is required. If you are stuck with Perl 5.005 use
the previous generation of this module. 0.8 is the latest version as
of this writing and it's available from:
http://www.cpan.org/authors/id/S/ST/STAS/Apache-VMonitor-0.8.tar.gz or
your favorite CPAN mirror.

You need to have B<Apache::Scoreboard> installed and configured in
I<httpd.conf>, which in turn requires mod_status to be installed. You
also have to enable the extended status for mod_status, for this
module to work properly. In I<httpd.conf> add:

  ExtendedStatus On

Notice that turning the C<ExtendedStatus> mode I<On> is not
recommended for high-performance production sites, as it adds an
overhead to the request response times.

You also need B<Time::HiRes> to be installed

If you want process status information, you need B<GTop> to be installed.

And of course you need a running mod_perl enabled apache server.

=head1 Subclassing

It should be trivial to subclass C<Apache::VMonitor>. Just override
I<tmpl_> and or I<data_> methods and off you go.

=head1 BUGS

Apache 2.0 doesn't have a complete scoreboard - access times are missing.

=head1 TODO

I want to include a report about open file handles per process to
track file handlers leaking. It's easy to do that by just reading them
from C</proc/$pid/fd> but you cannot do that unless you are
root. C<libgtop> doesn't have this capability - if you come up with
solution, please let me know. Thanks!

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<Apache::Scoreboard>, L<GTop>

=head1 AUTHORS

Stas Bekman <stas@stason.org>
Malcolm J Harwood <mjh-vmonitor@liminalflux.net>

=head1 COPYRIGHT

The Apache::VMonitor module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
