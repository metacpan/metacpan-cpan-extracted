$| = 1; print "1..19\n";

no warnings; # nazis

use AnyEvent::Socket;

print "ok 1\n";

sub ph {
   my ($id, $str, $dport, $host, $port) = @_;

   $str =~ s/_/ /g unless ref $str;

   my ($h, $p) = parse_hostport ref $str ? $$str : $str, $dport;

   print $h eq $host && $p eq $port ? "" : "not ", "ok $id # '$str,$dport' => '$h,$p' eq '$host,$port'\n";
}

ph  2, "";
ph  3, "localhost";
ph  4, qw(localhost 443 localhost 443);
ph  5, qw(localhost:444 443 localhost 444);
ph  6, qw(10.0.0.1 443 10.0.0.1 443);
ph  7, qw(10.1:80 443 10.1 80);
ph  8, qw(::1 443 ::1 443);
ph  9, qw(::1:80 443 ::1:80 443);
ph 10, qw([::1]:80 443 ::1 80);
ph 11, qw([::1]_80 443 ::1 80);
ph 12, qw([::1]_: 443);
ph 13, qw([::1]: 443);
ph 14, qw(::1_smtp 443 ::1 smtp);
ph 15, qw([www.linux.org]_80 443 www.linux.org 80);
ph 16, qw([10.1]:80 443 10.1 80);
ph 17, qw(10.1_80 443 10.1 80);

my $var = "2002:58c6:438b::10.0.0.17";
ph 18, \$var, qw(443 2002:58c6:438b::10.0.0.17 443);
ph 19, \$var, qw(443 2002:58c6:438b::10.0.0.17 443);

