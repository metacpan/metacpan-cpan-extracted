package Class::Delegate;

=head1 NAME

Class::Delegate - easy-to-use implementation of object delegation.

=head1 SYNOPSIS

    require Class::Delegate;
    @ISA    = 'Class::Delegate';

    $self->add_delegate('some_name', $a);
    $self->add_delegate($b);
    $self->do_something_that_b_knows_how_to_do();
    $self->do_something_that_a_knows_how_to_do();

=head1 DESCRIPTION

This class provides transparent support for object delegation.  For more
information on delegation, see B<Design Patterns> by Erich Gamma, et al.

=cut

use strict;
use vars qw($VERSION $AUTOLOAD);


$VERSION = '0.06';


my $Debug   = 0;
sub _debug  { $Debug = shift }
sub _log    { print STDERR @_ if $Debug }



=head1 METHODS

=over 4

=item add_delegate([ $name, ] $delegate)

Assigns a delegate to your object.  Any delegate can be named or unnamed
(see the delegate() method for information on the usefulness of naming a
delegate).

=cut

sub add_delegate
{
    my ($self, @delegates)  = @_;

    _prepare($self);

    # Each entry is either a <name, object> pair, or just an <object>.
    # If it is a lone object, then we name it after its stringified value.
    # NOTE:  If you don't specify a name for a delegate, then there is no
    # documented API for accessing said delegate!
    while (@delegates) {
        my $name    = ref($delegates[0]) ? "$delegates[0]" : shift @delegates;
        my $object  = shift @delegates;

        die "Argument `$object' to add_delegate() is not an object\n"
            unless (ref($object) and $object =~ /=/);

        $$self{__delegates}{$name}  = $object;

        # If the delegate wants to know who its owner is, then tell it.
        $object->set_owner($self) if $object->can('set_owner');
    }

    return $self;
}


=item resolve($methodname, $delegatename)

Declare that calls to $methodname should be dispatched to the delegate
named $delegatename.  This is primarily for resolving ambiguities when
an object may have multiple delegates, more than one of which implements
the same method.

=cut

sub resolve
{
    my ($self, $methodname, $delegatename)  = @_;
    my $delegate                            = $self->delegate($delegatename);

    die "No delegate named `$delegatename' found\n" unless defined $delegate;

    $$self{__delegation_cache}{$methodname} = $delegate;

    return $self;
}


=item delegate($name)

This method returns the delegate named $name, or the empty list if there is
no such delegate.

=cut

sub delegate
{
    my ($self, $name)   = @_;

    if (defined $$self{__delegates}{$name}) {
        return  $$self{__delegates}{$name};
    } else {
        return;
    }
}


# This method is currently for internal use only:
sub _delegates  { return %{ $_[0]->{__delegates} } }


# Assure that this object has the necessary structure to handle delegation.
sub _prepare
{
    my ($self)  = @_;

    die "$self is not an object"        unless ref($self);
    die "$self is not a hash reference" unless $self =~ /=HASH\(/;

    $$self{__delegates}         = {} unless defined $$self{__delegates};
    $$self{__delegation_cache}  = {} unless defined $$self{__delegation_cache};

    return $self;
}


# This subroutine does most of the work.  It catches an attempted subroutine
# call, and looks at all the delegates for the object to make sure that there
# is exactly one delegate that implements the given method.
sub AUTOLOAD
{
    my ($self, @args)   = @_;
    my $class           = ref $self;
    my ($method)        = ($AUTOLOAD =~ /([^:]+)$/);
    my ($pack,$file,$line) = caller;
    
    _log("AUTOLOAD is `$AUTOLOAD', class is `$class', method is `$method'\n");

    # If there's a cache miss:
    if (!defined $$self{__delegation_cache}{$method}) {
        my @targets;

        foreach my $delegate (values %{ $$self{__delegates} }) {
            no strict 'refs';
            my $public  = ref($delegate) . '::PUBLIC';

            # Look in @Somepackage::PUBLIC, if it exists . . .
            if (@{ $public }) {
                foreach my $public_method (@{ $public }) {
                    if ($public_method eq $method) {
                        push @targets, ref($delegate);
                        last;
                    }
                }
            # . . . else trundle through all of Somepackage's methods.
            } else {
                push @targets, $delegate if $delegate->can($method);
            }
        }

        if (@targets == 0) {
        	die "Unresolvable call to `$method' ",
			"from class `$class' ", 
			"in `$file' at `$line'\n";
        } elsif (@targets == 1) {
            $$self{__delegation_cache}{$method} = $targets[0];
        } else {
       		my @which   = map { ref($_) . "\n" } @targets;

       		die "Ambiguous call to $class->$method()",
	    		"implemented in `$file' at `$line' as:\n",
                	@which;
        }
    }

    # If we've gotten here, then the cache is primed:
    return $$self{__delegation_cache}{$method}->$method(@args);
}


1;


__END__

=back

=head1 SOME DETAILS

If a delegate's class defines a package variable called @PUBLIC, then
it is taken to be a list of method names that are available to be
made visible through the owner object.  Otherwise, all methods that
are implemented by the delegate (as returned by C<can()>) will be
available as call-throughs from the owner.

=head1 EXAMPLES

=head2 CALLING THE OWNER FROM THE DELEGATE

If the delegate object implements a C<set_owner()> method, then that
method will be called as part of the call to add_delegate().  Example:

    package Dispatcher;
    require Class::Delegate;
    @ISA    = qw(Class::Delegate);

    require Worker;

    sub new
    {
        my ($class) = @_;
        my $self    = bless {}, $class;

        $worker = Worker->new;
        $self->add_delegate('gofer', $worker);
    }

    sub respond_to_error { die "Oh no!\n" }

    ...

    package Worker;

    sub new { bless {}, shift }

    sub set_owner
    {
        my ($self, $owner)  = @_;

        $$self{owner}   = $owner;
    }

    sub do_something
    {
        my ($self, @args)   = @_;

        if (!@args) {
            $$self{owner}->respond_to_error();
        }

        ...
    }

=head1 BUGS

This class only works with owner objects that are implemented as hash
references.

If you assign a new value to a named delegate, the Right Thing will not
happen.

=head1 AUTHOR

    Kurt D. Starsinic <kstar@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2000, Smith Renaud, Inc.  This program is free software;
you may distribute it and/or modify it under the same terms as Perl
itself.

=head1 SEE ALSO

perl(1).

=cut
