package CGI::Session::Flash;
use Carp;
use strict;

our $VERSION = '0.02';


# Create a new flash object.
#
# A session is required, all other parameters are optional and specify
# options for the flash.
sub new
{
    my $class   = shift;
    my $session = shift;
    my %options = (
        session_key => '_flash',
        @_,
    );

    # Make sure a session was provided.
    croak "No session provided."
        unless (defined $session && ref $session &&
                $session->isa('CGI::Session'));

    # Initialize data from the session.
    my $data = $session->param($options{session_key}) || { };
    my $keep = $session->param($options{session_key} . '_keep') || [ ];

    my $self = {
        _session      => $session,
        _data         => $data,
        _keep         => { map { $_ => 1 } @$keep },
        _cleanup_done => 0,
        _session_key  => $options{session_key},
    };

    bless $self, $class;
    return $self;
}

# When the object goes out of scope and flush it's contents so that they get
# saved back into the session.
sub DESTROY { shift->flush(); }


# Accessors
#------------------------------------------------------------------------------

# Returns boolean for whether cleanup has been performed.
sub cleanup_done { shift->{_cleanup_done} }

# Return the associated session object.
sub session { shift->{_session} }

# A list of the session keys.  This returns an array ref, the first is the
# flash data, the second is the keys to keep.
sub session_key { shift->{_session_key} }


# Getting and setting values
#------------------------------------------------------------------------------

# Set the data in the flash for the specified key.
sub set
{
    my $self = shift;
    my $key  = shift;
    my @vals = @_;

    croak "No flash key specified."    unless (defined $key);
    croak "No flash values specified." unless (@vals);

    # Set the values and mark the key as not used.
    $self->{_data}{$key} = \@vals;
    $self->keep($key);

    return 1;
}

# Retrieve the data from the flash for the specified key.
sub get
{
    my $self = shift;
    my $key  = shift;
    my $vals;

    croak "No flash key specified." unless (defined $key);

    # Get the values. 
    $vals = $self->{_data}{$key} if ($self->has_key($key));

    return undef      if (!defined $vals);
    return $vals->[0] if (ref $vals eq "ARRAY" && @$vals == 1);
    return wantarray ? @$vals : $vals;
}

# Set data in the flash that will only last until the next time that cleanup
# is called.
sub now
{
    my $self = shift;
    my $key  = shift;
    my @vals = @_;

    croak "No flash key specified."    unless (defined $key);
    croak "No flash values specified." unless (@vals);

    $self->set($key => @vals);
    $self->discard($key);

    return 1;
}


# Keys and Contents
#------------------------------------------------------------------------------

# Get a hashref of the flash contents.  Used internally by the teardown hook
# for saving the flash to the session.
sub contents
{
    my $self = shift;
    
    return $self->{_data};
}

# Return a list of keys that are marked as kept.
sub keep_keys
{
    my $self = shift;
    my @keep = grep  { $self->{_keep}{$_} > 0 }
               keys %{ $self->{_keep} };

    return wantarray ? @keep : \@keep;
}

# Return a list of keys currently in the flash.
sub keys
{
    my $self = shift;
    my @keys = sort keys %{ $self->{_data} };

    return wantarray ? @keys : \@keys;
}

# Return true or false depending on if the flash contains the specified key.
sub has_key
{
    my $self = shift;
    my $key  = shift;

    croak "No flash key specified." unless (defined $key);

    return 1 if (exists $self->{_data}{$key});
    return 0;
}

# Returns true or false depending on if the flash is empty or not.
sub is_empty
{
    my $self = shift;

    return 0 if (scalar CORE::keys %{ $self->{_data} } > 0);
    return 1;
}

# Clear all flash data out and start fresh.
sub reset
{
    my $self = shift;

    $self->{_data}         = { };
    $self->{_keep}         = { };
    $self->{_cleanup_done} = 0;

    return 1;
}


# Keeping keys and cleanup
#------------------------------------------------------------------------------

# Mark the specified keys as being kept for one more iteration.
sub keep
{
    my $self = shift;
    my @keys = @_;

    # If no keys were specified, keep all.
    @keys = $self->keys unless (@_);

    foreach my $key (@keys)
    {
        $self->{_keep}{$key}++;
    }

    return 1;
}

# Mark the specified keys for deletion at the next time that cleanup is called.
sub discard
{
    my $self = shift;
    my @keys = @_;

    # If no keys were specified, keep all.
    @keys = $self->keys unless (@_);

    foreach my $key (@keys)
    {
        delete $self->{_keep}{$key};
    }

    return 1;
}

# Cleanup the flash.  All keys not marked as kept will be deleted, otherwise
# they are marked for discard next time this method is called.  This method
# is automatically called during flush().
#
# Cleanup process is tracked, and it will not be performed more than once unless
# you pass a true value to signify that you want to force the cleanup.
sub cleanup
{
    my $self = shift;
    my $force = shift;

    # Skip cleanup since it has already been performed.
    return 1 if ($self->cleanup_done && !$force);

    foreach my $key (CORE::keys %{ $self->{_data} })
    {
        if ($self->{_keep}{$key})
        {
            delete $self->{_keep}{$key};
        }
        else
        {
            delete $self->{_data}{$key};
        }
    }

    # Set flag
    $self->{_cleanup_done}++;

    return 1;
}

# Perform cleanup and save the contents of the flash back to the session.
sub flush 
{
    my $self        = shift;
    my $session_key = $self->session_key;

    # Perform cleanup
    $self->cleanup();

    # Save the data back into the session
    $self->session->param($session_key => $self->contents);
    $self->session->param($session_key . '_keep' => scalar $self->keep_keys);

    return 1;
}


# Debugging
#------------------------------------------------------------------------------

# Return a Data::Dumper dump of the flash for debugging purposes.
sub dump
{
    my $self = shift;

    require Data::Dumper;
    return Data::Dumper->Dump([ $self->contents ], [ "flash" ]);
}

1;
__END__

=head1 NAME

CGI::Session::Flash - Session Flash Object

=head1 SYNOPSIS

    use CGI::Session;
    use CGI::Session::Flash;

    my $session = CGI::Session->new(...);
    my $flash   = CGI::Session::Flash->new($session, \%options);

    # Get and set the values
    $flash->set(KEY => @VALUES);
    my @values = $flash->get('KEY');

    # Checking for keys and if the flash is empty.
    print "Flash is empty\n"     if ($flash->is_empty);
    print "Flash contains key\n" if ($flash->has_key('NAME'));
    print "Flash keys: ", join(", ", $flash->keys), "\n";

    # Dump the contents of the flash for debugging purposes.
    warn $flash->dump();

    # Refresh the flash, this basically just wipes it and starts fresh.
    $flash->reset();

=head1 DESCRIPTION

This module implements a Flash object.  A flash is session data with a
specific life cycle.  When you put something into the flash it stays there
until two C<cleanup> calls have been made.  What this generally means is
that in a web application the data in the flash will stay until the end
of the next request (the first cleanup call is made at the end of the first
request).  This allows you to use it for storing messages that
can be accessed after a redirect, but then are automatically cleaned up.

Textual messages are not the only data that can be stored in the flash though.
You can use it to store anything that can be properly serialized into the
session.  Another example use for it is to store previous form arguments for
when redirecting back to a form after an error occurred.

The advantage of using the flash instead of the session directly is that you
do not need to worry about cleaning up after yourself.

=head1 METHODS

=head2 Constructor

=over 4

=item CLASS->new($session, %options)

Create a new flash object.  The first parameter is a session object.  This
is used to initialize the flash.

Additional arguments specify options for the flash.  The possible options are

=over 4

=item session_key

This is the name of the key to use when storing the flash data in the session.
The default value is C<_flash>.  This actual flash data is stored in this key
and the list of flash keys to keep is stored in a key with C<_keep> appended.

=back

=back

=head2 Accessors

=over 4

=item $flash->cleanup_done

Returns true or false, depending on whether the cleanup process has been
performed already.

=item $flash->session

Returns the associated session object.

=item $flash->session_key

Return the session key.

=back

=head2 Getting and Setting Data

=over 4

=item $flash->get('KEY')

Retrieve the values from the flash for the specified key.

An undefined value is returned if the key does not exist.

If only a single piece of data is in the flash for the key then it is returned.
Otherwise all of the data is returned.  This method is context aware so if there
are multiple pieces of data for the key then they will be returned as an
arrayref in scalar context.

=item $flash->set('KEY' => @values)

Set the values in the flash.  Values can be a single item or a list of items.
Internally they are stored as an arrayref.

Keep in mind that since we are storing the data for the flash in the session
that it is best to just store simple things and not complex objects.

=item $flash->now('KEY' => @values)

This method is very similar to C<set>.  It takes the same arguments and sets
the data in the flash.  The primary difference is that after the data is set
in the flash, a call to C<discard> is made for the key.  This causes the data
to removed on the next call to C<cleanup>.

=back

=head2 Contents and Keys

=over 4

=item $flash->contents()

This returns a hashref that represents the contents of the flash.  The keys
are the keys in the flash and the values are an arrayref of the values.

This is not likely to be called directly, instead using C<get>.  This method
is used internally when storing the flash data into the session.

=item $flash->keep_keys()

Returns a list of keys that are currently marked as being kept.  If called in
scalar context then it will return an arrayref.

=item $flash->keys()

Returns a list of keys that are in the flash.

=item $flash->has_key('KEY')

Returns true or false depending on if the flash contains the specified key.

=item $flash->is_empty()

Returns true or false depending on if the flash is empty.

=item $flash->reset()

Reset the flash.  This wipes all data and kept keys.

=back

=head2 Cleanup

When an object goes out of scope the C<flush> method is automatically called. 
This will perform a C<cleanup> if it has not already been done.

=over 4

=item $flash->keep(@keys)

Mark the specified keys as being kept.  If no keys are specified then all
keys currently in the flash will be kept.  See C<cleanup> for details on how
this works.

Call this method if you know you want to keep everything for an additional
life cycle.

=item $flash->discard(@keys)

Mark the specified keys as being discarded.  If no keys are specified then all
keys currently in the flash will be marked as being discarded.  Once marked as
discarded they will be removed the next time that C<cleanup> is called.

=item $flash->cleanup($force)

Perform cleanup of the flash.

This method goes through all of the keys in the flash.  If the key is not
marked as being kept it is removed.  If it is marked as being kept then it is
not removed, but it is instead marked as being discarded for the next time that
the method is called.  Generally this method is not directly called, but
instead automatically called during C<flush>.

The cleanup process is tracked so that it will not run more than once unless
you pass a true value to specify force.

=item $flash->flush()

Perform C<cleanup> then save the contents of the flash back into the session.
This is automatically called when the flash object is destroyed.

=back

=head2 Debugging

=over 4

=item $flash->dump()

This method returns a L<Data::Dumper> representation of the contents of the
flash.  This is useful for debugging purposes.

=back

=head1 CAVEATS

The C<flush> method is automatically called when the object is destroyed.
However, there can be times when an object may not get properly destroyed
such as in the event of a circular reference.  Because of this, you may want
to explicitly call C<flush> in your cleanup code.

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-session-flash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Session-Flash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 ALTERNATIVES

The flash object is useful for passing data around between requests, but it
is not always needed.  Sometimes a simpler approach is better such as
redirecting with a query parameter such as C<is_success=1> and then checking
for that in your code.  This is particularly useful when not using sessions.

=head1 ACKNOWLEDGEMENTS

The concept and name of this module was inspired by the Ruby on Rails
framework.

=head1 SEE ALSO

L<CGI::Session>

=head1 AUTHOR

Bradley C Bailey, C<< <cgi-session-flash at brad.memoryleak.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Bradley C Bailey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
