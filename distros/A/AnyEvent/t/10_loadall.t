$| = 1;

print "1..24\n";

my $i = 0;
for (qw(
   AnyEvent
   AnyEvent::Util
   AnyEvent::DNS
   AnyEvent::Socket
   AnyEvent::Loop
   AnyEvent::Strict
   AnyEvent::Debug
   AnyEvent::Handle
   AnyEvent::Log
   AnyEvent::Impl::Perl
   AnyEvent::IO::Perl
   AnyEvent::IO
)) {
   print +(eval "require $_"  ) ? "" : "not ", "ok ", ++$i, " # $_ require $@\n";
   print +(eval "import $_; 1") ? "" : "not ", "ok ", ++$i, " # $_ import  $@\n";
}
