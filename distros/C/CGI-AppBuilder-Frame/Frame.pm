package CGI::AppBuilder::Frame;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;

our $VERSION = 1.001;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(frame_set frameset
                   );
our %EXPORT_TAGS = (
    frame => [qw(frame_set frameset)],
    all  => [@EXPORT_OK]
);

use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:all);
use CGI::AppBuilder::Table qw(:all);

=head1 NAME

CGI::AppBuilder::Frame - Configuration initializer 

=head1 SYNOPSIS

  use CGI::AppBuilder::Frame;

  my $ab = CGI::AppBuilder::Frame->new(
     'ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my ($q, $ar, $ar_log) = $ab->start_app($0, \%ARGV);
  print $ab->disp_form($q, $ar); 

=head1 DESCRIPTION

This class provides methods for reading and parsing configuration
files. 

=cut

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head2 frame_set ($q, $fr, $pr)

Input variables:

  $fr - frame set definiton array reference. The $fr contains two
        elements [$hr, $ar]: 
        $hr - a hash ref containing the frame set attributes
        $ar - a array ref containing hash references defining each
              frames in the frame set.
  $pr  - tag attribute array ref. It contains three elements:
    class - CSS class name
    attr  - attribute string such as 'width=5 onChange=js_func'
    hr    - hash ref with key and value pairs. This will be obtained
            from $fr for each frame set and frame.
    pretty - whether to add line breaks 

Variables used or methods called:

  CGI::AppBuilder::Table
    html_tag - generate HTML tags
  CGI::AppBuilder::Message
    echo_msg - display message

How to use:

The following shows how to define the frame array ($fr): 

  +-+----+    The following defines the left layout:
  | | T  |    
  | +----+    [{cols=>"150,*"},[     
  | |    |       {src=>"left.htm",name=>"L"},  
  |L| C  |      [{rows=>"100,*,50"},[           
  | |    |         {src=>"top.htm",name=>"T"},   
  | |----|         {src=>"main.htm",name=>"C"},
  | | B  |         {src=>"bottom.htm",name=>"B"}]]]
  +-+----+    ]

In YAML, here is how it looks like:

  ---
  cols: 150,\*
    - src: left.htm
      name: L
    - rows: 100,\*,50
      - src: top.htm
        name: T
      - src: main.htm
        name: C
      - src: bottom.htm
        name: B
  ...

  +-+------+  The following defines the left layout:
  | |  T   |  
  | +----+-+  [{cols=>"150,*"},[     
  | |    | |     {src=>"left.htm",name=>"L"},  
  |L| C  |R|     [{rows=>"100,*,50"},[           
  | |    | |       {src=>"top.htm",name=>"T"},   
  | |    | |       [{cols=>"*,100"},[
  | |----+-+         {src=>"main.htm",name=>"C"},
  | |      |         {src=>"right.htm",name=>"R"}] ] ],
  | |   B  |       {src=>"bottom.htm",name=>"B"}]]
  +-+----+-+  ]

In YAML, here is how it looks like:

  ---
  cols: 150,\*
    - src: left.htm
      name: L
    - rows: 100,\*,50
      - src: top.htm
        name: T
      - cols: \*,100
        - src: main.htm
          name: C
        - src: right.htm
          name: R
      - src: bottom.htm
        name: B
  ...

Here is the testing codes: 

  my $fr = [{cols=>"150,*"},[
            {src=>"left.htm",name=>"L"},
           [{rows=>"100,*,50"},[
               {src=>"top.htm",name=>"T"},
               {src=>"main.htm",name=>"C"},
               {src=>"bottom.htm",name=>"B"}]
           ]]
         ];
  my $pr = {pretty=>1};
  print $obj->frame_set($fr,$pr);
  # the following is the result:

  <FRAMESET cols='150,*'>
    <FRAME src='left.htm' name='L'>
    <FRAMESET rows='100,*,50'>
      <FRAME src='top.htm' name='T'>
      <FRAME src='main.htm' name='C'>
      <FRAME src='bottom.htm' name='B'>
    </FRAMESET>
  </FRAMESET>

  $pr->{_frameset_count} = 0;  # reset frame set counter
  my $f2 = [ {cols=>"150,*"},[
             {src=>"left.htm",name=>"L"},
            [{rows=>"100,*,50"},[
               {src=>"top.htm",name=>"T"},
              [{cols=>"*,100"},[
                 {src=>"main.htm",name=>"C"},
                 {src=>"right.htm",name=>"R"}]
              ],
               {src=>"bottom.htm",name=>"B"}]
            ]]
     ];
  print $obj->frame_set($f2,$pr);
  # the following is the result:

  <FRAMESET cols='150,*'>
    <FRAME src='left.htm' name='L'>
    <FRAMESET rows='100,*,50'>
      <FRAME src='top.htm' name='T'>
      <FRAMESET cols='*,100'>
        <FRAME src='main.htm' name='C'>
        <FRAME src='right.htm' name='R'>
      </FRAMESET>
      <FRAME src='bottom.htm' name='B'>
    </FRAMESET>
  </FRAMESET>

Return: HTML codes.

This method generates HTML codes based on the information provided.
This method is also called <I>frameset</I>.

=cut

sub frameset {
    my $s = shift;
    return $s->frame_set(@_); 
}

sub frame_set {
    my $s = shift;
    my ($q, $fr, $pr) = @_;
    if ($fr && ref($fr) !~ /ARRAY/) { 
      $s->echo_msg(ref($fr) . " Frame set is not in ARRAY",1);  
      return; 
    }
    $pr = {} if ! defined($pr) || ! $pr;
    my ($p, $v) = (@$fr); 
    $s->echo_msg("Frame set attribute is not defined.", 2)
         if ref($p) !~ /HASH/; 
    $pr->{hr} = $p; 
    ++$pr->{_frameset_count};
    my ($t,$idt) = ("", "  "); 
    $t .= $idt x ($pr->{_frameset_count}-1) if $pr->{_frameset_count}>1;
    $t .= $s->html_tag('frameset',$pr);
    # $t .= "\n" if exists $pr->{pretty} && $pr->{pretty}; 
    foreach my $k (@$v) {
        $pr->{hr} = $k; 
        if (ref($k) =~ /ARRAY/) { 
            $t .= $s->frame_set($q,$k,$pr); 
            --$pr->{_frameset_count};
            next;
        }
        $s->echo_msg("Frame attribute is not defined.", 2)
            if ref($k) !~ /HASH/; 
        $t .= $idt x $pr->{_frameset_count}; 
        $t .= $s->html_tag('frame',$pr);
    }
    if ($pr->{_frameset_count} > 1) { 
        $t .= ($idt x ($pr->{_frameset_count}-1)) . "</FRAMESET>\n"; 
    } else { 
        $t .= "</FRAMESET>\n"; 
    }
    return $t;
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version includes the frame_set method. 

=item * Version 0.20

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::Getopt, File::Xcopy,
CGI::AppBuilder, CGI::AppBuilder::Message, CGI::AppBuilder::Log,
CGI::AppBuilder::Config, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

