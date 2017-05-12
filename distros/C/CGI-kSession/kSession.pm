package CGI::kSession;
$CGI::kSession::VERSION = '0.5.3';
use strict;

sub new {
    my ($c, %args) = @_;
    my $class = ref($c) || $c;
    $args{SID} = $args{id};
    bless \%args, $class;
}

sub start {
    my $cl = shift;
    if (!exists($cl->{lifetime})) { $cl->{lifetime} = 600; }
    if (!exists($cl->{path})) { $cl->{path} = "/var/tmp/"; }
    # ustawia nowy ID jesli nie jest zaden podany juz
    if ((!exists($cl->{SID})) || ((length($cl->{SID}) == 0))) { $cl->id($cl->newID()); }
    
    if (-e $cl->getfile()) { return 0; }
    # nowy plik sesji jesli takowy juz nie istnieje
    open(SF,">".$cl->getfile()); close(SF);
    $cl->check_sessions();
    return 1;
}

sub check_sessions {
    my $cl = shift;
    opendir(SD,$cl->{path});
    my @files = readdir(SD);
    shift @files;
    shift @files;
    foreach my $f (@files) {
	if (((stat($cl->{path}.$f))[9] + $cl->{lifetime}) < time()) { 
		unlink($cl->{path}.$f); 
		}
	}
    closedir(SD);
}

sub destroy {
    my $cl = shift;
    if (!$cl->have_id()) { return -1; }
    if (-e $cl->getfile()) { unlink($cl->getfile()); }
    undef $cl->{SID};
    if (defined($cl->{id}))  { undef $cl->{id}; }
    return 1;
}

#czy sesja o podanym id istnieje
sub exists {
    my ($cl,$id) = @_;
    if (!defined($id)) { return 0; }
    my $file = $cl->{path}.$cl->{$id};
    if (-e $file) { return 1; }
    return 0;
}

sub have_id {
    my $cl = shift;
    if (!exists($cl->{SID})) { return 0; }
    return 1;
}

sub save_path {
    my ($cl, $path) = @_;
    if (defined($path)) { $cl->{path} = $path }
    return $cl->{path};
}

sub id {
    my ($cl, $newid) = @_;
    if (!$cl->have_id()) { return -1; }
    if (defined($newid)) { $cl->{SID} = $newid; }
    return $cl->{SID};
}

sub getfile {
    my $cl = shift;
    return $cl->{path}.$cl->{SID};
}

sub is_registered {
    my ($cl,$name) = @_;
    if (!$cl->have_id()) { return -1; }
    if (-e $cl->getfile()) {
	open(SF,$cl->getfile);
	while (my $l = <SF>) {
	    my @line = split (/=/,$l);
	    if ($line[0] eq $name) { 
		close(SF); 
		return 1;
		}
	    }
	close(SF);
    }
    return 0;
}


sub register {
    my ($cl,$name) = @_;
    if (!$cl->have_id()) { return -1; }
    if ($cl->is_registered($name)) { return 0; }
    if (-e $cl->getfile()) {
	open(SF,">>".$cl->getfile());
	print SF $name."=\n";
	close(SF);
	return 1;
    }
    return 0;
}

sub unregister {
    my ($cl,$name) = @_;
    my $content = "";
    if (!$cl->have_id()) { return -1; }
    if (!$cl->is_registered($name)) { return 0; }
     open(SF,$cl->getfile());
     while (my $l = <SF>) { 
        $l =~ s/^$name=(.*?)\n//i;
        $content .= $l; 
	}
     close(SF);
    open(SF,">".$cl->getfile());
#	$content =~ s/$name=(.*?)\n//gis;
    print SF $content; 
    close(SF);
}

sub unset {
    my $cl = shift;
    open(SF,">".$cl->getfile());
    close(SF);
}

sub get {
    my ($cl,$name) = @_;
    if (!$cl->have_id()) { return -1; }
    if ($cl->is_registered($name)) {
	if (-e $cl->getfile()) {
	open(SF,$cl->getfile());
	while (my $l = <SF>) {
	    if ($l =~ /^$name=(.*?)\n/i) {
		close(SF); 
		return $1; 
		}
#	    my @line = split (/=/,$l);
#	    if ($line[0] eq $name) { 
#		close(SF); 
#		return $line[1]; 
#		}
	    }
	close(SF);
	} 
    } else { 
    return -1;
    };
}

sub set {
    my ($cl,$name,$value) = @_;
    if (!$cl->have_id()) { return -1; }
    if ($cl->is_registered($name)) {
	my $content = "";
	
	open(SF,$cl->getfile()); 
	while (my $l = <SF>) { 
    	    $l =~ s/^$name=(.*?)\n/$name=$value\n/gis;
	    $content .= $l; 
	    }
	close(SF);
#	$content =~ s/$name=(.*?)\n/$name=$value\n/gis;
	open(SF,">".$cl->getfile());
	print SF $content; 
	close(SF);
	return 1;
    }
    return 0;
}


sub newID {
    my $cl = shift;
    my $ary = "0123456789abcdefghijABCDEFGH";	# replace with the set of characters
    $cl->{SID} = "";
    my $arylen = length($ary);
    for my $i (0 .. 23) {
	my $idx = int(rand(time) % $arylen);
	my $dig = substr($ary, $idx, 1);
#	if ($i > 0) {
#	    if ($i % 8 == 0) { $cl->{SID} .= "-"; }
#	    elsif ($i % 4 == 0) {$cl->{SID} .= "_"; }
#	} 
	$cl->{SID} .= $dig;
    } $cl->{SID};
}

#############################

1;

__END__

=head1 NAME

CGI::kSession - sessions manager for CGI

=head1 VERSION

kSession.pm v 0.5.3

=over 4

=item Recent Changes:

	0.5.3
	- updated the documentation
	0.5.2
	- fix value containing '='
	0.5.1
	- ugly fix with existing session
	0.5 
	- lifetime
	- path,lifetime as arguments with new

=back

=head1 DESCRIPTION

This module can be used anywhere you need sessions. As a session management module, it uses files with a configurable lifetime to handle your session data. For those of you familiar with PHP, you will notice that the session syntax is a little bit similar.

=head1 METHODS

The following public methods are availible:

=over 4

=item $s = new CGI::kSession();

The constructor, this starts the ball rolling. It can take the following hash-style parameters:

	lifetime - 	how long the session lasts, in seconds
	path	 -	the directory where you want to store your session files
	id	 -	if you want to give the session a non-random name, use this parameter as well

=item $s->start();

This creates a session or resumes an old one (could be used in conjunction with something like HTTP::Cookie). This will return '1' if this is a new session, and '0' if it's resuming an old one. If you defined no values in the 'new()' call, then the session will start with a default lifetime of 600 seconds, a path of /var/tmp, and a random string for an id.

=item $s->save_path();

Save the session path or, without an argument, return the current session path. Used with an argument, this performs the same thing as the 'path' parameter in the constructor.

=item $s->id();

If the session id exists, this will return the current session id - useful if you want to maintain state with a cookie! If you pass a parameter, it acts the same as new( id => 'some_session_name'), i.e., it creates a session with that id.

=item $s->register();

This takes a string as an arguement and basically tells the session object this: "Hey, this is a variable I'm thinking about associating with some data down the road. Hang onto it for me, and I'll let you know what I'm going to do with it". Once you register a variable name here, you can use it in 'set()' and 'get()'.

=item $s->is_registered();

Check to see if the function is registered. Returns '1' for true, '0' for false.

=item $s->unregister();

Tell the session jinn that you no longer want to use this variable, and it can go back in the bottle (the variable, not the jinn... you still want the jinn around until you call 'destroy()').

=item $s->set();

This is where you actually define your variables (once you have "reserved" them using 'register()'). This method takes two arguments: the first is the name of the variable that you registerd, and the second is the info you want to store in the variable.

=item $s->get();

This method allows you to access the data that you have saved in a session - just pass it the name of the variable that you 'set()'.

=item $s->unset();

Calling this method will wipe all the variables stored in your session.

=item $s->destroy();

This method deletes the session file, destroys all the evidence, and skips bail.

=back

=head1 EXAMPLES

=over 4

=item Session creation and destruction

 use strict;
 use CGI;
 use CGI::kSession;

    my $cgi = new CGI;
    print $cgi->header;

    my $s = new CGI::kSession(lifetime=>10,path=>"/home/user/sessions/",id=>$cgi->param("SID"));
    $s->start();
    # $s->save_path('/home/user/sessions/');

    # registered "zmienna1"
    $s->register("zmienna1");
    $s->set("zmienna1","wartosc1");
    print $s->get("zmienna1"); #should print out "wartosc1"

    if ($s->is_registered("zmienna1")) {
	print "Is registered";
	} else {
	print "Not registered";
	}

    # unregistered "zmienna1"
    $s->unregister("zmienna1");
    $s->set("zmienna1","wartosc2");
    print $s->get("zmienna1"); #should print out -1
    
    $s->unset(); # unregister all variables
    $s->destroy(); # delete session with this ID

I<Marcin Krzyzanowski>

=item Sessions, URLs, and Cookies

 use strict;
 use CGI;
 use CGI::Carp qw(fatalsToBrowser);
 use CGI::kSession;
 use CGI::Cookie;

    my $cgi = new CGI;
    my $last_sid = $cgi->param("SID");
    my $c = new CGI::Cookie(-name=>'SID',-value=>$last_sid);
    my ($id, $key, $value);

    my $s = new CGI::kSession(path=>"/tmp/");

    print $cgi->header(-cookie=>$c);

    print $cgi->start_html();

    if ($last_sid) {
        # note: the following I used for mozilla - your mileage may vary
        my $cookie_sid = (split/[=;]/, (fetch CGI::Cookie)->{SID})[1];

        if ($cookie_sid) {
            print "<b>We are now reading from the cookie:</b><p>";
            $id = $s->id($cookie_sid);
            $s->start($cookie_sid);
            print "The cookie's id: $cookie_sid<br>";
            print "Here's the test_value: ".$s->get("test_key")."<br>";
        } else {
            print "<b>We are now reading from the URL parameters:</b><p>";
            $id = $s->id($last_sid);
            $s->start($last_sid);
            print "Last page's id: $last_sid<br>";
            print "Here's the test_value: ".$s->get("test_key")."<br>";
        }
    } else {
        print "<b>Here we will set the session values:</b><p>";
        $s->start();
        $id = $s->id();
        print "My session id: $id<br>";
        $s->register("test_key");
        $s->set("test_key", "Oh, what a wonderful test_value this is...");
        print "Here's the test_value: ".$s->get("test_key")."<br>";
    }

    # note: the first click will set the session id from the URL the
    #           second click will retrieve a value from the cookie

    print "<a href=".(split/\//,$0)[-1]."?SID=$id>Next page</a>";
    print $cgi->end_html();

I<Duncan McGreggor>

=back

=head1 COPYRIGHT

Copyright 2000-2002 Marcin Krzyzanowski

=head1 AUTHOR

Marcin Krzyzanowski <krzak at linux.net.pl>
http://krzak.linux.net.pl/

Duncan McGreggor <oubiwann at yahoo.com>

=cut
