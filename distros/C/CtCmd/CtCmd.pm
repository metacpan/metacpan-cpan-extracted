##########################################################################
#                                                                        #
# © Copyright IBM Corporation 2001, 2013 All rights reserved.            #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# William Spurlin - Creation and framework                               #
#                                                                        #
##########################################################################

package ClearCase::CtCmd;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(cleartool);
$ClearCase::CtCmd::VERSION = '1.11';
bootstrap ClearCase::CtCmd $VERSION;


sub new {
  my $object = shift;
  my $this = {};
  %$this = @_;
  bless $this, $object;
  $this->{'status'} = 0;
  return $this;
}

sub status{
    my $this = shift;
    return $this->{'status'}
}

*cleartool = \&exec;


1;
__END__

=head1 NAME

ClearCase::CtCmd - Perl extension for Rational ClearCase

=head1 PLATFORMS/VERSIONS

See INSTALL for a list of supported platforms and ClearCase versions.

=head1 SYNOPSIS

    use ClearCase::CtCmd;

    @aa = ClearCase::CtCmd::exec("ls /vobs/public");

    my $status_now = $aa[0];

    $stdout = $aa[1];

    @aa = ClearCase::CtCmd::exec("ls /nowheresville");

    $error = $aa[2];

    die $error if $status_now;

    my $inst = ClearCase::CtCmd->new();

    my $pvob="\@/var/tmp/bills_1_pvob";

    ($status_now,my $stream)=$inst->exec(des,-fmt,"%Ln,dbid:2390".$pvob);

    ($status_now,my $stream,my $err) = $inst->exec(deliver,-to,wjs_integ_manhattan_y,-stream,$stream.$pvob,-complete,-force);

    die $err if $inst->status();

    use ClearCase::CtCmd "cleartool";

    @aa = cleartool(qw(lsproj -s -invob /vobs/projects));

    $x = ClearCase::CtCmd::exec("ls /nowheresville");

    die $x if &ClearCase::CtCmd::cmdstat;

=head1 DESCRIPTION


B<I/O>

ClearCase::CtCmd::exec() takes either a string or a list  as an input argument, and, in array context, returns a three element Perl array as output.  


The first output element is a status bit containing 0 on success, 1 on failure.The second output element is a scalar string corresponding to stdout, if any.  The third element contains any error message corresponding to output on stderr.  
In scalar context, ClearCase::CtCmd::exec() returns output corresponding to either stdout or stderr, as appropriate.  ClearCase::CtCmd::cmdstat() will return 0 upon success, 1 upon failure of the last previous command.

ClearCase::CtCmd->new()  may be used to create an instance of ClearCase::CtCmd.  There are three possible construction variables:

ClearCase::CtCmd->new(outfunc=>0,errfunc=>0,debug=>1);

Setting outfunc or errfunc to zero disables the standard output and error handling functions.  Output goes to stdout or stderr. The size of the output array is reduced correspondingly.


B<Exit Status>

I<Commands Performing a Single Operation>


For commands that perform only one operation if the first element has any content, the second element will be empty, and vice-versa.

Upon the return of class method exec:

    ($a,$b,$c) = ClearCase::CtCmd::exec( some command );   

the first returned element $a contains the status of "some command":  0 upon success, 1 upon failure.  

In scalar context  ClearCase::CtCmd::cmdstat() will return 0 upon success, 1 upon failure of the last previous command.

Upon the return of instance method exec:

    $x = ClearCase::CtCmd-new; $x->exec( some command );
  
instance method status() is available: 

 $status = $x->status();

status() returns 0 upon success, 1 upon failure.

I<Commands Performing Multiple Operations>

For commands that perform more than one operation, if an operation succeeds and an operation also fails, there may be content in both the second and third returned elements.  If any operation fails the first output element and the status() method will return 1.  If all operations succeed the first output element and the status() method will return 0.


=head1 SUPPORTED CLEARCASE COMMANDS

 

The module supports all cleartool commands except "-ver" and "-verall", including all UCM commands and all format strings for command output.

=head1 QUOTING

 

B<ClearCase::CtCmd::exec( list ) >

Since in its initial lexical scanning phase the Perl tokenizer
will treat single characters preceded by a hyphen as 
file test operators ( C<-e>,  C<-s>,  C<-l> etc.), such constructs must 
be quoted when passed as arguments to ClearCase::CtCmd::exec().
Similar considerations apply to the % character, used in
cleartool format conversion strings.  Otherwise list form arguments to
ClearCase::CtCmd->exec() do not need to be quoted, with the caveat that if
there is a name conflict between a cleartool command and a function 
unexpected results will follow unless the cleartool command is quoted,
e. g., 'desc' will protect function desc().


The qw operator eliminates the need to separately quote elements:


I<Example of list form with the qw operator>

 use ClearCase::CtCmd;
 $x = ClearCase::CtCmd->new();
 @aa = $x->exec(qw(lsproj -fmt %Ad\t Fanhattan@/var/tmp/bills_1_pvob xxx Yanhattan@/var/tmp/bills_1_pvob)); 
 print map $n++." $_\n", @aa

 0 1
 1 219   258
 2 ClearCase::CtCmd: Error: project not found: "xxx".


In the above example the '%' is unprotected except by the qw operator. The age in days of two projects is returned, corresponding to the use of the "%Ad" format conversion string.  An error message and error status are also returned because of the non-existence of project 'xxx'.



I<Examples of the single-letter switch condition:>

1.  Succeeds.


 use ClearCase::CtCmd;
 $i = A ;
 @aa = ClearCase::CtCmd::exec("lsproj","-s",-invob,"/var/tmp/bills_1_pvob");
 for(@aa){s/\n/\t/g; print $i++,"\t",$_,"\n"};'
 
 A       0
 B       Ranhattan       Yanhattan       Fanhattan
 C

2.  Fails.


 use ClearCase::CtCmd;
 $i = A;
 @aa = ClearCase::CtCmd::exec("lsproj",-s,-invob,"/var/tmp/bills_1_pvob");
 for(@aa){s/\n/\t/g; print $i++,"\t",$_,"\n"};

 A       1
 B
 C       noname: Error: project not found: "".   noname: Error: project not found: "-invob".     noname: Error: project not found: "/var/tmp/bills_1_pvob".



=head1 CONTRIBUTORS


Thanks to Alan Burlison and David Boyce for many helpful suggestions.

=head1 AUTHOR

Rational Software

=head1 SEE ALSO

perl(1).

=cut
