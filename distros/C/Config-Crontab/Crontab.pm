############################################################
############################################################
##
## Scott Wiersdorf
## Created: Fri May  9 14:03:01 MDT 2003
## Updated: $Id$
##
## Config::Crontab - a crontab(5) parser
##
## This file contains the following classes:
##
## - Config::Crontab - the top level crontab object
## - Config::Crontab::Block - crontab block (paragraph) handling
## - Config::Crontab::Event - "5 0 * * * /bin/command"
## - Config::Crontab::Env - "VAR=value"
## - Config::Crontab::Comment - "## a comment"
## - Config::Crontab::Base - base class from which all other
##     Config::Crontab classes inherit
## - Config::Crontab::Container - base class from which Crontab and
##     Block classes inherit
##
############################################################
############################################################

## to do: if -file = /etc/crontab, set system => 1
## to do: if adding a non-block to a $ct file, make a block for us automatically

## a crontab object is a list of Block objects (see below) This class
## (Config::Crontab) is for working with crontab files as a whole.
package Config::Crontab;
use strict;
use warnings;
use Carp;
use 5.006_001;

our @ISA = qw(Config::Crontab::Base Config::Crontab::Container);

## these two are for the 'write' method
use Fcntl;
use File::Temp qw(:POSIX);

our $VERSION = '1.45';

sub init {
    my $self = shift;
    my %args = @_;

    $self->file('');
    $self->mode('block');
    $self->squeeze(1);     ## only in block mode
    $self->strict(0);
    $self->blocks([]);
    $self->error('');
    $self->system(0);
    $self->owner('');
    $self->owner_re( '[^a-zA-Z0-9\._-]' );

    $self->file(     $args{'-file'})     if exists $args{'-file'};
    $self->mode(     $args{'-mode'})     if exists $args{'-mode'};
    $self->squeeze(  $args{'-squeeze'})  if exists $args{'-squeeze'};
    $self->strict(   $args{'-strict'})   if exists $args{'-strict'};
    $self->system(   $args{'-system'})   if exists $args{'-system'};
    $self->owner(    $args{'-owner'})    if exists $args{'-owner'};
    $self->owner_re( $args{'-owner_re'}) if exists $args{'-owner_re'};

    ## auto-parse if file is specified
    $self->read if $self->file;

    return 1;
}

sub read {
    my $self = shift;
    my %args = @_;

    $self->file(     $args{'-file'})     if exists $args{'-file'};
    $self->mode(     $args{'-mode'})     if exists $args{'-mode'};
    $self->squeeze(  $args{'-squeeze'})  if exists $args{'-squeeze'};
    $self->strict(   $args{'-strict'})   if exists $args{'-strict'};
    $self->system(   $args{'-system'})   if exists $args{'-system'};
    $self->owner(    $args{'-owner'})    if exists $args{'-owner'};
    $self->owner_re( $args{'-owner_re'}) if exists $args{'-owner_re'};

    ## set default system crontab
    if( $self->system && ! $self->file ) {
	$self->file('/etc/crontab');
    }

    my $fh;

    ## parse the file accordingly
    if( $self->file ) {
	open $fh, $self->file
	  or do {
	      $self->error($!);
	      if( $self->strict ) {
		  croak "Could not open " . $self->file . ": " . $self->error . "\n";
	      }
	      return;
	  }
    }

    else {
	my $crontab_cmd = "crontab -l 2>/dev/null|";
	if( $self->owner ) {
            if( $^O eq 'SunOS' ) {
                $crontab_cmd = "crontab -l " . $self->owner . " 2>/dev/null|";
            }
            else {
                $crontab_cmd = "crontab -u " . $self->owner . " -l 2>/dev/null|";
            }
	}
	open $fh, $crontab_cmd
	  or do {
	      $self->error($!);
	      if( $self->strict ) {
		  croak "Could not open pipe from crontab: " . $self->error . "\n";
	      }
	      return;
	  }
    }

    ## reset internal block list and errors
    $self->blocks([]);
    $self->error('');

  PARSE: {
	local $/;

	## each line is a block
	if( $self->mode eq 'line' ) {
	    $/ = "\n";
	}

	## whole file is a block
	elsif( $self->mode eq 'file' ) {
	    $/ = undef;
	}

	## each paragraph (\n\n+) is a block
	else {
	    $/ = ( $self->squeeze ? '' : "\n\n" );
	}

	local $_;
	while( <$fh> ) {
	    chomp;
	    $self->last( new Config::Crontab::Block( -system => $self->system,
						     -data   => $_ ) );
	}
    }
    close $fh;
}

## this is needed for Config::Crontab::Container class methods
*elements = \&blocks;

sub blocks {
    my $self   = shift;
    my $blocks = shift;

    if( ref($blocks) eq 'ARRAY' ) {
	$self->{'_blocks'} = $blocks;
    }

    ## return only blocks (in case of accidental non-block pushing)
    return grep { UNIVERSAL::isa($_, 'Config::Crontab::Block') }
      grep { ref($_) } @{$self->{'_blocks'}};
}

sub select {
    my $self = shift;
    my @results = ();
    push @results, $_->select(@_) for $self->blocks;
    @results;
}

sub select_blocks {
    my $self = shift;
    my %crit = @_;
    my @results = ();

    unless( keys %crit ) {
	@results = $self->blocks;
    }

    while( my($key, $value) = each %crit ) {
	$key =~ s/^\-//;  ## strip leading hyphen

	if( $key eq 'index' ) {
	    unless( defined $value ) {
		if( $self->strict ) {
		    carp "index value undefined\n";
		}
		next;
	    }

	    ## a list ref of integers
	    if( ref($value) eq 'ARRAY' ) {
		push @results, @{$self->{'_blocks'}}[@$value];
	    }

	    ## an integer
	    elsif( $value =~ /^\d+$/ ) {
		push @results, @{$self->{'_blocks'}}[$value];
	    }

	    else {
		if( $self->strict ) {
		    carp "index value not recognized\n";
		}
	    }
	}

	else {
	    if( $self->strict ) {
		carp "Unknown block selection type '$key'\n";
	    }
	}
    }
    @results;
}

sub block {
    my $self = shift;
    my $obj  = shift
      or return;
    my $rblock;

  BLOCK: for my $block ( $self->blocks ) {
	for my $line ( $block->lines ) {
	    if( $line == $obj ) {
		$rblock = $block;
		last BLOCK;
	    }
	}
    }

    return $rblock;
}

sub remove {
    my $self = shift;
    my @objs = @_;

    if( @objs ) {
	for my $obj ( @objs ) {
	    next unless defined $obj && ref($obj);

	    unless( UNIVERSAL::isa($obj, 'Config::Crontab::Block') ) {
		if( $self->block($obj) ) {
		    $self->block($obj)->remove($obj);
		}

		## a non-block object in our crontab file!
		else {
		    undef $obj;
		}
		next;
	    }

	    for my $block ( @{$self->{'_blocks'}} ) {
		next unless defined $block && ref($block);
		if( $block == $obj ) {
		    undef $block;
		}
	    }
	}

	## strip out undefined objects
	$self->blocks([ grep { defined } $self->elements ]);
    }

    return $self->elements;
}

## same as 'crontab -u user file'
sub write {
    my $self = shift;
    my $file = shift;

    ## see if a file is present, allow for ''
    if( defined $file ) {
	$self->file($file);
    }

    if( $self->file ) {
	open my $ct, ">" . $self->file
	  or croak "Could not open " . $self->file . ": $!\n";
	print {$ct} $self->dump;
	close $ct;
    }

    ## use a temporary filename
    else {
	my $tmpfile;
        my $ct;
	do { $tmpfile = tmpnam() }
	  until sysopen($ct, $tmpfile, O_RDWR|O_CREAT|O_EXCL);
	print {$ct} $self->dump;
	close $ct;

	my $crontab;
	if( my $owner = $self->owner ) {
	    $crontab = `crontab -u $owner $tmpfile 2>&1`;
	}
	else {
	    $crontab = `crontab $tmpfile 2>&1`;
	}
	chomp $crontab;
	unlink $tmpfile;

	if( $crontab || $? ) {
	    $self->error($crontab);
	    if( $self->strict ) {
		carp "Error writing crontab (crontab exited with status " . 
		  ($? >> 8) . "): " . $self->error;
	    }
	    return;
	}
    }

    return 1;
}

sub remove_tab {
    my $self = shift;
    my $file = shift;

    ## see if a file is present, allow for ''
    if( defined $file ) {
	$self->file($file);
    }

    if( $self->file ) {
	unlink $self->file;
    }

    else {
	my $output = '';
	if( my $owner = $self->owner ) {
	    $output = `crontab -u $owner -r 2>&1`;
	}
	else {
	    $output = `yes | crontab -r 2>&1`;
	}
	chomp $output;

	## FIXME: what if no $output, but only '$?' ?
	if( $output || $? ) {
	    $self->error($output);
	    if( $self->strict ) {
		carp "Error removing crontab (crontab exited with status " .
		  ($? >> 8) ."): " . $self->error;
	    }
	    return;
	}
    }

    return 1;
}

sub dump {
    my $self = shift;
    my $ret  = '';

    for my $block ( $self->blocks ) {
	$ret .= "\n" if $ret && $block->dump;  ## empty blocks should not invoke a newline
	$ret .= $block->dump;
    }

    return $ret;
}

sub owner {
    my $self = shift;
    if( @_ ) {
	my $owner = shift;
	if( $owner ) {
	    unless( defined( getpwnam($owner) ) ) {
		$self->error("Unknown user: $owner");
		if( $self->strict ) {
		    croak $self->error;
		}
		return;
	    }

	    if( $owner =~ $self->owner_re ) {
		$self->error("Illegal username: $owner");
		if( $self->strict ) {
		    croak $self->error;
		}
		return;
	    }
	}
	$self->{_owner} = $owner;
    }
    return ( defined $self->{_owner} ? $self->{_owner} : '' );
}

sub owner_re {
    my $self = shift;
    if( @_ ) {
	my $re = shift;
	$self->{_owner_re} = qr($re);
    }
    return ( defined $self->{_owner_re} ? $self->{_owner_re} : qr() );
}

############################################################
############################################################

=head1 NAME

Config::Crontab - Read/Write Vixie compatible crontab(5) files

=head1 SYNOPSIS

  use Config::Crontab;

  ####################################
  ## making a new crontab from scratch
  ####################################

  my $ct = new Config::Crontab;

  ## make a new Block object
  my $block = new Config::Crontab::Block( -data => <<_BLOCK_ );
  ## mail something to joe at 5 after midnight on Fridays
  MAILTO=joe
  5 0 * * Fri /bin/someprogram 2>&1
  _BLOCK_

  ## add this block to the crontab object
  $ct->last($block);

  ## make another block using Block methods
  $block = new Config::Crontab::Block;
  $block->last( new Config::Crontab::Comment( -data => '## do backups' ) );
  $block->last( new Config::Crontab::Env( -name => 'MAILTO', -value => 'bob' ) );
  $block->last( new Config::Crontab::Event( -minute  => 40,
                                            -hour    => 3,
                                            -command => '/sbin/backup --partition=all' ) );
  ## add this block to crontab file
  $ct->last($block);

  ## write out crontab file
  $ct->write;

  ###############################
  ## changing an existing crontab
  ###############################

  my $ct = new Config::Crontab; $ct->read;

  ## comment out the command that runs our backup
  $_->active(0) for $ct->select(-command_re => '/sbin/backup');

  ## save our crontab again
  $ct->write;

  ###############################
  ## read joe's crontab (must have root permissions)
  ###############################

  ## same as "crontab -u joe -l"
  my $ct = new Config::Crontab( -owner => 'joe' );
  $ct->read;

=head1 DESCRIPTION

B<Config::Crontab> provides an object-oriented interface to
Vixie-style crontab(5) files for Perl.

A B<Config::Crontab> object allows you to manipulate an ordered set
of B<Event>, B<Env>, or B<Comment> objects (also included with this
package). Descriptions of these packages may be found below.

In short, B<Config::Crontab> reads and writes crontab(5) files (and
does a little pretty-printing too) using objects. The general idea is
that you create a B<Config::Crontab> object and associate it with a
file (if unassociated, it will work over a pipe to C<crontab -l>). From
there, you can add lines to your crontab object, change existing line
attributes, and write everything back to file.

=over 4

=item

NOTE: B<Config::Crontab> does I<not> (currently) do validity checks
on your data (i.e., dates out of range, etc.). However, if the call
to B<crontab> fails when you invoke B<write>, B<write> will return
I<undef> and set B<error> with the error message returned from the
B<crontab> command. Future development may tend toward more validity
checks.

=back

Now, to successfully navigate the module's ins and outs, we'll need a
little terminology lesson.

=head2 Terminology

B<Config::Crontab> (hereafter simply B<Crontab>) sees a C<crontab>
file in terms of I<blocks>. A block is simply an ordered set of one
or more lines. Blocks are separated by two or more newlines. For
example, here is a crontab file with two blocks:

    ## a comment
    30 4 * * * /bin/some_command
    
    ## another comment
    ENV=some_value
    50 9 * * 1-5 /bin/reminder --meeting=friday

The first block contains two B<Config::Crontab::*> objects: a
B<Comment> object and an B<Event> object. The second block contains
an B<Env> object in addition to a B<Comment> object and an B<Event>
object. The B<Config::Crontab> class, then, consists of zero or more
B<Config::Crontab::Block> objects. B<Block> objects have these three
basic elements:

=over 4

=item B<Config::Crontab::Event>

Any lines in a crontab that look like these are B<Event> objects:

    5 10 * * * /some/command
    @reboot /bin/mystartup.sh
    ## 0 0 * * Fri /disabled/command

Notice that commented out event lines are still considered B<Event>
objects.

B<Event> objects are described below in the B<Event> package
description. Please refer to it for details on manipulating B<Event>
objects.

=item B<Config::Crontab::Env>

Any lines in a crontab that look like these are B<Env> objects:

    MAILTO=joe
    SOMEVAR = some_value
    #DISABLED=env_setting

Notice that commented out environment lines are still considered
B<Env> objects.

B<Env> objects are described below in the B<Env> package description.
Please refer to it for details on manipulating B<Env> objects.

=item B<Config::Crontab::Comment>

Any lines containing only whitespace or lines beginning with a pound
sign (but are not B<Event> or B<Env> objects) are B<Comment> objects:

    ## this is a comment
    (imagine somewhitespace here)

B<Comment> objects are described below in the B<Comment> package
description. Please refer to it for details on manipulating B<Comment>
objects.

=back

=head2 Illustration

Here is a simple crontab file:

  MAILTO=joe@schmoe.org

  ## send reminder in April
  3 10 * Apr Fri  joe  echo "Friday a.m. in April"

The file consists of an environment variable setting (MAILTO), a
comment, and a command to run. After parsing the above file, 
B<Config::Crontab> would break it up into the following objects:

    +---------------------------------------------------------+
    |     Config::Crontab object                              |
    |                                                         |
    |  +---------------------------------------------------+  |
    |  |      Config::Crontab::Block object                |  |
    |  |                                                   |  |
    |  |  +---------------------------------------------+  |  |
    |  |  |       Config::Crontab::Env object           |  |  |
    |  |  |                                             |  |  |
    |  |  |  -name => MAILTO                            |  |  |
    |  |  |  -value => joe@schmoe.org                   |  |  |
    |  |  |  -data => MAILTO=joe@schmoe.org             |  |  |
    |  |  +---------------------------------------------+  |  |
    |  +---------------------------------------------------+  |
    |                                                         |
    |  +---------------------------------------------------+  |
    |  |      Config::Crontab::Block object                |  |
    |  |                                                   |  |
    |  |  +---------------------------------------------+  |  |
    |  |  |       Config::Crontab::Comment object       |  |  |
    |  |  |                                             |  |  |
    |  |  |  -data => ## send reminder in April         |  |  |
    |  |  +---------------------------------------------+  |  |
    |  |                                                   |  |
    |  |  +---------------------------------------------+  |  |
    |  |  |       Config::Crontab::Event Object         |  |  |
    |  |  |                                             |  |  |
    |  |  |  -datetime => 3 10 * Apr Fri                |  |  |
    |  |  |  -special => (empty)                        |  |  |
    |  |  |  -minute => 3                               |  |  |
    |  |  |  -hour => 10                                |  |  |
    |  |  |  -dom => *                                  |  |  |
    |  |  |  -month => Apr                              |  |  |
    |  |  |  -dow => Fri                                |  |  |
    |  |  |  -user => joe                               |  |  |
    |  |  |  -command => echo "Friday a.m. in April"    |  |  |
    |  |  +---------------------------------------------+  |  |
    |  +---------------------------------------------------+  |
    +---------------------------------------------------------+

You'll notice the main Config::Crontab object encapsulates the entire
file. The parser found two B<Block> objects: the lone MAILTO variable
setting, and the comment and command (together). Two or more newlines
together in a crontab file constitute a block separator. This allows
you to logically group commands (as most people do anyway) in the
crontab file, and work with them as a Config::Crontab::Block objects.

The second block consists of a B<Comment> object and an B<Event>
object, shown are some of the data methods you can use to get or set
data in those objects.

=head2 Practical Usage: A Brief Tutorial

Now that we know what B<Config::Crontab> objects look like and what
they're called, let's play around a little.

Let's say we have an existing crontab on many machines that we want
to manage.  The crontab contains some machine-dependent information
(e.g., timezone, etc.), so we can't just copy a file out everywhere
and replace the existing crontab. We need to edit each crontab
individually, specifically, we need to change the time when a
particular job runs:

    30 2 * * * /usr/local/sbin/pirate --arg=matey

to 3:30 am because of daylight saving time (i.e., we don't want this
job to run twice).

We can do something like this:

    use Config::Crontab;

    my $ct = new Config::Crontab;
    $ct->read;

    my ($event) = $ct->select(-command_re => 'pirate --arg=matey');
    $event->hour(3);

    $ct->write;

All done! This shows us a couple of subtle but important points:

=over 4

=item *

The B<Config::Crontab> object must have its B<read> method invoked
for it to read the crontab file.

=item *

The B<select> method returns a list, even if there is only one item
to return. This is why we put parentheses around I<$event> (otherwise
we would be putting the return value of B<select> into scalar context
and we would get the number of items in the list instead of the list
itself).

=item *

The I<set> methods for B<Event> (and other) objects are usually
invoked the same way as their I<get> method except with an argument.

=item *

We must write the crontab back out to file with the B<write> method.

=back

Here's how we might do the same thing in a one-line Perl program:

    perl -MConfig::Crontab -e '$ct=new Config::Crontab; $ct->read; \
    ($ct->select(-command_re=>"pirate --arg=matey"))[0]->hour(3); \
    $ct->write'

Nice! Ok. Now we need to add a new crontab entry:

    35 6 * * * /bin/alarmclock --ring

We can do it like this:

    $event = new Config::Crontab::Event( -minute  => 36,
                                         -hour    => 6,
                                         -command => '/bin/alarmclock --ring');
    $block = new Config::Crontab::Block;
    $block->last($event);
    $ct->last($block);

or like this:

    $event = new Config::Crontab::Event( -data => '35 6 * * * /bin/alarmclock --ring' );
    $ct->last(new Config::Crontab::Block( -lines => [$event] ));

or like this:

    $ct->last(new Config::Crontab::Block(-data => "35 6 * * * /bin/alarmclock --ring"));

We learn the following things from this example:

=over 4

=item *

Only B<Block> objects can be added to B<Crontab> objects (see
L</CAVEATS>). B<Block> objects may be added via the B<last> method
(and several other methods, including B<first>, B<up>, B<down>,
B<before>, and B<after>).

=item *

B<Block> objects can be populated in a variety of ways, including the
B<-data> attribute (a string which may--and frequently does--span
multiple lines via a 'here' document), the B<-lines> attribute (which
takes a list reference), and the B<last> method. In addition to the
B<last> method, B<Block> objects use the same methods for adding and
moving objects that the B<Crontab> object does: B<first>, B<last>,
B<up>, B<down>, B<before>, and B<after>.

=back

After the B<Module Utility> section, the remainder of this document
is a reference manual and describes the methods available (and how to
use them) in each of the 5 classes: B<Config::Crontab>,
B<Config::Crontab::Block>, B<Config::Crontab::Event>,
B<Config::Crontab::Env>, and B<Config::Crontab::Comment>. The reader
is also encouraged to look at the example CGI script in the F<eg>
directory and the (somewhat contrived) examples in the F<t> (testing)
directory with this distribution.

=head2 Module Utility

B<Config::Crontab> is a useful module by virtue of the "one-liner"
test. A useful module must do useful work (editing crontabs is useful
work) economically (i.e., useful work must be able to be done on a
single command-line that doesn't wrap more than twice and can be
understood by an adept Perl programmer).

Graham Barr's B<Net::POP3> module (actually, most of Graham's work
falls in this category) is a good example of a useful module.

So, with no more ado, here are some useful one-liners with
B<Config::Crontab>:

=over 4

=item *

uncomment all crontab events whose command contains the string 'fetchmail'

  perl -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; \
  $_->active(1) for $c->select(-command_re => "fetchmail"); $c->write'

=item *

remove the first crontab block that has '/bin/unwanted' as a command

  perl -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; \
  $c->remove($c->block($c->select(-command_re => "/bin/unwanted"))); \
  $c->write'

=item *

reschedule the backups to run just Monday thru Friday:

  perl -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; \
  $_->dow("1-5") for $c->select(-command_re => "/sbin/backup"); $c->write'

=item *

reschedule the backups to run weekends too:

  perl -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; \
  $_->dow("*") for $c->select(-command_re => "/sbin/backup"); $c->write'

=item *

change all 'MAILTO' environment settings in this crontab to 'joe@schmoe.org':

  perl -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; \
  $_->value(q!joe@schmoe.org!) for $c->select(-name => "MAILTO"); $c->write'

=item *

strip all comments from a crontab:

  perl -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; \
  $c->remove($c->select(-type => "comment")); $c->write'

=item *

disable an entire block of commands (the block that has the word
'Friday' in it):

  perl -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; \
  $c->block($c->select(-data_re => "Friday"))->active(0); $c->write'

=item *

copy one user's crontab to another user:

  perl -MConfig::Crontab -e '$c = new Config::Crontab(-owner => "joe"); \
  $c->read; $c->owner("mike"); $c->write'

=back

=head1 PACKAGE Config::Crontab

This section describes B<Config::Crontab> objects (hereafter simply
B<Crontab> objects). A B<Crontab> object is an abstracted way of
dealing with an entire B<crontab(5)> file. The B<Crontab> class has
methods to allow you to select, add, or remove B<Block> objects as
well as read and parse crontab files and write crontab files.

=head2 init([%args])

This method is called implicitly when you instantiate an object via
B<new>. B<init> takes the same arguments as B<new> and B<read>. If
the B<-file> argument is specified (and is non-false), B<init> will
invoke B<read> automatically with the B<-file> value. Use B<init> to
re-initialize an object.

Example:

    ## auto-parses foo.txt in implicit call to init
    $ct = new Config::Crontab( -file => 'foo.txt' );

    ## re-initialize the object with default values and a new file
    $ct->init( -file => 'bar.txt' );

=head2 strict([boolean])

B<strict> enforces the following constraints:

=over 4

=item *

if the file specified by the B<file> method (or B<-file> attribute in
B<new>) does not exist at the time B<read> is invoked, B<read> sets
B<error> and dies: "Could not open (filename): (reason)".  If strict
is disabled, B<read> returns I<undef> (B<error> is set).

=item *

If the file specified by the B<file> method (or B<-file> attribute in
B<new>) cannot be written to, or the C<crontab> command fails,
B<write> sets B<error> and warns: "Could not open (filename):
(reason)". If strict is disabled, B<write> returns I<undef> (B<error> is
set).

=item *

Croaks if an illegal username is specified in the B<-owner> parameter.

=back

Examples:

    ## disable strict (default)
    $ct->strict(0);

=head2 system([boolean])

B<system> tells B<config::crontab> to assume that the crontab object
is after the pattern described in L<crontab(5)> with an extra I<user>
field before the I<command> field:

  @reboot     joeuser    /usr/local/bin/fetchmail -d 300

where the given command will be executed by said user. when a crontab
file (e.g., F</etc/crontab>) is parsed without B<system> enabled, the
I<user> field will be lumped in with the command. When enabled, the
user field will be accessible in each event object via the B<user>
method (see L</"user"> in the B<event> documentation below).

=head2 owner([string])

B<owner> sets the owner of the crontab. If you're running
Config::Crontab as a privileged user (e.g., "root"), you can read and
write user crontabs by specifying B<owner> either in the constructor,
during B<init>, or using B<owner> before a B<read> or B<write> method
is called:

  $c = new Config::Crontab( -owner => 'joe' );
  $c->read;  ## reading joe's crontab

Or another way:

  $c = new Config::Crontab;
  $c->owner('joe');
  $c->read;  ## reading joe's crontab

You can use this to copy a crontab from one user to another:

  $c->owner('joe');
  $c->read;
  $c->owner('bob');
  $c->write;

=head2 owner_re([regex])

B<Config::Crontab> is strict in what it will allow for a username,
since this information internally is passed to a shell. If the
username specified is not a user on the system, B<Config::Crontab>
will set B<error> with "Illegal username" and return I<undef>; if
B<strict> mode is enabled, B<Config::Crontab> will croak with the same
error.

Further, once the username is determined valid, the username is then
checked against a regular expression to thwart null string attacks and
other maliciousness. The default regular expression used to check for
a safe username is:

    /[^a-zA-Z0-9\._-]/

If the pattern matches (i.e., if any characters other than the ones
above are found in the supplied username), B<Config::Crontab> will
set B<error> with "Illegal username" and return I<undef>. If B<strict>
mode is enabled, B<Config::Crontab> will croak with the same error.

  $c->owner_re('[^a-zA-Z0-9_\.-#]');  ## allow # in usernames

=head2 read([%args])

Parses the crontab file specified by B<file>. If B<file> is not set
(or is false in some way), the crontab will be read from a pipe to
C<crontab -l>. B<read> optionally takes the same arguments as B<new>
and B<init> in C<key =E<gt> value> style lists.

Until you B<read> the crontab, the B<Crontab> object will be
uninitialized and will contain no data. You may re-read existing
objects to get new crontab data, but the object will retain whatever
other attributes (e.g., strict, etc.) it may have from when it was
initialized (or later attributes were changed) but will reset
B<error>. Use B<init> to completely refresh an object.

If B<read> fails, B<error> will be set.

Examples:

    ## reads the crontab for this UID (via crontab -l)
    $ct = new Config::Crontab;
    $ct->read;

    ## reads the crontab from a file
    $ct = new Config::Crontab;
    $ct->read( -file => '/var/cronbackups/cron1' );

    ## same thing as above
    $ct = new Config::Crontab( -file => '/var/cronbackups/cron1' );
    $ct->read; ## '-file' attribute already set

    ## ditto using 'file' method
    $ct = new Config::Crontab;
    $ct->file('/var/cronbackups/cron1');
    $ct->read;

    ## ditto, using a pipe
    $ct = new Config::Crontab;
    $ct->file('cat /var/cronbackups/cron1|');
    $ct->read;

    ## ditto, using 'read' method
    $ct = new Config::Crontab;
    $ct->read( -file => 'cat /var/cronbackups/cron1|');

    ## now fortified with error-checking
    $ct->read
      or do {
        warn $ct->error;
        return;
      };

=cut

## FIXME: need to say something about squeeze here, but squeeze(0)
## doesn't seem to work correctly (i.e., it still squeezes the file)

=head2 mode([mode])

Returns the current parsing mode for this object instance. If a mode
is passed as an argument, next time this instance parses a crontab
file, it will use this new mode. Valid modes are I<line>, I<block>
(the default), or I<file>.

Example:

    ## re-read this crontab in 'file' mode
    $ct->mode('file');
    $ct->read;

=head2 blocks([\@blocks])

Returns a list of B<Block> objects in this crontab. The B<blocks>
method also takes an optional list reference as an argument to set
this crontab's block list.

Example:

    ## get blocks, remove comments and dump
    for my $block ( $ct->blocks ) {
        $block->remove($block->select( -type   => 'comment' ) );
        $block->remove($block->select( -type   => 'event',
                                       -active => 0 );
        print $block->dump;
    }

    ## one way to remove unwanted blocks from a crontab
    my @keepers = $ct->select( -type    => 'comment',
                               -data_re => 'keep this block' );
    $ct->blocks(\@keepers);

    ## another way to do it (notice 'nre' instead of 're')
    $ct->remove($ct->select( -type     => 'comment',
                             -data_nre => 'keep this block' ));

=head2 select([%criteria])

Returns a list of crontab lines that match the specified criteria.
Multiple criteria may be specified. If no criteria are specified,
B<select> returns a list of all lines in the B<Crontab> object.

Field names should be preceded by a hyphen (though without a hyphen
is acceptable too).

The following criteria and associated values are available:

=over 4

=item * -type

One of 'event', 'env', or 'comment'

=item * -E<lt>fieldE<gt>

The object in the block will be matched using 'eq' (string comparison)
against this criterion.

=item * -E<lt>fieldE<gt>_re

The value of the object method specified will be matched using Perl
regular expressions (see L<perlre>) instead of string comparisons
(uses the C<=~> operator internally).

=item * -E<lt>fieldE<gt>_nre

The value of the object method specified will be negatively matched
using Perl regular expressions (see L<perlre>) instead of string
comparisons (uses the C<!~> operator internally).

=back

Examples:

    ## returns a list of comments in the crontab that matches the
    ## exact phrase '## I like bread'
    @comments = $ct->select( -type => 'comment',
                             -data => '## I like bread' );

    ## returns a list of comments in the crontab that match the
    ## regular expression 'I like bread'
    @comments = $ct->select( -type    => 'comment', 
                             -data_re => 'I like bread' );

    ## select all cron jobs likely to repeat during daylight saving
    @events = $ct->select( -type => 'event',
                           -hour => '2' );

    ## select cron jobs that happen from 10:20 to 10:40 on Fridays
    @events = $ct->select( -type      => 'event',
                           -hour      => '10',
                           -minute_re => '^(?:[2-3][0-9]|40)$',
                           -dow_re    => '(?:5|Fri)' );

    ## select all cron jobs that execute during business hours
    @events = $ct->select( -type    => 'event',
                           -hour_re => '^(?:[8-9]|1[0-6])$' );

    ## select all cron jobs that don't execute during business hours
    @events = $ct->select( -type     => 'event',
                           -hour_nre => '^(?:[8-9]|1[0-6])$' );

    ## get all event lines in the crontab
    @events = $ct->select( -type => 'event' );

    ## get all lines in the crontab
    @lines => $ct->select;

    ## get a line: note list context, also, no 'type' specified
    ($line) = $ct->select( -data_re => 'start backups' );

=head2 select_blocks([%criteria])

Returns a list of crontab Block objects that match the specified
criteria. If no criteria are specified, B<select_blocks> behaves just
like the B<blocks> method, returning all blocks in the crontab object.

The following criteria keys are available:

=over 4

=item * -index

An integer or list reference of integers. Returns a list of blocks
indexed by the given integer(s).

Example:

  ## select the first block in the file
  @blocks = $ct->select_blocks( -index => 1 );

  ## select blocks 1, 5, 6, and 7
  @blocks = $ct->select_blocks( -index => [1, 5, 6, 7] );

=back

B<select_blocks> returns B<Block> objects, which means that if you
need to access data elements inside the blocks, you'll need to
retrieve them using B<lines> or B<select> method first:

  ## the first block in the crontab file is an environment variable
  ## declaration: NAME=value
  @blocks = $ct->select_blocks( -index => 1 );
  print "This environment variable value is " . ($block[0]->lines)[0]->value . "\n";

=head2 block($line)

Returns the block that this line belongs to. If the line is not found
in any blocks, I<undef> is returned. I<$line> must be a
B<Config::Crontab::Event>, B<Config::Crontab::Env>, or
B<Config::Crontab::Comment> object.

Examples:

    ## will always return undef for new objects; you'd never really do this
    $block = $ct->block( new Config::Crontab::Comment(-data => '## foo') );

    ## returns a Block object
    $block = $ct->block($existing_crontab_line);
    $block->dump;

    ## find and remove the block in which '/bin/baz' is executed
    my $event = $ct->select( -type       => 'event',
                             -command_re => '/bin/baz');
    $block = $ct->block($event);
    $ct->remove($block);

=head2 remove($block)

Removes a block from the crontab file (if a block is specified) or a
crontab line from its block (if a crontab line object is specified).

Example:

    ## remove this block from the crontab
    $ct->remove($block);

    ## remove just a line from its block
    $ct->remove($line);

=head2 replace($oldblock, $newblock)

Replaces I<$oldblock> with I<$newblock>. Returns I<$oldblock> if
successful, I<undef> otherwise.

Example:

    ## look for the block containing 'oldtuesday' and replace it with our new block
    $newblock = new Config::Crontab::Block( -data => '5 10 * * Tue /bin/tuesday' );
    my $oldblock = $ct->block($ct->select(-data_re => 'oldtuesday'));
    $ct->replace($oldblock, $newblock);

=head2 up($block), down($block)

These methods move a single B<Config::Crontab::Block> object up or
down in the B<Crontab> object's internal array. If the B<Block> object
is not already a member of this array, it will be added to the array
in the first position (for B<up>) and in the last position (for
B<down>. See also B<first> and B<last> and B<up> and B<down> in the
B<Block> class.

Example:

    $ct->up($block);  ## move this block up one position

=head2 first(@block), last(@block)

These methods move the B<Config::Crontab::Block> object(s) to the
first or last positions in the B<Crontab> object's internal array. If
the block is not already a member of the array, it will be added in
the first or last position respectively.

Example:

    $ct->last(new Config::Crontab::Block( -data => <<_BLOCK_ ));
    ## eat ice cream
    5 * * * 1-5 /bin/eat --cream=ice
    _BLOCK_

=head2 before($look_for, @blocks), after($look_for, @blocks)

These methods move the B<Config::Crontab::Block> object(s) to the
position immediately before or after the I<$look_for> (or reference)
block in the B<Crontab> object's internal array.

If the objects are not members of the array, they will be added before
or after the reference block respectively. If the reference object
does not exist in the array, the blocks will be moved (or added) to
the beginning or end of the array respectively (like B<first> and
B<last>).

Example:

    ## search for a block containing a particular event (line)
    $block = $ct->block($ct->select(-command_re => '/bin/foo'));

    ## add the new blocks immediately after this block
    $ct->after($block, @new_blocks);

=head2 write([$filename])

Writes the crontab to the file specified by the B<file> method. If
B<file> is not set (or is false), B<write> will attempt to write to
a temporary file and load it via the C<crontab> program (e.g.,
C<crontab filename>).

You may specify an optional filename as an argument to set B<file>,
which will then be used as the filename.

If B<write> fails, B<error> will be set.

Example:

    ## write out crontab
    $ct->write
      or do {
        warn "Error: " . $ct->error . "\n";
        return;
      };

    ## set 'file' and write simultaneously (future calls to read and
    ## write will use this filename)
    $ct->write('/var/mycronbackups/cron1.txt');

    ## same thing
    $ct->file('/var/mycronbackups/cron1.txt');
    $ct->write;

=head2 remove_tab([file])

Removes a crontab. If B<file> is set, that file will be unlinked. If
B<file> is not set (or is false), B<remove_tab> will attempt to remove
the selected user's crontab via F<crontab -u username -r> or F<crontab
-r> for the current user id.

If B<remove_tab> fails, B<error> will be set.

Example:

  $ct->remove_tab('');  ## unset file() and remove the current user's crontab

=head2 error([string])

Returns the last error encountered (usually during a file I/O
operation). Pass an empty string to reset (calling B<init> will also
reset it).

Example:

    print "The last error was: " . $ct->error . "\n";
    $ct->error('');

=head2 dump

Returns a string containing the crontab file.

Example:

    ## show crontab
    print $ct->dump;

    ## same as 'crontab -l' except pretty-printed
    $ct = new Config::Crontab; $ct->read; print $ct->dump;

=cut

############################################################
############################################################

package Config::Crontab::Block;
use strict;
use warnings;
use Carp;

our @ISA = qw(Config::Crontab::Base Config::Crontab::Container);

sub init {
    my $self = shift;
    my %args = @_;

    $self->lines([]);  ## initialize
    $self->strict(0);
    $self->system(0);

    $self->lines($args{'-lines'})   if defined $args{'-lines'};
    $self->strict($args{'-strict'}) if defined $args{'-strict'};
    $self->system($args{'-system'}) if defined $args{'-system'};

    my $rv = 1;
    if( defined $args{'-data'} ) {
	$self->lines([]);
	$rv = $self->data($args{'-data'});
    }

    return ( defined $rv ? 1 : undef );
}

sub data {
    my $self  = shift;
    my $data  = shift;
    my @lines = ();

    if( defined $data ) {
	if( ref($data) eq 'ARRAY' ) {
	    @lines = @$data;
	}

	elsif( $data ) {
	    @lines = split(/\n/, $data);
	}

	elsif( $data eq '' ) {
	    @lines = ($data);
	}

	else {
	    @lines = ();
	}

	for my $line ( @lines ) {
	    my $obj;
	    if( $obj = new Config::Crontab::Event(-data => $line, 
						  -system => $self->system) ) {
	    }

	    elsif( $obj = new Config::Crontab::Env(-data => $line) ) {
	    }

	    elsif( $obj = new Config::Crontab::Comment(-data => $line) ) {
	    }

	    else {
		if( $self->strict ) {
		    carp "Skipping illegal line in block: $line\n";
		}
		next;
	    }

	    $self->last($obj);
	}
    }

    my $ret = '';
    for my $obj ( $self->lines ) {
	$ret .= "\n" if $ret; ## empty objects are empty lines, so we do a newline always
	$ret .= $obj->dump;
    }
    $ret .= "\n" if $ret;

    return $ret;
}

## this is needed for Config::Crontab::Container class methods
*elements = \&lines;

sub lines {
    my $self = shift;
    my $objs = shift;

    if( ref($objs) eq 'ARRAY' ) {
	$self->{'_lines'} = $objs;
    }

    return @{$self->{'_lines'}};
}

sub select {
    my $self = shift;
    my %crit = @_;

    ## return all lines unless criteria specified
    return $self->lines
      unless scalar keys %crit;

    my @results = ();
  LINE: for my $line ( $self->lines ) {
	my $j = scalar keys %crit;  ## reset keys
	while( my($key,$value) = each %crit ) {
	    $key =~ s/^\-//;  ## strip leading hyphen

	    ## FIXME: would be nice to have a negated 'type' option or a re

	    ## special case for 'type'
	    if( $key eq 'type' ) {
		if( $value eq 'event' ) {
		    next LINE unless UNIVERSAL::isa($line, 'Config::Crontab::Event');
		}
		elsif( $value eq 'env' ) {
		    next LINE unless UNIVERSAL::isa($line, 'Config::Crontab::Env');
		}
		elsif( $value eq 'comment' ) {
		    next LINE unless UNIVERSAL::isa($line, 'Config::Crontab::Comment');
		}
		else {
		    if( $self->strict ) {
			carp "Unknown object type '$value'\n";
		    }
		    next LINE;
		}
	    }

	    ## not special 'type' case
	    else {
		no strict 'refs';
		if( $key =~ /^(.+)_re$/ ) {
		    next LINE unless $line->$1() =~ qr($value);
		}
		elsif( $key =~ /^(.+)_nre$/ ) {
		    next LINE unless $line->$1() !~ qr($value);
		}
		else {
		    next LINE unless $line->$key() eq $value;
		}
	    }

	}
	push @results, $line;
    }

    return @results;
}

sub remove {
    my $self = shift;
    my @objs = @_;

    if( @objs ) {
	for my $obj ( @objs ) {
	    next unless defined $obj && ref($obj);
	    for my $line ( @{$self->{'_lines'}} ) {
		next unless defined $line && ref($line);
		if( $line == $obj ) {
		    undef $line;
		}
	    }
	}

	## strip out undefined objects
	$self->elements([ grep { defined } $self->elements ]);
    }

    return $self->elements;
}

sub active {
    my $self   = shift;

    return 1 unless @_;

    my $active = shift;
    local $_;
    $_->active($active) for $self->select(-type => 'env');
    $_->active($active) for $self->select(-type => 'event');

    return $active;
}

sub nolog {
    my $self = shift;
    return 1 unless @_;

    my $nolog = shift;
    local $_;
    $_->nolog($nolog) for $self->select(-type => 'event');

    return $nolog;
}

############################################################
############################################################

=head1 PACKAGE Config::Crontab::Block

This section describes B<Config::Crontab::Block> objects (hereafter
referred to as B<Block> objects). A B<Block> object is an abstracted
way of dealing with groups of crontab(5) lines. Depending on how
B<Config::Crontab> parsed the file (see the B<read> and B<mode>
methods in B<Config::Crontab> above), a block may consist of:

=over 4

=item a single line (e.g., a crontab event, environment setting, or comment)

=item a "paragraph" of lines (a group of lines, each group separated
by at least two newlines). This is the default parsing mode.

=item the entire crontab file

=back

The default for B<Config::Crontab> is to read in I<block> (paragraph)
mode. This allows you to group lines that have a similar purpose as
well as order lines within a block (e.g., often you want an
environment setting to take effect before certain cron commands
execute).

An illustration may be helpful:

=over 4

=item B<a crontab file read in block (paragraph) mode:>

    Line     Block    Block Line    Entry
    1        1        1             ## grind disks
    2        1        2             5 5 * * * /bin/grind
    3        1        3

    4        2        1             ## backup reminder to joe
    5        2        2             MAILTO=joe
    6        2        3             5 0 * * Fri /bin/backup
    7        2        4

    8        3        1             ## meeting reminder to bob
    9        3        2             MAILTO=bob
    10       3        3             30 9 * * Wed /bin/meeting

Notice that each block has its own internal line numbering. Vertical
space has been inserted between blocks to clarify block structures.
Block mode parsing is the default.

=item B<a crontab file read in line mode:>

    Line     Block    Block Line    Entry
    1        1        1             ## grind disks
    2        2        1             5 5 * * * /bin/grind
    3        3        1
    4        4        1             ## backup reminder to joe
    5        5        1             MAILTO=joe
    6        6        1             5 0 * * Fri /bin/backup
    7        7        1
    8        8        1             ## meeting reminder to bob
    9        9        1             MAILTO=bob
    10       10       1             30 9 * * Wed /bin/meeting

Notice that each line is also a block. You normally don't want to
read in line mode unless you don't have paragraph breaks in your
crontab file (the dumper prints a newline between each block; with
each line being a block you get an extra newline between each line).

=item B<a crontab file read in file mode:>

    Line     Block    Block Line    Entry
    1        1        1             ## grind disks
    2        1        2             5 5 * * * /bin/grind
    3        1        3
    4        1        4             ## backup reminder to joe
    5        1        5             MAILTO=joe
    6        1        6             5 0 * * Fri /bin/backup
    7        1        7
    8        1        8             ## meeting reminder to bob
    9        1        9             MAILTO=bob
    10       1        10            30 9 * * Wed /bin/meeting

Notice that there is only one block in file mode, and each line is a
block line (but not a separate block).

=back

=head1 METHODS

This section describes methods accessible from B<Block> objects.

=head2 new([%args])

Creates a new B<Block> object. You may create B<Block> objects in any
of the following ways:

=over 4

=item Empty

    $event = new Config::Crontab::Block;

=item Fully Populated

    $event = new Config::Crontab::Block( -data => <<_BLOCK_ );
    ## a comment
    5 19 * * Mon /bin/fhe --turn=dad
    _BLOCK_

=back

Constructor attributes available in the B<new> method take the same
arguments as their method counterparts (described below), except that
the names of the attributes must have a hyphen ('-') prepended to the
attribute name (e.g., 'lines' becomes '-lines'). The following is a
list of attributes available to the B<new> method:

=over 4

=item B<data>

=item B<lines>

=back

If the B<-data> attribute is present in the constructor when other
attributes are also present, the B<-data> attribute will override all
other attributes.

Each of these attributes corresponds directly to its similarly-named
method.

Examples:

    ## create an empty block object & populate it with the data method
    $block = new Config::Crontab::Block;
    $block->data( <<_BLOCK_ );  ## via a 'here' document
    ## 2:05a Friday backup
    MAILTO=sysadmin@mydomain.ext
    5 2 * * Fri /sbin/backup /dev/da0s1f
    _BLOCK_

    ## create a block in the constructor (also via 'here' document)
    $block = new Config::Crontab::Block( -data => <<_BLOCK_ );
    ## 2:05a Friday backup
    MAILTO=sysadmin@mydomain.ext
    5 2 * * Fri /sbin/backup /dev/da0s1f
    _BLOCK_

    ## create an array of crontab objects
    my @lines = ( new Config::Crontab::Comment(-data => '## run bar'),
                  new Config::Crontab::Event(-data => '5 8 * * * /foo/bar') );

    ## create a block object via lines attribute
    $block = new Config::Crontab::Block( -lines => \@lines );

    ## ...or with lines method
    $block->lines(\@lines);  ## @lines is an array of crontab objects

If bogus data is passed to the constructor, it will return I<undef>
instead of an object reference. If there is a possiblility of poorly
formatted data going into the constructor, you should check the object
variable for definedness before using it.

If the B<-data> attribute is present in the constructor when other
attributes are also present, the B<-data> attribute will override all
other attributes.

=head2 data([string])

Get or set a raw block. Internally, B<Block> passes its arguments to
other objects for parsing when a parameter is present.

Example:

    ## re-initialize this block
    $block->data("## comment\n5 * * * * /bin/checkup");

    print $block->data;

Block data is terminated with a final newline.

=head2 lines([\@objects])

Get block data as a list of B<Config::Crontab::*> objects. Set block
data using a list reference.

Example:

    $block->lines( [ new Config::Crontab::Comment( -data => "## run backup" ),
                     new Config::Crontab::Event( -data => "5 4 * * 1-5 /sbin/backup" ) ] );

    ## sorta like $block->dump
    for my $obj ( $block->lines ) {
        print $obj->dump . "\n";
    }

    ## a clumsy way to "unshift" a new event
    $block->lines( [new Config::Crontab::Comment(-data => '## hi mom!'),
                    $block->lines] );

    ## the right way to add a new event
    $block->first( new Config::Crontab::Comment(-data => '## hi mom!') );
    print $_->dump for $block->lines;

=head2 select([%criteria])

Returns a list of B<Event>, B<Env>, or B<Comment> objects from a block
that match the specified criteria. Multiple criteria may be specified.

Field names should be preceded by a hyphen (though without a hyphen
is acceptable too; we use hyphens to avoid the need for quoting keys
and avoid potential bareword collisions).

If not criteria are specified, B<select> returns a list of all lines
in the block (like B<lines>).

Example:

    ## select all events
    for my $event ( $block->select( -type => 'event') ) {
        print $event->dump . "\n";
    }

    ## select events that have the word 'foo' in the command
    for my $event ( $block->select( -type => 'event', -command_re => 'foo') ) {
        print $event->dump . "\n";
    }

=head2 remove(@objects)

Remove B<Config::Crontab::*> objects from this block.

Example:

    ## simple case: you need to get a handle on these objects first
    $block->remove( $obj1, $obj2, $obj3 );

    ## more complex: remove an event from a block by searching
    for my $event ( $block->select( -type => 'event') ) {
        next unless $event->command =~ /\bbackup\b/;  ## look for backup command
        $block->remove($event); last;  ## and remove it
    }

=head2 replace($oldobj, $newobj)

Replaces I<$oldobj> with I<$newobj> within a block. Returns I<$oldobj>
if successful, I<undef> otherwise.

Example:

    ## replace $event1 with $event2 in this block.
    ## '=>' is the same as a comma (,)
    ($event1) = $block->select(-type => 'event', -command => '/bin/foo');
    $event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
    ok( $block->replace($event1 => $event2) );

=head2 up($target_obj), down($target_obj)

These methods move the B<Config::Crontab::*> object up or down within
the block.

If the object is not a member of the block, it will be added to the
block in the first position for B<up> and it will be added to the
block in the last position for B<down>.

Examples:

    $block->up($event);  ## move event up one position in the block

    ## add a new event at the end of the block
    $block->down(new Config::Crontab::Event(-data => '5 2 * * Mon /bin/monday'));

=head2 first(@target_obj), last(@target_obj)

These methods move the B<Config::Crontab::*> object(s) to the first
or last positions in the block.

If the object or objects are not members of the block, they will be
added to the first or last part of the block respectively.

Examples:

    $block->first($comment);  ## move $comment to the first line in this block

    ## add these new events to the end of the block
    $block->last( new Config::Crontab::Comment(-data => '## hi mom!'),
                  new Config::Crontab::Comment(-data => '## hi dad!'), );

=head2 before($look_for, @obj), after($look_for, @obj)

These methods move the B<Config::Crontab::*> object(s) to the position
immediately before or after the I<$look_for> (or reference) object
in the block.

If the objects are not members of the block, they will be added
to the block before or after the reference object. If the reference
object does not exist in the block, the objects will be moved (or
added) to the beginning or end of the block respectively (much the
same as B<first> and B<last>).

    ## simple example
    $block->after($event, $comment);  ## move $comment after $event in this block

=head2 active(boolean)

Activates or deactivates an entire block. If no arguments are given,
B<active> returns true but does nothing, otherwise the boolean used
to activate or deactivate the block is returned.

If you have a series of related crontab lines you wish to comment out
(or uncomment), you can use this handy shortcut to do it. You cannot
deactivate B<Comment> objects (i.e., they will always be comments).

Example:

    $block->active(0);  ## deactivate this block

=head2 nolog(boolean)

This is (currently) a SuSE-specific extension. From B<crontab(5)>:

  If the uid of the owner is 0 (root), he can put a "-" as first
  character of a crontab entry. This will prevent cron from writing a
  syslog message about this command getting executed.

B<nolog> enables adds or removes this hyphen for a given cron event
line (regardless of whether the user is I<root> or not).

Example:

    $block->nolog(1);  ## quiet all entries in this block

=head2 flag(string)

Flags a block or an object inside a block with the specified data. The
data you specify is completely up to you. This can be handy if you
need to operate on many objects at once and don't want to risk pulling
the rug out from under some (i.e., deleting numbered elements from a
list changes the numbering of subsequent objects in the list, which is
probably not what you want).

All normal query operations apply to B<-flag> attributes (e.g.,
B<-flag_re>, B<-flag_nre>, etc).

Example:

    ## delete every other event in this block
    my $count = 0;
    for my $event ( $block->select( -type => 'event' ) ) {
        $event->flag('deleteme!')
          if $count % 2 == 0;
        $count++;
    }

    ## delete all blocks marked as 'deleteme!'
    $block->remove( $block->select( -flag => 'deleteme!' ) );

=head2 dump

Returns a formatted string of the B<Block> object (recursively calling
all its objects' dump methods). A B<Block> dump is newline terminated.

Example:

    print $block->dump;

=cut

############################################################
############################################################

package Config::Crontab::Event;
use strict;
use warnings;
use Carp;

our @ISA = qw(Config::Crontab::Base);

use constant RE_DT        => '(?:\d+|\*)(?:[-,\/]\d+)*';
use constant RE_DTLIST    => RE_DT . '(?:,' . RE_DT . ')*';
use constant RE_DM        => '\w{3}(?:,\w{3})*';
use constant RE_DTELEM    => '(?:\*|' . RE_DTLIST . ')';
use constant RE_DTMOY     => '(?:\*|' . RE_DTLIST . '|' . RE_DM . ')';
use constant RE_DTDOW     => RE_DTMOY;
use constant RE_ACTIVE    => '^\s*(\#*)\s*';
use constant RE_NOLOG     => '(-?)';  ## SuSE-specific extension
use constant RE_SPECIAL   => '(\@(?:reboot|midnight|(?:year|annual|month|week|dai|hour)ly))';
use constant RE_DATETIME  => '(' . RE_DTELEM . ')' .
                          '\s+(' . RE_DTELEM . ')' .
                          '\s+(' . RE_DTELEM . ')' .
                          '\s+(' . RE_DTMOY  . ')' .
                          '\s+(' . RE_DTDOW  . ')';
use constant RE_USER      => '\s+(\S+)';
use constant RE_COMMAND   => '\s+(.+?)\s*$';
use constant SPECIAL      => RE_ACTIVE . RE_NOLOG . RE_SPECIAL  . RE_COMMAND;
use constant DATETIME     => RE_ACTIVE . RE_NOLOG . RE_DATETIME . RE_COMMAND;
use constant SYS_SPECIAL  => RE_ACTIVE . RE_NOLOG . RE_SPECIAL  . RE_USER . RE_COMMAND;
use constant SYS_DATETIME => RE_ACTIVE . RE_NOLOG . RE_DATETIME . RE_USER . RE_COMMAND;

sub init {
    my $self = shift;
    my %args = @_;
    my $rv = 1;

    ## set defaults
    $self->active(1);
    $self->nolog(0);
    $self->system(0);

    $self->special(undef);
    $self->minute('*');
    $self->hour('*');
    $self->dom('*');
    $self->month('*');
    $self->dow('*');
    $self->user('');

    ## get arguments and set new defaults
    $self->system($args{'-system'})     if defined $args{'-system'};  ## -system arg overrides implicits
    unless( $args{'-data'} ) {
	$self->minute($args{'-minute'})     if defined $args{'-minute'};
	$self->hour($args{'-hour'})         if defined $args{'-hour'};
	$self->dom($args{'-dom'})           if defined $args{'-dom'};
	$self->month($args{'-month'})       if defined $args{'-month'};
	$self->dow($args{'-dow'})           if defined $args{'-dow'};

	$self->user($args{'-user'})         if defined $args{'-user'};
	$self->system(1)                    if defined $args{'-user'};

	$self->special($args{'-special'})   if defined $args{'-special'};
	$self->datetime($args{'-datetime'}) if defined $args{'-datetime'};
	$self->command($args{'-command'})   if $args{'-command'};
	$self->active($args{'-active'})     if defined $args{'-active'};
        $self->nolog($args{'-nolog'})       if defined $args{'-nolog'};
    }
    $rv = $self->data($args{'-data'})   if defined $args{'-data'};

    return ( defined $rv ? 1 : undef );
}

## returns the crontab line w/o '(in)?active' pound sign (#)
sub data {
    my $self = shift;
    my $data = '';

    if( @_ ) {
	$data = shift;
	$data = '' unless $data;  ## normalize false values

	my @matches = ();

	## system (user) syntax
	if( $self->system ) {
	    if( @matches = $data =~ SYS_SPECIAL or
		@matches = $data =~ SYS_DATETIME ) {
		my $active = shift @matches;
                my $nolog = shift @matches;
		$self->active( ($active ? 0 : 1) );
                $self->nolog( ($nolog ? 1 : 0) );
		$self->command( pop @matches );
		$self->user( pop @matches );
		$self->datetime( \@matches );
	    }

	    ## not a good -data value
	    else {
		return;
	    }
	}

	## non-system (regular user crontab style) syntax
	else {
	    ## is a command
	    if( @matches = $data =~ SPECIAL or
		@matches = $data =~ DATETIME ) {
		my $active = shift @matches;
                my $nolog = shift @matches;
		$self->active( ($active ? 0 : 1) );
                $self->nolog( ($nolog ? 1 : 0) );
		$self->command( pop @matches );
		$self->user('');
		$self->datetime( \@matches );
	    }

	    ## not a good -data value
	    else {
		return;
	    }
	}
    }

    my $fmt = "%s";
    $fmt .= ( $self->command
	      ? ( $self->system 
		  ? ($self->special ? "\t\t\t\t\t%s" : "\t%s") . ( $self->user ? "\t%s" : '' )
		  : " %s" )
	      : '' );

    return sprintf($fmt, ( $self->command
			   ? ( $self->datetime, ($self->system && $self->user ? $self->user : ()))
			   : () ), $self->command )
}

sub datetime {
    my $self = shift;
    my $data = shift;
    my @matches = ();

    if( $data ) {
	## an array reference: when called from 'data' method
	if( ref($data) eq 'ARRAY' ) {
	    @matches = @$data;

	    ## likely special datetime format (e.g., @reboot, etc.)
	    if( scalar(@matches) == 1 ) {
		$self->special( @matches );
		$self->minute(  '*' );
		$self->hour(    '*' );
		$self->dom(     '*' );
		$self->month(   '*' );
		$self->dow(     '*' );
	    }

	    ## likely standard datetime format (e.g., '6 1 * * Fri', etc.)
	    elsif( scalar @matches ) {
		$self->special( undef);
		$self->minute(  shift @matches );
		$self->hour(    shift @matches );
		$self->dom(     shift @matches );
		$self->month(   shift @matches );
		$self->dow(     shift @matches );
	    }
	    else {
		## empty array ref
		carp "No data in array constructor\n";
		return;
	    }
	}

	## not a reference: when called as a method directly (e.g., 'init' method)
	else {
	    ## special datetime format (@reboot, @daily, etc.)
	    if( @matches = $data =~ RE_SPECIAL ) {
		$self->special( @matches );
		$self->minute(  '*' );
		$self->hour(    '*' );
		$self->dom(     '*' );
		$self->month(   '*' );
		$self->dow(     '*' );
	    }

	    ## standard datetime format ("0 5 * * Fri", etc.)
	    elsif( @matches = $data =~ RE_DATETIME ) {
		$self->special( undef);
		$self->minute(  shift @matches );
		$self->hour(    shift @matches );
		$self->dom(     shift @matches );
		$self->month(   shift @matches );
		$self->dow(     shift @matches );
	    }

	    ## not a valid datetime format
	    else {
		## some bad data
		carp "Bad datetime spec: $data\n";
		return;
	    }
	}
    }

    if( $self->special ) {
	return $self->special;
    }

    my $fmt = ( $self->system 
		? "%s\t%s\t%s\t%s\t%s"
		: "%s %s %s %s %s" );

    return sprintf( $fmt, $self->minute, $self->hour, $self->dom, $self->month, $self->dow);
}

## this is duplicated in AUTOLOAD, but we need to set system also
sub user {
    my $self = shift;
    if( @_ ) {  ## setting a value, set system too
	$self->system($_[0] ? 1 : 0);
	$self->{_user} = shift;
    }
    return ( defined $self->{_user} ? $self->{_user} : '' );
}

sub dump {
    my $self = shift;
    my $rv   = '';

    $rv .= ( $self->active
             ? '' 
             : '#' );
    $rv .= ( $self->nolog
             ? '-'
             : '' );
    $rv .= $self->data;
    return $rv;
}

############################################################
############################################################

=head1 PACKAGE Config::Crontab::Event

This section describes B<Config::Crontab::Event> objects (hereafter
B<Event> objects). A B<Event> object is an abstracted way of dealing
with crontab(5) lines that look like any of the following (see
L<crontab(5)>):

=over 4

=item 5 0 * 3,6,9,12 *  /bin/quarterly_report

=item 0 2 * * Fri  $HOME/bin/cake_reminder

=item @daily  /bin/bar arg1 arg2

=item #30 10 12 * *  /bin/commented out

=item 5 4 * * *  joeuser  /bin/winkerbean

=back

B<Event> objects are lines in the crontab file which trigger an event
at a certain time (or set of times). This includes events that have
been commented out. In B<Event> object terms, an event that has been
commented out is I<inactive>. Events that have not been commented out
are I<active>.

=head2 Terminology

The following description will serve as a terminology guide for this
class:

Given the following crontab event entry:

    5 3 * Apr Sun  /bin/rejoice

we define the following parts of the B<Event> object:

    5 3 * Apr Sun  /bin/rejoice
    -------------  ------------
      datetime       command

We can break down the B<datetime> field into the following parts:

     5      3     *    Apr   Sun
   ------  ----  ---  -----  ---
   minute  hour  dom  month  dow

We might also see an event with a "special" datetime part:

    @daily    /bin/brush --teeth --feet
    --------  -------------------------
    datetime          command

This special datetime field can also be called 'special':

    @daily   /bin/brush --teeth --feet
    -------  -------------------------
    special          command

As of version 1.05, B<Crontab> supports system crontabs, which adds
an extra I<user> field:

    5 3 * Apr Sun  chris  /bin/rejoice
    -------------  -----  ------------
      datetime     user     command

This field is described in L<crontab(5)> on most systems.

These and other methods for accessing and manipulating B<Event>
objects are described in subsequent sections.

=head1 METHODS

This section describes methods available to manipulate B<Event>
objects' creation and attributes.

=head2 new([%args])

Creates a new B<Event> object. You may create B<Event> objects in any
of the following ways:

=over 4

=item Empty

    $event = new Config::Crontab::Event;

=item Partially Populated

    $event = new Config::Crontab::Event( -minute => 0 );

=item Fully Populated

    $event = new Config::Crontab::Event( -minute  => 5,
                                         -hour    => 2,
                                         -command => '/bin/document my_proggie', );

=item System Event

    $event = new Config::Crontab::Event( -minute  => 5,
                                         -hour    => 2,
                                         -user    => 'joeuser',
                                         -command => '/bin/foo --bar=blech', );

=item System Event

    $event = new Config::Crontab::Event( -data   => '30 3 * * 5,6 joeuser /bin/blech',
                                         -system => 1, );

=back

Constructor attributes available in the B<new> method take the same
arguments as their method counterparts (described below), except that
the names of the attributes must have a hyphen ('-') prepended to the
attribute name (e.g., 'month' becomes '-month'). The following is a
list of attributes available to the B<new> method:

=over 4

=item B<-minute>

=item B<-hour>

=item B<-dom>

=item B<-month>

=item B<-dow>

=item B<-special>

=item B<-data>

=item B<-datetime>

=item B<-user>

=item B<-system>

=item B<-command>

=item B<-active>

=back

Each of these attributes corresponds directly to its similarly-named
method.

Examples:

    ## use datetime attribute; using a 'special' string in -datetime is
    ## ok, but the reverse is not true (using a standard datetime string
    ## in -special)
    $event = new Config::Crontab::Event( -datetime => '@hourly',
                                         -command  => '/bin/bar' );


    ## use special attribute
    $event = new Config::Crontab::Event( -special => '@hourly',
                                         -command => '/bin/bar' );


    ## use datetime attribute
    $event = new Config::Crontab::Event( -datetime => '5 * * * Fri',
                                         -command  => '/bin/bar' );


    ## this is an error because '5 * * * Fri' is not one of the special
    ## datetime strings. Currently this does not throw an error, but 
    ## behavior is undefined for an object initialized thusly
    $event = new Config::Crontab::Event( -special => '5 * * * Fri',
                                         -command => '/bin/bar' );


    ## create an inactive Event; default for datetime fields is '*'
    ## the result is the line: "#0 2 * * * /bin/foo" (notice '#')
    $event = new Config::Crontab::Event( -active   => 0,
                                         -minute   => 0,
                                         -hour     => 2,  ## 2 am
                                         -command  => '/bin/foo' );
    ...time passes...
    $event->active(1);  ## now activate that event


    ## let the object do all the hard parsing
    $event = new Config::Crontab::Event( -data => '30 3 * * 5,6 /bin/blech' );
    ...time passes...
    $event->hour(4);  ## change the event from 3:30a to 4:30a

If bogus data is passed to the constructor, it will return I<undef>
instead of an object reference. If there is a possiblility of poorly
formatted data going into the constructor, you should check the object
variable for definedness before using it.

=head2 A note about the datetime fields

B<Event> objects have several ways of setting the datetime fields:

    ## via the special method
    $event->special('@daily');

    ## via datetime
    $event->datetime('@daily');

    ## via datetime
    $event->datetime('0 0 * * *');

    ## via datetime fields
    $event->minute(0);
    $event->hour(0);

    ## via data (takes the command part also)
    $event->data('0 0 * * * /bin/foo');

    ## via the constructor at object instantiation time
    $event = new Config::Crontab::Event( -special => '@reboot' );

The standard datetime fields are: B<minute>, B<hour>, B<dom>,
B<month>, and B<dow>. If you set B<datetime> using a B<special> field,
or if you initialize an B<Event> object using a B<special> datetime
field, the standard datetime fields are reset to '*' and are invalid.

The special datetime field is a single field that takes the place of
the 5 standard datetime fields (see L<crontab(5)> and L</"special">).
Currently, if you set B<special> via the B<special> method, the
standard datetime fields (e.g., B<minute>, B<hour>, etc.) are I<not>
reset; the standard datetime fields are reset to '*' if you set
B<special> via the B<datetime> method.

See other important information in the B<datetime> and B<special>
method descriptions below.

If the B<-data> attribute is present in the constructor when other
attributes are also present, the B<-data> attribute will override all
other attributes.

=head2 minute([digits])

Get or set the minute attribute of the B<Event> object.

Example:

    $event->minute(30);

    print "This event will occur at " . $event->minute . " minutes past the hour\n";

    $event->minute(40);

    print "Now it will occur 10 minutes later\n";

Note from L<crontab(5)>:

    Ranges of numbers are allowed.  Ranges are two numbers separated with a
    hyphen.  The specified range is inclusive.  For example, 8-11 for an
    ``hours'' entry specifies execution at hours 8, 9, 10 and 11.

    Lists are allowed.  A list is a set of numbers (or ranges) separated by
    commas.  Examples: ``1,2,5,9'', ``0-4,8-12''.

    Step values can be used in conjunction with ranges.  Following a range
    with ``/<number>'' specifies skips of the number's value through the
    range.  For example, ``0-23/2'' can be used in the hours field to specify
    command execution every other hour (the alternative in the V7 standard is
    ``0,2,4,6,8,10,12,14,16,18,20,22'').  Steps are also permitted after an
    asterisk, so if you want to say ``every two hours'', just use ``*/2''.

=head2 hour([digits])

Get or set the hour attribute of the B<Event> object.

Example: analogous to B<minute>

Note from L<crontab(5)>: see B</"minute">.

=head2 dom([digits])

Get or set the day-of-month attribute of the B<Event> object.

Example: analogous to B<minute>

Note from L<crontab(5)>:

    Note: The day of a command's execution can be specified by two fields --
    day of month, and day of week.  If both fields are restricted (ie, aren't
    *), the command will be run when either field matches the current time.
    For example,
    ``30 4 1,15 * 5'' would cause a command to be run at 4:30 am on the 1st
    and 15th of each month, plus every Friday.

=head2 month([string])

Get or set the month. This may be a digit (1-12) or a three character
English abbreviated month string (Jan, Feb, etc.).

Note from L<crontab(5)>:

    Names can also be used for the ``month'' and ``day of week'' fields.  Use
    the first three letters of the particular day or month (case doesn't mat-
    ter).  Ranges or lists of names are not allowed.

=head2 dow([string])

Get or set the day of week.

Example: analogous to B<minute>

Note from L<crontab(5)>: see the B</"month"> entry above.

=head2 special([string])

Get or set the special datetime field.

The special datetime field is one of (from L<crontab(5)>):

    string          meaning
    ------          -------
    @reboot         Run once, at startup.
    @yearly         Run once a year, "0 0 1 1 *".
    @annually       (sames as @yearly)
    @monthly        Run once a month, "0 0 1 * *".
    @weekly         Run once a week, "0 0 * * 0".
    @daily          Run once a day, "0 0 * * *".
    @midnight       (same as @daily)
    @hourly         Run once an hour, "0 * * * *".

If you set a datetime via B<special>, this will override anything in
the other standard datetime fields.

While you may use a special datetime string as an argument to the
B<datetime> method, you may I<not> use a standard datetime string in
the B<special> method. Currently there is no error checking on this
field, but behavior is undefined.

The B<datetime> method will return the B<special> value in preference
to any other standard datetime fields. That is, if B<special> has a
value (e.g., '@reboot', etc.) it will be returned in all methods that
return aggregate event data (e.g., B<datetime>, B<dump>, B<data>,
etc.). If B<special> is false, the standard datetime fields will be
returned instead. Thus, you should always check the value of
B<special> before using any of the standard datetime fields:

    if( $event->special ) {
        print $event->special . "\n";
    }

    ## use standard datetime elements
    else {
        print $event->minute . " " . $event->hour ...
    }

If you're presenting the entire datetime field formatted, use the
B<datetime> method (and then you don't have to do any checks on
B<special>):

    ## will print the special datetime value if set,
    ## standard datetime fields otherwise
    print $event->datetime . "\n";

=head2 data([string])

Get or set the raw event line.

Internally, this is how the main B<Config::Crontab> class does its
parsing: it iterates over the crontab file and hands each line off to
the B<data> method for further parsing.

Example:

    $event->data("#0 2 * * * /bin/foo");

    ## prints "inactive (/bin/foo): 0 2 * * *";
    print ( $event->active ? '' : 'in' ) . 'active ' 
        . '(' . $event->command . '): " 
        . $event->datetime;

=head2 datetime([string])

Get or set the datetime fields of an event.

Possible datetime fields are either a special datetime format (e.g.,
@daily, @weekly, etc) B<or> a standard datetime format (e.g., "0 2 *
* Mon" is standard).

B<datetime> is often a convenient shortcut for parsing a datetime
field if you're not precisely sure what's in it (but are sure that
it's either a special datetime field or a standard datetime field):

    $event->datetime($some_string);

While you may pass a special datetime field into B<datetime>, you may
B<not> pass a standard field into the B<special> method. Currently,
the object will not complain, and may even work in most cases, but the
behavior is undefined and will likely become more strict in the
future.

=head2 user([string])

Get or set the user part of a I<system> B<event> object.

Example:

    $event->user('joeuser');

The B<user> field is only accessible when the crontab object was
created or parsed with B<system> mode enabled (see L</"system">
above).

=head2 system([boolean])

When set, will parse a B<-data> string looking for a username before
the command as described in L<crontab(5)>.

Example:

    $event->system(1);
    $event->data('0 2 * * * joeuser /bin/foo --args');

This will set the user as 'joeuser' and the command as '/bin/foo
--args'. Notice that if you pass bad data, the B<Event> parser really
can't help since the I<user> (including '/E<lt>login-classE<gt>')
syntax is now supported as of version 1.05:

    $event = new Config::Crontab::Event( -data   => '2 5 * * * /bin/foo --args',
                                         -system => 1 );

The B<Event> object will have '/bin/foo' as its user and '--args' as
its command. While things will usually work out when you write to
file, you definitely won't get what you're expecting if you grok the
I<command> field.

=head2 command([string])

Get or set the command part of a B<Event> object.

Example:

    $event->command('/bin/foo with args here');

=head2 active([boolean])

Get or set whether the B<Event> object is active. In practical terms,
this simply inserts a pound sign before the datetime fields when
accessing the B<dump> method. It is only used implicitly in B<dump>,
but may be accessed separately whenever convenient.

    print ( $event->active ? '' : '#' ) . $event->data . "\n";

is the same as:

    print $event->dump . "\n";

=head2 dump

Returns a formatted string of the B<Event> object. This method is
called implicitly when flushing to disk in B<Config::Crontab>. It is
not newline terminated.

Example:

    print $event->dump . "\n";

=cut

############################################################
############################################################

## env objects are a few lines of comments followed by a variable assignment
package Config::Crontab::Env;
use strict;
use warnings;

our @ISA = qw(Config::Crontab::Base);

use constant RE_ACTIVE   => '^\s*(\#*)\s*';
use constant RE_VAR      => q!(["']?[^=]+?['"]?)\s*=\s*(.*)$!;
use constant RE_VARIABLE => RE_ACTIVE . RE_VAR;

sub init {
    my $self = shift;
    my %args = @_;

    $self->active(1);

    $self->active($args{'-active'})  if defined $args{'-active'};
    $self->name($args{'-name'})      if $args{'-name'};
    $self->value($args{'-value'})    if defined $args{'-value'};

    my $rv = 1;
    if( defined $args{'-data'} ) {
	$rv = $self->data($args{'-data'});
    }

    return ( defined $rv ? 1 : undef );
}

sub data {
    my $self = shift;
    my $data = '';

    if( @_ ) {
	$data = shift;
	$data = '' unless $data;  ## normalize false values

	my @matches = ();
	if( @matches = $data =~ RE_VARIABLE ) {
	    my $active = shift @matches;
	    $self->active( ($active ? 0 : 1) );
	    $self->name(   shift @matches );
	    $self->value(  shift @matches );
	}

	## not a valid Env object
	else {
	    return;
	}
    }

    return ( $self->name 
	     ? $self->name . '=' . $self->value 
	     : $self->name );
}

sub inactive {
    my $self = shift;
    return ( $self->active ? 0 : 1 );
}

sub dump {
    my $self = shift;
    my $ret  = '';
    
    if( $self->name ) {
	$ret .= ( $self->active
		  ? ''
		  : '#' );
    }

    $ret .= $self->data;
}

############################################################
############################################################

=head1 PACKAGE Config::Crontab::Env

This section describes B<Config::Crontab::Env> objects (hereafter
B<Env> objects). A B<Env> object is an abstracted way of dealing with
crontab lines that look like any of the following (see L<crontab(5)>):

    name = value

From L<crontab(5)>:

    the spaces around the equal-sign (=) are optional, and any
    subsequent non-leading spaces in value will be part of the value
    assigned to name.  The value string may be placed in quotes
    (single or double, but matching) to preserve leading or trailing
    blanks.  The name string may also be placed in quote (single or
    double, but matching) to preserve leading, traling or inner
    blanks.

Like B<Event> objects, B<Env> objects may be I<active> or I<inactive>,
the difference being an I<inactive> B<Env> object is commented out:

    #FOO=bar

=head2 Terminology

Given the following crontab environment line:

    MAILTO=joe

we define the following parts of the B<Env> object:

    MAILTO        =        joe
    ======  ============  =====
     name   (not stored)  value

These and other methods for accessing and manipulating B<Event>
objects are described in subsequent sections.

=head1 METHODS

=head2 new([%args])

Creates a new B<Env> object. You may create B<Env> objects any of the
following ways:

=over 4

=item Empty

    $env = new Config::Crontab::Env;

=item Partially Populated

    $env = new Config::Crontab::Env( -value => 'joe' );

=item Fully Populated

    $env = new Config::Crontab::Env( -name  => 'FOO',
                                     -value => 'blech' );

=back

Constructor attributes available in the B<new> method take the same
arguments as their method counterparts (described below), except that
the names of the attributes must have a hyphen ('-') prepended to the
attribute name (e.g., 'value' becomes '-value'). The following is a
list of attributes available to the B<new> method:

=over 4

=item B<-name>

=item B<-value>

=item B<-data>

=item B<-active>

=back

Each of these attributes corresponds directly to its similarly-named
method.

Examples:

    ## use name and value
    $env = new Config::Crontab::Env( -name  => 'MAILTO',
                                     -value => 'joe@schmoe.org' );

    ## parse a whole string
    $env = new Config::Crontab::Env( -data => 'MAILTO=joe@schmoe.org' );

    ## use name and value to create an inactive object
    $env = new Config::Crontab::Env( -active => 0,
                                     -name   => 'MAILTO',
                                     -value  => 'mike', );
    $env->active(1);  ## now activate it

    ## create an object that will unset the environment variable
    $env = new Config::Crontab::Env( -name => 'MAILTO' );

    ## another way
    $env = new Config::Crontab::Env( -data => 'MAILTO=' );

    ## yet another way
    $env = new Config::Crontab::Env;
    $env->name('MAILTO');

If bogus data is passed to the constructor, it will return I<undef>
instead of an object reference. If there is a possiblility of poorly
formatted data going into the constructor, you should check the object
variable for definedness before using it.

If the B<-data> attribute is present in the constructor when other
attributes are also present, the B<-data> attribute will override all
other attributes.

=head2 name([string])

Get or set the object name.

Example:

    $env->name('MAILTO');

=head2 value([string])

Get or set the value associated with the name attribute.

Example:

    $env->value('tom@tomorrow.org');

    print "The value for " . $env->name . " is " . $env->value . "\n";

=head2 data([string])

Get or set a raw environment line.

Example:

    $env->data('MAILTO=foo@bar.org');

    print "This object says: " . $env->data . "\n";

=head2 active([boolean])

Get or set whether the B<Env> object is active. In practical terms,
this simply inserts a pound sign before the B<name> field when
accessing the B<dump> method. It may be used whenever convenient.

    print $env->dump . "\n";

is the same as:

    print ( $env->active ? '' : '#' ) . $env->data . "\n";

=head2 dump

Returns a formatted string of the B<Env> object. This method is called
implicitly when flushing to disk in B<Config::Crontab>. It is not
newline terminated.

    print $env->dump . "\n";

=cut

############################################################
############################################################

## comment objects are empty lines (lines containing only whitespace)
## or lines beginning with # and which do not match an event or
## environment pattern
package Config::Crontab::Comment;
use strict;
use warnings;

our @ISA = qw(Config::Crontab::Base);

sub init {
    my $self = shift;
    my %args = ( @_ == 1 ? ('-data' => @_) : @_ );
    my $data = '';

    if( exists $args{'-data'} ) {
	$data = $args{'-data'};
    }

    ## no '-data' tag, just the data
    elsif( @_ ) {
	$data = shift;
    }

    chomp $data if $data;

    my $rv = $self->data($data);

    return ( defined $rv ? 1 : undef );
}

sub data {
    my $self = shift;
    my $data = '';

    if( @_ ) {
	$data = shift;
	$data = '' unless $data;  ## normalize false values

	unless( $data =~ /^\s*$/ || $data =~ /^\s*\#/ ) {
	    return;
	}

	$self->{'_data'} = $data;
    }

    return ( defined $self->{'_data'} ? $self->{'_data'} : $data );
}

############################################################
############################################################

=head1 PACKAGE Config::Crontab::Comment

This section describes B<Config::Crontab::Comment> objects (hereafter
B<Comment> objects). A B<Comment> object is an abstracted way of
dealing with crontab comments and whitespace (blank lines or lines
that consist only of whitespace).

=head1 METHODS

=head2 new([%args])

Creates a new B<Comment> object. You may create B<Comment> objects in
any of the following ways:

=over 4

=item Empty

    $comment = new Config::Crontab::Comment;

=item Populated

    $comment = new Config::Crontab::Comment( -data => '# this is a comment' );

and an alternative:

    $comment = new Config::Crontab::Comment( '# this is a constructor shortcut' );

=back

Constructor attributes available in the B<new> method take the same
arguments as their method counterparts (described below), except that
the names of the attributes must have a hyphen ('-') prepended to the
attribute name (e.g., 'data' becomes '-data'). The following is a list
of attributes available to the B<new> method:

=over 4

=item B<-data>

=back

Each of these attributes corresponds directly to its similarly-named
method.

Examples:

    ## using data
    $comment = new Config::Crontab::Comment( -data => '## a nice comment' );

    ## using data method
    $comment = new Config::Crontab::Comment;
    $comment->data('## hi Mom!');

If bogus data is passed to the constructor, it will return I<undef>
instead of an object reference. If there is a possiblility of poorly
formatted data going into the constructor, you should check the object
variable for definedness before using it.

As a shortcut, you may omit the B<-data> label and simply pass the
comment itself:

    $comment = new Config::Crontab::Comment('## this space for rent or lease');

=head2 data([string])

Get or set a comment.

Example:

    $comment->data('## this is not the comment you are looking for');

=head2 dump

Returns a formatted string of the B<Comment> object. This method is
called implicitly when flushing to disk in B<Config::Crontab>. It is
not newline terminated.

=cut

############################################################
############################################################

## a virtual base class for top-level container classes
package Config::Crontab::Container;
use strict;
use warnings;
use Carp;

sub up {
    my $self = shift;
    my $targ = shift;

    return unless ref($targ);

    my @objs = $self->elements;

    my $found;
    for my $i ( 0..$#objs ) {
	if( $objs[$i] == $targ ) {
	    ($objs[$i], $objs[$i-1]) = ($objs[$i-1], $objs[$i])  ## swap...
	      unless $i == 0;                                    ## unless already first
	    $found = 1;
	    last;
	}
    }

    unshift @objs, $targ unless $found;
    $self->elements( \@objs );
}

sub down {
    my $self = shift;
    my $targ = shift;

    return unless ref($targ);

    my @objs = $self->elements;

    my $found;
    for my $i ( 0..$#objs ) {
	if( $objs[$i] == $targ ) {
	    ($objs[$i], $objs[$i+1]) = ($objs[$i+1], $objs[$i])  ## swap...
	      unless $i == $#objs;                               ## unless already last
	    $found = 1;
	    last;
	}
    }

    push @objs, $targ unless $found;
    $self->elements( \@objs );
}

sub first {
    my $self = shift;
    my @targ = grep { ref($_) } @_;

    $self->remove(@targ);
    $self->elements( [@targ, $self->elements] );
}

sub last {
    my $self = shift;
    my @targ = grep { ref($_) } @_;

    $self->remove(@targ);
    $self->elements( [$self->elements, @targ] );
}

sub before {
    my $self = shift;
    my $ref  = shift;
    my @targ = @_;

    $self->remove(@targ);

    my @objs  = ();
    my $found = 0;
    for my $obj ( $self->elements ) {
	if( ! $found && $ref && ($obj == $ref) ) {
	    push @objs, @targ;
	    $found = 1;
	}
	push @objs, $obj;
    }

    unshift @objs, @targ unless $found;

    $self->elements(\@objs);
}

sub after {
    my $self = shift;
    my $ref  = shift;
    my @targ = @_;

    $self->remove(@targ);

    my @objs  = ();
    my $found = 0;
    for my $obj ( $self->elements ) {
	push @objs, $obj;
	if( ! $found && ($obj == $ref) ) {
	    push @objs, @targ;
	    $found = 1;
	}
    }

    push @objs, @targ unless $found;

    $self->elements(\@objs);
}

sub replace {
    my $self = shift;
    my $old  = shift;
    my $new  = shift;

    return unless ref($old) && ref($new);

    my @objs = $self->elements;
    my $found;
    for my $i ( 0..$#objs ) {
	if( $objs[$i] == $old ) {
	    $objs[$i] = $new;
	    $found = 1;
	    last;
	}
    }

    $self->elements( \@objs );
    return ( $found ? $old : undef );
}

############################################################
############################################################

## the virtual base class of all Config::Crontab classes
package Config::Crontab::Base;
use strict;
use warnings;
use Carp;

our $AUTOLOAD;

sub new {
    my $self  = { };
    my $proto = shift;
    my $class = ref($proto) || $proto;

    bless $self, $class;

    my $rv = $self->init(@_);
    $self->flag('');

    return ( $rv ? $self : undef );
}

## boolean: if returns false, 'new' will return undef, $self otherwise
sub init {
    my $self = shift;
    my %args = @_;

    return 1;
}

sub dump {
    my $self = shift;
    return $self->data;  ## this will AUTOLOAD if not present
}

sub flag {
    my $self = shift;
    $self->{'_flag'} = shift if @_;
    return $self->{'_flag'};
}

sub AUTOLOAD {
    my $self = shift or return;

    my $sub = $AUTOLOAD;
    $sub =~ s/^.*:://;
    return if $sub eq 'DESTROY';

    my $foni;

    ## new accessor
    if( $sub =~ /^(\w+)$/ ) {
	my $subname = $1;
	$foni = sub {
	    my $self = shift;
	    $self->{"_$subname"} = shift if @_;
	    return ( defined $self->{"_$subname"} ? $self->{"_$subname"} : '' );
	};
    }

    else {
	croak "Undefined subroutine '$sub'";
    }

    ## do magic
  SYMBOLS: {
	no strict 'refs';
	*$AUTOLOAD = $foni;
    }
    unshift @_, $self;  ## put me back on call stack
    goto &$AUTOLOAD;    ## jump to me
}

1;
__END__

############################################################
############################################################

=head1 CAVEATS

=over 4

=item *

Thanks to alert reader "Kirk" (no lastname given), we learn that some
versions of Debian linux's "crontab -l" does not strip the internal
crontab(1) comments (e.g., "DO NOT EDIT THIS FILE" and subsequent
meta-data) at the start of user crontabs.

This means that if you use Config::Crontab to edit a user's crontab
file, those three headers will be added to the Config::Crontab object,
and written back out again, and crontab(1) will add its own comments,
effectively adding 3 comment lines each time you edit the crontab.

You may use this little heuristic as a starting point for stripping
those comments:

    my $ct = new Config::Crontab;
    $ct->read;
    
    ## make "crontab -l | crontab -" idempotent for Debian
    for my $line ( grep { defined } ($ct->select(-type => 'comment'))[0..2] ) {
        if( $line->data =~ qr(^# (?:DO NOT EDIT|[\(]\S+ installed|[\(]Cron version)) ) {
            $ct->remove($line);
        }
    }
    
    ...
    
    $ct->write;

=item *

As of version 1.05, B<Config::Crontab> supports the user field (with
optional ':group' and '/E<lt>login-classE<gt>') via the B<-system>
initialization parameter, B<system> B<Event> method, or B<user>
B<Event> method and B<Event> initialization parameter.

=item *

You will not get good results adding non-B<Block> objects to a
B<Crontab> object directly:

    $ct->last( new Config::Crontab::Event(-data => '1 2 3 4 5 /bin/friday') );

This doesn't do anything (and shouldn't). You should be adding
B<Block> objects to the B<Crontab> object instead:

    $block->last(new Config::Crontab::Event(-data => '1 2 3 4 5 /bin/friday'));
    $ct->last($block);

or the slightly more economical:

    $ct->last( new Config::Crontab::Block(-data => '1 2 3 4 5 /bin/friday') );

This is nice since the B<Block> constructor parses its B<-data>
parameter as raw data and creates all the necessary objects to
populate itself. The downside of this last approach is that you don't
get a handle to your block if you need to make later changes. It can
be easily got, however, since we appended it to the end (using
B<last>) of the B<Crontab> object:

    $block = ($ct->blocks)[-1];

=back

=head1 TODO

=over 4

=item *

a better query language that would allow for boolean operators and
more complexity (SQL, maybe? I've seen that in one of Ken William's
modules using Parse::RecDescent)

=item *

would be cool to use some fancier datetime parsers that can guess when
an event will occur and allow that in our select methods.  I've seen
one of those on CPAN but didn't look too closely. Maybe someone will
use both if they need both.

=item *

need copy constructors (and clone method)

=item *

need to be more strict about strict (it should do more things, enable
more regex checks on data, etc.)

=item *

some pretty-print options for B<dump>

=item *

alternative crontab syntax support (e.g. SysV-syntax used by Solaris
doesn't support weekday 7 or 3-letter month and day name abbreviations)

B<Config::Crontab> will support SysV-syntax since it is a proper subset
of Vixie cron syntax, but you will need to necessarily perform your
own syntax checking and omit elements unique to Vixie cron in your UI.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Juan Jose Natera Abreu (naterajj@yahoo.com) for unsafe POSIX::tmpnam
alert; now using File::Temp.

=back

=head1 SEE ALSO

cron(8), crontab(1), crontab(5)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
