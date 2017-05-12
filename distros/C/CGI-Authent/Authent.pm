package CGI::Authent;
$VERSION='0.2.1';

sub can_read {
    foreach (@_) {
     return undef unless (-r $_);
    }
    1;
}

sub isbetween {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
      localtime(time);
    my ($h1,$m1,$h2,$m2) = $_[0] =~ /(\d+):(\d+)-(\d+):(\d+)/;

    my $res = (
      ($h1<=$h2) ?
      (
         (
          $h1 < $hour
          or
          ($h1 == $hour and $m1 <= $min)
         )
         and
         (
          $hour < $h2
          or
          ($hour == $h2 and $min <= $m2)
         )
      ) : (
         (
          $hour < $h2
          or
          ($h2 == $hour and $min <= $m2)
         )
         or
         (
          $h1 < $hour
          or
          ($hour == $h1 and $m1 <= $min)
         )
      )
    );
    $res;
}

sub between ($) {
    unless (isbetween(@_)) {
        $header =~ s/401.*?\n/403 Forbidden\x0D\x0A/m;
        $msg = <<"*END*";
<HTML>
 <HEAD><TITLE>Temporarily forbidden</TITLE></HEAD>
 <BODY>
  <h1>Temporarily forbidden</h1>
  This resource is available only at $_[0]. Please come later.
 </BODY>
</HTML>
*END*
    }
    return $res;
}

sub import {
 ($header,$msg) = ($ENV{PERLXS} eq 'PerlIS' ? "HTTP/1.0 401 Access Denied\r\n" : "Status: 401 Access Denied\r\n",<<'*END*');
<HTML>
 <HEAD><TITLE>UnAuthentificated</TITLE></HEAD>
 <BODY>
  <h1>UnAuthentificated</h1>
  You have to provide a correct login&password to access this page!
 </BODY>
</HTML>
*END*
 shift @_;
 my ($hash,$value,$test);
 if (ref $_[0] eq 'HASH') {
    $hash = shift @_;
    $msg = (shift @_ or $msg);
 } else {
    if (@_ & 1) {
        $msg = (pop @_ or $msg);
    }
    my %tmp = @_;
    $hash = \%tmp;
 }
 eval {require 'CGI/Authent.config.pl';} unless %default;
 foreach (keys %$hash) {@default{$_} = $hash->{$_}};
 my $authent;
 while (($_,$value) = each %default) {

    if ($_ eq 'NTLM' and $value) {
        $header .= "WWW-Authenticate: NTLM\r\n";
        $authent=1;
    } elsif (/^Basic$/i) {
        if ($value and !($value =~ '_default' or $value =~ 'IP')) {
            $header .= qq{WWW-Authenticate: Basic realm="$value"\r\n}
        } else {
            $header .= qq{WWW-Authenticate: Basic realm="$ENV{LOCAL_ADDR}"\r\n}
        }
        $authent=1;
    } elsif (/^Authent/i) {
        $header .= 'WWW-Authenticate: '.join("\r\nWWW-Authenticate: ",split(/\r?\n/,$value))."\r\n";
        $authent=1;
    } elsif (/^msg$/i) {
        $msg = $value;
    } elsif (/^head/) {
        $header .= $value;
    } elsif (/^test$/i) {
        $test = $value;
    }
 }
 $header .= qq{WWW-Authenticate: Basic realm="$ENV{LOCAL_ADDR}"\r\n} unless $authent;
 my $res;
 if (ref $test eq 'CODE') {
    $res = &$test
 } elsif (!defined $test or $test =~ /^_default$/i) {
    $res = 1 unless ($ENV{HTTP_HOST} and ! $ENV{REMOTE_USER})
 } else {
    $res = eval ($test);
 }
 if (! $res) {
  $header .= "Content-Type: text/html\r\n\r\n";
  print $header,$msg;
  exit;
 }
}

1;

=head1 NAME

CGI::Authent - request a HTTP authentification under specified conditions

version 0.2.1

=head1 SYNOPSIS

use CGI::Authent Basic => 'The realm name', test => 'CGI::Authent::between "h:m-h:m"';

=head1 DESCRIPTION

Send the HTTP 401 UnAuthentified header if a condition (by default
"defined $ENV{REMOTE_USER}") fails. Since your script doesn't get the
password the user entered, you cannot use it as the only
authentification scheme. And it was not intended to work like this. You
have to find some other way to check the username/password pair.

It was written primarily to overcome a bug in MS IIS/3.0.
IIS usualy sends a HTTP 401 response if it finds out that it cannot
access a file using the current users premissions
(IUSR_... or the login/password you entered),
but since IIS doesn't check the permissions to the script before launching
perl, you get an error message :

    CGI Error

    The specified CGI application misbehaved by not returning a complete set
    of HTTP headers. The headers it did return are:

    Can't open perl script "...": Permission denied 

instead of a login/password dialog.

So instead of restricting the permissions for the scripts,
you will add

    use CGI::Authent;

at the very beginning of your scripts and update CGI/Authent.config.pl
to suggest your servers authentification method.

The login/password pair your user will enter into the dialog /s?he/ will
get will be checked by the server and mapped to an account, so all
you have to do, if all authentified users are to be able to access
your script, is to check the system variable REMOTE_USER - the default test.

If you want to restrict the access to a group of users you may
check whether the script as it runs has enough permissions
to access a file and then restrict the access to this file.

    use CGI::Authent {test => 'CGI::Authent::can_read "c:\\inetpub\\group1.lck"'}

=head2 Ussage

    use CGI::Authent;
     Use the default options as set in CGI/Authent.config.pl.
    use CGI::Authent {options}, [$msg];
    use CGI::Authent options, [$msg];
     Replace the default options from CGI/Authent.congfig.pl, by the ones
     presented here.

=head2 Options

 NTLM => 1/0
  Should we use/suggest NTLM authentification?
  
 Basic => ''/'IP'/'_default'/'the realm'
  Should we use the Basic authentification?
  '', 'IP' and '_default' both mean that the realm will
  be the servers IP address, which is default for MS IIS.
 
 msg => 'the message that should be showed if the authentification fails'
 
 test => \&some_boolean_function / 'some perl code' / '_default'
      / 'Authent::can_read "filename"' / 'Authent::between "h:m-h:m"'
  The test that should be performed. You may use either a reference to
  a function, or a string to be eval()uated. The string '_default' has
  a special meaning, it gets translated to 'defined $ENV{REMOTE_USER}',
  so it checks if the user was authentificated by the server.
  If the function/expression returns a true value, the script runs,
  otherwise the user gets asked for a login/password pair.

 header => 'Some: additional headers'
  You may add some headers to the response that will be sent if the test fails.
  You may add several headers either as
   header => 'Header1\r\nHeader2'
  or
   header1 => 'Header1',
   header2 => 'Header2'
   
 Authenticate => 'Additional authentification methods'
  You may specify additional authentification methods here.
  The string you specify will be prepended by 'WWW-Authenticate: ' and
  added to the headers.
  You may use the same methods for several methods as with headers.

=head2 Tests

The default test is 'defined $ENV{REMOTE_USER}' which only checks
whether the user entered any login/password pair that was accepted
by the server.

Other predefined tests are :

 CGI::Authent::can_read $file[, $file2, ...]
  Does the script have permissions to read the file(s)?
 
 CGI::Authent::isbetween 'h:m-h:m';
  It the time in this range?

 CGI::Authent::between 'h:m-h:m';
  It the time in this range? This version will disallow
  access buring other times completely! No request for authentification,
  just 403 Forbiden response!


You may of course combine several tests :

 test => 'CGI::Authent::can_read "c:\\inetpub\\group1.lck" and CGIAuthent::between '8:00-17:00'
          or
          CGI::Authent::can_read "c:\\inetpub\\group2.lck" and CGI::Authent::between '17:00-8:00'
         '

=head2 Other functions

 CGI::Authent::forbide [$message]
  Send the "HTTP 403 Forbiden" response.

 CGI::Authent::login [$message]
  Send the "HTTP 401 UnAuthentified" response.

=head2 REMINDER

CGI::Authent doesn't validate the passwords. It cannot even see them. It
just does a few tests and if the tests fail it sends to the user a
request for authentication. But it's the server's task to validate the
credentials passed by the browser.

If you want for example to validate passwords against a database,
consult your servers documentation. You will probably have to install some filter or plugin.
It should be relatively easy to find such beasts on the net. I've written an ISAPI filter for this,
you may get it at http://jenda.krynicky.cz/authfilter.1.0.zip . Take it as an example, not as a solution!

=head2 Guts

All options are parsed and added to the headers before yout test runs,
so you may change the headers from it.

The headers are in $CGI::Authent::header, the message is in $CGI::Authent::message.

=head2 AUTHOR

Jan Krynicky <Jenda@Krynicky.cz>
7/26/1999

=cut
