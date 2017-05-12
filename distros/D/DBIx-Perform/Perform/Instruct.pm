# instructions
# These functions do the instructions part of a Perform script
# Instructions are grouped into blocks:
#   before, after, on beginning, on ending
# Each block may contain actions:
#   nextfield, abort, comments, let, if-then-else, call
#
# Brenton Chapin

use strict;

our $VERSION = '0.694';

our $GlobalUi = $DBIx::Perform::GlobalUi;
our $DB = $DBIx::Perform::DB;

# trigger on column, table.column, and maybe table of the given field object
sub trigger_ctrl_blk_fld
{
    my $when    = shift;    # one of "before" or "after"
    my $event   = shift;
    my $fo	= shift;
    my ( $field_tag, $table, $column_name) = $fo->get_names;

    my $app = $GlobalUi->{app_object};
if ($::TRACE) {
my $tbl = '';
$tbl = " $table" if $app->{fresh};
warn "TRACE: entering trigger_ctrl_blk_fld $when $table.$column_name$tbl\n";
}

    my @ofs = ($column_name, "$table.$column_name");
    push @ofs, $table if $app->{'fresh'};
    $app->{'fresh'} = 0;

    return trigger_ctrl_blk($when, $event, @ofs);
}
   
sub trigger_ctrl_blk
{
    my $when    = lc(shift);    # one of "before" or "after"
    my $event   = shift;
    my @ofs     = @_;

#warn "TRACE: entering trigger for '$when $event'\n"
#     . join (", ", @ofs) . "\n" if $::TRACE;

    my $app = $GlobalUi->{app_object};
    my $instrs   = $app->getField('instrs');
    my $controls = $instrs->{'CONTROLS'};

    #my @actions = map {$controls->{$_}{$event}{$when}} @cols;
    my @actions;

    foreach (@ofs) {
        if ($controls->{$_}) {           # if ctrl block exists
            if ($controls->{$_}{$event}) {    # if the col has an event defined
                my $act = $controls->{$_}{$event}{$when}; # get actions
                push @actions,$act if $act;   # if defined, add it to the array
            }
        }
    }

    return "\c0" unless @actions;

warn "$when $event of " . join(', ', @ofs) . "\n" if $::TRACE_DATA;

#warn "TRACE: leaving trigger\n" if $::TRACE;

    return act(@actions);
}


sub goto_nextfield {
    my $field_tag = shift;

    my $app = $GlobalUi->{app_object};
    my $form = $GlobalUi->get_current_form;
    my $old_tag = $GlobalUi->{'focus'};
    if ($old_tag ne $field_tag) {
        my $subform = $form->getSubform('DBForm');
        my $widget = $subform->getWidget($old_tag);
        $widget->{CONF}->{'EXIT'} = 1;
        my $scrns = get_screen_from_tag($field_tag);
        my $scrn = $$scrns[0];
        goto_screen("Run$scrn");
        $form = $app->getForm("Run$scrn");
        $subform = $form->getSubform('DBForm');
	$subform->setField('FOCUSED', $field_tag);
    }
    $GlobalUi->{'newfocus'} = $field_tag
        unless $GlobalUi->{'newfocus'};
}

# The actions are stored in an array.
#   Intent is to handle nested if-then-else actions
#   by calling this function recursively
sub act
{
    my $actions = shift;

    my $app = $GlobalUi->{app_object};

    foreach my $act (@$actions) {
	my ($ac, $field_tag, $perfexpr, $perfexpr2) = @$act;
if ($::TRACE) {
my $ft_print = $field_tag;
$ft_print = Data::Dumper->Dump([$field_tag], ['tag']) if ref $field_tag;
my $pe_print = $perfexpr;
$pe_print = Data::Dumper->Dump([$perfexpr], ['expr']) if ref $perfexpr;
warn "action :$ac:$ft_print:$pe_print:\n";
}
	if ($ac eq 'nextfield'){
            return "\c[" if (lc($field_tag) eq 'exitnow');
	    goto_nextfield($field_tag);
	}
	elsif ($ac eq 'abort') {
            return "\cC";
        }
        elsif ($ac eq 'comments') {
#ANSI Escape sequence to reverse text sometimes doesn't work
#            $perfexpr = "\e[7m". $perfexpr . "\e[0m"
#                if ($field_tag =~ /reverse/i);
            my $rr = $field_tag !~ /reverse/i;
            $GlobalUi->display_error ( $perfexpr, $rr );
            beep if ($field_tag =~ /bell/i);
        }
	elsif ($ac eq 'let') {
            my $val = do_the_math($perfexpr);
            my $fo = DBIx::Perform::get_field_object_from_tag($field_tag);
            $fo->set_value($val);
	    my ($rval, $rc) = $fo->format_value_for_display($val);
            $GlobalUi->set_screen_value($field_tag, $rval);
	    DBIx::Perform::trigger_lookup($field_tag);
	}
        elsif ($ac eq 'if') {
            my $val = do_the_math($field_tag);
            if ($val) {
                return act($perfexpr);
            } else {
                return act($perfexpr2);
            }
        }
        elsif ($ac eq 'call') {
            my $parmlist = do_the_math($perfexpr);
            my @parms = split /,/, $parmlist;
#            push @parms, "''" unless defined @parms;
	    warn "call to " . $field_tag . ", parameters :" 
                 .  $parmlist .":\n" if $::TRACE;
            call_extern_C_func($field_tag, 0, \@parms);
        }
    }
    return "\c0";
}

#takes a template of an expression (in $math) and fills in the
#"variables" (field-tags) given in @$fts with their current values.
#Also fills in the string literals and regex literals from @$strs.
#
#FIX  Need way to handle both strings and numbers.
#     This will probably break if the Perform script has
#     "if (a = b)" and a and b are fields that turn out to contain
#     strings rather than numbers.
sub do_the_math
{
    my $parms = shift;
    my ($math, $strs, $fts) = @$parms;
#warn "expr :$math:\n";
#warn "strings: " . join (' ', @$strs) . "\n";
#warn "fields: " . join (' ', @$fts) . "\n";
    my ($si, $vi) = (0, 0);
    my $result;
#    my $e = '$result = ';
    my @e;
    my $i;
    my $nest = 0;
    my $fflag = 0;
    my (@funcs, @fnest, @fparms);
    push @fnest, -1;

    my @m = split //, $math;
    for ($i=0; $i < length $math; $i++) {
        my $c = $m[$i];
        if ($c eq '"') {
            $e[$#fnest] .= @$strs[$si++];
        }
        elsif ($c eq 'v') {
#            my $v = get_value_from_tag(@$fts[$vi++]);
            my $v = $GlobalUi->get_screen_value(@$fts[$vi++]);
#warn "field :@$fts[$vi-1]:  =  :$v:\n";
            $v =~ s/'/\\'/g;
            $v = "'" . $v . "'" unless DBIx::Perform::DigestPer::is_number($v);
            $e[$#fnest] .= $v;
        }
        elsif ($c eq 'c') {
            push @funcs, @$fts[$vi++];
            $fflag = 1;
        }
        elsif ($c eq '(') {
            if ($fflag) {
                push @fnest, $nest;
            } else {
                $e[$#fnest] .= $c;
            }
            $fflag = 0;
            $nest++;
        }
        elsif ($c eq ')') {
            $nest--;
            if ($nest == $fnest[$#fnest]) {
                $e[$#fnest] = '$result = [' . $e[$#fnest] . ']';
                eval $e[$#fnest];
                pop @fnest;
                my $fname = pop @funcs;
                my $v = call_extern_C_func($fname, 1, $result);               
warn "return val from C function = :$v:\n" if $::TRACE;
                $v =~ s/'/\\'/g;
                $v = "'" . $v . "'"
                    unless DBIx::Perform::DigestPer::is_number($v);
                $e[$#fnest] .= $v;
            } else {
                $e[$#fnest] .= $c;
            }
        }
        else {
            $e[$#fnest] .= $c;
        }
    }
warn "evaluating :$e[0]:\n" if $::TRACE;
    $e[0] = "''" unless $e[0] =~ /\S/;
    $e[0] = '$result = ' . $e[0];
    eval $e[0];
    $result = '' unless defined $result;
warn "result = :$result:\n" if $::TRACE;
    return $result;
}


#removes all string literals to an array, and remove all comments.
#  leaves " in place of each string
sub pull_strings
{
    my $strung = shift;
    my @strs;
    my $unstrung = $strung;
    my $strb;

#remove \" by removing all \.
    $unstrung =~ s/\\./xx/g;

    my $e = length $strung;
# $i is index into the string, $q = 1 (q for "quote") if inside
# a string literal, and $r = 1 (r for "remark") if inside a comment
    my  ($i, $j, $q, $r) = (0,0,0,0);
    my @ca = split //, $unstrung;
    my @cb;
    my $c;
    for ($i = 0; $i < $e; $i++) {
        $c = $ca[$i];
        $r = 1 if ($c eq '{' && !$q);
        if ($c eq '"' && !$r) {
#entering or leaving a string literal (and not inside a comment)
            $q ^= 1;
            if ($q) {
                $strb = $i+1;
                $cb[$j++] = '"';
            } else {
                $ca[$i] = 'x';
                push @strs, substr($strung, $strb, $i-$strb);
            }
        }
        else {
            if ($q || $r) {
                $ca[$i] = 'x';
            } else {
                $cb[$j++] = $c;
            }
        }
        $r = 0 if ($c eq '}' && $r);
    }
    if ($q) {
        warn "ERROR:  no ending \" for string literal\n";
    }
    $unstrung = join '', @ca;
    return ($unstrung, @strs);
}


our $extern_started = 0;
our ($sock, $asock);
use IO::Socket::UNIX;
sub call_extern_C_func
{
    my $funcname = shift;
    my $is_retval = shift;
    my $parms    = shift;
    my $extern_exe;

    if (! $extern_started) {
warn "call_extern_C_func:  parms = :" . join ("\n", @$parms) .":\n" if $::TRACE;

        if (!defined $DBIx::Perform::extern_name) {
            warn "Error: This Perform script uses external C functions\n" .
                 "and no C program was specified.\n";
            return 0;
        }
        $extern_exe = "$DBIx::Perform::extern_name"; 
        unless (-e $extern_exe) {
            warn "can't find external program '$extern_exe'\n";
            return 0;
        }
        unless (-x $extern_exe) {        
            warn "external program '$extern_exe' is not executable\n";
            return 0;
        }

warn "call_extern_C_func: found $extern_exe\n" if $::TRACE;

        socket($sock, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
        my $socknm = extern_socket_name();
        my $saddr = sockaddr_un($socknm);
        unlink $socknm;
        bind $sock, $saddr or die "can't bind to $socknm\n";
# 2 is just a guess.  Number of connections probably never > 1
        listen $sock, 2  or die "can't listen to $socknm\n";

        my @cline = ($extern_exe, $socknm);
        if (!fork) {
#	    my $child_db = $DB->clone();
	    $DB->{InactiveDestroy} = 1;
#	    $DB->disconnect;
            undef $DB;
            exec(@cline);
            die "ERROR: exec failed! err = $!\n";
        }

        accept($asock, $sock);
warn "socket connected, using $socknm\n" if $::TRACE;
        $extern_started = 1;

    }
    if (! $extern_started) {
        warn "cannot access external program $extern_exe\n";
        return 0;
    }

#send out all field-tags and current values
    my @data_to = extern_data_out($funcname, $is_retval, $parms);
    my $i;
    for ($i = 0; $i < @data_to; $i++) {
warn "P: sending $data_to[$i]\n" if $::TRACE_DATA;
      send ($asock, $data_to[$i] . "\n", 0);
    }
    send ($asock, ";\n", 0);
warn "sent data to C program, waiting for results\n" if $::TRACE;
    my  $more = 1;
    my  $din = '';
    my  $lin = '';
    my  $rcvd;
    my  @data_from;
    do {
warn "P: calling recv()\n" if $::TRACE_DATA;
        recv ($asock, $rcvd, 4096, 0);
        $din .= $rcvd;
warn "P: recv buffer :$rcvd:\ndin = :$din:\n" if $::TRACE_DATA;
        while ($din =~ /\A([^\n]*)\n((.|\n)*)\z/) {
            $lin = $1;
            $din = $2;
warn "P: received 1:$lin:2:$din:3\n" if $::TRACE_DATA;
            if ($lin =~ /^;/) {
                $more = 0;
            } else {
                push @data_from, $lin;
            }
        }
    } while ($more);
warn "exiting call_extern_C_func\n" if $::TRACE;
    return  extern_data_in(@data_from);
}

sub extern_socket_name {
    return "/tmp/perl_perform.$ENV{USER}.$$";
}

sub extern_exit {
warn "exiting external program\n" if $::TRACE;
    if ($extern_started) {
        send($asock, ".\n", 0);
        close($asock);
        my $socknm = extern_socket_name();
        unlink $socknm;
    }
}

#assemble data for external program
#trying to keep the format simple, so everything depends on the first
# char of each line:
# [A-Za-z]      field-tag  value
# &             name of function to call
# @             name of database
# <             parameter for function (can be 0, 1, more than 1)
# >             return value
# This means, can't have any CR/LF characters in the values or parameters
# (could use \ to escape those)
sub extern_data_out
{
    my $funcname = shift;
    my $is_retval = shift;
    my $parms    = shift;
    my @data_o;
    my $fl = $GlobalUi->get_field_list;
    my $app = $GlobalUi->{app_object};

    push @data_o, "\@$ENV{DB_NAME}";
    push @data_o, "\&$funcname";
    push @data_o, ">" if $is_retval;
    my $i;
    for ($i = 0; $i < @$parms; $i++) {
        push @data_o, "<@$parms[$i]";
    }

    $fl->reset;
    while ( my $fo = $fl->iterate_list )
    {
        my $ft = $fo->get_field_tag;
        my $scrns = get_screen_from_tag($ft);
        my $scrn = $$scrns[0];
        my $form = $app->getForm("Run$scrn");
        my $subform = $form->getSubform('DBForm');
        my $val = $subform->getWidget($ft)->getField('VALUE');
        push @data_o, "$ft $val";
    }
    return @data_o;
}

sub extern_data_in
{
    my  @data_i = shift;
    my  $rv;
    my  $i;
    for ($i = $#data_i; $i >= 0; $i--) {
warn "extern_data_in: :$data_i[$i]:\n" if $::TRACE;
        if ($data_i[$i] =~ /^>(.*?)$/) {
            $rv = $1;
        }
        elsif ($data_i[$i] =~ /^$/) {
            next;
        }
        elsif ($data_i[$i] =~ /^;$/) {
            last;
        }
        elsif ($data_i[$i] =~ /^[^A-Za-z]?$/) {
#shouldn't happen
            die "Error:  Reception from C function is wrong.\n";
        }
        else {
            $data_i[$i] =~ /^([\S]+)\s(.*?)$/;
            my $field_tag = $1;
            my $val = $2;
warn ":$field_tag: = :$val:\n" if $::TRACE_DATA;
            if ($field_tag eq 'nextfield') {
		goto_nextfield($val);
	    } else {
                my $fo = DBIx::Perform::get_field_object_from_tag($field_tag);
	        if (defined $fo) {
                    $fo->set_value($val);
                    my ($pos, $rc);
                    ($val, $rc) = $fo->format_value_for_display($val);
                    $GlobalUi->set_screen_value($field_tag, $val);
		}
	    }
        }
    }
    $GlobalUi->redraw_subform;
    return  $rv;
}

1;
