package Chatbot::Alpha::Syntax;

our $VERSION = '0.4';

use strict;
use warnings;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		debug    => 0,
		version  => $VERSION,
		deny     => {},
		allow    => {},
		denytype => 'alloy_all', # deny_all, allow_some, deny_some
		cusdeny  => 0,
		syntax   => 'strict',
	};

	bless ($self,$class);
	return $self;
}

sub syntax {
	my ($self,$syn) = @_;

	if ($syn =~ /^(loose|strict)$/i) {
		$self->{syntax} = $syn;
		return 1;
	}

	return 0;
}

sub deny_type {
	my ($self,$type) = @_;

	if ($type =~ /^(alloy|deny)_(all|some)$/i) {
		$self->{cusdeny} = 1;

		$type = lc($type);
		$type =~ s/ //g;

		$self->{denytype} = $type;
	}
	else {
		return 0;
	}
	return 1;
}

sub deny {
	my ($self,@commands) = @_;

	# Deny each command.
	foreach my $cmd (@commands) {
		delete $self->{allow}->{$cmd} if exists $self->{allow}->{$cmd};
		$self->{deny}->{$cmd} = 1;
	}

	$self->deny_type ('deny_some') unless $self->{cusdeny} == 1;
}

sub allow {
	my ($self,@commands) = @_;

	# Allow each command.
	foreach my $cmd (@commands) {
		delete $self->{deny}->{$cmd} if exists $self->{deny}->{$cmd};
		$self->{allow}->{$cmd} = 1;
	}

	$self->deny_type ('allow_some') unless $self->{cusdeny} == 1;
}

sub check {
	my ($self,$file) = @_;

	open (FILE, $file) or return 0;
	my @data = <FILE>;
	close (FILE);

	# Handle dos text files on Mac and Unix
	if($/ ne "\r\n") {
		local $/ = "\r\n";
		chomp @data;
	}

	chomp @data;

	# Go through each line.
	my $num = 0;
	foreach my $line (@data) {
		$num++;
		next if length $line == 0;
		next if $line =~ /^\//;
		$line =~ s/^\s+//g;
		$line =~ s/^\t+//g;
		$line =~ s/^\s//g;
		$line =~ s/^\t//g;

		my ($cmd,$data) = split(//, $line, 2);
		$data =~ s/^\s+//g;
		$data =~ s/^\s//g;

		next unless length $cmd > 0;

		# Denied/Not allowed?
		if ($self->{denytype} ne 'allow_all') {
			if ($self->{denytype} eq 'deny_some') {
				if (exists $self->{deny}->{$cmd}) {
					die "Command $cmd is not allowed at $file line $num; ";
				}
			}
			elsif ($self->{denytype} eq 'allow_some') {
				if (!exists $self->{allow}->{$cmd}) {
					die "Command $cmd not in allowlist at $file line $num; ";
				}
			}
		}
		elsif ($self->{denytype} eq 'deny_all') {
			die "No commands allowed at $file line $num; ";
		}

		if ($cmd eq '>') {
			my @args = split(/\s+/, $data);
			if (scalar(@args) != 2) {
				die "Bad number of arguments in >LABEL at $file line $num; ";
			}
		}
		elsif ($cmd eq '<') {
			my @args = split(/\s+/, $data);
			if (scalar(@args) != 1) {
				die "Bad number of arguments in <LABEL at $file line $num; ";
			}
		}
		elsif ($cmd eq '+') {
			# On strict: must be lowercase, simplistic.
			if ($self->{syntax} eq 'strict') {
				if ($data =~ /[^a-z0-9 \*]/) {
					die "+TRIGGERS must be lowercase alphanumeric "
						. "while in 'strict' syntax at $file line $num; ";
				}
			}
			elsif ($self->{syntax} eq 'loose') {
				if ($data =~ /[^A-Za-z0-9 \*]/) {
					warn "+TRIGGERS must be alphanumeric while in 'loose' "
						. "syntax at $file line $num; ";
				}
			}
		}
		elsif ($cmd eq '%') {
			# On strict: must be lowercase, simplistic.
			if ($self->{syntax} eq 'strict') {
				if ($data =~ /[^a-z0-9 ]/) {
					die "+TRIGGERS must be lowercase alphanumeric "
						. "while in 'strict' syntax at $file line $num; ";
				}
			}
			elsif ($self->{syntax} eq 'loose') {
				if ($data =~ /[^A-Za-z0-9 ]/) {
					warn "+TRIGGERS must be alphanumeric while in 'loose' "
						. "syntax at $file line $num; ";
				}
			}
		}
		elsif ($cmd eq '-') {
			if (length $data == 0) {
				die "Empty -RESPONSE data at $file line $num; ";
			}
		}
		elsif ($cmd eq '^') {
			if (length $data == 0) {
				die "Empty ^CONTINUE data at $file line $num; ";
			}
		}
		elsif ($cmd eq '@') {
			if ($self->{syntax} eq 'strict') {
				if ($data =~ /[^a-z0-9 \*\<\>]/) {
					die "\@REDIRECTIONS must be lowercase alphanumeric "
						. "while in 'strict' syntax at $file line $num; ";
				}
			}
			elsif ($self->{syntax} eq 'loose') {
				if ($data =~ /[^A-Za-z0-9 \*\<\>]/) {
					die "\@REDIRECTIONS must be alphanumeric while in 'loose' "
						. "syntax at $file line $num; ";
				}
			}
		}
		elsif ($cmd eq '*') {
			if ($data !~ /^(.*?)=(.*?)::(.*?)$/i) {
				die "Syntax error at *CONDITION at $file line $num; ";
			}
		}
		elsif ($cmd eq '&') {
			if (length $data == 0) {
				die "Empty &HOLDER data at $file line $num; ";
			}
		}
		elsif ($cmd eq '#') {
			if (length $data == 0) {
				die "Empty #CODE data at $file line $num; ";
			}
		}
		elsif ($cmd eq '/') {
			# Comment data.
		}
		elsif ($cmd eq '~') {
			# A regexp. Leave it be.
		}
		else {
			warn "Unknown command '$cmd' with data '$data' at $file line $num; ";
		}
	}

	return 1;
}

1;
__END__

=head1 NAME

Chatbot::Alpha::Syntax - Syntax checking for Chatbot::Alpha replies.

=head1 SYNOPSIS

  use Chatbot::Alpha::Syntax;
  
  my $syntax = new Chatbot::Alpha::Syntax;
  
  # Set 'strict' syntax.
  $syntax->syntax ('strict');
  
  # Changed my mind, use 'loose'
  $syntax->syntax ('loose');
  
  # Only allow SOME commands.
  $syntax->deny_type ('allow_some');
  
  # Allow only +'s and -'s.
  $syntax->allow ('+', '-');
  
  # Syntax-check this file.
  $syntax->check ("replies.cba");

=head1 DESCRIPTION

Chatbot::Alpha::Syntax provides syntax checking for Alpha documents. All syntax errors
result in a 'die' so don't expect to run your syntax checking halfway through a large
application's process. Doing it in initialization is always fine though.

=head1 METHODS

=head2 new (ARGUMENTS)

Creates a new Chatbot::Alpha::Syntax object. You can pass in any defaults here.

=head2 syntax (TYPE)

Define a syntax type, either 'strict' or 'loose'. Defaults to strict. See below for definitions
on the various syntax types.

=head2 deny_type (DENYTYPE)

Must be 'deny_all', 'deny_some', 'allow_some', or 'allow_all' - defaults to 'allow_all'. If you're
going to want to deny/allow certain commands, it's best to use deny_type to set this. The automatic
settings of deny() and allow() may not always end up how you want them.

=head2 deny (COMMANDS)

Denies a list of COMMANDS. These are the Alpha commands (+, -, @, &, etc). Syntax errors will
arrise when these commands are found in the Alpha document.

=head2 allow (COMMANDS)

Adds COMMANDS to the allow list.

=head2 check (FILE)

Check the syntax of FILE. Will return 0 if the file couldn't be opened, return 1 if everything
went well, or die if a syntax error is found.

=head1 SYNTAX TYPES

Syntax types mostly only refer to the +TRIGGER command, as that's the part of your code that's
put through a regexp.

=head2 strict

This is the default (and most recommended) syntax type. The rules are as follows:

  - Triggers must be lowercase, numbers and letters only.
  - Spaces are allowed. All other symbols are NOT allowed.

=head2 loose

This one is less strict on your trigger syntax. The recommended rules are as follows:

  - Triggers can be capitilized, lowercase, or any combination.
  - Triggers can contain letters or numbers or spaces.
  - Any foreign symbols aren't recommended, however it won't kill you.

The loose syntax check will only 'warn' when one of these isn't true, but it won't
hold it against you.

=head1 ALPHA SYNTAX

Here is the proper syntax of each Alpha command.

=head2 +TRIGGER

See SYNTAX TYPES.

=head2 ~REGEXP

No syntax rules have been applied to these. Just make sure your regexp triggers are
friendly.

=head2 -RESPONSE

A value of any length must be given. A response of all spaces is bad.

=head2 >LABEL

Two arguments must be given, separated by spaces: the label type, and its
one-word value.

=head2 <LABEL

One argument given.

=head2 @REDIRECT

Follows the same rules as +TRIGGER

=head2 &HOLDER

Follows the same rules as -RESPONSE

=head2 *CONDITION

Must follow this syntax exactly:

  * ___=___::___
    ^var  ^val ^response

=head2 #CODE

Must have a length to it.

=head1 KNOWN BUGS

No bugs known at the moment.

=head1 CHANGES

  Version 0.2
  - Fixed some bugs, blank lines shouldn't ever be considered commands,
    and incase of unknown command anyway only a warn is used but not a
    die.

  Version 0.1
  - Initial release.

=head1 FUTURE PLANS

  - Add methods for defining your own syntax, for example if you make
    a custom mod to Chatbot::Alpha to add new commands, the syntax
    checker would know what to do with them.

=head1 SEE ALSO

L<Chatbot::Alpha>

=head1 AUTHOR

Casey Kirsle, http://www.cuvou.com/

=head1 COPYRIGHT AND LICENSE

    Chatbot::Alpha - A simple chatterbot brain.
    Copyright (C) 2005  Casey Kirsle

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
