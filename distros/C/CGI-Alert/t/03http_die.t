# -*- perl -*-
#

use strict;
use warnings;

use Test::More;
use Test::Differences;
use File::Temp	'tempfile';

umask 077;

my ($script_fh, $script_path) = tempfile( "CGI-Alert-t-03.script.XXXXXX" );
my (undef,      $output_path) = tempfile( "CGI-Alert-t-03.output.XXXXXX" );

printf $script_fh <<'-', $^X, $output_path, $output_path;
#!%s -Tw -Iblib/lib

use CGI::Alert		qw(nobody http_die);

# Not interested in any email being sent
$SIG{__DIE__}  = 'DEFAULT';
$SIG{__WARN__} = sub { print STDOUT @_ };

# FIXME-document
package CGI;
use subs qw(header start_html);
package main;

*CGI::header = sub {
    print "header()\n";
    use Data::Dumper; print Dumper(\@_);
};
*CGI::start_html = sub {
    print "start_html()\n";
    use Data::Dumper; print Dumper(\@_);
};

# Pretend that we've loaded CGI module
$INC{'CGI.pm'} = 'HACK ALERT';

open STDOUT, '>', '%s'
  or die "Cannot create %s: $!\n";

CGI::Alert::extra_html_headers(
		-author  => 'esm@cpan.org',
		-style   => {
			     -src  => '/foo.css',
			    },
	       );


# Here we go.
http_die '400 Bad Request', 'this is the body';
-


close $script_fh;

chmod 0500 => $script_path;

my $expect = do { local $/; <DATA>; };

plan tests => 2;

{
    local %ENV =
      (
       (map { $_ => $ENV{$_} || 'undef' } qw(HOME PATH LOGNAME USER SHELL)),

       HTTP_HOST      => 'http-host-name',
       REQUEST_URI    => '/sample/url',
      );

    system "./$script_path";
}

is $?, 0, 'exit code of sample script';

my $i = 0;
open ERROR, '<', $output_path;
my $actual = do { local $/; <ERROR>; };
close ERROR;

eq_or_diff $actual, $expect, "fixme";

unlink $script_path, $output_path;


#
# The output we expect
#
__END__
header()
$VAR1 = [
          '-status',
          '400 Bad Request'
        ];
start_html()
$VAR1 = [
          '-title',
          '400 Bad Request',
          '-author',
          'esm@cpan.org',
          '-style',
          {
            '-src' => '/foo.css'
          }
        ];
11

<h1>Bad Request</h1>
<p />
this is the body
<p />
<hr />
Script error: 400 Bad Request
: this is the body at blib/lib/CGI/Alert.pm line 548.
