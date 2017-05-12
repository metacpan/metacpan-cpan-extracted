# purldoc.pl - Part of the kinder, gentler #Perl.

# Though he hates to admit it, this was written by the gent
# on EFNet #Perl known most often as Masque.  Comments to 
# masque@pound.perl.org.  This code is covered under the same
# license as the rest of infobot.

# Eternal thanks to oznoid for writing the other bits, and 
# for being a good friend to all Perldom.  We're fortunate
# to have him.

# Please note that in this version, purldoc only searches the
# question _titles_.  This is MUCH faster, and reduces the 
# amount of work that the host machine has to do.  This is
# the same way that perldoc -q does it, so don't complain
# _too_ loudly. 

# KNOWN BUGS: Still sucks in many ways.

# removed all throttling code and replaced with returning
# \n-delimited clumps rather than direct msg or say.

# 1999-Dec-12 <lenzo@cs.cmu.edu> coerced to new module format

package Amethyst::Brain::Infobot::Module::Purldoc;

use strict;
use vars qw(@ISA);
use Amethyst::Message;
use Amethyst::Brain::Infobot;

@ISA = qw(Amethyst::Brain::Infobot::Module);

my $any_bad;

sub new {
	my $class = shift ;
	return undef if $any_bad;

	my $self  = $class->SUPER::new(
					Name	=> 'Purldoc',
					Regex	=> qr/^p[ue]rldoc (.*)$/i,
					Usage	=> 'purldoc (.*)',
					Description	=> "Get related FAQ questions",
					@_
						);

	return bless $self, $class;
}

sub action {
	my ($self, $message, $what) = @_;

	my @results;

	my $output = $self->purldoc_lookup($what, \@results);

	if (@results) {
		my $reply = $self->reply_to($message, join(", ", @results));
		$reply->send;
	}
	else {
		my $reply = $self->reply_to($message, $output);
		$reply->send;
	}

	return 1;
}



# I probably don't need to pass the array to the subroutine, but
# it looks more impressive when the subroutine is all pr0totyped,
# etc., and perhaps I can distract you, the noble reader, from
# noticing the other less impressive bits of this code by putting
# in overly complicated code.  We pass the array because we're only
# using return values if the sub blows up.  Lame?  Yes.  Stupid?
# Perhaps.  Intentional?  Sure!  This is perl, it's supposed to 
# be fun.  ;)

sub purldoc_lookup ($\$\@) {
  my $self = shift ;

  my $regex            =  shift;
  my $original_regex   =  $regex;
  my $target_filename  =  'pod/perlfaq.pod';
  my $results          =  shift;

# There is most likely a much more elegant way to do this search, however
# this works, and it's 2am, so you're welcome to comment all you like either
# to /dev/null or to masque@pound.perl.com.  Patches welcome.  :]

	foreach (@INC) { 
		if (-e "$_/$target_filename") {
			$target_filename = "$_/$target_filename";
			last;
		}
	}

# We don't do -f.  -f would be crazy-long to return.  It'd be easy 
# enough to do, but it should only reply via /msg if implemented.
# Hmm...perhaps it should also be usable as 
# 'tell $who about purldoc -f $function', though that has the 
# potential for abuse.  Perhaps purl should respond '$who wants
# you to ask me about purldoc -f $function,' but that is really
# pretty lame (and likely to be ignored.)  Ah well.  Reserved for
# future use.

  return "No -f for you!  NEXT!" if $regex =~ /^\s*-t?f/i;

# Sanity check on $regex.  We don't want people searching for 'I', etc.
# It was most tempting to add 'HTML' and 'CGI' to the first regex, but
# I overcame the temptation...for now.  ;)

  $regex =~ s/(?:^|\b|\s)(?:\-t?qt?|I|do|how|my|what|which|who|can)\b/ /gi;

# I'm not proud of using the fearsome '.*?' here, but that leading and
# trailing whitespace MUST GO!  IT ALL MUST GO!  WE'LL MAKE ANY DEAL!
# IT'S CRAAAAAAAAAAAAAAAAAAZY MASQUE'S USED REGEX EMPORIUM!  COME ON
# DOWN!  WE'LL CLUB A SEAL TO MAKE A BETTER DEAL!  (Weird Al, UHF)++ 

  $regex =~ s/^\s*(.*?)\s*$/$1/;

# We're pretty picky about the regex.  Currently there are no helpful 
# two-letter strings in perlfaq (with the possible exception of 'do', 
# which is being filtered for other reasons) so we require the length
# to be above that, and also we only want letters of the alphabet, 
# thanks.  

  return "\'$original_regex\' isn't a good purldoc search string." 
      unless $regex =~ /^[A-Za-z ]+$/ and length $regex > 2;

  open PURLDOC, "<$target_filename"
  		or return "Sorry, guys.  I can't open perlfaq right now: $!";

# ACHTUNG!  THE FOLLOWING CODE IS WILDLY INEFFICIENT!  HAVE A CAPS LOCKY DAY.

	my $chapter;
	my $versecount;

	while (<PURLDOC>) {
		if (/^=head1 Credits/) {
			last;
		}
		if (/^=item L<(\w+\d)/) {
			$chapter = $1 and $versecount = 0
			}
		elsif (s/=item \* //) { 
			chomp;
			$versecount++;
			push(@$results, "$chapter, question $versecount: $_")
							if /$regex/i;
		}
	}

  return "No matches for keyphrase '$regex' found." unless scalar @$results;
}
1;

__END__

=head1 NAME

purldoc.pl - Interface to the Perl FAQ.

=head1 SYNOPSIS

Returns the names of questions matching the search words.

purldoc string
purldoc array

=head1 PREREQUISITES

Nothing.

=head1 PARAMETERS
    
=over 4
   
=item purldoc
    
Turns the facility on and off
    
=item purldoc_triggers
    
Regexp used to match a call to the FAQ. Should be something like
`purldoc' or `perldoc'.

=head1 PUBLIC INTERFACE

(Depends on your triggers, but generally:)
	purldoc <topic>


=head1 DESCRIPTION

This looks up the given words as parts of a question in the Perl FAQ,
and returns the top three matching questions.

=head1 AUTHORS

Masque <masque@pound.perl.org>
