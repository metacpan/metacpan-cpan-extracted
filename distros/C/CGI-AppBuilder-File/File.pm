package CGI::AppBuilder::File;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI qw(:standard);
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use File::Copy;
use File::Basename;

our $VERSION = 0.10;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(disp_file copy_file prt_bin_file
                   );
our %EXPORT_TAGS = (
    file => [qw(disp_file copy_file)],
    all  => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::File - File module

=head1 SYNOPSIS

  use CGI::AppBuilder::File;

  my $ab = CGI::AppBuilder::File->new(
     'ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my ($q, $ar, $ar_log) = $ab->start_app($0, \%ARGV);
  my $fn = 'test.txt';
  print $ab->disp_file($fn, $ar); 

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

=head2 disp_file ($fn, $ar)

Input variables:

  $q    - CGI object
  $ar 	- array ref for parameters
  $fn	- file name
  $rt   - whether to return the text to caller
  $st	- search text

Variables used or routines called:
  N/A

How to use:

  print     $self->disp_file($ar,'test.txt');
  my $txt = $self->disp_file($ar,'test.txt',1);

Return: none or text

=cut

sub disp_file {
  my ($s,$q,$ar,$fn,$rt,$st) = @_;

  # $s->disp_param($ar);
    
  my $prg = 'AppBuilder::File->disp_file'; 
  my $f1 = $s->set_param('f', $ar); 
  $fn = (!$fn && $f1)? $f1 : '';
  my $txt_ext = 'txt|log|sql|pl|csv|lis|ddl|trc|cmd|bat|pm|trm|htm|html';  

  if (!$fn) {
    $s->echo_msg("ERR: ($prg) no files to be displayed.", 0);
    return; 
  }
  my ($fname, $path, $sfx) = fileparse($fn,qr{\..*});
  if ($fn !~ /($txt_ext)$/i) { 
    $s->prt_bin_file($fn);
    return;
  }
  
  my $f_html = ($sfx =~ /(htm|html)$/i) ? 1 : 0; 
  my $t = ($f_html) ? '' : "<center><b>$fname$sfx</b></center>\n<hr>\n<pre>\n";
  
  open FILE, "<$fn" or die "ERR: could not open $fn: $!\n";
  while (<FILE>) {
    next if $_ =~ /^\s*$/;
    if (! $f_html) {
      s/</\&lt;/g; s/>/\&gt;/g;
      s//^L/g;    # change the non-printable char to printable char
    } 
    if ($st) { 
      s/($st)/<font color=red>$1<\/font>/ig; 
    }
    my ($tt, $i, $n) = ($_, -1, 120); 
#    if (length($tt) < $n) {
#      $t .= $tt; next;
#    }
#    while (length($tt) >= $n) {
#      ++$i;
#      if ($i) {     # the second line
#        $t .= " "x4 . substr($tt, 0, $n) . "\n";
#      } else {      # first line
#        $t .= substr($tt, 0, $n) . "\n";
#      }
#      $tt = substr($tt, $n);
#    }
#    $t .= " "x4 . $tt;
     $t .= $tt; 
  }
  close FILE;
  $t = "<pre>\n$t</pre>\n<hr>\n" if !$f_html;
  return $t if $rt; 
  print $t;
}


=head2 prt_bin_file ($fn)

Input variables:

  $fn	- file name

Variables used or routines called:
  N/A

How to use:

  print     $self->prt_bin_file('test.tar');

Return: none or text

=cut

sub prt_bin_file {
    my ($s, $fn) = @_;

  my $cr = {
    '.xls'  => 'application/msexcel',
  #  '.csv' => 'application/msexcel',
    '.doc'  => 'application/msword',
    '.rtf'  => 'application/msword',
    '.pdf'  => 'application/pdf',
    '.vsd'  => 'application/visio',  
    '.jpg'  => 'image/jpeg',
    '.gif'  => 'image/gif',
    '.txt'  => 'text/html',
    '.html' => 'text/html',
    '.htm'  => 'text/html',
    '.ddl'  => 'text/html',
    '.trc'  => 'text/html',
    '.xml'  => 'text/xml',  
    '.ppt'  => 'application/powerpoint',  
    '.pptx' => 'application/powerpoint',  
    '.tgz'  => 'application/tar',    
    '.mov'  => 'video/quicktime',  
    '.erwin'  => 'application/ERwin',
    '.zip'  => 'application/tar',    
    };

    my ($fname, $path, $sfx) = fileparse($fn,qr{\..*$});
    my $ct = (exists $cr->{$sfx}) ? $cr->{$sfx} : $cr->{'.jpg'};
    
    print "Content-type: $ct\n";
    print "Content-Disposition: inline; filename=$fn\n\n";
    
    binmode STDOUT;
    my $buffer; 
    open FILE, "$fn" or die "ERR: could not open $fn: $!\n";    
    binmode(FILE);
    while (
      read (FILE, $buffer, 65536)   # read in (up to) 64k chunks
      && print $buffer
    ) {};
    close FILE;
}


=head2 copy_file ($f1, $f2, $txt)

Input variables:

  $f1   - source file name
  $f2   - target file name
  $txt  - text to be appended to $f2

Variables used or routines called:

  File::Copy 
    copy - copy files

How to use:

  my $f1 = 'text1.txt';
  my $f2 = 'text1.out';
  # duplicate the file and add 'quit' in the end
  $self->copy_file($f1, $f2, 'quit');

Return: none

=cut

sub copy_file {
    my ($s,$f1,$f2,$txt) = @_;
    
    return if !$f1 || !-f $f1;
    # return if !$f2 || !-f $f2;
    copy($f1,$f2) or croak "ERR: Copy failed from $f1 to $f2: $!\n";
    return if !$txt;
    open FF, ">>$f2" or croak "ERR: could not write to $f2: $!\n";
    print FF "$txt\n";
    close FF;
}


1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracts the disp_form method from CGI::Getopt class, 
inherits the new constructor from CGI::AppBuilder, and adds
new methods of replace_named_variables, explode_variable, and 
explode_html.

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

