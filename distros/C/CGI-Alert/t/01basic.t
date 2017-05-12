# -*- perl -*-
#

use Test::More;
use File::Temp	'tempfile';

umask 077;

my ($script_fh, $script_path) = tempfile( "CGI-Alert-t-01.script.XXXXXX" );
my (undef,      $output_path) = tempfile( "CGI-Alert-t-01.output.XXXXXX" );

printf $script_fh <<'-', $^X, $output_path;
#!%s -Tw -Iblib/lib

use CGI::Alert		'nobody';
use CGI;

BEGIN { $CGI::Alert::DEBUG_SENDMAIL = '%s' }

warn "this is warning number 1\n";

print $nonexistent_variable;

die "this is where we die\n";
-


close $script_fh;

chmod 0500 => $script_path;

my @expect = <DATA>;

plan tests => 1 + @expect;

{
    local %ENV =
      (
       (map { $_ => $ENV{$_} || 'undef' } qw(HOME PATH LOGNAME USER SHELL)),

       HTTP_HOST      => 'http-host-name',
       REQUEST_URI    => '/sample/url',
      );

    system "./$script_path", 'arg1=val1', 'arg2=val2.1', 'arg2=val2.2';
}

is $?, 0, 'exit code of sample script';

my $i = 0;
open ERROR, '<', $output_path;
while (@expect && defined (my $line = <ERROR>)) {
    chomp $line;

    # What we expect to see, (from below).
    my $expect = shift @expect;
    chomp $expect;
    $expect =~ s/\s+/\\s+/g;		# Ignore whitespace diffs

    # Generate a description of this test
    my $desc = "email line " . ++$i;
    $desc .= " ($1)" if $expect =~ /^Content-Type.*\bname="(.*)"/;

    like $line, qr/^$expect$/, $desc;
}
close ERROR;

unlink $script_path, $output_path;


__END__
From:    CGI Errors <nobody\@http-host-name>
To:      nobody
Subject: FATAL ERRORS in http://http-host-name/sample/url
X-mailer: \S+, via CGI::Alert v\S+
Precedence: bulk
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="==(.*)"

This is a MIME-Encapsulated message.  You can read it as plain text
if you insist.

--==.*
Content-Type: text/plain; charset=us-ascii

The script died with:

  this is where we die


In addition, the following warnings were detected:


  \* Name "main::nonexistent_variable" used only once: possible typo at \S+ line 10.

  \* this is warning number 1

  \* Use of uninitialized value(\s\$\S+)? in print at \S+ line 10.



This message brought to you by CGI::Alert v\S+

--==.*
Content-Type: text/plain; name="stack-trace"
Content-Description: Stack Trace

  \S+ :   12    die\( "this is where we die\\n" \)

--==.*
Content-Type: text/plain; name="CGI-Params"
Content-Description: CGI Parameters \(no REQUEST_METHOD\)

  arg1 = val1
  arg2 = val2.1
       \+ val2.2

--==.*
Content-Type: text/plain; name="warnings"
Content-Description: Warnings, with Stack Traces

  \* Name "main::nonexistent_variable" used only once: possible typo at \S+ line 10.
  \S+ :   10    warn\( "Name "main::nonexistent_variable" used only once: possible typo at \S+ line 10.\\n" \)


  \* this is warning number 1
  \S+ :    8    warn\( "this is warning number 1\\n" \)


  \* Use of uninitialized value(\s\$\S+)? in print at \S+ line 10.
  \S+ :   10    warn\( "Use of uninitialized value(\s\$\S+)? in print at \S+ line 10.\\n" \)




--==.*
Content-Type: text/plain; name="Environment"
Content-Description: Environment

HOME            = .*
HTTP_HOST       = http-host-name
LOGNAME         = .*
PATH            = .*
REQUEST_URI     = /sample/url
SHELL           = .*
USER            = .*

--==.*
Content-Type: text/plain; name="%INC"
Content-Description: Included Headers
