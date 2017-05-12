#!/usr/bin/perl
package Apache::EmbeddedPerl::Lite;
#use strict;
#use diagnostics;

use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.06 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	embedded
);

if (eval { require Apache2::RequestRec }) {
  require Apache2::RequestUtil;
  require Apache2::RequestIO;
}

=head1 NAME

Apache::EmbeddedPerl::Lite - light weight embedded perl parser

=head1 SYNOPSIS

  PerlModule Apache::EmbeddedPerl::Lite

  <Files *.ebhtml>
    SetHandler perl-script
    PerlHandler Apache::EmbeddedPerl::Lite
    PerlSetVar ContentType text/html
  </Files>

or

  use Apache::EmbeddedPerl::Lite qw(
	embedded
  };

  $response = embedded($class,$r,$filename,@args)

=head1 DESCRIPTION

This modules is a light weight perl parser designed to be used in
conjunction wit mod_perl and Apache 1 or Apache 2. It may be used as a
handler for files containing embedded perl or it may be called as a
subroutine to conditionally parse files of your choosing.

Perl code may be embedded in a file parsed by this module as described
below. Each section of perl code is collected and eval'd as a subroutine that
is passed the two arguments ($classnam,$r) in its input array @_;

Embedded perl should have the following format:

  On a line by itself:

  {optional whitespace}  <!-- {whitespace} perl 

  perl code here

# terminating bracket on a line by itself
  {optional whitespace} -->

The beginning and terminating brackets may optionally be followed by a white
space and comments, which will be ignored.

  i.e.

  <!--  perl
# perl code goes here, it will be executed as a subroutine
#
# anon_sub($classname,$r) {
      my($class,$r) = @_;
      $r->print("Hello World, I am in package $class\n");
# }
  -->

=item * $http_response = handler($classname,$r);

The function "handler" has the prototype:

	handler ($$) : method {

which receives the arguments $class, $r from Apache mod_perl.

  input:	class name,	(a scalar, not a ref)
		request handle

  return:	Apache response code or undef

  handler is not exported.

Expected Codes:

	  0	OK
	404	File Not Found
	500	Server Error

  404 could not find, open, etc... file
  500 missing closing embedded perl bracket
      embedded perl has an error

When a 500 error is returned, a warning will be issued to STDERR providing
details about the error.
	
A ContentType header will not be sent unless the type is specified as
follows:

	PerlSetVar	ContentType	text/html

mod_perl configuration is as follows:

  PerlModule Apache::EmbeddedPerl::Lite

  <Files *.ebhtml>
    SetHandler perl-script
    PerlHandler Apache::EmbeddedPerl::Lite
    PerlSetVar ContentType text/html
  </Files>

=item * $http_response = embedded($classname,$r,$file,@args);

The function "embedded" is similar to "handler" above except that it does not send any headers.
Headers are the responsibility of the application "handler", or the embedded
code.

@args are optional arguments that may be passed from your handler to embedded.

  input:	class name,	(a scalar, not a ref)
		request handle,
		file name
		@args	[optional] appication specific

  return:	Apache response code or undef

  ... at startup or .httaccess ...

  use Apache::EmbeddedPerl::Lite qw(embedded);

  ... in the application handler ...

	if ($r->filename =~ /\.ebhtml$/) {
  ...	  set content type, etc...

	  $response = embedded(__PACKAGE__,$r,$r->filename);
	} else {
	  $response = embedded(__PACKAGE__,$r,$someotherfile);
	}
	return $response if $response; # contains error

  ...	  do something else

=cut

sub handler ($$) : method {
  my($class,$r) = @_;
  my $ct = $r->dir_config('ContentType');
  $r->content_type($ct) if $ct;
  embedded($class,$r,$r->filename);
}

# execute in an environment with no lexical variables
sub _ex_eval {
  local $_ = shift;
# eval sees our global @_

  {	local $SIG{__WARN__} = sub {};
	eval;
  }
}

sub embedded {
  my ($class,$r,$file,@args) = @_;
  my $lineno = 0;
  local *F;
  my $line;
  (-e $file && open(F,$file)) or return 404;
READLINE:
  while (defined ($line = <F>)) {
    $lineno++;
    if ($line =~ /^\s*\<\!--\s+perl\s*/) {
      (my $perl = $0) =~ s/::/_/g;
      $perl =~ s/([^a-zA-Z0-9_])/sprintf("%02X",ord($1))/seg;
      $perl = 'package '. __PACKAGE__ .'::anon::'. $perl .";\nno strict;\n";
      $perl .= "use diagnostics;\n" if exists $INC{'diagnostics.pm'};
      my $start = $lineno;
      while (defined ($line = <F>)) {
	$lineno++;
	if ($line =~ /^\s*-->/) {
	  _ex_eval($perl,@_);
	  if ($@) {
	    close F;
	    warn "$class embedded: failed $file line $start\n$@";
	    return 500;
	  }
	  next READLINE;
	}
        $perl .= $line;
      }
      close F;
      warn "$class embedded: $file line $start\nno closing '-->'\n";
      return 500;
    }
    $r->print($line);
  }
  close F;
  return 0;	# Apache::Constant::OK
}
 
=head1 PREREQUISITES

	Apache
  or
	Apache2
	Apache2::RequestRec
	Apache2::RequestUtil;
	Apache2::RequestIO;
    
=head1 EXPORT_OK

	embedded

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT

Copyright 2013-2014, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the same terms of the Apache Software License, a copy of which is
included in this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
