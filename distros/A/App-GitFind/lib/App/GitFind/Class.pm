# App::GitFind::Class - Class::Tiny base class supporting new(-arg => value)
package App::GitFind::Class;

use 5.010;
use strict;
use warnings;
use App::GitFind::Base;

our $VERSION = '0.000002';

# No parent, so Class::Tiny will become the parent
use Class::Tiny;

# Docs {{{1

=head1 NAME

App::GitFind::Class - Class::Tiny base class supporting new(-arg => value)

=head1 SYNOPSIS

This is the same as L<Class::Tiny> except for a custom C<BUILDARGS()> method
that permits you to put hyphens in front of the argument names in the
constructor call.  This provides consistency with L<Getargs::Mixed>.

=cut

# }}}1

=head1 FUNCTIONS

=head2 BUILDARGS

Pre-process the constructor arguments to strip leading hyphens from
argument names.

Note: L<Class::Tiny> prohibits attributes named C<-> (a single hyphen),
so we don't handle that case.

=cut

# The internal builder, so I don't have to worry about dispatch
# once our BUILDARGS is called.

sub _app_gitfind_class_builder_internal {
    my $class = shift or require Carp, Carp::croak 'Need a class';

    if(@_ == 1 && ref $_[0] eq 'HASH') {
        @_ = ($class, %{$_[0]});
        goto \&_app_gitfind_class_builder_internal;
            # No extra stack frame for the sake of croak()
    } elsif(@_ == 1 && ref $_[0]) {
        require Carp;
        Carp::croak "$class\->new(arg) with @{[ref $_[0]]} instead of HASH ref";
    } elsif(@_ % 2) {
        require Carp;
        Carp::croak "Odd number of arguments to $class\->new()";
    }

    # Now we have key-value pairs.  Trim leading hyphens on the keys.
    my %args = @_;
    for (keys %args) {
        next unless /^-/;
        $args{ substr $_, 1 } = $args{ $_ };
        delete $args{ $_ };
    }

    return \%args;
};  # $_builder()

sub BUILDARGS {
    goto \&App::GitFind::Class::_app_gitfind_class_builder_internal;
} #BUILDARGS()

1;
__END__
# vi: set fdm=marker: #
