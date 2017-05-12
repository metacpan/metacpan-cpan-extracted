use strict;
use Apache::SubProcess qw(system exec);

my $r = shift;
$r->send_http_header('text/plain');

#override built-in system() function
system "/bin/echo hi there";

#send output of a program
my $efh = $r->spawn_child(\&env);
$r->send_fd($efh);

#pass arguments to a program and sends its output
#my $fh = $r->spawn_child(\&banner);
#$r->send_fd($fh);

#pipe data to a program and send its output
use vars qw($String);
$String = "hello world";
my($out, $in, $err) = $r->spawn_child(\&echo);
print $out $String;
$r->send_fd($in);

#override built-in exec() function
exec "/usr/bin/cal"; 

print "NOT REACHED\n";

sub env {
    my $r = shift;
    #$r->subprocess_env->clear;
    $r->subprocess_env(HELLO => 'world');
    $r->filename("/bin/env");
    $r->call_exec;
}

sub banner {
    my $r = shift;
    $r->filename("/usr/bin/banner"); 
    $r->args("-w40+Hello%20World");  
    $r->call_exec;
}

sub echo {
    my $r = shift;
    $r->subprocess_env(CONTENT_LENGTH => length $String);
    $r->filename("/home/dougm/bin/pecho");
    $r->call_exec;
}
#where /home/dougm/bin/pecho is:
#!/usr/local/perl/bin/perl 
#read STDIN, $buf, $ENV{CONTENT_LENGTH}; 
#print "STDIN: `$buf' ($ENV{CONTENT_LENGTH})\n"; 
