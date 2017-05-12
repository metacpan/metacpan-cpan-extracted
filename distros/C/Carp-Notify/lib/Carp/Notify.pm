use 5.005;
use strict;
use warnings;

package Carp::Notify;
$Carp::Notify::VERSION = '1.13';
# ABSTRACT: Loudly complain in lots of places when things break badly

my %def = (
    "smtp"   => 'your.smtp.com', # IMPORTANT!  Set this!  I mean it!
    "domain" => 'smtp.com',      # IMPORTANT!  Set this!  I mean it!
    "port"   => 25,

    "email_it" => 1,                       # should we email by default? true/false
    "email"    => 'someone@your.smtp.com', # who are we emailing by default?
    "return"   => 'someone@your.smtp.com', # who is the error coming from?
    "subject"  => 'Ye Gods!  An error!',

    "log_it"   => 1,                # should we log by default?
    "log_file" => '/tmp/error.log', # default error log for notifys and explodes

    "log_explode" => 0,                  # should we log explodes by default?
    "explode_log" => '/tmp/explode.log', # default error log for explodes ONLY

    "log_notify" => 0,                 # should we log notifys by default?
    "notify_log" => '/tmp/notify.log', # default error log for notifys ONLY

    "store_vars"  => 1, # should we store variables by default? true/false
    "stack_trace" => 1, # should we do a stack trace by default? true/false
    "store_env"   => 1, # should we store our environment by default? true/false

    "die_to_stdout"  => 0, # should we send our death_message to STDOUT by default? true/false
    "die_everywhere" => 0, # should we send our death_message to STDOUT and STDERR by default? true/false
    "die_quietly"    => 0, # should we not print our death_message anywhere?  true/false

    "error_function" => '', # function to call if Carp::Notify encounters an error
    "death_function" => '', # function to call upon termination, used in place of death_message

    # What would you like to die with?  This is probably the message that's going to your user in
    # his browser, so make it something nice.  You'll have to set the content type yourself, though.
    # Why's that, you ask?  I wanted to be sure that you had the option of easily redirecting to
    # a different page if you'd prefer.

    "death_message"   => <<'eoE'
Content-type:text/plain\n\n

We're terribly sorry, but some horrid internal error seems to have occurred.  We are actively
looking into the problem and hope to repair the error shortly.  We're sorry for any inconvenience.

eoE
);
# end defaults.  Don't mess with anything else! I mean it!

my $settables = "(?:" . join('|', keys %def) . ')';

$Carp::Notify::fatal = 1;

{
    my $calling_package = undef;

    my %storable_vars = ();

    my @storable_vars = ();
    my %init = ();

    sub import {
        # this wants rework, badly
        no strict 'refs';
        my ($package, $file, $line) = caller;
        $calling_package = $package;

        *{$package . "::explode"} = \&Carp::Notify::explode;
        *{$package . "::notify"} = \&Carp::Notify::notify;

        while (defined (my $var = shift)){
            if ($var eq ""){die ("Error...tried to import undefined value in $file, Line $line\n")};

            if ($var =~ /^$settables$/o){
                $def{$var} = shift;
                next;
            };

            push @storable_vars, $var if $var =~ /^[\$@%&]/;
            push @{$storable_vars{$calling_package}}, $var if $var =~ /^[\$@%&]/;

            # see if we want to overload croak or export anything while we're at it.

            *{$package . "::croak"}           = \&Carp::Notify::explode if $var eq "croak";
            *{$package . "::carp"}            = \&Carp::Notify::notify if $var eq "carp";
            *{$package . "::make_storable"}   = \&Carp::Notify::make_storable if $var eq "make_storable";
            *{$package . "::make_unstorable"} = \&Carp::Notify::make_unstorable if $var eq "make_unstorable";
        };
    };

    sub store_vars {
        # this wants rework
        no strict 'refs';

        my $stored_vars = "";
        my $calling_package = (caller(1))[0]; # eek!  This may not always work

        foreach my $storable_var (@{$storable_vars{$calling_package}}){
            my $type = '';
            $type = $1 if $storable_var =~ s/([\$@%&])//;

            my $package = $calling_package . "::";
            $package = $1 if $storable_var =~ s/(.+::)//;

            if ($type eq '$') {
                my $storable_val = ${$package . "$storable_var"};
                $stored_vars .= "\t\$${package}$storable_var : $storable_val\n";next;
            }
            elsif ($type eq '@') {
                my @storable_val = @{$package . "$storable_var"};
                $stored_vars .= "\t\@${package}$storable_var : (@storable_val)\n";next;
            }
            elsif ($type eq '%') {
                my %temp_hash = %{$package . "$storable_var"};
                my @storable_val =  map {"\n\t\t$_ => $temp_hash{$_}"} keys %temp_hash;
                $stored_vars .= "\t\%${package}$storable_var : @storable_val\n";next;
            }
            elsif ($type eq '&'){
                my $storable_val = &{$package . "$storable_var"};
                $stored_vars .= "\t\&${package}$storable_var : $storable_val\n";next;
            };
        };

        return $stored_vars;
    };

    sub make_storable {
        foreach my $var (@_){
            push @storable_vars, $var if $var =~ /^[\$@%&]/;;
        };
        return 1;
    };

    sub make_unstorable {
        my $no_store = join("|", map {quotemeta} @_);
        @storable_vars = grep {!/^(?:$no_store)$/} @storable_vars;
        return 1;
    };

    # hee hee!  Remember, a notification is just an explosion that isn't fatal.  So we use our nifty handy dandy
    # fatal class variable to tell explode that it's not a fatal error.  explode() will set fatal back to 1 once
    # it realizes that errors are non-fatal.  That way a future explosion will still be fatal.
    #
    # and then goto &explode makes perl think it just started at the explode function.  Even caller can't catch it!
    sub notify {
        $Carp::Notify::fatal = 0;
        goto &explode;
    };

    sub explode {
        my $errors = undef;

        my %init = ();

        while (defined (my $arg = shift)) {
            if ($arg =~ /^$settables$/o){
                $init{$arg} = shift;
            }
            else {$errors .= "\t$arg\n"};
        };

        %init = (%def, %init);

        my( $stored_vars, $stack, $environment ) = ( '', '', '' );

        $stored_vars = store_vars()  if $init{'store_vars'};
        $stack       = stack_trace() if $init{'stack_trace'};
        $environment = store_env()   if $init{'store_env'};

        my $message = "";

        my $method = $Carp::Notify::fatal ? 'explosion' : 'notification';

        $message .= "An error via $method occurred on " . today() . "\n";

        $message .= "\n>>>>>>>>>\nERROR MESSAGES\n>>>>>>>>>\n\n$errors\n<<<<<<<<<\nEND ERROR MESSAGES\n<<<<<<<<<\n"          if $errors;
        $message .= "\n>>>>>>>>>\nSTORED VARIABLES\n>>>>>>>>>\n\n$stored_vars\n<<<<<<<<<\nEND STORED VARIABLES\n<<<<<<<<<\n" if $stored_vars;
        $message .= "\n>>>>>>>>>\nCALL STACK TRACE\n>>>>>>>>>\n\n$stack\n<<<<<<<<<\nEND CALL STACK TRACE\n<<<<<<<<<\n"       if $init{'stack_trace'};
        $message .= "\n>>>>>>>>>\nENVIRONMENT\n>>>>>>>>>\n\n$environment\n<<<<<<<<<\nEND ENVIRONMENT\n<<<<<<<<<\n"           if $init{'store_env'};

        log_it(
            "log_it"         => $init{'log_it'},
            "log_file"       => $init{'log_file'},

            "log_explode"    => $Carp::Notify::fatal && $init{"log_explode"} ? $init{"log_explode"} : 0,
            "explode_log"    => $init{'explode_log'},

            "log_notify"     => ! $Carp::Notify::fatal && $init{"log_notify"} ? $init{"log_notify"} : 0,
            "notify_log"     => $init{"notify_log"},

            "message"        => $message,
            "error_function" => $init{'error_function'}
        );

        simple_smtp_mailer(
            "email"          => $init{'email'},
            "return"         => $init{'return'},
            "message"        => $message,
            "subject"        => $init{'subject'},
            "smtp"           => $init{'smtp'},
            "port"           => $init{'port'},
            "error_function" => $init{'error_function'}
        ) if $init{'email_it'};

        if ($Carp::Notify::fatal){
            if ($init{'die_quietly'}){
                exit;
            }
            elsif ($init{'death_function'}){
                if (ref $init{'death_function'} eq 'CODE'){
                    $init{'death_function'}->(%init, 'errors' => $errors);
                }
                else {
                    # this wants rework, badly
                    no strict 'vars';
                    my ($calling_package) = (caller)[0];
                    my $package = $calling_package . "::";
                    $package = $1 if $init{'death_function'} =~ s/(.+::)//;
                    $init{'death_function'} =~ s/^&//;
                    &{$package . $init{'death_function'}}(%init, 'errors' => $errors);
                    exit;
                };
            }
            else {
                if ($init{'die_to_stdout'}){
                    print STDERR $init{'death_message'} if $init{'die_everywhere'};
                    print $init{'death_message'};
                    exit;
                }
                else {
                    print $init{'death_message'} if $init{'die_everywhere'};
                    die $init{'death_message'};
                };
            };
        }
        else {
            $Carp::Notify::fatal = 1;
            return;
        };
    };
};


# psst!  If you're looking for store_vars, it's up at the top wrapped up with import!

sub store_env {
    my $env = '';
    foreach (sort keys %ENV){
        $env .= "\t$_ : $ENV{$_}\n";
    };
    return $env;
};

sub stack_trace {
    my $caller_count = 1;
    my $caller_stack = undef;
    my @verbose_caller = ("Package: ", "Filename: ", "Line number: ", "Subroutine: ", "Has Args? : ", "Want array? : ", "Evaltext: ", "Is require? : ");

    push @verbose_caller, ("Hints:  ", "Bitmask:  ") if $] >= 5.006; # 5.6 has a more verbose caller stack.

    while (my @caller = caller($caller_count++)){
        $caller_stack .= "\t---------\n";
        foreach (0..$#caller){
            $caller_stack .= "\t\t$verbose_caller[$_]$caller[$_]\n" if $caller[$_];
        };
    };

    $caller_stack .= "\t---------\n";
    return $caller_stack;
};

sub log_it {
    my %init = @_;

    my $message  = $init{message};

    local *LOG;

    my %pairs = (
        "log_notify"  => "notify_log",
        "log_explode" => "explode_log",
        "log_it"      => "log_file"
    );

    foreach my $permission (grep {$init{$_}} keys %pairs) {
        my $file = $init{$pairs{$permission}};
        if (ref $file){
            print $file "\n__________________\n$message\n__________________\n";
        }
        else {
            open (LOG, ">>$file") or error($init{'error_function'},"Cannot open log file: $!");
            print LOG "\n__________________\n$message\n__________________\n";
            close LOG or error($init{'error_function'},"Cannot close log file: $!");
        };
    };
};

sub simple_smtp_mailer {
    my %init = @_;
    my $message = $init{"message"};

    use Socket;

    local *MAIL;
    my $response = undef;
    my ($s_tries, $c_tries) = (5, 5);
    local $\ = "\015\012";
    local $/ = "\015\012";

    # connect to the server
    1 while ($s_tries-- && ! socket(MAIL, PF_INET, SOCK_STREAM, getprotobyname('tcp')));
    return error($init{'error_function'}, "Socket error $!") if $s_tries < 0;

    my $remote_address = inet_aton($init{'smtp'});
    my $paddr = sockaddr_in($init{'port'}, $remote_address);
    1 while ! connect(MAIL, $paddr) && $c_tries--;
    return error($init{'error_function'}, "Connect error $!") if $c_tries < 0;

    # keep our bulk pipes piping hot.
    select((select(MAIL), $| = 1)[0]);
    # connected

    # build the envelope
    my @conversation =
        (
            ["", "No response from server: ?"],
            ["HELO $def{'domain'}", "Mean ole' server won't say HELO: ?"],
            ["RSET", "Cannot reset connection: ?"],
            ["MAIL FROM:<$def{'return'}>", "Invalid Sender: ?"],
            ["RCPT TO:<$init{'email'}>", "Invalid Recipient: ?"],
            ["DATA", "Not ready to accept data: ?"]
        );

    while (my $array_ref = shift @conversation){
        my ($i_say, $i_die) = @{$array_ref};
        print MAIL $i_say if $i_say;
        my $response = <MAIL> || "";

        if (! $response || $response =~ /^[45]/){
            $i_die =~ s/\?/$response/;
            return error($init{'error_function'}, $i_die);
        };
        return error($init{'error_function'}, "Server disconnected: $response") if $response =~ /^221/;

    };
    # built

    # send the data
    print MAIL "Date: ", today();
    print MAIL "From: $init{'return'}";
    print MAIL "Subject: $init{'subject'}";
    print MAIL "To: $init{'email'}";
    print MAIL "X-Priority:2  (High)";
    print MAIL "X-Carp-Notify: $Carp::Notify::VERSION";

    print MAIL "";

    $message =~ s/^\./../gm;
    $message =~ s/(\r?\n|\r)/\015\012/g;

    print MAIL $message;

    print MAIL ".";
    # sent

    return 1; # yay!
};

sub today {
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @days   = qw(Sun Mon Tue Wed Thu Fri Sat);

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $year += 1900;
    my ($gmin, $ghour, $gsdst) = (gmtime(time))[1,2, -1];

    my $diffhour = $hour - $ghour;
    $diffhour = 12 - $diffhour if $diffhour > 12;
    $diffhour = 12 + $diffhour if $diffhour < -12;

    ($diffhour = sprintf("%03d", $diffhour)) =~ s/^0/\+/;

    return sprintf("%s, %02d %s %04d %02d:%02d:%02d %05s",
        $days[$wday], $mday, $months[$mon], $year, $hour, $min, $sec, $diffhour . sprintf("%02d", $min - $gmin));
};

# error does nothing unless you specify the error_function, in that case it's called with the error provided.
sub error {
    my ($func, $error) = @_;
    if (ref $func eq 'CODE'){
        $func->($error);
    }
    elsif ($func){
        # this wants reworked
        no strict 'refs';
        my ($calling_package) = (caller)[0];
        my $package = $calling_package . "::";
        $package = $1 if $$func =~ s/(.+::)//;
        &{$package . $func}($error);
    }
    else {
        return;
    };
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Carp::Notify - Loudly complain in lots of places when things break badly

=head1 VERSION

version 1.13

=head1 SYNOPSIS

Use it in place of die or croak, or warn or carp.

 # with Carp;
 use Carp;
 if ($something_a_little_bad) { carp("Oh no, a minor error!")};
 if ($something_bad) { croak ("Oh no an error!")};


 # with Carp::Notify;
 use Carp::Notify;
 if (something_a_little_bad) {notify("Oh no, a minor error!")};
 if ($something_bad) { explode ("Oh no an error!")};

=head1 DESCRIPTION

Carp::Notify is an error reporting module designed for applications that are running unsupervised (a CGI script, for example,
or a cron job).  If a program has an explosion, it terminates (same as die or croak or exit, depending on preference) and
then emails someone with useful information about what caused the problem.  Said information can also be logged to a file.
If you want the program to tell you something about an error that's non fatal (disk size approaching full, but not quite
there, for example), then you can have it notify you of the error but not terminate the program.

Defaults are set up within the module, but they can be overridden once the module is used, or as individual explosions take place.
B<Please> set up your appropriate defaults in the module.  It'll save you headaches later.

=head1 IMPORTANT NOTE

This version is nearly identical to, and I<is> bug-for-bug compatible with, version 1.10 which has been on CPAN
for years but has not been indexed.

This public release is intended to catch the attention of anyone actually using this module and let them know
that changes are coming!

=head1 REQUIRES

Perl 5.005, Socket (for emailing)

=head1 BUILT IN STUFF

=over 11

=item Using the module

use Carp::Notify;

will require and import the module, same as always.  What you decide to import it with is up to you.  You can choose to import
additional functions into your namespace, set up new default values, or give it a list of variables to store.

Carp::Notify will B<always> export the explode function and the notify function.  Carp always exports carp, croak, and confess,
so I figure that I can get away with always exporting explode and notify.  Nyaah.

Be sure that you set your default variables before using it!

=over 3

=item make_storable

if this is an import argument, it will export the make_storable function into your namespace.  See make_storable, below.

=back

=over 3

=item make_unstorable

If this is an import argument, it will export the make_unstorable function into your namespce.  See make_unstorable, below.

=back

=over 3

=item croak

If this is an import argument, it will override the croak function in your namespace and alias it to explode.  That way
you can switch all of your croaks to explodes by just changing how you use your module, and not all of your code.

=back

=over 3

=item carp

If this is an import argument, it will override the carp function in your namespace and alias it to notify.  That way
you can switch all of your carps to notifies by just changing which module you use, and not all of your code.

=back

=over 3

=item (log_it|log_file|log_explode|explode_log|log_notify|notify_log|store_vars|stack_trace|store_env|email_it|email|return|subject|smtp|domain|port|die_to_stdout|die_quietly|die_everywhere|death_message|death_function|error_function)

Example:

 use Carp::Notify (
        "log_it" => 1,
        "email_it => 0,
        "email" => 'thomasoniii@yahoo.com'
 );

These are hash keys that allow you to override the Carp::Notify's module defaults.  These can also all be overloaded explicitly
in your explode() calls, but this allows a global modification.

=back

=over 2

=item log_it

Flag that tells Carp::Notify whether or not to log the explosions to the main log file

=back

=over 2

=item log_file

Overrides the default log file.  This file will be opened in append mode and the error
message will be stored in it, if I<log_it> is true.

If you'd like, you can give log_file a reference to a glob that is an open filehandle instead
of a scalar containing the log name.  This is most useful if you want to redirect your error log
to STDERR or to a pipe to a program.

Be sure to use globrefs only explicitly in your call to explode, or to wrap the definition of the
filehandle in a begin block before using the module.  Otherwise, you'll be trying to log to
a non-existent file handle and consequently won't log anything.  That'd be bad.

log_file stores all notifications AND explosions

=back

=over 2

=item log_explode

Flag that tells Carp::Notify whether or not to log the explosions to the explosion log

=back

=over 2

=item explode_log

Overrides the default explosion log file.  This file will be opened in append mode and the explosion
message will be stored in it, if I<log_it> is true.

If you'd like, you can give explode_log a reference to a glob that is an open filehandle instead
of a scalar containing the log name.  This is most useful if you want to redirect your explosion log
to STDERR or to a pipe to a program.

Be sure to use globrefs only explicitly in your call to explode, or to wrap the definition of the
filehandle in a begin block before using the module.  Otherwise, you'll be trying to log to
a non-existent file handle and consequently won't log anything.  That'd be bad.

explode_log stores ONLY explosions

=back

=over 2

=item log_notify

Flag that tells Carp::Notify whether or not to log the notifications to the notification log

=back

=over 2

=item notify_log

Overrides the default notification log file.  This file will be opened in append mode and the notification
message will be stored in it, if I<log_it> is true.

If you'd like, you can give notify_log a reference to a glob that is an open filehandle instead
of a scalar containing the log name.  This is most useful if you want to redirect your notification log
to STDERR or to a pipe to a program.

Be sure to use globrefs only explicitly in your call to notify, or to wrap the definition of the
filehandle in a begin block before using the module.  Otherwise, you'll be trying to log to
a non-existent file handle and consequently won't log anything.  That'd be bad.

notify_log stores ONLY notifications

=back

=over 2

=item store_vars

Flag that tells Carp::Notify whether or not to list any storable variables in the error message.  See storable variables, below.

=back

=over 2

=item stack_trace

Flag that tells Carp::Notify whether or not to do a call stack trace of every function call leading up to the explosion.

=back

=over 2

=item store_env

Flag that tells Carp::Notify whether or not to store the environment variables in the error message.

=back

=over 2

=item email_it

Flag that tells Carp::Notify whether or not to email a user to let them know something broke

=back

=over 2

=item email

Overrides the default email address.  This is whoever the error message will get emailed to
if C<email_it> is true.

=back

=over 2

=item return

Overrides the default return address.  This is whoever the error message will be coming from
if C<email_it> is true.

=back

=over 2

=item subject

Overrides the default subject.  This is the subject of the email message
if C<email_it> is true.

=back

=over 2

=item smtp

Allows you to set a new SMTP relay for emailing

=back

=over 2

=item port

Allows you to set a new SMTP port for emailing

=back

=over 2

=item domain

Allows you to set a new SMTP domain for emailing

=back

=over 2

=item die_to_stdout

Allows you to terminate your program by displaying an error to STDOUT, not to STDERR.

=back

=over 2

=item die_quietly

Terminates your program without displaying any message to STDOUT or STDERR.

=back

=over 2

=item die_everywhere

Terminates your program and displays error message to STDOUT and STDERR.

=back

=over 2

=item death_message

The message that is printed to the appropriate location, unless we're dying quietly.

=back

=over 2

=item death_function

death_function can be called instead of death_message, for a more dynamic error message.
It is handed a hash all of the Carp::Notify variables along with an additional key 'errors' containing
the errors in the current explosion or notification.

death_function's use will cause the program to terminate with a simple 'exit'.  You'll have to die within death_function
yourself if you want to pass on that way.

death_function may be a coderef or a string containing a function name ('death_function', 'main::death', '&death', etc.)

=back

=over 2

=item error_function

error_function is called by Carp::Notify if it encounters an error (cannot open log file, or cannot connect
to SMTP server, for instance), it is given one parameter, the literal error that occurred.  You may set this parameter
to do additional processing if Carp::Notify cannot complete error notification.

error_function may be a coderef or a string containing a function name ('error_function', 'main::error', '&error', etc.)
=back

=back

=over 3

=item (I<storable variable>)

A variable name within B<single> quotes will tell the Carp::Notify module that you want to report the current value of that variable when
the explosion occurs.  Carp::Notify will report an error if you try to store a value that is undefined, if you had accidentally
typed something in single quotes, for instance.  For example,

 use Carp::Notify ('$scalar', '@array');

 $scalar = "some_value";
 @array = qw(val1 val2 val3);

 explode("An error!");

will write out the values "$scalar : some_value" and "@array : val1 val2 val3" to the log file.

This can B<only> be used to store global variables. Dynamic or lexical variables need to be explicitly placed in explode() calls.

You can store variables from other packages if you'd like:

use Carp::Notify ('$other_package::scalar', '@some::nested::package::array');

Only I<global> scalars, arrays, and hashes may be stored in 1.00. 1.10 allows you to store a function call as well, the function will
be called with the same arguements that death_message would receive.  Its return value will be stored along with other stored variables.

=back

=back

=over 11

=item make_storable

Makes whatever variables it's given storable.  See I<storable variables>, above.

 make_storable('$new_scalar', '@different_array');

=back

=over 11

=item make_unstorable

Stops whatever variables it's given from being stored.  See I<storable variables>, above.

 make_unstorable('$scalar', '@different_array');

=back

=over 11

=item explode

explode is where the magic is.  It's exported into the calling package by default (no point in using this module if you're
not gonna use this function, after all).

You can override your default values here (see I<Using the module above>), if you'd like, and otherwise specify as many error messages
as you'd like to show up in your logs.

 # override who the mail's going to, and the log file.
 explode("email" => "thomasoniii@yahoo.com", log_file => "/home/jim/jim_explosions.log", "A terrible error: $!");

 # Same thing, but with a globref to the same file
 open (LOG, ">>/home/jim/jim_explosions.log");
 explode("email" => "thomasoniii@yahoo.com", log_file => \*LOG, "A terrible error: $!");


 # don't log.
 explode ("log_it" => 0, "A terrible error: $!");

 # keep the defaults
 explode("A terrible error: $!", "And DBI said:  $DBI::errstr");

=back

=over 11

=item notify

notify is to explode as warn is to die.  It does everything exactly the same way, but it won't terminate your program the
way that an explode would.

=back

=head1 Internal functions

=over 11

=item error

Used to proxy to the registered error_function, if any.

=item today

Used to for standard formatting of the date.

=item simple_smtp_mailer

Used to speak to an SMTP server.

=back

=head1 FAQ

B<So what's the point of this thing?>

It's for programs that need to keep running and that need to be fixed quickly when they break.

B<But I like Carp>

I like Carp too.  :)

This isn't designed to replace Carp, it serves a different purpose.  Carp will only tell you the line on which your error occurred.
While this i helpful, it doesn't get your program running quicker and it doesn't help you to find an error that you're not aware of
in a CGI script that you think is running perfectly.

Carp::Notify tells you ASAP when your program breaks, so you can inspect and correct it quicker.  You're going to have less downtime
and the end users will be happier with your program because there will be fewer bugs since you ironed them out quicker.

B<Wow.  That was a real run-on sentence>

Yeah, I know.  That's why I'm a programmer and not an author.  :)

B<What about CGI::Carp?>

That's a bit of a gray area.  Obviously, by its name, CGI::Carp seems designed for CGI scripts, whereas Carp::Notify is more
obvious for anything (cron jobs, command line utilities, as well as CGIs).

Carp::Notify also can store more information with less interaction from the programmer.  Plus it will email you, if you'd like
to let you know that something bad happened.

As I understand it, CGI::Carp is a subset feature-wise of Carp::Notify.  If CGI::Carp is working fine for you -- great, continue to use
it.  If you want more flexible error notification, then try out Carp::Notify.

B<But I can send email with CGI::Carp by opening up a pipe to send mail and using that as my error log.  What do you have
to say about that?>

Good for you.  I can too.  But most people that I've interacted with either don't have the know-how to do that or just plain
wouldn't have thought of it.  Besides, it's still more of a hassle than just using Carp::Notify.

B<Why are your stored variables kept in an array instead of a hash?  Hashes are quicker to delete from, after all>

While it is definitely true that variables can be unstored a little quicker in a hash, I figured that stored variables
will only rarely be unstored later.  Arrays are quicker for storing and accessing the items later, since they're only accessed en masse.
I'll live with the slight performance hit for the rarer case.

B<Can I store variables that are in another package from the one that called Carp::Notify?>

You betcha.  Just prepend the classpath to the variable name, same as you always have to to access variables not in your name
space.  If the variable is already in your name space (you imported it), you don't need the classpath since explode will
just pick it up within your own namespace.

B<Can I store local or my variables?>

Not in the use statement, but you can in an explicit explode.

B<Are there any bugs I should be aware of?>

If you import explode into your package, then subclass it and export explode back out it won't correctly
pick up your stored variables unless you fully qualified them with the class path ($package::variable instead of just $variable)

Solution?  Don't re-export Carp::Notify.  But you already knew that you should just re-use it in your subclass, right?

Always exports explode and notify no matter what is specified in the use statement. This is according to the original design but contrary to
current conventions and is now considered to be a bug.

make_storable and make_unstorable don't scope the variables they store/unstore by the calling package, which means
that they don't affect the results of store_vars.

store_vars destroys the contents of the stored variables, making multiple notifications from the same package not work well.

store_vars doesn't gracefully handle being called directly from the main script (i.e. it expects there to be at least one other function
in the call stack).

The internal function today doesn't always report GMT offsets for some timezones that don't use whole hours
(e.g. Indian/Cocos aka CCT, which is sometimes reported as +07-30 instead of +0630).

The internal function today has an edge condition where the GMT offset could report one additional or one less
minute of offset (rare).

B<Could I see some more examples?>

Sure, that's the next section.

B<Okay, you've convinced me.  What other nifty modules have you distributed?>

Mail::Bulkmail and Text::Flowchart.

B<Was that a shameless plug?>

Why yes, yes it was.

=head1 Examples

 # store $data, do email the errors, and alias croak => explode
 use Carp::Notify ('$data', 'email_it' => 1, "croak");

 # email it to a different address, and don't log it.
 use Carp::Notify ("email" => 'thomasoniii@yahoo.com', 'log_it' => 0);

 # don't use global log file, log explosions and notifys separately.
 use Carp::Notify ('log_it' => 0, 'log_explode' => 1, 'log_notify => 1);

 # die with an explosion.
 explode("Ye gods!  An error!");

 # die with an explosion and a different email subject.
 explode ('subject' => "HOLY SHIT THIS IS BAD!", "The reactor core breached.");

 # explode, but do it quietly.
 explode ("die_quietly" => 1, "Ye gods!  An error!");

 # notify someone of a problem, but keep the program running
 notify ("Ye gods!  A little error!");

=head1 Version History

=over 11

v1.12 - Mar 31, 2016 -

* Fix tests relying on hash ordering

* fix double adding of 1900 to year in calculations

* minor cleanups for Test::Perl::Critic and Test::Pod::Coverage

* eliminate conditional 'my' statements

v1.11 - Feb 1, 2013 -

* Updated documentation and maintainership.

v1.10 - April 13, 2001 -

* Long overdue re-write/enhancements.

* Cleaned up the internals.

* Added support for different log files for notifys/explodes.

* Added support for changing all the defaults externally.

* Improved today() function with Mail::Bulkmail's date generation.

* Added death_function to call upon dying instead of death_message.

* Added error_function to help handle unforeseen problems.

* Perl 5.6's 'caller' function returns an extra two fields of information.  Jeff Boes pointed this
out and extra-helpfully provided a patch for it as well.

* Added the ability to config the SMTP port.  I was just being lazy in v1.00.  :*)

v1.00 - August 10, 2000 - Changed the name from Explode to Carp::Notify.  It's more descriptive and I don't create a new namespace.

v1.00 FC1 - June 9, 2000 - First publically available version.

=back

=head1 AUTHORS

=over 4

=item *

Brian Conry <perl@theconrys.com>

=item *

Jim Thomason <thomasoniii@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Conry, and 2000, 2001 by Jim Thomason.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Carp::Notify

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Carp-Notify>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Carp-Notify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Notify>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Carp-Notify>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Carp-Notify>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Carp-Notify>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Carp-Notify>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Carp-Notify>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Carp-Notify>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Carp::Notify>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-carp-notify at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Carp-Notify>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/buc0/carp-notify>

  git clone git://github.com/buc0/carp-notify.git

=cut
