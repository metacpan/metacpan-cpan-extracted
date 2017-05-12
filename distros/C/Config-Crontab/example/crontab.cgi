#!/usr/bin/perl -w
use strict;

## Scott Wiersdorf
## Created: Mon May 19 11:55:06 MDT 2003
## $Id$

## a simple CGI for crontab editing
##
## most useful under Apache's suEXEC wrapper ;o)
##
## This program is a demonstration of the capabilities of the
## Config::Crontab module. The bulk of this program is CGI logic (tip
## o' the hat to Lincoln Stein), but look for the Config::Crontab::*
## calls and objects named $ct, $block, $newblock, and $obj. These are
## all Config::Crontab::* objects (and the reason for this demo
## program's creation).
##

##
## WARNING * ACHTUNG * AVISO ##
##
## This program may modify your crontab file. This program is provided
## AS IS under the terms of the Perl Artistic License to illustrate
## some possible uses of Config::Crontab.
##
## This program inherently is a security problem because it provides
## no authentication mechanism. You should enable your web server's
## authentication to prevent unauthorized access to this script.
##
## The author assumes no liability for damages of any kind caused by
## (mis)?use of this program. Please see paragraph 10 of the Artistic
## License distributed with Perl. Have a nice day!
##

## to do:
##
## - enable/disable blocks and lines within a block

use CGI;
use Config::Crontab;

#########################
## user-servicable parts:
#########################
my $file = '';    ## set this to a pathname of a file (it needn't
		  ## exist) if you want to practice with a temporary
                  ## crontab file instead of your real one
my $DEBUG = 0;    ## a little extra information in your error_log

#######################################
## no user-servicable parts below here:
#######################################
my $q = new CGI;
my $self = $q->url;
my $info;  ## used for passing messages to main form

print $q->header;

ACTION: {

    #############################################################
    #############################################################
    ##                                                         ##
    ## General Block Operations: these don't require 'blockno' ##
    ##                                                         ##
    #############################################################
    #############################################################

    ##############################################
    ##         Cancel Block Operation           ##
    ##############################################
    if( $q->param('Block Cancel') || $q->param('Cancel') ) {
	$info = "Action cancelled";
	last ACTION;
    }


    ##############################################
    ##        Complete Block Operation          ##
    ##############################################
    elsif( $q->param('Block Done') ) {
	$info = "Action completed";
	last ACTION;
    }

    ##############################################
    ##              New Raw Block               ##
    ##############################################
    elsif( $q->param('Block Raw New') ) {
	## display edit page and exit
	print $q->start_html("New crontab block for " . getpwuid($<)),
	  $q->strong('Add a new crontab entry:'), $q->p, "\n\n";
	print "<ul>" . $info . "</ul>" if $info;
	print $q->start_form;
	print $q->textarea( -name    => 'blocktext',
			    -default => '',
			    -rows    => 10,
			    -columns => 50 );
	print $q->p, "\n";
	print $q->submit('Block New Commit', 'Commit'), $q->reset, $q->submit('Block Cancel', 'Cancel');
	print $q->end_form;
	print $q->end_html;
	exit;
    }

    ##########################################
    ##          New Block Commit            ##
    ##########################################
    elsif( $q->param('Block New Commit') ) {
	my $ct = new Config::Crontab( -file => $file );  $ct->read;
	my $bt = $q->param('blocktext'); $bt =~ s/\r\n/\n/g;
	my $newblock = new Config::Crontab::Block( -data => $bt );
	$ct->last($newblock);
	$ct->write;
	$info = "New block added";
	last ACTION;
    }

    ##############################################
    ##               New Block                  ##
    ##############################################
    elsif( $q->param('Block New') ) {
	my $ct = new Config::Crontab( -file => $file );  $ct->read;
	$ct->first(new Config::Crontab::Block(-data => '## new cron event') );
	$ct->write;

	$q->param('blockno', 0);
	$q->param('Block Edit', 1);
    }

    ## add new non-blockno operations here

    #########################################################
    #########################################################
    ##                                                     ##
    ## Block Operations: these require 'blockno' to be set ##
    ##                                                     ##
    #########################################################
    #########################################################
    unless( defined $q->param('blockno') ) {
	print STDERR "No block found. Jumping to end of ACTION\n" if $DEBUG;
	last ACTION;
    }

    ## parse the crontab file
    my $ct = new Config::Crontab( -file => $file );  $ct->read;
    my $block = ($ct->blocks)[$q->param('blockno')];
    unless( ref($block) ) {
	$info = "Couldn't find block!";
	print STDERR "Block " . $q->param('blockno') . " missing\n" if $DEBUG;
	last ACTION;
    }

    ##############################################
    ##             Raw Block Edit               ##
    ##############################################
    if( $q->param('Block Raw Edit') ) {
	print $q->start_html("Edit crontab block for " . getpwuid($<)),
	  $q->strong('Edit this block:'), $q->p, "\n\n";
	print "<ul>" . $info . "</ul>" if $info;
	print $q->start_form;
	print $q->hidden('blockno', $q->param('blockno'));
	print $q->textarea( -name    => 'blocktext',
			    -default => $block->dump,
			    -rows    => 10,
			    -columns => 50 );
	print $q->p, "\n";
	print $q->submit('Block Commit', 'Commit'),
	  $q->reset,
	    $q->submit('Block Cancel', 'Cancel');
	print $q->end_form;
	print $q->end_html;
	exit;
    }

    ##############################################
    ##             Commit Block                 ##
    ##############################################
    elsif( $q->param('Block Commit') ) {
	unless( defined $q->param('blocktext') && $q->param('blocktext') ) {
	    $info = "No blocktext";
	    print STDERR "Commit: $info\n" if $DEBUG;
	    last ACTION;
	}

	my $bt = $q->param('blocktext'); $bt =~ s/\r\n/\n/g;
	my $newblock = new Config::Crontab::Block( -data => $bt );
	$ct->replace( $block, $newblock );
	$ct->write;
	$info = "New block written";
	last ACTION;
    }

    ##############################################
    ##             Delete Block                 ##
    ##############################################
    elsif( $q->param('Block Delete') ) {
	$ct->remove($block);
	$ct->write;
	$info = "Block deleted!";
	last ACTION;
    }

    ##############################################
    ##               Move Block                 ##
    ##############################################
    elsif( $q->param('Block Up')    || $q->param('Block Down') ||
	   $q->param('Block First') || $q->param('Block Last') ) {

	if(    $q->param('Block Up')    ) { $ct->up($block)    }
	elsif( $q->param('Block Down')  ) { $ct->down($block)  }
	elsif( $q->param('Block First') ) { $ct->first($block) }
	elsif( $q->param('Block Last')  ) { $ct->last($block)  }

	$ct->write;
	$info = "Block moved";
	last ACTION;
    }

    ##############################################
    ##               Edit Block                 ##
    ##                                          ##
    ## This section is a "substate" since it    ##
    ## loops within itself until 'Done' is      ##
    ## pressed.                                 ##
    ##                                          ##
    ##############################################
    if( $q->param('Block Edit') ) {

      BLOCK_EDIT: {

	    ######################################
	    ## all sections below require 'blockno'
	    ######################################
	    my $block = ($ct->blocks)[$q->param('blockno')];
	    unless( ref($block) ) {
		$info = "Couldn't find block";
		print STDERR "$info (" . $q->param('blockno') . ")\n" if $DEBUG;
		last ACTION;
	    }

	    ######################################
	    ## 'objno' not required
	    ######################################

	    if( $q->param('New Line') ) {
		if( $q->param('newobjtype') eq 'Comment' ) {
		    $block->last(new Config::Crontab::Comment(-data => '## comment'));
		} elsif( $q->param('newobjtype') eq 'Environment' ) {
		    $block->last(new Config::Crontab::Env(-data => 'NAME=value'));
		} elsif( $q->param('newobjtype') eq 'Event' ) {
		    $block->last(new Config::Crontab::Event(-data => '0 0 * * 1 /bin/true'));
		} else {
		    $info = "Unknown object type";
		    print STDERR "Edit (new line): $info (" . $q->param('newobjtype') . ")\n" if $DEBUG;
		    last ACTION;
		}
		$ct->write;
		$info = "New " . $q->param('newobjtype') . " created";
		last BLOCK_EDIT;
	    }

	    ######################################
	    ## the following sections require 'objno'
	    ######################################
	    last BLOCK_EDIT unless defined $q->param('objno');

	    my $line  = ($block->lines)[$q->param('objno')];

	    if( $q->param('Delete Line') ) {
		$block->remove($line);
		$info = "Line deleted";
	    }
	    elsif( $q->param('Commit Line') ) {
		my $obj;
		if( $q->param('objtype') eq 'comment' ) {
		    $obj = new Config::Crontab::Comment( -data => $q->param('comment') );
		} elsif( $q->param('objtype') eq 'env' ) {
		    $obj = new Config::Crontab::Env( -name  => $q->param('envname'),
						     -value => $q->param('envvalue') );
		} elsif( $q->param('objtype') eq 'event' ) {
		    $obj = new Config::Crontab::Event( -datetime => $q->param('datetime'),
						       -command  => $q->param('command') );
		}
		else {
		    $info = "Invalid object type: " . $q->param('objtype');
		    print STDERR "$info\n" if $DEBUG;
		    last ACTION;
		}
		$block->replace($line, $obj);
		$info = "Line changes saved";
	    }
	    elsif( $q->param('Revert Line') ) {
		$info = "Line reverted";
	    }
	    elsif( $q->param('First Line') ) {
		$block->first($line);
		$info = "Line moved to first";
	    }
	    elsif( $q->param('Last Line') ) {
		$block->last($line);
		$info = "Line moved to last";
	    }
	    elsif( $q->param('Up Line') ) {
		$block->up($line);
		$info = "Line moved up";
	    }
	    elsif( $q->param('Down Line') ) {
		$block->down($line);
		$info = "Line moved down";
	    }
	    else { last BLOCK_EDIT; }
	    $ct->write;
	    last BLOCK_EDIT;
	}

	## this will trigger if user deletes last line in a block, or the
	## block was emptied by someone else before we got here (no locking)
	last ACTION unless $block->lines;

	## display edit block page and exit
	print $q->start_html("Edit crontab block for " . getpwuid($<)),
	  $q->strong('Edit this block:'), "<br>\n";
	print "Date: " . scalar(localtime) . "<br>\n";
	print "<ul>" . $info . "</ul>" if $info;

	print $q->start_form;
	$q->param('Block Edit', 0);
	print $q->hidden('Block Edit');
	print $q->submit('Block Done', 'Done'), $q->reset;
	print "<br>Be sure to 'Commit' your changes before hitting 'Done'<br>\n";
	print $q->end_form;

	print qq!<table border="1"><tr valign="top">\n!;
	print qq!<td>!, $q->start_form;
	print $q->submit("New Line", "Add"), $q->br;
	print $q->hidden('blockno');
	$q->param('Block Edit', 1);
	print $q->hidden('Block Edit');

	print $q->radio_group(-name    => 'newobjtype',
			      -values  => ['Comment','Environment','Event'],
			      -default => 'Event');
	print "\n";
	print $q->end_form, qq!</td></tr></table>\n!;

	print qq!<table border="1">\n!;
	print qq!<tr><td>Delete</td><td>Commit</td><td>Undo</td><td>First</td><td>Up</td><td>Down</td><td>Last</td></tr>\n!;
	my $cols = 10;
	my $i = 0;
	for my $obj ( $block->lines ) {
	    print $q->start_form;
	    print qq!<tr valign="top">\n!;
	    print q!<td width="! . int(100*(1/$cols)) . q!%">!, 
	      $q->submit("Delete Line", 'X'), "</td>\n";
	    print q!<td width="! . int(100*(1/$cols)) . q!%">!,
	      $q->submit("Commit Line", 'O'), "</td>\n";
	    print q!<td width="! . int(100*(1/$cols)) . q!%">!,
	      $q->submit("Revert Line", 'U'), "</td>\n";
	    print q!<td width="! . int(100*(1/$cols)) . q!%">!,
	      $q->submit("First Line", '|<'), "</td>\n";
	    print q!<td width="! . int(100*(1/$cols)) . q!%">!,
	      $q->submit("Up Line", '<'), "</td>\n";
	    print q!<td width="! . int(100*(1/$cols)) . q!%">!,
	      $q->submit("Down Line", '>'), "</td>\n";
	    print q!<td width="! . int(100*(1/$cols)) . q!%">!,
	      $q->submit("Last Line", '>|'), "</td>\n";
	    $q->param('Block Edit', 1);
	    print $q->hidden('Block Edit'), "\n";
	    $q->param('objno', $i++);
	    print $q->hidden(-name => 'objno'), "\n";
	    print $q->hidden('blockno'), "\n";

	    if( UNIVERSAL::isa($obj, 'Config::Crontab::Comment') ) {
		print qq!<td colspan="3" width="! . int(100*(3/$cols)) . q!%">!;
		$q->param('comment', $obj->dump);
		print "Comment:<br>", $q->textfield(-name => "comment",
						    -size  => 25), "\n";
		print $q->hidden('objtype', 'comment'), "\n";
		print "</td>";
	    }

	    elsif( UNIVERSAL::isa($obj, 'Config::Crontab::Env') ) {
		print qq!<td>!;
		$q->param('envname', $obj->name);
		print "Name:<br>", $q->textfield(-name  => "envname",
						 -size  => 12), "\n";
		print "</td><td>=</td><td>";
		$q->param('envvalue', $obj->value);
		print "Value:<br>", $q->textfield(-name => "envvalue",
						  -value => $obj->value), "\n";
		print $q->hidden('objtype', 'env'), "\n";
		print "</td>";
	    }

	    elsif( UNIVERSAL::isa($obj, 'Config::Crontab::Event') ) {
		print qq!<td colspan="1" width="! . int(100*(1/$cols)) . q!%">!;
		$q->param('datetime', $obj->datetime);
		print "Scheduled:<br>", $q->textfield(-name => "datetime",
						      -size  => 12), "\n";
		print qq!</td><td colspan="2" width="! . int(100*(2/$cols)) . q!%">!;
		$q->param('command', $obj->command);
		print "Command:<br>", $q->textfield(-name => "command"), "\n";
		print $q->hidden('objtype', 'event'), "\n";
		print "</td>";
	    }
	    print "</tr>\n\n";
	    print $q->end_form;
	}

	print "</table>\n";
	print $q->start_form;
	$q->param('Block Edit',0);
	print $q->hidden('Block Edit');
	print $q->submit('Block Done', 'Done'), $q->reset;
	print "<br>Be sure to 'Commit' your changes before hitting 'Done'<br>\n";
	print $q->end_form;
	print $q->end_html;

	exit;
    }
}

print $q->start_html("Crontab for " . getpwuid($<)),
  $q->strong('Edit your crontab:'), "<br>\n\n";
print "Date: " . scalar(localtime) . "<br>\n";
print "<ul><em>" . $info . "</em></ul>" if $info;

print $q->start_form;
print $q->submit("Block New", "New"), $q->submit("Block Raw New", "Raw New"), $q->submit("Cancel"), "\n";
print $q->end_form;
print "<hr>\n";

my $ct = new Config::Crontab( -file => $file); $ct->read;
my $i = 0;
for my $block ( $ct->blocks ) {
    print $q->start_form;
    $q->param('blockno', $i++);
    print $q->hidden( -name=>'blockno' );
    print qq!<table border="1">\n!;
    print qq!<tr><td>Delete</td><td>Edit</td><td>Raw<br>Edit</td><td>First</td><td>Up</td><td>Down</td><td>Last</td></tr>\n!;
    print qq!<tr valign="middle">\n!;
    print "<td>", $q->submit("Block Delete", "X"), "</td>\n";
    print "<td>", $q->submit("Block Edit", "E"), "</td>\n";
    print "<td>", $q->submit("Block Raw Edit", "R"), "</td>\n";
    print "<td>", $q->submit("Block First", "|<"), "</td>\n";
    print "<td>", $q->submit("Block Up", "<"), "</td>\n";
    print "<td>", $q->submit("Block Down", ">"), "</td>\n";
    print "<td>", $q->submit("Block Last", ">|"), "</td>\n";
    print "<td><pre>\n";
    print $block->dump;
    print "</pre></td>\n";
    print "</tr></table>\n";

    print $q->end_form;
    print "<hr>\n";
    print "\n\n";
}
print $q->start_form;
print $q->submit("Block New", "New"), $q->submit("Block Raw New", "Raw New"), $q->submit("Cancel"), "\n";
print $q->end_form;
print $q->end_html;
exit;
