#!/usr/bin/perl -wT
#This file is Copyright (C) 2000-2003 Peter Behroozi and is
#licensed for use under the same terms as Perl itself.
package CGI::SecureState;

use strict;
use CGI;
use Crypt::Blowfish;
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);
use File::Spec;
use Fcntl qw(:flock :DEFAULT);
use vars qw(@ISA $VERSION $Counter $NASTY_WARNINGS $AVOID_SYMLINKS
	    $SEEK_SET $USE_FLOCK);

BEGIN {
@ISA=qw(CGI);
$VERSION = '0.36';

#Set this to 0 if you want warnings about deprecated behavior to be suppressed,
#especially if you are upgrading from CGI::SecureState 0.2x.  However, heed the
#warnings issued when this is set to 1 because they will better your coding style
#and likely increase program security.
$NASTY_WARNINGS = 1;

#Set this to 0 if you don't want CGI::SecureState to test for a symlink attack
#before writing to a state file.  If this is set to 1 and CGI::SecureState sees a
#symlink in place of a real file, it will spit out a fatal error.
$AVOID_SYMLINKS = 1;

#Set this to 0 if you do not want CGI::SecureState to use flock() to assure that
#only one instance of CGI::SecureState is accessing the state file at a time.
#Leave this at 1 unless you really have a good reason not to.
$USE_FLOCK = 1;

#The operating systems below do not support flock, except for Windows NT systems,
#but it is impossible to distinguish WinNT systems from Win9x systems only based
#on $^O
local $_=$^O;
$USE_FLOCK = 0 if (/MacOS/i || /V[MO]S/i || /MSWin32/i);

#Workaround for Perl v5.005_03
$SEEK_SET = ($]<5.006) ? 0 : &Fcntl::SEEK_SET;
}

sub import {
    foreach (@_) {
	$NASTY_WARNINGS=0, next if (/[:-]?no_nasty_warnings/);
	$AVOID_SYMLINKS=0, next if (/[:-]?dont_avoid_symlinks/);
	$USE_FLOCK=0,      next if (/[:-]?no_flock/);
	$USE_FLOCK=1,      next if (/[:-]?use_flock/);
	if (/[:-]?(extra|paranoid|no)_secure/) {
	    $CGI::PRIVATE_TEMPFILES = ! /no_/;
	    $CGI::POST_MAX = /no_/ ? -1 : 10240;
	    $CGI::DISABLE_UPLOADS = /paranoid_/;
	}
    }
}


sub new
{
    #Obtain the class (should be CGI::SecureState in most cases)
    my $class = shift;

    #populate the argument array
    my %args = args_to_hash([qw(-stateDir -mindSet -memory -temp -key)], @_);

    #Set up the CGI object to our liking
    my $cgi=new CGI;

    #We don't want any nassssty tricksssy people playing with things that we
    #should be setting ourselves
    $cgi->delete($_) foreach (qw(.statefile .cipher .isforgetful .memory
				 .recent_memory .age .errormsg));

    #if the user has an error message subroutine, we should use it:
    $cgi->{'.errormsg'} = $args{'-errorSub'} || $args{'-errorsub'} || undef;

    #set the forgetfulness;  By default, this is "forgetful" because it encourages
    #cleaner programming, but if the user is upgrading from 0.2x series, this will be
    #undef; if so, be backwards-compatible but give them a few nasty warning messages.
    $args{'-mindSet'} = $args{'-mindset'} unless (defined $args{'-mindSet'});
    $cgi->{'.isforgetful'} = $args{'-mindSet'};

    if (defined $args{'-mindSet'}) {
	$cgi->{'.isforgetful'} = 0 if ($args{'-mindSet'} =~ /unforgetful/i);
    } elsif ($NASTY_WARNINGS) {
	warn "Programmer did not set mindset when declaring new CGI::SecureState object at ",
	    (caller)[1], " line ", (caller)[2], ".  Please tell him/her to read the new CGI::SecureState ",
	    "documentation.\n";
    }

    #Set up long-term memory
    $args{'-memory'} ||= $args{'-longTerm'} || $args{'-longterm'} || [];
    $cgi->{'.memory'} = {map {$_ => 1} @{$args{'-memory'}}};

    #Set up short-term memory
    $args{'-temp'} ||= $args{'-shortTerm'} || $args{'-shortterm'} || [];
    $cgi->{'.recent_memory'} = {map {$_ => undef} @{$args{'-temp'}}};

    #Check for ID tag in url if it is not in the normal parameters list
    if (!defined($cgi->param('.id')) && $cgi->request_method() eq 'POST') {
	$cgi->param('.id', $cgi->url_param('.id'));
    }

    #Set up the encryption part
    my $id = $cgi->param('.id') || sha1_hex($args{'-key'} or generate_id());
    my $remote_addr = $cgi->remote_addr();
    my $remoteip = pack("CCCC", split (/\./, $remote_addr));
    my $key = pack("H*",$id) . $remoteip;
    $cgi->{'.cipher'} = new Crypt::Blowfish($key) || errormsg($cgi, 'invalid state file');

    #set the directory where we will store saved information
    my $statedir = $args{'-stateDir'} || $args{'-statedir'} || ".";

    #Set up (and untaint) the name of the location to store data
    my $statefile = sha1_base64($id.$remote_addr);
    $statefile =~ tr|+/|_-|;
    $statefile =~ /([\w-]{27})/;
    $cgi->{'.statefile'} = File::Spec->catfile($statedir,$1);

    #convert $cgi into a CGI::SecureState object
    bless $cgi, $class;

    #if this is not a new session, attempt to read from the state file
    $cgi->param('.id') ? $cgi->recover_memory : $cgi->param('.id' => $id);

    #save any changes to the state file; if there are none, then update only the timestamp
    my $newmemory = (@{$args{'-memory'}}) ? 1 : 0;
    ($newmemory || !$cgi->{'.isforgetful'}) ? $cgi->save_memory : $cgi->encipher;

    #finish
    return $cgi;
}

sub add {
    my $self = shift;
    my %params = (ref($_[1]) eq 'ARRAY') ? @_ : (shift, \@_);
    $self->param($_, @{$params{$_}}) foreach (keys %params);
    $self->remember(keys %params);
}

sub remember {
    my $self = shift;
    my ($isforgetful,$memory) = @$self{'.isforgetful','.memory'};
    $isforgetful ? $memory->{$_}=1 : delete($memory->{$_}) foreach (@_);
    $self->save_memory;
}

sub delete {
    my $self = shift;
    my ($isforgetful,$memory) = @$self{'.isforgetful','.memory'};
    foreach (@_) {
	delete $memory->{$_} if ($isforgetful);
	$self->SUPER::delete($_);
    }
    $self->save_memory;
}

sub delete_all
{
    my $self = shift;
    my (@state) = @$self{qw(.statefile .cipher .isforgetful .memory .age .errormsg)};
    my $id=$self->param('.id');
    $self->SUPER::delete_all();
    $self->param('.id' => $id);
    @$self{qw(.statefile .cipher .isforgetful .memory .age .errormsg)} = @state;
    $self->{'.memory'}={} if ($self->{'.isforgetful'});
    $self->{'.recent_memory'} = {};
    $self->save_memory;
}

sub delete_session {
    my $self = shift;
    unlink $self->{'.statefile'} or $self->errormsg('failed to delete the state file');
    $self->SUPER::delete_all;
}

sub params {
    my $self = shift;
    return $self->param unless (@_);
    return map { scalar $self->param($_) } @_;
}

sub user_param 
{
    my $self = shift;
    return $self->param unless (@_);
    if (@_ == 1) {
	my $param = shift;
	my $value = $self->{'.recent_memory'}->{$param};
	return $self->param($param) if (!defined $value);
	return wantarray ? @$value : $value->[0];
    } else {
	my %params = (ref($_[1]) eq 'ARRAY') ? @_ : (shift, \@_);
	$self->{'.recent_memory'}->{$_}=[@{$params{$_}}] foreach (keys %params);
    }
}

sub user_params {
    my $self = shift;
    return $self->param unless (@_);
    return map { scalar $self->user_param($_) } @_;
}

sub user_delete {
    my $self = shift;
    delete @{$self->{'.recent_memory'}}{@_};
}

sub age {
    my $self = shift;
    if (defined $self->{'.age'}) {
	my $current_time=unpack("N",pack("N",time()));
	return (($current_time-$self->{'.age'})/24/3600);
    }
    return 0;
}

sub state_url {
    my $self = shift;
    return $self->script_name()."?.id=".$self->param('.id');
}

sub state_param {
    my $self = shift;
    return ".id=" . $self->param('.id');
}

sub state_field {
    my $self = shift;
    return $self->hidden('.id' => $self->param('.id'));
}

sub memory_as {
    my ($self, $type) = @_;
    return (($type eq 'url')   ?  $self->state_url   . $self->stringify_recent_memory('url')  :
	    ($type eq 'param') ?  $self->state_param . $self->stringify_recent_memory('url')  :
	    ($type eq 'field') ?  $self->state_field . $self->stringify_recent_memory('form') : undef);
}

sub start_html {
    my $self=shift;
    my $isforgetful=$self->{'.isforgetful'};
    if ($NASTY_WARNINGS && ! defined $isforgetful) {
	return $self->SUPER::start_html(@_) . 'The author of this dynamic web-enabled application did not set the '.
	    'mandatory \'-mindSet\' attribute when creating a CGI::SecureState object.  Please contact him/her and '.
	    'tell him/her to read the updated CGI::SecureState documentation.';
    }
    return $self->SUPER::start_html(@_);
}


sub clean_statedir
{
    my $self = shift;
    my %args = args_to_hash([qw(-age -directory)], @_);
    my @states;

    if (!defined $args{'-directory'}) {
	return unless $self->{'.statefile'};
	my ($volume, $directory) = File::Spec->splitpath($self->{'.statefile'});
	$args{'-directory'} = ($volume or '') . $directory;
    }
    $args{'-age'} ||= 1/24;

    opendir STATEDIR, $args{'-directory'} or return;
    foreach (readdir STATEDIR) {
	next unless /^([0-9A-Za-z_-]{27})$/;
	push @states, File::Spec->catfile($args{'-directory'}, $1);
    }
    closedir STATEDIR;

    my $removed = 0;
    my @old_states = grep { -M $_ > $args{'-age'} } @states;
    foreach (@old_states) {
	warn "Symlink encountered at $_\n" if ($AVOID_SYMLINKS && -l);
	(unlink $_) ? $removed++ : warn "Could not remove old state file $_: $!\n";
    }
    return @old_states ? $removed/@old_states : 1;
}

sub errormsg
{
    my $self=shift;
    if (ref($self->{'.errormsg'}) eq 'CODE') {
	$self->{'.errormsg'}->(@_) && exit;
    }
    my $error = shift;
    print $self->header;
    print $self->start_html(-title => "Server Error: \u$error.", -bgcolor => "white");
    print "<br>\n", $self->h1("The following error was encountered:");
    if ($error =~ /^failed/) {
	print("<p>The server $error, which is a file manipulation error.  This is most likely due to a bug in ",
	      "the referring script or a permissions problem on the server.</p>");
    } elsif ($error eq "symlink encountered") {
	print("<p>The server encountered a symlink in the state file directory.  This is usually the sign of an ",
	      "attempted security breach and has been logged in the server log files.  It is unlikely that you are ",
	      "responsible for this error, but it is nonetheless fatal.</p>");
	warn("CGI::SecureState FATAL error: Symlink encountered while trying to access $self->{'.statefile'}");
    } elsif ($error eq "invalid state file") {
	print("The file that stores information about your session has been corrupted on the server. ",
	      "This is usually the sign of an attemped security breach and has been logged in the server ",
	      " log files.  It is unlikely that you are responsible for this error, but it is nonetheless fatal.</p>");
	warn("CGI::SecureState FATAL error: The state file $self->{'.statefile'} became corrupted.");
    } elsif ($error eq "statefile inconsistent with mindset") {
	print("The mindset of the statefile is different from that specified in the referring script.  This is",
	      " most likely a bug in the referring script, but could also be due to a file permissions problem.</p>");
    } else {
	print "<p>$error.</p>";
	warn("CGI::SecureState FATAL error: $error.");
    }
    print $self->end_html;
    exit;
}


#### Subroutines below this line are for private use only ####
sub generate_id {
    return join("", map { sprintf("%.32f", $_) }
		        (rand(), rand(), time()^rand(), $CGI::SecureState::Counter+=rand()));
}


sub args_to_hash {
    my $list = shift;
    return unless @_;
    return ($_[0] =~ /^-/) ? @_ : map { shift @$list => $_ } @_;
}



sub stringify_recent_memory 
{
    my ($self, $format) = @_;
    my $recent_memory = $self->{'.recent_memory'};
    my ($leading, $separating, $closing, $result);

    if ($format eq 'url') {
	$leading = $CGI::USE_PARAM_SEMICOLONS ? ';' : '&';
	($separating, $closing) = ('=', '');
    } elsif ($format eq 'form') {
	($leading, $separating, $closing) = ("\n<input type=hidden name=\"", '" value="', '" />');
    }

    foreach (keys %$recent_memory) {
	next if ($_ eq '.id' or substr($_,0,4) eq '.tmp');
	my $param = $_;
	escape_url($param) if ($format eq 'url');  #Do URL-encoding
	$param = $self->escapeHTML($param) if ($format eq 'form');
	foreach (@{$recent_memory->{$param}}) {
	    my $value = $_;
	    escape_url($value) if ($format eq 'url');  #Do URL-encoding
	    $value = $self->escapeHTML($value) if ($format eq 'form');
	    $result .= $leading . ".tmp$param" . $separating . $value . $closing;
	}
    }
    return $result;
}

sub recover_recent_memory {
    my $self = shift;
    my $recent_memory = $self->{'.recent_memory'};
    foreach my $param (keys %$recent_memory) {
	my @values = $self->param($param);
	$recent_memory->{$param} = @values ? \@values : [ $self->param(".tmp$param") ];
	$self->SUPER::delete(".tmp$param");
	$self->param($param => undef) unless @values;
    }
}


#Workaround for Perl v5.005_03 so that Unicode is encrypted
#and decrypted properly.
BEGIN {
my $subs = <<'END_OF_FUNCTIONS'

#Derived from the escape funtion of CGI::Util
sub escape_url {
    $_[0]=~s/([^a-zA-Z0-9_.-])/sprintf("%%%02X",ord($1))/eg;
}

sub save_memory
{
    my $self=shift;
    my (@data,@values,$entity);
    my ($isforgetful,$memory)=@$self{'.isforgetful','.memory'};

    #If we are forgetful, then we need to save the contents of our memory
    #If we remember stuff, then we need to save everything but the contents of our memory
    foreach ($self->param)  {
	next if ($isforgetful xor (exists $memory->{$_}));
	next if ($_ eq '.id' or substr($_,0,4) eq '.tmp');
	if (@values=$self->param($_)) {
	    foreach $entity ($_, @values) { $entity =~ s/([ \n\\])/\\$1/go }  #escape meta-characters
	    push @data, join("  ",@values), $_;
	}
    }

    push @data, $isforgetful ? "Forgetful" :  "Remembering";
    $self->encipher(join("\n\n", @data, "Saved-Values"));
}

sub recover_memory
{
    my $self=shift;
    my (@data,$param,@values, $value);
    my ($isforgetful,$memory)=@$self{'.isforgetful','.memory'};

    #recover short-term "recent" memory
    $self->recover_recent_memory();

    @data = split(/(?<!\\)\n\n/, $self->decipher);

    if (@data) {
	#skip over fields until we get to the Saved-Values section
	#to retain compatibility with later versions of CGI::SecureState
	do { $param=pop(@data) } while ($param ne "Saved-Values" && @data);

	#check to make sure that our mindset is the same as the statefile's
	$param=pop @data;
	if ($param ne ($isforgetful ? "Forgetful" : "Remembering")) {
	    $self->errormsg('statefile inconsistent with mindset') }

	while (@data) {
	    ($param = pop @data) =~ s/\\(.)/$1/go; #unescape meta-characters
	    @values=split(/(?<!\\)\ \ /, pop @data);
	    next if (!$isforgetful && (exists($memory->{$param}) || defined $self->param($param)));
	    foreach $value (@values) { $value =~ s/\\(.)/$1/go } #unescape meta-characters
	    $self->param($param,@values);
	    $self->{'.memory'}->{$param}=1 if ($isforgetful);
	}
    }
}


#The encipher subroutine accepts a list of values to encrypt and writes them to
#the state file.  If the list of values is empty, it merely updates the timestamp
#of the state file.
sub encipher
{
    my ($self, $buffer) = @_;
    my ($cipher, $statefile) = @$self{'.cipher','.statefile'};
    my ($length, $time, $block);
    $time=pack("N",time());

    # Open the target file and die with warnings if necessary
    my $open_flags = $buffer ? (O_WRONLY | O_TRUNC | O_CREAT) : (O_RDWR | O_CREAT);
    if ($AVOID_SYMLINKS && -l $statefile) { $self->errormsg('symlink encountered') }
    sysopen(STATEFILE, $statefile, $open_flags, 0600 ) or $self->errormsg('failed to open the state file');
    if ($USE_FLOCK && !flock(STATEFILE, LOCK_EX)) { $self->errormsg('failed to lock the state file') }
    binmode STATEFILE;

    #if we've got nothing to write, only update the timestamp
    unless ($buffer) {
	if (sysread(STATEFILE,$buffer,16)==16) {
	    #the length of the encrypted data is stored in the first four bytes of the state file
	    $length=substr($cipher->decrypt(substr($buffer,0,8)),0,4);
	    $buffer=$length.($time^substr($buffer,12,4));
	} else {
	    $length=pack("N",0);
	    $buffer=$length.$time;
	}
	sysseek(STATEFILE,0,$SEEK_SET);
	syswrite(STATEFILE,$cipher->encrypt($buffer));
    }
    else {
	#add metadata to the beginning of the plaintext
	$length=length($buffer);
	$buffer=pack("N",$length).$time.$buffer;

	#pad the buffer to have a length that is divisible by 8
	if ($length%=8) {
	    $length=8-$length;
	    $buffer.=chr(int(rand(256))) while ($length--);
	}

	#encrypt in reverse-CBC mode
	$block=$cipher->encrypt(substr($buffer,-8,8));
	substr($buffer,-8,8,$block);

	$length=length($buffer) - 8;
	while(($length-=8)>-8) {
	    $block^=substr($buffer,$length,8);
	    $block=$cipher->encrypt($block);
	    substr($buffer,$length,8,$block);
	}

	#blast it to the file
	syswrite(STATEFILE,$buffer);
    }
    if ($USE_FLOCK) { flock(STATEFILE, LOCK_UN) || $self->errormsg('failed to unlock the state file') }
    close(STATEFILE) || $self->errormsg('failed to close the state file');
}


sub decipher
{
    my $self = shift;
    my ($cipher,$statefile) = @$self{'.cipher','.statefile'};
    my ($length,$extra,$decoded,$buffer,$block);

    if ($AVOID_SYMLINKS) { -l $statefile and $self->errormsg('symlink encountered')}
    sysopen(STATEFILE,$statefile, O_RDONLY) || $self->errormsg('failed to open the state file');
    if ($USE_FLOCK) { flock(STATEFILE, LOCK_SH) || $self->errormsg('failed to lock the state file') }
    binmode STATEFILE;

    #read metadata
    sysread(STATEFILE,$block,8);
    $block = $cipher->decrypt($block);

    #if there is nothing in the file, only set the age; otherwise read the contents
    unless (sysread(STATEFILE,$buffer,8)==8) {
	$self->{'.age'} = unpack("N",substr($block,4,4));
	$buffer = "";
    } else {
	#parse metadata
	$block^=$buffer;
	$self->{'.age'} = unpack("N",substr($block,4,4));
	$length = unpack("N",substr($block,0,4));
	$extra = ($length % 8) ? (8-($length % 8)) : 0;
	$decoded=-8;

	#sanity check
	if ((stat(STATEFILE))[7] != ($length+$extra+8))
	{ $self->errormsg('invalid state file') }

	#read the rest of the file
	sysseek(STATEFILE, 8, $SEEK_SET);
	unless (sysread(STATEFILE,$buffer,$length+$extra) == ($length+$extra))
	{ $self->errormsg('invalid state file') }

	my $next_block;
	$block = $cipher->decrypt(substr($buffer,0,8));
	#decrypt it
	while (($decoded+=8)<$length-8) {
	    $next_block = substr($buffer,$decoded+8,8);
	    $block^=$next_block;
	    substr($buffer, $decoded, 8, $block);
	    $block=$cipher->decrypt($next_block);
	}
	substr($buffer, $decoded, 8, $block);
	substr($buffer, -$extra, $extra, "");

    }
    if ($USE_FLOCK) { flock(STATEFILE, LOCK_UN) || $self->errormsg('failed to unlock the state file') }
    close(STATEFILE) || $self->errormsg('failed to close the state file');

    return($buffer);
}
END_OF_FUNCTIONS
    ;
eval(($]<5.006) ? $subs : "use bytes; $subs");
}

"True Value";

=head1 NAME

CGI::SecureState -- Transparent, secure statefulness for CGI programs

=head1 SYNOPSIS

    use CGI::SecureState;

    my @memory = qw(param1 param2 other_params_to_remember);
    my $cgi = new CGI::SecureState(-stateDir => "states",
                                   -mindSet => 'forgetful',
                                   -memory => \@memory);

    print $cgi->header(), $cgi->start_html;
    my $url = $cgi->state_url();
    my $param = $cgi->state_param();
    print "<a href=\"$url\">I am a stateful CGI session.</a>";
    print "<a href=\"other_url.pl?$param\">I am a different ",
          "script that also has access to this session.</a>";


=head2 Very Important Note for Users of CGI::SecureState 0.2x

For those still using the 0.2x series, CGI::SecureState changed enormously between
0.26 and 0.30.  Specifically, the addition of mindsets is so important that if you
run your old scripts unchanged under CGI::SecureState 0.3x, you will receive nasty
warnings (likely both in output web pages and your log files) that will tell you not
to do so.  Please do yourself a favor by re-reading this documentation, as this
mysterious mindset business (as well as all the scrumptious new features) will be
made clear.

Of course, any and all comments on the changes are welcome.  If you are interested,
send mail to behroozi@cpan.org with the subject "CGI::SecureState Comment".


=head1 DESCRIPTION

A Better Solution to the stateless problem.

HTTP is by nature a stateless protocol; as soon as the requested object is
delivered, HTTP severs the object's connection to the client.  HTTP retains no 
memory of the request details and does not relate subsequent requests with what
it has already served.

There are a few methods available to deal with this problem, including forms
and cookies, but most have problems themselves, including security issues
(cookie stealing), browser support (cookie blocking), and painful
implementations (forms).

CGI::SecureState solves this problem by storing session data in an encrypted
state file on the server.  CGI::SecureState is similar in purpose to CGI::Persistent
(and retains much of the same user interface) but has a completely different
implementation.  For those of you who have worked with CGI::Persistent before,
you will be pleased to learn that CGI::SecureState was designed to work with Perl's
taint mode and has worked flawlessly with mod_perl and Apache::Registry for over
two years.  CGI::SecureState was also designed from the ground up for security, a
fact which may rear its ugly head if anybody tries to do something tricksy.


=head1 MINDSETS

If you were curious about the mindset business mentioned earlier, this section
is for you.  In the past, CGI::SecureState had only one behavior (which I like
to call a mindset), which was to store all the CGI parameters that the client
sent to it.  Besides bloating session files, this mindset encouraged all sorts of
insidious bugs where parameters saved by one script would lurk in the state file
and cause problems for scripts down the line.

If you could tell CGI::SecureState exactly which parameters to save, then life
would get much better.  This is exactly what the shiny new "forgetful" mindset
does, as it will only store parameters that are I<in> its "memory".  The
old behavior remains, slightly modified, in the form of the "unforgetful" mindset,
which will cause CGI::SecureState to save (and recall) all parameters passed to
the script I<excepting> those that are in its "memory".

You may wonder why "memory" is in quotes.  The answer is simple: you pass
the "memory" to the CGI::SecureState object when it is initialized.  So, to
have a script that remembers everything except the parameters "foo" and "bar",
do

    my $cgi = new CGI::SecureState(-mindSet => 'unforgetful',
                                   -memory => [qw(foo bar)]);

but to have a script that forgets everything except the parameters "user" and
"pass", you would do instead

    my $cgi = new CGI::SecureState(-mindSet => 'forgetful',
                                   -memory => [qw(user pass)]);

Simple, really.  In accord with the mindset of Perl, which is that methods should
Do the Right Thing, the "forgetful" mindset will remember parameters when you
tell it to, and not forget them until you force it to do so.  This means
that if you have a script to handle logins, like

    my $cgi = new CGI::SecureState(-mindSet => 'forgetful',
                                   -memory => [qw(user pass)]);

then other scripts do not have to re-memorize the "user" and "pass" parameters;
a mere

    my $cgi = new CGI::SecureState(-mindSet => 'forgetful');
    my ($user,$pass) = ($cgi->param('user'),$cgi->param('pass'));

would suffice.  However, had you read the rest of the documentation, that last line
could even have been

    my ($user,$pass) = $cgi->params('user','pass');

Once you all see how more intuitive this new mindset is, I am sure that you
will make the switch, but, in the meantime, the "unforgetful" mindset remains.

One more note about mindsets.  In order to retain compatibility with older
scripts, the "unforgetful" mindset will allow CGI parameters received from
a client to overwrite previously saved parameters on disk.  The new
"forgetful" mindset discards parameters from clients if they already exist
on disk.  If you want to instead look at what the client sent you, then
look at the section entitled "Recent Memory".



=head1 RECENT MEMORY

Most of you know that we as humans have two types of memory: short term
and long term.  Short term memory is useful if you only need the information
for a short while and can then forget it (as in studying before a final exam).
Long term memory is useful for things that stick around, like knowing how to
ride a bicycle.

There are also two types of persistent data that a CGI application needs to store.
The first type covers data that is used a few times and then forgotten, such as
parameters passed to a search engine that displays its results over multiple pages
(known as page-state).  The second type covers data that is mostly static throughout
the application, like a username and password (known as application-state).
Coincidence?  Perhaps.

Fortunately, CGI::SecureState now supports both.  For purely short term data,
you can use the user_* functions to replace the ones you would normally use.
The user_* functions are so named to remind you that parameters that the user
passes will override corresponding parameters already in short term memory.  An
extra feature is that they will fall back to the normal functions (param(), etc.)
if you are requesting a parameter that is not in short term memory.

This means that you can now say:

   my $cgi = new CGI::SecureState(-mindSet => 'forgetful',
                                  -shortTerm => [qw(query type)]);

   my ($query, $type) = $cgi->user_params(qw(query type));
   my $next_page_url = $cgi->memory_as('url').";page=2";

and things will work out nicely.  Now, you could have used long term memory
to do the same thing, but you would be in for a nasty shock when the back button
failed to work properly.  For example, returning to the search engine, suppose
a user searched for "marzipan" and then for "eggs".  Realizing that marzipan
is the more essential ingredient, the user backs up until he gets to the marzipan
results and presses the "Next Page" link.   Since the state file would store only
the most recent search, the user recoils in horror as the "Next Page" is not filled
with succulent almond pastries but instead white quasi-elliptical spheroids.
Temporary memory does not have this problem, as it is not stored in the state file
but tacked on as a special parameter list or a special sequence of hidden input fields
when you use the memory_as() function.  The only downside is, of course, that the
temporary memory is not encrypted.  This may be fixed in a future release of
CGI::SecureState, but for now you will have to restrict sensitive information to
long term memory only.


=head1 METHODS

After that lecture on script design, I am sure that you are hungering to know how
to actually use this module.  You will not be disappointed.  CGI::SecureState inherits
its methods from CGI.pm, overriding them as necessary:

=over 4

=item B<new()>

Creates a new CGI object and creates an associated encrypted state file if
one does not already exist.  new() has exactly one required argument (the mindset,
of course!), and takes four optional arguments:

=over 2

=item -mindSet

If the mindset is not specified, then CGI::SecureState will spit out nasty warnings until you
change your scripts or set $CGI::SecureState::NASTY_WARNINGS to 0.

The mindset may be specified in a few different ways, the most common being
to spell out 'forgetful' or 'unforgetful'.  If it pleases you, you may also
use '1' to specify forgetfulness, and '0' to specify unforgetfulness.

=item -memory

These are the parameters that you either want to persist between sessions
(if you have a forgetful mindset), or those that you do not want to do so
(if you have an unforgetful mindset).  You may pass these parameters as a
reference to an array.  If you prefer the aliases "-longTerm" or "-longterm",
you may use one of those instead.

=item -shortTerm

Also taking an array reference, this argument specifies the parameters that
are not permanent enough for the state file but that you still want to keep
around for a few requests.  If you prefer the alias "-temp", you may use that
instead.

=item -key

If you are concerned about the quality of the random data generated by
multiple calls to rand(), then you can pass some better data along with
this argument.

=item -errorSub

If you do not like the default error pages, then you may pass a reference to
a subroutine that prints them out how you like them.  The subroutine should
print out a complete web page and include the "Content-Type" header.
The possible errors that can be caught by the subroutine are:

    failed to open the state file
    failed to lock the state file
    failed to unlock the state file
    failed to close the state file
    failed to delete the state file
    invalid state file
    statefile inconsistent with mindset
    symlink encountered

If the subroutine can handle the error, it should return a true value,
otherwise it should return false.

=back


Examples: 

    #forget everything but the "user" and "pass" params.
    $cgi = new CGI::SecureState(-mindSet => 'forgetful',
                                -memory => [qw(user pass)]);


    #invoke the old behavior of CGI::SecureState
    $cgi = new CGI::SecureState(-mindSet => 'unforgetful');
    $cgi = new CGI::SecureState(-mindSet => 0); #same thing

    #full listing
    $cgi = new CGI::SecureState(-stateDir => $statedir,
				-mindSet => $mindset,
				-memory => \@memory,
				-shortTerm => \@temp_memory,
				-errorSub => \&errorSub,
				-key => $key);

    #if you don't like my capitalizations, then try
    $cgi = new CGI::SecureState(-statedir => $statedir,
				-mindset => $mindset,
				-memory => \@memory,
				-shortterm => \@temp_memory,
				-errorsub => \&errorSub,
				-key => $key);

    #if you prefer the straight argument style (note absence of
    #errorSub -- it is only supported with the new argument style)
    $cgi = new CGI::SecureState($statedir, $mindset, \@memory,
				\@temp_memory, $key);

    #cause nasty warnings by not specifying the mindset
    $cgi = new CGI::SecureState($statedir);


=item B<state_url()>

Returns the URL of the current script with the state identification string.
This URL should be used for referring to the stateful session associated with
the query.  Do NOT use this as the action of a form; see the state_field() function
instead.  Note that this does not include the short term memory; see the memory_as()
function to do that.

=item B<state_param()>

Returns a key-value pair that you can use to retain the session when linking
to other scripts.  If, for example, you want the script "other.pl" to be able
to see your current script's session, you would use

    print "<a href=\"other.pl?",$cgi->state_param,
           "\">Click Here!</a>";

to do so.  Note that this does not include the short term memory; see the memory_as()
function to do that.

=item B<state_field()>

Returns a hidden INPUT type for inclusion in HTML forms. Like state_url(),
this element is used in forms to refer to the stateful session associated
with the query.  Note that this does not include the short term memory; see the memory_as()
function to do that.

=item B<memory_as()>

This allows you to get a state url/parameter/field with the short term memory
attached.  So, for example, if you wanted to retain short term memory between
invocations of your script, you would write C<< $cgi->memory_as('url') >> instead of
C<< $cgi->state_url >>.  You can also write C<< $cgi->memory_as('param') >> and
C<< $cgi->memory_as('field') >> instead of C<< $cgi->state_param >> and C<< $cgi->state_field >>.

=item B<params()>

Allows you to get the scalar values of multiple parameters at once.

    my ($user,$pass) = $cgi->params(qw(user pass));

is equivalent to

    my ($user,$pass) = (scalar $cgi->param('user'),
                        scalar $cgi->param('pass'));


=item B<user_param()>

Allows you to get (and set) a parameter in short term memory.  If it cannot
find the parameter you want to retrieve in short term memory, it will fall
back to the normal param() call to get it for you.  Setting parameters via
this function will automatically add them to short term memory if they do
not already exist.  The interface is exactly the same as that of the ordinary
param() call, except you can set more than one parameter at a time by passing
names of parameters followed by array references, as you can with add().


=item B<user_params()>

This function is analogous to params() except that it uses user_param() instead
of param() to fetch multiple values for you.


=item B<add()>

This command adds a new parameter to the CGI object and stores it to disk.
Use this command if you want something to be saved, since the param() method
will only temporarily set a parameter.  add() uses the same syntax as param(),
but you may also add more than one parameter at once if the values are in a
reference to an array:

    $cgi->add(param_a => ['value'], param_b => ['value1', 'value2']);



=item B<remember()>

This command is similar to add(), but saves current parameters to disk instead
of new ones.  For example, if "foo" and "bar" were passed in by the user and
were not previously stored on disk,

    $cgi->remember('foo','bar');

will save their values to the state file.  Use the add() method instead if you
also want to set a new value for the parameter.



=item B<delete()>

delete() is an overridden method that deletes named attributes from the
query.  The state file on disk is updated to reflect the removal of
the parameter.  Note that this has changed to accept a list of params to
delete because otherwise the state file would be separately rewritten for
each delete().

Important note: Attributes that are NOT explicitly delete()ed will lurk
about and come back to haunt you unless you use the 'forgetful' mindset!


=item B<user_delete()>

This function deletes values only from the short term memory, and has the
same syntax as the overridden delete().


=item B<delete_all()>

This command toasts all the current cgi parameters, but it merely clears
the state file instead of deleting it.  For that, use delete_session() instead.


=item B<delete_session()>

This command not only deletes all the cgi parameters, but kills the
disk image of the session as well. This method should be used when you
want to irrevocably destroy a session.


=item B<age()>

This returns the time in days since the session was last accessed.


=item B<clean_statedir()>

Over time, if you are not careful, a buildup of stale state files may occur.
You should use this call to clean them up, especially in logout scripts or cron
jobs, where performance is not the most critical issue.  This function optionally
takes two arguments: a maximum idle time (in days) beyond which state files are deleted,
and a directory to clean.  The default behavior is to clean the current state directory
of any state files that have been idle for more than an hour.  You may also name the
arguments using the '-age' and '-directory' attributes if you want to specify things
out-of-order (like C<$cgi->clean_statedir(-directory => "foo", -age => 1/2);>).

=back


=head1 GLOBALS

You may set these options to globally affect the behavior of CGI::SecureState.

=over 4

=item B<NASTY_WARNINGS>

Set this to 0 if you want warnings about deprecated behavior to be suppressed.
This is especially true if you want to be left in peace while updating scripts based 
on older versions of CGI::SecureState.  However, the warnings issued should be heeded
because they generally result in better coding style and program security.

You may either do
    use CGI::SecureState qw(:no_nasty_warnings); #or
    $CGI::SecureState::NASTY_WARNINGS = 0;


=item B<AVOID_SYMLINKS>

Set this to 0 if you don't want CGI::SecureState to test for the presence of a symlink
before writing to a state file.  If this is set to 1 and CGI::SecureState sees a 
symlink in place of a real file, it will spit out a fatal error.  It is generally
a good idea to keep this in place, but if you have a good reason to, then do
    use CGI::SecureState qw(:dont_avoid_symlinks); #or
    $CGI::SecureState::AVOID_SYMLINKS = 1;


=item B<USE_FLOCK>

Set this to 0 if you do not want CGI::SecureState to use "flock" to assure that
only one instance of CGI::SecureState is accessing the state file at a time.
Leave this at 1 unless you really have a good reason not to.

For users running a version of Windows NT (including 2000 and XP), you should set
this variable to 1 because $^O will always report "MSWin32", regardless of whether
your system is Win9x (which does not support flock) or WinNT (which does).

To set to 0, do
    use CGI::SecureState qw(:no_flock); #or
    $CGI::SecureState::USE_FLOCK = 0;

To set to 1, do
    use CGI::SecureState qw(:use_flock); #or
    $CGI::SecureState::USE_FLOCK = 1;


=item B<Extra and Paranoid Security>

If the standard security is not enough, CGI::SecureState provides extra security
by setting the appropriate options in CGI.pm.  The ":extra_security" option
enables private file uploads and sets the maximum size for a CGI POST to be
10 kilobytes.  The ":paranoid_security" option disables file uploads entirely.
To use them, do
    use CGI::SecureState qw(:extra_security);  #or
    use CGI::SecureState qw(:paranoid_security);

To disable them, do
    use CGI::SecureState qw(:no_security);
=back


=head1 EXAMPLES

There is now an official example of how to use CGI::SecureState in a large
project.  If that is what you are looking for, check out the Anthill
Bug Manager at Sourceforge (L<http://anthillbm.sourceforge.net/>).


This example is a simple log-in script.  It should have a directory called "states"
that it can write to.

  #!/usr/bin/perl -wT
  use CGI::SecureState qw(:paranoid_security);

  my $cgi = new CGI::SecureState(-stateDir => 'states',
                                 -mindSet => 'forgetful');

  my ($user,$pass,$lo)=$cgi->params(qw(user pass logout));
  my $failtime = $cgi->param('failtime') || 0;

  print $cgi->header();
  $cgi->start_html(-title => "CGI::SecureState Example");

  if ($user ne 'Cottleston' || $pass ne 'Pie') {
    if (defined $user) {
      $failtime+=$cgi->age()*86400;
      print "Incorrect Username/Password. It took you only ",
	     $cgi->age*86400, " seconds to fail this time.";
      print " It has been $failtime seconds since you started.";
      $cgi->add(failtime => $failtime);
    }
    print $cgi->start_form(-action => $cgi->url());
    print $cgi->state_field();
    print "\n<b>Username: </b>", $cgi->textfield("user");
    print "\n<br><b>Password: </b>", $cgi->password_field("pass");
    print "<br>",$cgi->submit("Login"),$cgi->reset;
    print $cgi->end_form;
  } elsif (! defined $lo) {
    print "You logged in!\n<br>";
    print "Click <a href=\"",$cgi->url,"?",$cgi->state_param;
    print ";logout=true\">here</a> to logout.";
    $cgi->remember('user','pass');
  } else {
    print "You have logged out.";
    $cgi->delete_session;
  }
  print $cgi->end_html;

This example will show a form that will tell you what what previously
entered.  It should have a directory called "states" that it can write to.


  #!/usr/bin/perl -wT
  use CGI::SecureState qw(:paranoid_security);

  my $cgi = new CGI::SecureState(-stateDir => 'states',
                                -mindSet => 'unforgetful');
  print $cgi->header();
  $cgi->start_html(-title => "CGI::SecureState test",
		 -bgcolor => "white");
  print $cgi->start_form(-action => $cgi->url());
  print $cgi->state_field();
  print "\n<b>Enter some text: </b>";
  print $cgi->textfield("input","");
  print "<br>",$cgi->submit,$cgi->reset;
  print $cgi->end_form;
  print "\n<br><br><br>";

  unless (defined $cgi->param('num_inputs')) {
      $cgi->add('num_inputs' => '1');
  }
  else {
      $cgi->add('num_inputs' => ($cgi->param('num_inputs')+1));
  }
  $cgi->add('input'.$cgi->param('num_inputs') =>
  	  $cgi->param('input'));
  $cgi->delete('input');

  foreach ($cgi->param()) {
      print "\n<br>$_ -> ",$cgi->param($_) if (/input/);
  }
  print $cgi->end_html;


This example is a cron job that cleans up old state files in the directories
F</var/www/perl/states> and F</var/www/cgi-bin/states>:

  #!/usr/bin/perl -w
  use CGI::SecureState;

  $cgi = new CGI::SecureState(-mindSet => 'forgetful',
			      -stateDir => '/var/www/perl/states');
  $cgi->cleanup_states;
  $cgi->cleanup_states(-directory => '/var/www/cgi-bin/states');
  $cgi->delete_session;


=head1 BUGS

There are B<no known bugs> with the current version.  However, take note
of the limitations section.

If you do find a bug, you should send it immediately to
behroozi@cpan.org with the subject "CGI::SecureState Bug".
I am I<not responsible> for problems in your code, so make sure
that an example actually works before sending it.  It is merely acceptable
if you send me a bug report, it is better if you send a small
chunk of code that points it out, and it is best if you send a patch--if
the patch is good, you might see a release the next day on CPAN.
Otherwise, it could take weeks . . .



=head1 LIMITATIONS

Crypt::Blowfish is the only cipher that CGI::SecureState is using
at the moment.  Change at your own risk.

CGI.pm has a tendency to set default values for form input fields
that CGI::SecureState does NOT override. If this becomes problematic,
use the -override setting when calling things like hidden().

Changes have been made so that saving/recovering Unicode now appears
to work (with Perl 5.8.0).  This is still not guaranteed to work; if
you have reports of problems or solutions, please let me know.

As far as threading is concerned, CGI::SecureState (the actual module)
is thread-safe as long as you provide it with an absolute path to the
state file directory or if you do not change working directories in
mid-stream.  This does not mean that it is necessarily safe to use
CGI::SecureState in an application with threads, as thread-safety may
be compromised by either Crypt::Blowfish or Digest::SHA1.  Check these
modules to make sure that they are thread-safe before proceeding to
use CGI::SecureState in an application with threads.

Until I can do more tests, assume that there is precisely zero
support for either threading or unicode.  If you would like to
report your own results, send me a note and I will see what I
can do about them.

Many previous limitations of CGI::SecureState have been
removed in the 0.3x series.


CGI::SecureState requires:


Long file names (at least 27 chars): needed to ensure session
authenticity.


Crypt::Blowfish: it couldn't be called "Secure" without.  At some point in
the future, this requirement will be changed.  Tested with versions 2.06, 2.09.


Digest::SHA1: for super-strong (160 bit) hashing of data.  It is used in
key generation and filename generation.  Tested with versions 1.03, 2.01.


CGI.pm: it couldn't be called "CGI" without.  Should not be a problem as it
comes standard with Perl 5.004 and above.  Tested with versions
2.56, 2.74, 2.79, 2.89.

Fcntl: for file flags that are portable (like LOCK_SH and LOCK_EX).  Comes
with Perl.  Tested with version 1.03.

File::Spec: for concatenating directories and filenames in a portable way.
Comes with Perl.  Tested with version 0.82.

Perl: Hmmm.  Tested with stable releases from v5.005_03 to v5.8.0.
There may be several bugs induced by lower versions of Perl,
which are not limited to the failure to compile, the failure to
behave properly, or the mysterious absence of your favorite pair of
lemming slippers.  The author is exempt from wrongdoing and liability,
especially if you decide to use CGI::SecureState with a version of Perl
less than 5.005_03.


=head1 SEE ALSO

  CGI(3), CGI::Persistent(3)

=head1 AUTHORS

Peter Behroozi, behroozi@cpan.org

=cut
