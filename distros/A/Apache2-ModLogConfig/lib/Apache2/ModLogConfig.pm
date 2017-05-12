package Apache2::ModLogConfig;

use 5.008008;
use strict;
use warnings;

{
    our $VERSION = '0.01';
    require XSLoader;
    XSLoader::load('Apache2::ModLogConfig', $VERSION);
}

1;
__END__

=encoding utf8

=head1 NAME

Apache2::ModLogConfig - a Perl interface to mod_log_config

=head1 SYNOPSIS

Call a Perl handler from a C<CustomLog> format specification:

 <Perl>
   use Apache2::ModLogConfig ();

   sub My::Format {
     my ($r)=@_;

     return $a_string;
   }
 </Perl>

 CustomLog LOGFILE "... %{My::Format}^..."

Use a Perl handler as logfile:

 PerlModule Apache2::ModLogConfig
 PerlModule My::LogReceiver

 CustomLog "@perl: My::LogReceiver" "format spec"

Print to a logfile:

 use Apache2::ModLogConfig ();

 sub handler {
   my ($r)=@_;
   ...
   my $log=$r->server->custom_log_by_name('logs/access_log');
   my $success=$log->print($r, qw/тут был вася/, "\n");
   ...
 }

=head1 DESCRIPTION

The reason to start this module was to monitor the number of incoming and
outgoing bytes for each request. C<mod_log_config> in combination with
C<mod_logio> can log these numbers. But in Perl they are really hard to get.

C<mod_logio> uses a network-level input filter as byte counter. The outgoing
bytes are counted by the core output filter and reported back to C<mod_logio>
if loaded.

Now, with the help of this module you can do 3 things:

=over 4

=item * call a Perl handler from a C<CustomLog> format specification

=item * use a Perl handler in place of a logfile

=item * write out-of-bound messages to logfiles managed by C<mod_log_config>

=back

For this to work, the module must be loaded before the C<PerlOpenLogsHandler>
phase. Calling a Perl handler from a format specification requires an early
start of the interpreter and the module must be loaded at that stage.
That means you need
either a C<< <Perl>...</Perl> >> section in your F<httpd.conf> or the
module must be loaded by C<PerlLoadModule>.

Note, while developing this module I have found a bug in httpd that can lead
to segfaults. It is present at least up to httpd 2.2.17. It occurs if
C<mod_log_config> is statically compiled into httpd and C<BufferedLogs> are
used. In this case avoid changing the C<BufferedLogs> setting while restarting
httpd via C<SIGHUP> or C<SIGUSR1>.

See L<https://issues.apache.org/bugzilla/show_bug.cgi?id=50861>

=head2 Call a Perl handler from a C<CustomLog> format specification

To be used this way C<Apache2::ModLogConfig> registers the C<^> format
with C<mod_log_config>.

C<^> was chosen because it resembles the C<^> in a
number of Perl variables like C<$^V> for example.

Now, a format specifier can receive an argument. The argument is given in
braces between the C<%> sign and the specifier. The C<^> specifier's
argument specifies the Perl handler to call. A fully qualified name is
expected.

Example:

 LogFormat "%{My::Handler::function}^" perllog

The handler is called with an L<Apache2::RequestRec> object as the only
parameter. In a chain of internal redirects this is by default the final
request. It can be modified according to the C<mod_log_config>
documentation:

 LogFormat "%<{My::Handler::function}^" perllog

This way the initial request is passed to the handler.

Other modifiers are also applicable as described by C<mod_log_config>.

=head2 Use a Perl handler in place of a logfile

Now Perl handler works as log drain. That means it will receive
a log file.

 CustomLog "@perl: My::LogReceiver" FORMATSPEC

The prefix C<@perl:> is used to distinguish between a normal file name or pipe
specification and the Perl handler.

The actual handler name is resolved the usual modperl way. That means if there
is no function named C<My::LogReceiver>, C<My::LogReceiver::handler> is
looked up. Auto-loading should work as well (although untested). Further,
an anonymous function can be specified as:

 CustomLog "@perl: sub { my ($r, @strings)=@_; ... }" FORMATSPEC

The handler is called with the final request of a chain of internal redirects
as the first parameters. The other parameters are all strings where each one
corresponds to either a the result of a format specifier or a constant string.

Assuming the following format specification

 "input bytes=%I, output bytes=%O"

the handler is called with 6 parameters:

=over 4

=item * the request object

=item * the string C<input bytes=>

=item * a number according to C<%I>

=item * the string C<, output bytes=>

=item * a number according to C<%O>

=item * and a trailing C<\n> to close the line

=back

Note, a possible C<PerlLogHandler> runs B<before> the C<mod_log_config> handler.
So, it's not possible to record a few values here and use them in a
C<PerlLogHandler>. A C<PerlCleanupHandler> or a request pool cleanup handler
however should be fine.

My original problem now can be solved as:

 package My::IO;

 sub handler {
   my ($r, $in, $out)=@_;
   $r->notes->{InBytes}=$in;
   $r->notes->{OutBytes}=$out;
 }

 sub cleanup {
   my ($r)=@_;
   my ($in, $out)=@{$r->notes}{qw/InBytes OutBytes/};
   ...
 }

in F<httpd.conf>:

 CustomLog "@perl: My::IO" "%I%O"
 PerlCleanupHandler My::IO::cleanup

=head2 Writing to a C<CustomLog> logfile and introspection

Have you ever wanted to write to the F<access_log> directly? I haven't.
But now it's feasible and perhaps someone finds a weird usage case.

C<Apache2::ModLogConfig> implements the following methods.

=head3 @names=$s-E<gt>custom_logs

Assuming C<$s> is a L<Apache2::ServerRec> object this method returns the
logfile names defined for this VHost. The elements of C<@names> are literally
the strings specified as first parameter to C<CustomLog>.

=head3 $log=$s-E<gt>custom_log_by_name($name)

Assuming C<$s> is a L<Apache2::ServerRec> object this method returns an
C<Apache2::ModLogConfig> object for the given name.

=head3 $status=$log-E<gt>print($r, @strings)

Assuming C<$log> is an C<Apache2::ModLogConfig> object and C<$r> is an
L<Apache2::RequestRec> this method prints the strings in C<@strings> to
the file. No escaping is done.

C<$status> is an APR status code (C<APR::Const::SUCCESS> if all is well).

=head2 EXPORT

None.

=head1 SEE ALSO

modperl, mod_log_config, apache httpd

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
