package Bayonne::Libexec;

use 5.008004;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Bayonne::Libexec ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory. 
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
 
our $VERSION = '0.03'; 

# disable buffering
$|=1;

sub new {
	my ($class, %args) = @_;
	my $self = {};
	my ($buffer);
	my ($num);

	# default voice
	$self->{'voice'} = "";

	# digits buffer
	$self->{'digits'} = "";

	# query buffer
	$self->{'query'} = "";

	# audio position
	$self->{'position'} = "00:00:00.000";

	# last header reply id number
	$self->{'reply'} = 0;

	# last result code from a transaction.
	$self->{'result'} = 0;

	# exit code if terminated by server, 0 if active
	$self->{'exitcode'} = 0;

	# version of our interface
	$self->{'version'} = "4.0";

	# audio level of tones...
	$self->{'level'} = 0;

	$self->{'tsession'} = $ENV{'PORT_TSESSION'} if $ENV{'PORT_TSESSION'};
	
	if(!$self->{'tsession'}) {
		$self->{'exitcode'} = 1;
	        bless $self, ref $class || $class;
        	return $self;   
	}

	# issue libexec HEAD request to get headers...

	print STDOUT "$self->{'tsession'} HEAD\n";
	while(<STDIN>)
	{
		$buffer = $_;
		$num = 0;

		if(length($buffer) > 0 && substr($buffer, 0, 1) gt '0' && substr($buffer, 0, 1) le '9') {
                        $num = 0 + substr($buffer, 0, 3);
                }  

		if($num > 900) {
			$self->{'reply'} = $num - 0;
			$self->{'exitcode'} = $num - 900;
			last;
		}
		if($num > 0) {
			$self->{'reply'} = $num - 0;
			next;
		}
		if($buffer eq "\n") {
			last;
		}
		$_ =~ /(.*?)[:][ ](.*\n)/;
		my($keyword, $value) = ($1, $2);
		$value =~ s/\s+$//;
		if($keyword eq "DIGITS") {
			$self->{'digits'} = $value;
		}
		$self->{head}{$keyword}=$value;
	}

	# issue libexec ARGS request to get command arguments...

	print STDOUT "$self->{'tsession'} ARGS\n";
	while(<STDIN>)
	{
		$buffer = $_;
		$num = 0;
		if(length($buffer) > 0 && substr($buffer, 0, 1) gt '0' && substr($buffer, 0, 1) le '9') {
                        $num = 0 + substr($buffer, 0, 3);
                }  
		if($num > 900) {
			$self->{'reply'} = $num - 0;
			$self->{'exitcode'} = $num - 900;
			last;
		}
		if($num > 0) {
			$self->{'reply'} = $num - 0;
			next;
		}
		if($buffer eq "\n") {
			last;
		}
		$_ =~ /(.*?)[:][ ](.*\n)/;
		my($keyword, $value) = ($1, $2);
		$value =~ s/\s+$//;
		$self->{args}{$keyword}=$value;
	}
	
	bless $self, ref $class || $class;
	return $self;
};

# hangup

sub hangup($) {
	my($self) = @_;
	my($tsid) = $self->{'tsession'};
	if($tsid) {
		print STDOUT "$tsid hangup\n";
		$self->{'tsession'} = undef;
	}
}

# disconnect (server resumes...)

sub detach($$) {
	my($self,$code) = @_;
	my($tsid) = $self->{'tsession'};

	if($tsid) {
		print STDOUT "$tsid exit $code\n";
		$self->{'tsession'} = undef;	
	}
}

sub error($$) {
	my($self,$msg) = @_;
	my($tsid) = $self->{'tsession'};

	if($tsid) {
		print STDOUT "$tsid error $msg\n";
		$self->{'tsession'} = undef;
	}
}

sub post($$$) {
	my($self, $id, $value) = @_;
	my $sid = $self->{head}{'SESSION'};
	print STDOUT "$sid POST $id $value\n";
}

sub pathname($$) {
	my($self,$file) = @_;
	my $prefix = $self->{head}{'PREFIX'};
	my $var = $ENV{'SERVER_PREFIX'};
	my $ram = $ENV{'SERVER_TMPFS'};
	my $tmp = $ENV{'SERVER_TMP'};
	my $ext = $self->{head}{'EXTENSION'};

	if(!$file) {
		return undef;
	}

	my $spos = rindex $file, "/";
	my $epos = rindex $file, ".";

	if($epos < $spos) {
		$epos = -1;
	}

	if($epos < 1) {
		$file = "$file$ext";
	}

	if(substr($file, 0, 4) eq "tmp:") {
		my $sub = substr($file, 4);
		return "$tmp/$sub";
	}

	if(substr($file, 0, 4) eq "ram:") {
		my $sub = substr($file, 4);
		return "$ram/$sub";
	}

	$_ = $file;
	my $count = tr/://;
	if($count > 0) {
		return undef;
	}

	$_ = $file;
	$count = tr:/::;
	if($count < 1) {
		if(!$prefix or $prefix == "") {
			return undef;
		}
		return "$var/$prefix/$file";
	}
	return "$var/$file";
}

# check file validity for write/modify

sub filename($$) {
	my($self,$file) = @_;
	my $prefix = $self->{head}{'PREFIX'};

	if(!$file) {
		return undef;
	}

	if(substr($file, 0, 4) eq "tmp:") {
		return $file;
	}

	if(substr($file, 0, 4) eq "ram:") {
		return $file;
	}

	if(substr($file, 0, 1) eq "/") {
		return undef;
	}

	$_ = $file;
	my $count = tr/://;
	if($count > 0) {
		return undef;
	}

	$_ = $file;
	$count = tr:/::;
	if($count == 0 && !$prefix) {
		return undef;
	}

	if($count == 0) {
		return "$prefix/$file";
	}

	return "$file";
}

# move files

sub move($$$) {
	my ($self,$file1,$file2) = @_;
	$file1 = $self->pathname($file1);
	$file2 = $self->pathname($file2);
	if(!$file1 || !$file2) {
		$self->{'result'} = 254;
		return 254;
	}
	rename($file1, $file2);
	$self->{'result'} = 0;
	return 0;
}	

# erase file

sub erase($$) {
	my ($self,$file) = @_;
	$file = $self->pathname($file);
	if(!$file) {
		$self->{'result'} = 254;
		return 254;
	}
	remove("$file");
	$self->{'result'} = 0;
	return 0;
}

# play audio tone

sub tone {
	my $self = shift;
	my $tone = shift;
	my $duration = shift;
	my $level = shift;

	if(!$duration) {
		$duration = 0;
	}

	if(!$level) {
		$level = $self->{'level'}; 	
	}
	return $self->command("tone $tone $duration $level");
}

sub single_tone {
	my $self = shift;
	my $tone = shift;
	my $duration = shift;
	my $level = shift;

	if(!$duration) {
		$duration = 0;
	}

	if(!$level) {
		$level = $self->{'level'}; 	
	}
	return $self->command("stone $tone $duration $level");
}

sub dual_tone {
	my $self = shift;
	my $tone1 = shift;
	my $tone2 = shift;
	my $duration = shift;
	my $level = shift;

	if(!$duration) {
		$duration = 0;
	}

	if(!$level) {
		$level = $self->{'level'}; 	
	}
	return $self->command("dtone $tone1 $tone2 $duration $level");
}

# replay audio

sub replay {
	my $self = shift;    
        my $file = shift;
        my $offset = undef;  

	$file = $self->filename($file);

	if(!$file) {
		$self->{'result'} = 254;
		return "255";
	}

	if($offset) {
		return $self->command("replay $file $offset");
	} else {
		return $self->command("replay $file");
	}
}

# record audio

sub record {
	my $self = shift;
	my $file = shift;
	my $timeout = shift;
	my $silence = undef;
	my $offset = undef;

	$file = $self->filename($file);

	if(!$file) {
		$self->{'result'} = 254;
		return "254";
	}

	if($timeout) {
		$silence = shift;
		if($silence) {
			$offset = shift;
		}
	}

	if(!$timeout) {
		$timeout = 60;
	}

	if(!$silence) {
		$silence = 0;
	}

	if($offset) {
		return $self->command("record $file $timeout $silence $offset");
	} else {
		return $self->command("record $file $timeout $silence");
	}
}	

# set voice to use, undef to reset...

sub voice {
	my $self = shift;
	my $voice = shift;

	$self->{'voice'} = $voice;
}

sub level($$) {
	my($self, $level) = @_;
	$self->{'level'} = $level;
}

# process input line

sub input($$$) {
	my ($self, $count, $timeout) = @_;

	if(!$count) {
		$count = 1;
	}

	if(!$timeout) {
		$timeout = 0;
	}

	my $result = $self->command("READ $timeout $count");
	if($result != 0) {
		return "";
	}

	return $self->{'digits'};
}

# clear pending input

sub clear($) {
	my($self) = @_;
	return $self->command("FLUSH");
}

# wait for a key event

sub wait($$) {
	my ($self, $timeout) = @_;

	if(!$timeout) {
		$timeout = 0;
	}
	my $result = $self->command("WAIT $timeout");
	if($result == 3) {
		return 1;
	}
	return 0;
}

# process single key input

sub inkey($$) {
	my ($self, $timeout) = @_;

	if(!$timeout) {
		$timeout = 0;
	}

	my $result = $self->command("READ $timeout");
	if($result != 0) {
		return "";
	}
	return substr($self->{'digits'}, 0, 1);
}

# send results back to server.

sub result($$) {
	my($self, $buf) = @_;
	$buf =~ s/\%/\%\%/g;
        $buf =~ s/(.)/ord $1 < 32 ?
                sprintf "%%%s", chr(ord($1) + 64) : sprintf "%s",$1/eg; 

	return $self->command("result $buf");
}

# transfer extension

sub transfer($$) {
	my($self, $dest) = @_;
	return $self->command("xfer $dest");
}

# get symbol value

sub get($$) {
	my($self, $buf) = @_;
	$self->command("get $buf");
	return $self->{'query'};
}

# set symbol value

sub set($$$) {
	my($self, $id, $value) = @_;
	return $self->command("set $id $value");
}

sub add($$$) {
        my($self, $id, $value) = @_;
        return $self->command("add $id $value");
} 

# size a symbol

sub size($$$) {
	my($self, $id, $buf) = @_;
	my($size) = $buf - 0;
	return $self->command("new $id $size");
}
	
# build prompt

sub speak($$) {
        my($self, $buf) = @_;
	my($voice) = $self->{'voice'};

	if(!$voice) {
		$voice = "prompt";
	}

	if($voice eq "") {
		$voice = "prompt";
	}

        return $self->command("$voice $buf");
}

# issue a libexec command and parse the transaction results.

sub command($$) {
	my($self,$buf) = @_;
        my($hid) = 0;
        my($result) = 255;      # no result value   
	my($tsession) = $self->{'tsession'};
	my($exitcode) = $self->{'exitcode'};
	my($buffer);
	my($num);

	if(!$tsession || $exitcode > 0) {
		return -$exitcode;
	}
        $buf =~ s/\%/\%\%/g;
        $buf =~ s/(.)/ord $1 < 32 ?
                sprintf "%%%s", chr(ord($1) + 64) : sprintf "%s",$1/eg; 

	$self->{'query'} = "";
	print STDOUT "$tsession $buf\n";

	while(<STDIN>)
        {
                $buffer = $_;
		$num = 0;
		if(length($buffer) > 0 && substr($buffer, 0, 1) gt '0' && substr($buffer, 0, 1) le '9') {
			$num = 0 + substr($buffer, 0, 3);
		}
			
                if($num > 900) {
                        $self->{'reply'} = $num - 0;
                        $self->{'exitcode'} = $num - 900;
                        last;      
                }      	
                if($num > 0) {
                        $self->{'reply'} = $num - 0;
			$hid = $num - 0;
                        next;
                } 
		if($buffer eq "\n") {
                        last;
                }
		if($hid != 100 && $hid != 400) {
			next;
		}
                $_ =~ /(.*?)[:][ ](.*\n)/;
                my($keyword, $value) = ($1, $2);
                $value =~ s/\s+$//; 
		$keyword = lc($keyword);
		if($hid == 400) {
			$keyword = "query";
		}
		if($keyword eq "result") {
			$result = $value - 0;
		}
		$self->{$keyword}=$value;
	}
	return $result;  
}	

# generic print function, works whether in TGI or direct execute mode

sub print($$) {
	my($self,$buf) = @_;
  	$buf =~ s/\%/\%\%/g; 
  	$buf =~ s/(.)/ord $1 < 32 ? 
		sprintf "%%%s", chr(ord($1) + 64) : sprintf "%s",$1/eg; 
	if($self->{'tsession'}) {
		print STDERR $buf;
	} else {
		print STDOUT $buf;
	}
}
1;
__END__

=head1 NAME

Bayonne::Libexec - Perl extension for executing applications under Bayonne 2

=head1 SYNOPSOS

  use Bayonne::Libexec;
  $TGI = new Bayonne::Libexec;

=head1 DESCRIPTION

  This module is used to create an instance of the Bayonne::Libexec.  You
  only need to create one instance.  The Bayonne::Libexec object includes
  member functions which issue commands to the running Bayonne server that
  the application was launched from, and receives reply messages.

=head1 EXPORT

None by default.

=head1 SEE ALSO

Documentation for GNU Bayonne 2.  Support is available from the Bayonne 2
developers mailing list, bayonne-devel@gnu.org.

=head1 AUTHOR

David Sugar, E<lt>dyfet@gnutelephony.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by David Sugar, Tycho Softworks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available. 


=cut


  
