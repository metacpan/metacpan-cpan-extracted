package CGI::Capture; # git description: cc2391e
# ABSTRACT: Meticulously thorough capture and replaying of CGI calls

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   # Capture the current CGI to a file, and replay it once created
#pod   use CGI::Capture 'fileupload.dat';
#pod   
#pod   # Create an object and capture the state
#pod   my $Capture = CGI::Capture->new->capture;
#pod   
#pod   # Store it in a file and load it back in
#pod   $Capture->store('somefile.dat');
#pod   my $second = CGI::Capture->apply('somefile.dat');
#pod   
#pod   # Apply the CGI call to the current environment
#pod   $second->apply;
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<CGI> does a terribly bad job of saving CGI calls. C<CGI::Capture> tries
#pod to resolve this and save a CGI call in as much painstaking detail as it
#pod possibly can.
#pod
#pod Because of this, C<CGI::Capture> should work with server logins, cookies,
#pod file uploads, strange execution environments, special environment
#pod variables, the works.
#pod
#pod It does this by capturing a large amount of the perl environment
#pod BEFORE F<CGI.pm> itself gets a chance to look at it, and then restores
#pod it in the same way.
#pod
#pod So in essence, it grabs all of C<STDIN>, C<%ENV>, C<@INC>, and anything
#pod else it can think of. The things it can't replicate, it records anyway
#pod so that later in the debugger it can ensure that the execution
#pod environment is as close as possible to what it captured (and bitch at
#pod you about anything you are doing wrong).
#pod
#pod This is a huge help when resolving problems such as when a bug won't
#pod appear because you aren't debugging the script as the web user and in
#pod the same directory.
#pod
#pod =head2 Using CGI::Capture
#pod
#pod The brain-dead way is to use it as a pragma.
#pod
#pod Add the following to your web application BEFORE you load in CGI itself.
#pod
#pod   use CGI::Capture 'cookiebug.dat';
#pod
#pod If the file C<cookiebug.dat> does not exist, CGI::Capture will take a
#pod snapshot of all the bits of the environment that matter to a CGI call, and
#pod freeze it to the file.
#pod
#pod If the file DOES exist however, CGI::Capture will load in the file and
#pod replace the current CGI call with the stored one.
#pod
#pod =head2 Security
#pod
#pod The actual captured CGI files are Storable CGI::Capture objects. If you
#pod want to use CGI::Capture in an environment where you have CODE references
#pod in your @INC path (such as with PAR files), you will need to disable
#pod security for Storable by setting $CGI::Capture::DEPARSE to true, which will
#pod enable B::Deparse and Eval support for stored objects.
#pod
#pod =head2 Hand-Crafting CGI Captures
#pod
#pod In its default usage, B<CGI::Capture> takes an all or nothing approach,
#pod requiring you to capture absolutely every element of a CGI call.
#pod
#pod Sometimes you want to be a little more targeted, and for these situations
#pod an alternative methodology is provided.
#pod
#pod The C<as_yaml> and C<from_yaml> methods allow you to store and retrieve a
#pod CGI capture using L<YAML::Tiny> instead of L<Storable>.
#pod
#pod Once you have stored the CGI capture as a YAML file, you can hand-edit the
#pod capture file, removing any keys you will not want to be restored, keeping
#pod only the useful parts.
#pod
#pod For example, to create a test file upload or CGI request involving
#pod cookies, you could discard everything except for the STDIN section of
#pod the capture file, which will then allow you to reuse the capture on
#pod other hosts, operating systems, and so on.
#pod
#pod =head1 METHODS
#pod
#pod In most cases, the above is all you probably need. However, if you want to
#pod get more fine-grained control, you can create and manipulate CGI::Capture
#pod object directly.
#pod
#pod =cut

use 5.006;
use strict;
use warnings;
use Carp              ();
use Config            ();
use Storable     2.11 ();
use IO::Scalar  2.110 ();
use YAML::Tiny   1.36 ();
use Params::Util 0.37 qw{ _SCALAR0 _HASH0 _CODE _INSTANCE };

our $VERSION = '1.15';

use CGI::Capture::TieSTDIN ();

our $DEPARSE;



#####################################################################
# Constructor and Accessors

#pod =pod
#pod
#pod =head2 new
#pod
#pod The C<new> only creates a new, empty, capture object.
#pod
#pod Because capturing is destructive to some values (STDIN for example) the
#pod capture method will capture and then immediately reapply the object, so that
#pod the current call can continue.
#pod
#pod Returns a CGI::Capture object. Never dies or returns an error, and so
#pod can be safely method-chained.
#pod
#pod =cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	# Create the empty object
	bless {}, $class;
}

# The import expects a file name and does the following.
# 1. If the file does not exist, captures to it and continues.
# 2. If the file exists, restores from it and continues.
# 4. Does nothing if passed nothing.
sub import {
	my $class = ref $_[0] ? ref shift : shift;
	return 1 unless defined $_[0];
	return (-f $_[0])
		? $class->apply(shift)
		: $class->store(shift);
}





#####################################################################
# Implement the Storable API

#pod =pod
#pod
#pod =head2 store $filename
#pod
#pod This method behaves slightly differently in object and static context.
#pod
#pod In object context ( $object->store($filename) ) it stores the captured data
#pod to a file via Storable.
#pod
#pod In static context ( CGI::Capture->store($filename) ) automatically creates a
#pod new capture object, captures the CGI call, and then stores it, all in one hit.
#pod
#pod Returns as for Storable::store or dies if there is a problem storing the file.
#pod Also dies if it finds a CODE reference in @INC and you have not enabled
#pod C<$CGI::Capture::Deparse>.
#pod
#pod =cut

sub store {
	my $self = ref $_[0] ? shift : shift->capture;

	# Make sure we are allowed to use B::Deparse to serialise
	# CODE refs in INC if needed.
	my $any_CODE_refs = scalar grep { _CODE($_) } @{$self->{INC}};
	if ( $any_CODE_refs and ! $DEPARSE ) {
		die "Found a CODE reference in \@INC, but \$CGI::Capture::DEPARSE is not true";
	}
	local $Storable::Deparse = $any_CODE_refs;

	Storable::lock_nstore($self, shift);
}

#pod =pod
#pod
#pod =head2 retrieve
#pod
#pod The C<retrieve> method is used identically to the Storable method of the
#pod same name, and wraps it.
#pod
#pod Loads in a stored CGI::Capture object from a file.
#pod
#pod If the stored object had a CODE ref in it's @INC, you will also need to
#pod enable $CGI::Capture::DEPARSE when loading the file.
#pod
#pod Returns a new CGI::Capture object, or dies on failure.
#pod
#pod =cut

sub retrieve {
	my $class = ref $_[0] ? ref shift : shift;
	local $Storable::Eval = $DEPARSE;
	my $self = Storable::lock_retrieve(shift);
	return $self if _INSTANCE($self, $class);
	die "Storable did not contains a $class object";
}

#pod =pod
#pod
#pod =head2 as_yaml
#pod
#pod To allow for more portable storage and communication of the CGI
#pod environment, the C<as_yaml> method can be used to generate a YAML
#pod document for the request (generated via L<YAML::Tiny>).
#pod
#pod Returns a YAML::Tiny object.
#pod
#pod =cut

sub as_yaml {
	my $self = shift;
	my $yaml = YAML::Tiny->new;

	# Populate the YAML
	$yaml->[0] = Storable::dclone( { %$self } );
	$yaml->[0]->{STDIN} = ${$yaml->[0]->{STDIN}};

	return $yaml;
}

#pod =pod
#pod
#pod =head2 from_yaml
#pod
#pod To allow for more portable storage and communication of the CGI
#pod environment, the C<from_yaml> method can be used to restore a
#pod B<CGI::Capture> object from a L<YAML::Tiny> object.
#pod
#pod Returns a new B<CGI::Capture> object, or croaks if passed an
#pod invalid parameter.
#pod
#pod =cut

sub from_yaml {
	my $class = shift;

	# Check params
	my $yaml  = shift;
	unless ( _INSTANCE($yaml, 'YAML::Tiny') ) {
		Carp::croak("Did not provide a YAML::Tiny object to from_yaml");
	}
	unless ( _HASH0($yaml->[0]) ) {
		Carp::croak("The YAML::Tiny object does not have a HASH as first element");
	}

	# Create the object
	my $self = $class->new;
	%$self = %{$yaml->[0]};

	# Correct some nigglies
	if ( exists $self->{STDIN} ) {
		my $stdin = $self->{STDIN};
		$self->{STDIN} = \$stdin;
	}

	return $self;
}

#pod =pod
#pod
#pod =head2 as_yaml_string
#pod
#pod To allow for more portable storage and communication of the CGI
#pod environment, the C<as_yaml_string> method can be used to generate a YAML
#pod document for the request (generated via L<YAML::Tiny>).
#pod
#pod Returns a YAML document as a string.
#pod
#pod =cut

sub as_yaml_string {
	$_[0]->as_yaml->write_string;
}

#pod =pod
#pod
#pod =head2 from_yaml_string
#pod
#pod To allow for more portable storage and communication of the CGI
#pod environment, the C<from_yaml_string> method can be used to 
#pod restore a B<CGI::Capture> object from a string containing a YAML
#pod document.
#pod
#pod Returns a new B<CGI::Capture> object, or croaks if the YAML document
#pod is invalid.
#pod
#pod =cut

sub from_yaml_string {
	my $class  = shift;
	my $string = shift;
	my $yaml   = YAML::Tiny->read_string( $string );
	return $class->from_yaml( $yaml );
}





#####################################################################
# Main Methods

#pod =pod
#pod
#pod =head2 capture
#pod
#pod Again, C<capture> can be used either as an object or static methods
#pod
#pod When called as an object method ( $object->capture ) it captures the
#pod current CGI call environment into the object, replacing the existing
#pod one if needed.
#pod
#pod When called as a static method ( CGI::Capture->capture ) it acts as a
#pod constructor, creating an object and capturing the CGI call into it
#pod before returning it.
#pod
#pod In both cases, returns the CGI::Capture object. This method will not
#pod die or return an error and can be safely method-chained.
#pod
#pod =cut

sub capture {
	my $self = ref $_[0] ? shift : shift->new;

	# Reset the object
	%$self = (
		CAPTURE_TIME    => time,
		CAPTURE_VERSION => $VERSION,
	);

	# Capture the environment
	$self->{ENV} = { %ENV };

	# Grab ARGV just to be on the safe side
	$self->{ARGV} = [ @ARGV ];

	if ( -t STDIN ) {
		# Interactive mode
		$self->{STDIN} = \'';
	} else {
		# Grab the contents of STDIN
		$self->{STDIN} = do { local $/; my $tmp = <STDIN>; \$tmp };

		# Having captured it, restore it
		$self->_stdin( $self->{STDIN} );
	}

	# Grab the include path
	$self->{INC} = [ @INC ];

	# Grab various environment-like state variables.
	# Especially ones they might have changed.
	$self->{OUTPUT_AUTOFLUSH}   = $|;
	$self->{REAL_USER_ID}       = $<;
	$self->{EFFECTIVE_USER_ID}  = $>;
	$self->{REAL_GROUP_ID}      = $(;
	$self->{EFFECTIVE_GROUP_ID} = $);
	$self->{PROGRAM_NAME}       = $0;
	$self->{OSNAME}             = $^O;
	$self->{TAINT}              = ${^TAINT};
	$self->{PERL_VERSION}       = $];

	# Capture the most critical %Config values
	$self->{CONFIG_PATH}        = $INC{'Config.pm'};
	$self->{PERL_PATH}          = $Config::Config{perlpath};

	$self;
}

#pod =pod
#pod
#pod =head2 apply [ $filename ]
#pod
#pod Again, C<apply> works different when called as an object of static method.
#pod
#pod If called as an object method ( $object->apply ) it will take the CGI
#pod call the object contains, and apply it to the current environment.
#pod Because this works at the environment level, it needs to be done BEFORE
#pod CGI.pm attempts to create the CGI object.
#pod
#pod The C<apply> method will also check certain values against the current
#pod environment. In short, if it can't alter the environment, it won't run unless
#pod YOU alter the environment and try again.
#pod
#pod These include the real and effective user and group, the OS name, the perl
#pod version, and whether Tainting is on or off.
#pod
#pod The effect is to really make sure you are replaying the call in your console
#pod debugger exactly as it was from the browser, and you aren't accidentally using
#pod a different user, a different perl, or are making some other overlooked and
#pod hard to debug mistake.
#pod
#pod In the future, by request, I may add some options to selectively disable some
#pod of the tests. But unless someone asks, I'm leaving all of them on.
#pod
#pod In the static context, ( CGI::Capture->apply($file) ) it takes a filename
#pod argument, immediately retrieves the CGI call from the object and immediately
#pod applies it to the current environment.
#pod
#pod In both context, returns true on success or dies on error, or it your testing
#pod environment does not match.
#pod
#pod =cut

sub apply {
	my $self = ref $_[0] ? shift : shift->retrieve(shift);
	$self->{CAPTURE_TIME} or die "Cannot apply empty capture object";

	# Update the environment
	if ( exists $self->{ENV} ) {
		%ENV = %{$self->{ENV}};
	}

	# Set @ARGV
	if ( exists $self->{ARGV} ) {
		@ARGV = @{$self->{ARGV}};
	}

	# Set STDIN
	if ( exists $self->{STDIN} ) {
		$self->_stdin( $self->{STDIN} );
	}

	# Replace INC
	if ( exists $self->{INC} ) {
		@INC = @{$self->{INC}};
	}

	# Replace the internal variables we are allowed to
	if ( exists $self->{OUTPUT_AUTOFLUSH} ) {
		$| = $self->{OUTPUT_AUTOFLUSH};
	}
	if ( exists $self->{PROGRAM_NAME} ) {
		$0 = $self->{PROGRAM_NAME};
	}

	# Check that the variables we can't control match
	$self->_check( CAPTURE_VERSION    => $VERSION                  );
	$self->_check( OSNAME             => $^O                       );
	$self->_check( REAL_USER_ID       => $<                        );
	$self->_check( EFFECTIVE_USER_ID  => $>                        );
	$self->_check( REAL_GROUP_ID      => $(                        );
	$self->_check( EFFECTIVE_GROUP_ID => $)                        );
	$self->_check( TAINT              => ${^TAINT}                 );
	$self->_check( PERL_VERSION       => $]                        );
	$self->_check( CONFIG_PATH        => $INC{'Config.pm'}         );
	$self->_check( PERL_PATH          => $Config::Config{perlpath} );

	1;
}

# Checks a stored value against its current value
sub _check {
	my $self  = shift;
	my $name  = defined $_[0] ? shift : die "Var name not passed to ->_check";
	unless ( exists $self->{$name} ) {
		# Not defined in the capture, nothing to check
		return;
	}
	my $value = shift;
	unless ( defined $self->{$name} or defined $value ) {
		return 1;
	}
	if ( defined $self->{$name} and defined $value ) {
		return 1 if $self->{$name} eq $value;
	}

	# Didn't match
	my $current = defined $value ? '"' . quotemeta($value) . '"' : 'undef';
	my $cgi = defined $self->{$name} ? '"' . quotemeta($self->{$name}) . '"' : 'undef';
	die "Current $name $current does not match the captured CGI call $cgi";
}

# Takes a scalar reference and sets STDIN to read from it
sub _stdin {
	my $self = shift;
	my $scalar_ref = _SCALAR0($_[0]) ? shift
		: die "SCALAR reference not passed to ->_stdin";
	tie *MYSTDIN, 'CGI::Capture::TieSTDIN', $scalar_ref;
	*STDIN = *MYSTDIN;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Capture - Meticulously thorough capture and replaying of CGI calls

=head1 VERSION

version 1.15

=head1 SYNOPSIS

  # Capture the current CGI to a file, and replay it once created
  use CGI::Capture 'fileupload.dat';
  
  # Create an object and capture the state
  my $Capture = CGI::Capture->new->capture;
  
  # Store it in a file and load it back in
  $Capture->store('somefile.dat');
  my $second = CGI::Capture->apply('somefile.dat');
  
  # Apply the CGI call to the current environment
  $second->apply;

=head1 DESCRIPTION

L<CGI> does a terribly bad job of saving CGI calls. C<CGI::Capture> tries
to resolve this and save a CGI call in as much painstaking detail as it
possibly can.

Because of this, C<CGI::Capture> should work with server logins, cookies,
file uploads, strange execution environments, special environment
variables, the works.

It does this by capturing a large amount of the perl environment
BEFORE F<CGI.pm> itself gets a chance to look at it, and then restores
it in the same way.

So in essence, it grabs all of C<STDIN>, C<%ENV>, C<@INC>, and anything
else it can think of. The things it can't replicate, it records anyway
so that later in the debugger it can ensure that the execution
environment is as close as possible to what it captured (and bitch at
you about anything you are doing wrong).

This is a huge help when resolving problems such as when a bug won't
appear because you aren't debugging the script as the web user and in
the same directory.

=head2 Using CGI::Capture

The brain-dead way is to use it as a pragma.

Add the following to your web application BEFORE you load in CGI itself.

  use CGI::Capture 'cookiebug.dat';

If the file C<cookiebug.dat> does not exist, CGI::Capture will take a
snapshot of all the bits of the environment that matter to a CGI call, and
freeze it to the file.

If the file DOES exist however, CGI::Capture will load in the file and
replace the current CGI call with the stored one.

=head2 Security

The actual captured CGI files are Storable CGI::Capture objects. If you
want to use CGI::Capture in an environment where you have CODE references
in your @INC path (such as with PAR files), you will need to disable
security for Storable by setting $CGI::Capture::DEPARSE to true, which will
enable B::Deparse and Eval support for stored objects.

=head2 Hand-Crafting CGI Captures

In its default usage, B<CGI::Capture> takes an all or nothing approach,
requiring you to capture absolutely every element of a CGI call.

Sometimes you want to be a little more targeted, and for these situations
an alternative methodology is provided.

The C<as_yaml> and C<from_yaml> methods allow you to store and retrieve a
CGI capture using L<YAML::Tiny> instead of L<Storable>.

Once you have stored the CGI capture as a YAML file, you can hand-edit the
capture file, removing any keys you will not want to be restored, keeping
only the useful parts.

For example, to create a test file upload or CGI request involving
cookies, you could discard everything except for the STDIN section of
the capture file, which will then allow you to reuse the capture on
other hosts, operating systems, and so on.

=head1 METHODS

In most cases, the above is all you probably need. However, if you want to
get more fine-grained control, you can create and manipulate CGI::Capture
object directly.

=head2 new

The C<new> only creates a new, empty, capture object.

Because capturing is destructive to some values (STDIN for example) the
capture method will capture and then immediately reapply the object, so that
the current call can continue.

Returns a CGI::Capture object. Never dies or returns an error, and so
can be safely method-chained.

=head2 store $filename

This method behaves slightly differently in object and static context.

In object context ( $object->store($filename) ) it stores the captured data
to a file via Storable.

In static context ( CGI::Capture->store($filename) ) automatically creates a
new capture object, captures the CGI call, and then stores it, all in one hit.

Returns as for Storable::store or dies if there is a problem storing the file.
Also dies if it finds a CODE reference in @INC and you have not enabled
C<$CGI::Capture::Deparse>.

=head2 retrieve

The C<retrieve> method is used identically to the Storable method of the
same name, and wraps it.

Loads in a stored CGI::Capture object from a file.

If the stored object had a CODE ref in it's @INC, you will also need to
enable $CGI::Capture::DEPARSE when loading the file.

Returns a new CGI::Capture object, or dies on failure.

=head2 as_yaml

To allow for more portable storage and communication of the CGI
environment, the C<as_yaml> method can be used to generate a YAML
document for the request (generated via L<YAML::Tiny>).

Returns a YAML::Tiny object.

=head2 from_yaml

To allow for more portable storage and communication of the CGI
environment, the C<from_yaml> method can be used to restore a
B<CGI::Capture> object from a L<YAML::Tiny> object.

Returns a new B<CGI::Capture> object, or croaks if passed an
invalid parameter.

=head2 as_yaml_string

To allow for more portable storage and communication of the CGI
environment, the C<as_yaml_string> method can be used to generate a YAML
document for the request (generated via L<YAML::Tiny>).

Returns a YAML document as a string.

=head2 from_yaml_string

To allow for more portable storage and communication of the CGI
environment, the C<from_yaml_string> method can be used to 
restore a B<CGI::Capture> object from a string containing a YAML
document.

Returns a new B<CGI::Capture> object, or croaks if the YAML document
is invalid.

=head2 capture

Again, C<capture> can be used either as an object or static methods

When called as an object method ( $object->capture ) it captures the
current CGI call environment into the object, replacing the existing
one if needed.

When called as a static method ( CGI::Capture->capture ) it acts as a
constructor, creating an object and capturing the CGI call into it
before returning it.

In both cases, returns the CGI::Capture object. This method will not
die or return an error and can be safely method-chained.

=head2 apply [ $filename ]

Again, C<apply> works different when called as an object of static method.

If called as an object method ( $object->apply ) it will take the CGI
call the object contains, and apply it to the current environment.
Because this works at the environment level, it needs to be done BEFORE
CGI.pm attempts to create the CGI object.

The C<apply> method will also check certain values against the current
environment. In short, if it can't alter the environment, it won't run unless
YOU alter the environment and try again.

These include the real and effective user and group, the OS name, the perl
version, and whether Tainting is on or off.

The effect is to really make sure you are replaying the call in your console
debugger exactly as it was from the browser, and you aren't accidentally using
a different user, a different perl, or are making some other overlooked and
hard to debug mistake.

In the future, by request, I may add some options to selectively disable some
of the tests. But unless someone asks, I'm leaving all of them on.

In the static context, ( CGI::Capture->apply($file) ) it takes a filename
argument, immediately retrieves the CGI call from the object and immediately
applies it to the current environment.

In both context, returns true on success or dies on error, or it your testing
environment does not match.

=head1 SEE ALSO

L<http://ali.as/>, L<CGI>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Capture>
(or L<bug-CGI-Capture@rt.cpan.org|mailto:bug-CGI-Capture@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Adam Kennedy Karen Etheridge

=over 4

=item *

Adam Kennedy <adam@ali.as>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
