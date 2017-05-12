package DNS::BL;

use 5.006001;
use strict;
use warnings;

use Carp;

# These constans are used to specify specific error condition / result
# codes.

=pod

=head1 NAME

DNS::BL - Manage DNS black lists

=head1 SYNOPSIS

  use DNS::BL;

=head1 DESCRIPTION

This class provides the services required to manage DNSBL data using
this module hierarchy. It does so by implementing a series of methods,
that perform the required function and when called in array context,
return a two-element list, whose first element is a return code and
its second element, is a diagnostic message.

In scalar context, only the constant is returned.

The following constants are defined:

=over

=item B<DNSBL_OK>

Denotes a succesful operation.

=item B<DNSBL_ECONNECT>

A problem related to the connection or lack of, to the backend.

=item B<DNSBL_ECOLLISSION>

When inserting entries in the backend, a previous entry conflicts with
this one.

=item B<DNSBL_ENOTFOUND>

When looking up entries in the backend, no suitable entry has been
found.

=item B<DNSBL_ESYNTAX>

A syntax error was detected by a callback handler.

=item B<DNSBL_EOTHER>

Some other kind of error.

=back

=cut

use constant DNSBL_OK		=> 0;
use constant DNSBL_ECONNECT	=> 1;
use constant DNSBL_ECOLLISSION	=> 2;
use constant DNSBL_ENOTFOUND	=> 4;
use constant DNSBL_ESYNTAX	=> 8;
use constant DNSBL_EOTHER	=> 16;

use constant ERR_MSG => "Must issue a 'connect' first";

our $VERSION = '0.03';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Preloaded methods go here.

=pod

The following methods are implemented by this module:

=over

=item C<-E<gt>new()>

This method creates a new C<DNS::BL> object. No parameters are
required.

=cut

sub new($)
{
    my $class = shift;
    return bless 
    {
	k => {},		# Storage
    }, $class;
}


=pod

=item C<-E<gt>parse($command)>

This method tokenizes each line given in C<$command>, loading and
calling the appropiate modules to satisfy the request. As shipped,
each command verb, usually the first word of a C<$command>, will
invoke a class from the C<DNS::BL::cmds::*> hierarchy, which handles
such commands. A summary of those is included in
L<DNS::BL::cmds>. Likely, you can provide your own commands by
subclassing C<DNS::BL::cmds> in your own classes.

Note that this method supports comments, by prepending a pound
sign. Most Perl-ish way.

When a command is invoked for the first time, the class is
C<use()>d. For example, the "foo" command would involve loading the
C<DNS::BL::cmds::foo> class.

After this loading process, the class' C<execute()> method is
invoked. This is documented in L<DNS::BL::cmds>.

=cut

sub parse($$)
{
    my $self = shift;
    my $comm = shift;

    $comm =~ s/^\s+//;		# Remove leading whitespace
    $comm =~ s/\s+$//;		# Remove trailing whitespace

    my @tok = ();		# List of tokens
    my $proto = undef;		# A proto-token
    my $in_string = 0;		# State: Are we within a quoted string?
    
    # Iterate through characters in a simple automaton

    for my $c (split //, $comm)
    {
	if ($c eq '"')
	{
	    push @tok, $proto if defined $proto || $in_string;
	    $proto = undef;
	    $in_string = ! $in_string;
	    next;
	}
	elsif ($c eq '#' and ! $in_string)
	{
	    last;
	}
	elsif ($c =~ /\s/s and ! $in_string and defined $proto)
	{
	    push @tok, $proto;
	    $proto = undef;
	}
	else
	{
	    next if $c =~ /\s/s and ! $in_string;
	    $proto .= $c;
	}
    }

    # Flag trailing quoted strings
    if ($in_string)
    {
	return wantarray?(DNSBL_ESYNTAX, 
			  "End of command within a quoted string")
	    :DNSBL_ESYNTAX 
    }

    # The ending token must be considered too
    push @tok, $proto if defined $proto;

    # Trivial case: An empty line...
    unless (@tok)
    {
	return wantarray?(DNSBL_OK, "-- An empty line, huh?")
	    : DNSBL_OK;
    }

    my $verb = shift @tok;

    do {
	no strict 'refs';
	unless (*{ __PACKAGE__ . "::cmds::${verb}::execute"}{CODE})
	{
	    eval "use " . __PACKAGE__ . "::cmds::${verb};";
	    if ($@)
	    {
		return wantarray?(DNSBL_ESYNTAX, "Verb $verb undefined: $@")
		    :DNSBL_ESYNTAX;
	    }
	}

	if (*{ __PACKAGE__ . "::cmds::${verb}::execute"}{CODE})
	{			# Handler exists
	    return &{ __PACKAGE__ 
			  . "::cmds::${verb}::execute"}($self, $verb, @tok);
	}
    };
    
    return wantarray?(DNSBL_ESYNTAX, "Verb $verb is undefined")
	:DNSBL_ESYNTAX;
}

=pod

=item C<-E<gt>set($key, $value)>

Set the value of a C<$key> which is stored in the object itself, to
the scalar C<$value>.

=cut

sub set { my $ret = $_[0]->{k}->{$_[1]}; $_[0]->{k}->{$_[1]} = $_[2]; 
	  return $ret; }

=pod

=item C<-E<gt>get($key)>

Retrieve the scalar value associated to the given C<$key>.

=cut

sub get { return $_[0]->{k}->{$_[1]}; }

=pod

=back

The following methods are really pointers meant to be replaced by the
L<DNS::BL::cmds::connect::*> classes invoked at runtime. The specific
function of each function is discussed below (briefly) and in
L<DNS::BL::cmds::connect>.

The L<DNS::BL::cmds::connect::*> classes must replace them by using
the the accessors to store the reference to the function (or clusure),
using the same name of the method, prepending an underscore.

=over

=item C<-E<gt>read($entry)>

Given an C<$entry>, retrieve all the L<DNS::BL::Entry> objects
contained in the IP address range denoted in its C<-E<gt>addr()>
method, stored in the C<connect>ed backend. Its return value, is a
list where the first element is the result code, the second is a
message suitable for diagnostics. The rest of the elements, if any,
are the matching entries found.

C<$entry> should be a L<DNS::BL::Entry> object.

=item C<-E<gt>match($entry)>

Given an C<$entry>, retrieve all the L<DNS::BL::Entry> objects that
contain the IP address range denoted in its C<-E<gt>addr()> method,
stored in the C<connect>ed backend. Its return value, is a list where
the first element is the result code, the second is a message suitable
for diagnostics. The rest of the elements, if any, are the matching
entries found.

C<$entry> should be a L<DNS::BL::Entry> object.

=item C<-E<gt>write($entry)>

Store the given L<DNS::BL::Entry> object in the connected backend.

=item C<-E<gt>erase($entry)>

Delete all the C<DNS::BL::Entries> from the connected backend, whose
C<-E<gt>addr()> network range falls entirely within the one given in
C<$entry>.

=item C<-E<gt>commit()>

Commit all the changes to the backend. In some backends this is a
no-op, but it should be invoked at the end of each command block.

=back

=cut

sub read	{ &{$_[0]->{k}->{_read}		|| *{_io}{CODE}}(@_); }
sub match	{ &{$_[0]->{k}->{_match}	|| *{_io}{CODE}}(@_); }
sub write	{ &{$_[0]->{k}->{_write}	|| *{_io}{CODE}}(@_); }
sub erase	{ &{$_[0]->{k}->{_erase}	|| *{_io}{CODE}}(@_); }
sub commit	{ &{$_[0]->{k}->{_commit}	|| *{_io}{CODE}}(@_); }
sub _io		{ wantarray?(&DNSBL_ECONNECT, &ERR_MSG):&DNSBL_ECONNECT }

sub DNS::BL::cmds::commit::execute { $_[0]->commit(@_); }

sub DNS::BL::cmds::_dump::execute
{
    use Data::Dumper;
    my $self = shift;

    print "*** Current object $self:\n";
    print Data::Dumper->Dump([$self]); 

    if (@_)
    {
	print "*** Arguments:\n";
	print "  '$_'\n" for @_;
    }
    else
    {
	print "*** No arguments\n";
    }
    return wantarray ? (DNSBL_OK, "Debug dump done") : DNSBL_OK;
}

1;
__END__

=pod

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.00_01

Original version; created by h2xs 1.22

=item 0.01

First RC

=item 0.02

Added an index to db connection method. This improves performance. Minor
changes to other components. Added regression testing for IO commands.

=back



=head1 SEE ALSO

Perl(1), L<DNS::BL::cmds>, L<DNS::BL::Entry>,
L<DNS::BL::cmds::connect>, L<DNS::BL::cmds::connect::*>.

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
