package BugCli;

our $VERSION = '0.2';
use base qw(Term::Shell);
use BugCli::Help;
use BugCli::Summaries;
use BugCli::Completions;
use BugCli::Config;
use strict;
use Getopt::Std;
use FileHandle;
use DBIx::SQLEngine;
use Data::Dumper;
use POSIX qw(strftime);
use Text::Table;
use Config::Tiny;
use Term::ANSIColor qw(:constants);

$Term::ANSIColor::AUTORESET = 1;

our ( $config, $dbh, %login_to_uid, %uid_to_login, $llogin, %lastbugs,
    $lastquery, $hostname );
our (%Query) = ( "AutoIncrement" => 'select LAST_INSERT_ID()', );

sub process_bind {
    my ( $self, $cmd ) = @_;
    $self->cmd( $config->{bind}->{$cmd} );
}

sub init_mysql {
    my ($self) = @_;
    $self->{API}{check_idle} =
      exists $config->{server}->{timeout} ? $config->{server}->{timeout} : 60;
    foreach my $cmd ( keys %{ $config->{command} } ) {
        my ($code) = ord eval "\"$config->{command}->{$cmd}\"";
        $self->term()
          ->add_defun( 'process_bind', sub { process_bind( $self, $cmd ) },
            $code );
    }
    $dbh = DBIx::SQLEngine->new(
        "DBI:mysql:$config->{server}->{table}:$config->{server}->{host}",
        $config->{server}->{user},
        $config->{server}->{password},
        {
            RaiseError         => 1,
            ShowErrorStatement => 1,
        }
    );
    my ($uth) = $dbh->fetch_select(
        table   => 'profiles',
        columns => [ 'userid', 'login_name' ]
    );

    foreach my $uid ( @{$uth} ) {
        $login_to_uid{ $$uid{login_name} } = $$uid{userid};
        $uid_to_login{ $$uid{userid} }     = $$uid{login_name};
    }
    $llogin = $config->{server}->{login};
}

sub idle {
    %lastbugs = query_to_bugs( $dbh->fetch_select( sql => $lastquery ) )
      if defined $lastquery;
}

sub run_history {
    my ($self) = @_;
    print join( "\n", $self->term()->GetHistory() ) . "\n";

}

sub add_bug {
    my ( $dbh, $assignee, $subject, $text, $version, $milestone, $severity ) =
      @_;
    my ($time) = strftime "%Y-%m-%d %H:%M:%S", localtime;
    my ($sth) = $dbh->do_insert(
        'table'   => 'bugs',
        'columns' => [
            qw(assigned_to bug_severity bug_status creation_ts short_desc product_id reporter version target_milestone component_id)
        ],
        'values' => [
            $login_to_uid{$assignee},         $severity,
            $time,                            $subject,
            $config->{product}->{product_id}, $login_to_uid{$llogin},
            $version,                         $milestone,
            $config->{product}->{component_id}
        ]
    );
    my ($bugid) = $dbh->fetch_one_value( sql => $Query{AutoIncrement} );
    update_bug( $dbh, $bugid, undef, undef, $text );
    return $bugid;
}

sub update_bug {
    my ( $dbh, $bug_id, $bug_resolution, $bug_status, $text ) = @_;
    if ( defined $bug_resolution ) {
        $dbh->do_update(
            'table'    => 'bugs',
            'values'   => { resolution => "'$bug_resolution'" },
            'criteria' => { bug_id => $bug_id }
        );
    }
    if ( defined $bug_status ) {
        $dbh->do_update(
            'table'    => 'bugs',
            'values'   => { bug_status => "'$bug_status'" },
            'criteria' => { bug_id => $bug_id }
        );
    }

    my ($time) = strftime "%Y-%m-%d %H:%M:%S", localtime;
    $dbh->do_insert(
        'table'   => 'longdescs',
        'columns' => [qw(bug_id who bug_when work_time thetext)],
        'values'  => [ $bug_id, $login_to_uid{$llogin}, "'$time'", 0.00, $text ]
    );
}

#only delete a certain description

sub bugs_to_table {
    my (%bugs) = @_;
    my (@b);
    foreach my $bid ( keys %bugs ) {
        push @b,
          [
            $bid,                      $bugs{$bid}->{bug_severity},
            $bugs{$bid}->{bug_status}, $bugs{$bid}->{short_desc},
            $bugs{$bid}->{version},    $bugs{$bid}->{resolution}
          ];
    }
    return @b;
}

sub query_to_bugs {
    my ($sth) = @_;
    my (%bugs);
    foreach my $a ( @{$sth} ) {
        $bugs{ $$a{bug_id} } = $a;
        $bugs{ $$a{bug_id} }{COMMENTS} = get_comments( $dbh, $$a{bug_id} );
    }

    return %bugs;

}

sub print_bug {
    my ( $id, $bug ) = @_;
    return <<EOT;
=====================
Bug #$id Information
Subject:    $$bug{short_desc}
Severity:   $$bug{bug_severity}
Status:     $$bug{bug_status}
Resolution: $$bug{resolution}
Comments: 
$$bug{COMMENTS}
=====================
EOT
}

sub get_comments {
    my ( $dbh, $bugid ) = @_;
    my ($text);
    my ($bth) = $dbh->fetch_select(
        table    => 'longdescs',
        criteria => { bug_id => $bugid },
        columns  => [qw(who bug_when thetext)]
    );

    foreach my $z ( @{$bth} ) {
        next if not defined $$z{thetext} or
	        $$z{thetext} =~ /^\n$/ or
		$$z{thetext} =~ /^\s*(:?done|fixed|\.)\s*$/i;
        $text .= "\n-------------------\n";
        $text .= "From: $uid_to_login{$$z{who}} When: $$z{bug_when}\n";
        $text .= $$z{thetext};
    }
    return $text;

}

sub prompt_str { "$config->{server}->{login}" . BLUE . "\@" . RESET . UNDERLINE . 
	         "$config->{server}->{host}> " }
	 
sub alias_exit { 'q', 'quit' }

sub prepare_query {
    my ( $fmt, $regexp ) = @_;
    $fmt =~ s/\%uid/$login_to_uid{$llogin}/g;
    $fmt =~ s/\%regexp/$regexp/g;
    return $fmt;
}

sub run_changelog {
    my ($self, $date, @param) = @_;
    my(@ta) = @ARGV;
    @ARGV = @param;
    my(%opts,$fh);
    getopts('fo:',\%opts);
    @ARGV = @ta;
    my($sql) = "SELECT * FROM bugs WHERE (lastdiffed > '" . range_to_date($date) . "' AND assigned_to = $login_to_uid{$llogin} AND  resolution = 'FIXED')";
    my(%bugz) = query_to_bugs( $dbh->fetch_select(sql=>$sql ) );
    $fh = new FileHandle; 	       
    if($opts{o}){
	    $fh->open("> $opts{o}");
    }else{
	    $fh->open(">&STDOUT");
    }
    foreach my $bugid (sort keys %bugz) {
	    print $fh "[BUG #$bugid] $bugz{$bugid}{short_desc}\n";
	    if($opts{f}){
		    print $fh "$bugz{$bugid}{COMMENTS}\n";
	    }
	    
    }
    print "Output written to $opts{o} \n" if $opts{o};
    $fh->close;
}

sub range_to_date {
	my($scale) = @_;
	# general format: "[d<day-of-mont/day-of-week>][w<week-of-year>][m<month>][y<year>]
	# default month,year - current
	# month-week mutualy excluded.
	# monthes - 0-11; weekdays - 0-6; monthdays 1-31
	# week #0 is week containgin 1 Jan. 
	# negative value - backward from this moment i.e. kw-1 - previous week
	# TODO ranges - like km2-4 for spring.
	if (my ($day1,$week1,$mon1,$year1) = $scale =~ /^(?:d(-?\d+))?(?:w(-?\d+))?(?:m(-?\d+))?(?:y(-?\d+))?$/) {
	    #	    Error "wrong kalendar range given: $scale", return undef unless
	    #		defined $day1 || ( defined $week1 && !defined $mon1);

  	    my(undef,undef,undef,$cur_day,$cur_mon,$cur_year,$cur_wday,$cur_yday) = localtime;
	    my($day,$mon,$dd,$dm,$week2) = (1,0,0,0);
	    my($year) = !defined $year1 ? $cur_year :
	            $year1 > 1000 ? $year1-1900 : 
	            $year1 > 0 ? $year1 :
		    $cur_year + $year1;

	    $mon1 = $cur_mon+$mon1 if defined $mon1 && $mon1=~/^-/;
	    
	    if (defined $week1) {
		my $f_wday = (localtime POSIX::mktime(0,0,0,0,0,$year,0,0,-1))[6];
		if ($week1 !~ /^-/) {
		    $week2 = $week1;
		    $week1 = $week1 * 7 - $f_wday;
		} else { 
                    $week1 = $cur_yday + 1 + $week1 * 7 - $cur_wday;
		    $week2 = int(($week1 + $f_wday) / 7);
		}
	    }

	    my $k;

	    if (defined $day1) {
		$dd = 1;
	        $day = $day1 > 0 ? $day1 : $cur_day + $day1;
		$k .= "d$day";
		if (defined $week1) {
                    $day += $week1;
		    $k .= "w$week2";
		} elsif (defined $mon1) {
                    $mon = $mon1;
		    $k .= "m$mon";
		} else {
                    $mon = $cur_mon;
		    $k .= "m$mon";
		}
	    } elsif (defined $week1) {
	        $k .= "w$week2";
		$dd = 7;
		$day = $week1;
	    } elsif (defined $mon1) {
		$dm = 1;
                $mon = $mon1;
	        $k .= "m$mon";
	    } else {
		$dm = 12;
	    }

	    $k .= "y$year";

	    return strftime("%Y-%m-%d %H:%M:%S", localtime (POSIX::mktime(0,0,0,$day,$mon,$year,0,0,-1)));
    }
}

# delete command declaration {{{
sub run_delete {
    my ( $self, $comm, @params ) = @_;
    if ( $comm =~ /^\d+$/ ) {
        print "BUG: ID#$comm TITLE:$lastbugs{$comm}->{short_desc}\n";
        my ($ans);
        if ( $params[0] ne '-f' ) {
            $ans =
              $self->prompt( "Are you sure that you want to delete this bug?",
                "Y" );
        }
        else { $ans = 'y' }
        if ( $ans =~ /^y/i ) {
            $dbh->query("DELETE FROM bugs WHERE bug_id=$comm");
            $dbh->query("DELETE FROM longdescs WHERE bug_id=$comm");
        }
        print "Bug deleted.\n";
    }

}

# }}}

# show command declarations {{{

sub run_show {
    my ( $self, $comm ) = @_;
    my (@bugids);
    if ( $comm =~ /^\d+$/ ) {    #ok. just show by bugid
        push @bugids, $comm;
    }
    elsif ( $comm =~ m#^/(.*)/$# ) {    #ok, got regexp. let's find em!
        my ($r) = $1;
        my (%a) = query_to_bugs(
            $dbh->fetch_select(
                sql => "SELECT bug_id FROM bugs where short_desc REGEXP '$1'"
            )
        );

        push @bugids, keys %a;
    }
    else {
        print "Whoopsie! Bad syntax. See 'help show' for explainations.\n";
        return;
    }
    foreach my $bugid (@bugids) {
        my (%b) = query_to_bugs(
            $dbh->fetch_select(
                table    => 'bugs',
                criteria => { 'bug_id' => $bugid }
            )
        );
        $self->page( print_bug( $bugid, $b{$bugid} ) );
        print "Press any key to continue...";
        getc;
    }

}

sub run_take {
    push @_, undef if scalar(@_) < 3;
    do_fix( @_, undef, undef, undef, 'take' );
}

sub run_comment {
    push @_, undef if scalar(@_) < 3;
    do_fix( @_, undef, undef, undef, 'comment' );
}

sub run_fix {
    push @_, undef if scalar(@_) < 3;
    do_fix( @_, undef, undef, undef, 'fix' );
}


sub do_fix {
    my ( $self, $bugid, $text, undef, undef, undef, $cmd ) = @_;
    if ( defined $bugid && $bugid =~ /^\d+/ ) {
        my (%b) = query_to_bugs(
            $dbh->fetch_select(
                table    => 'bugs',
                criteria => { 'bug_id' => $bugid }
            )
        );
        print "No such bug!\n", return if not keys %b;
        if ( not defined $text ) {
            print "Please enter a comment: (Ctrl-D to finish) \n";
            $text = join '', <STDIN>;
        }
        print "You should enter some comments!", return if $text eq '';
        if ( $cmd eq 'fix') {
            update_bug( $dbh, $bugid, 'FIXED', 'RESOLVED', $text );
        }
        elsif ( $cmd eq 'comment' ) {
            update_bug( $dbh, $bugid, undef, undef, $text );
        }
        elsif ( $cmd eq 'take' ) {
            update_bug( $dbh, $bugid, undef, 'ASSIGNED', $text );
        }
    }
    else {
        print "Incorrect syntax! Read 'help fix'. \n";
    }

}

# }}}

# bugs command declarations {{{
sub run_bugs {
    my ( $self, $query, $param ) = @_;
    my $tb =
      Text::Table->new(qw|ID SEVERITY STATUS SUBJECT VERSION RESOLUTION|);
    if ($query) {
        my ($q);
        if ( $query =~ m#^/(.*)/$# ) {    #ok user wants a regexp
            $q =
"SELECT * from $config->{server}->{table} where short_desc regexp '$1'";
        }
        if ( exists $config->{query}->{$query} ) {
            $q = prepare_query( $config->{query}->{$query}, $param );
        }
        if ($q) {
            %lastbugs = query_to_bugs( $dbh->fetch_select( sql => $q ) );
            $lastquery = $q;
            my (@b) = bugs_to_table(%lastbugs);
            $tb->load(@b);
        }
        else {
            print "Such query is not defined!\n";
        }
      
    print "\n$tb";
    }
    else {
	$self->config_show_query(1);
    }

}

1;

