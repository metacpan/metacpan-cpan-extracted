package Catalyst::Plugin::C3;

use strict;
use warnings;
use NEXT;
use Class::C3;

our $VERSION = '0.03';

=head1 NAME

Catalyst::Plugin::C3 - Catalyst Plugin to subvert NEXT to use Class::C3

=head1 SYNOPSIS

Use it in an application:

  package MyCatApp;
  use Catalyst qw/ -Debug C3 Static::Simple /;

Use it in another plugin:

  package Catalyst::Plugin::FooBar;
  use base qw/ Catalyst::Plugin::C3 /;

=head1 DESCRIPTION

*** WARNING *** THIS MODULE IS STILL EXPERIMENTAL !!!

This module is related to the possible transition of Catalyst from L<NEXT>
to L<Class::C3>.  This transition hasn't happened yet, and might not for
a while.

This module is only intended for use by Catalyst module developers at
this time.  You would know it if you should be using this module.

*** END WARNING ***

This module makes the use of the following idiom:

  use NEXT;

  sub foo {
    my $self = shift->NEXT::foo(@_);
  }

actually accomplish something more like:

  use Class::C3;

  sub foo {
    my $self = shift->next::method(@_);
  }

It does this by temporarily replacing L<NEXT/AUTOLOAD> during the
entire L<Catalyst> request-handling phase.  The behavior of the replacement
function is dependant upon the class (or the class of the object) that
L<NEXT> was being called on.

If the class is not Catalyst-related, the function falls back to normal
L<NEXT> behavior.  If the class is Catalyst-related, but its inheritance
hierarchy is not C3-compatible, the function warns about the situation
(once per class per interpreter) and again falls back to normal L<NEXT>
behavior.

If the class is both Catalyst-related and has a C3-compatible hierarchy,
then L<NEXT> calls are silently upgraded to their L<Class::C3> equivalents.

The difference between C<$self-E<gt>NEXT::foo()> and
C<$self-E<gt>NEXT::ACTUAL::foo()> is preserved (the former becomes
C<maybe::next::method> and the latter becomes C<next::method>).

If you are going to place this module in your plugins list for
a Catalyst app, it is best placed at the top of the list, above
all other plugins.

Some other plugins may need require this plugin as a base-class in order
to transition themselves to L<Class::C3> without worrying about being
broken by other plugins which haven't made the transition.  Most plugins
will *not* need to do so.  Any that do would have wierd hacks involving
C<*{NEXT::NEXT}> in them prior to their C3 conversion, so you'd know it.

In other words, a plugin should only base on this plugin if it
needed L<NEXT> hacks to work right under L<NEXT>, and you're
transitioning it to use L<Class::C3>.

=head1 METHODS

=cut

# boolean result: does this class inherit from a Cat base class?
sub _is_cat_based {
    my $class = shift;

    # This could be simplified if there were a singular real Catalyst
    #  base class that parented all of these:

    return $class->isa('Catalyst::Component')
        || $class->isa('Catalyst::Request')
        || $class->isa('Catalyst::Response')
        || $class->isa('Catalyst::Action')
        || $class->isa('Catalyst::Engine')
        || $class->isa('Catalyst::Dispatcher')
        || $class->isa('Catalyst::DispatchType')
        || $class->isa('Catalyst::Exception')
        || $class->isa('Catalyst::Log');
}

# Hack NEXT::AUTOLOAD to use C3's ->next::method iff the object
#  ->isa Catalyst object of some sort AND the object has a C3-valid
#  inheritance heirarchy.
{
    my %__c3_mro_ok;
    my $__saved_next_autoload = \&NEXT::AUTOLOAD;

    sub __hacked_next_autoload {
        # $class is the class of the object ->NEXT::methodname was used on
        my $class = ref $_[0] || $_[0];

        my $wanted = $Catalyst::Plugin::C3::AUTOLOAD || 'NEXT::AUTOLOAD';
        my ($wanted_class, $wanted_method) = $wanted =~ m{(.*)::(.*)}g;

        # Check each class only once
        if(!exists $__c3_mro_ok{$class}) {
            if(_is_cat_based($class)) {
                eval { Class::C3::calculateMRO($class) };
                my $err = $@;
                if($err) {
                    warn "Class::C3::calculateMRO('$class') Error: '$err'; Falling"
                       . ' back to plain NEXT.pm behavior for this class';
                    $__c3_mro_ok{$class} = 0;
                }
                else {
                    $__c3_mro_ok{$class} = 1;
                }
            }
            else {
                # don't muck around with non-Cat stuff that uses NEXT,
                #  but don't warn about it either
                $__c3_mro_ok{$class} = 0;
            }
        }

        goto &$__saved_next_autoload if !$__c3_mro_ok{$class};
        goto &next::method if $wanted_class =~ /^NEXT:.*:ACTUAL/;
        goto &maybe::next::method;
    }
}

package Catalyst::Plugin::C3;

=head2 handle_request

This plugin hooks into the C<handle_request> method, sets up a C<local>
override of the standard version of L<NEXT/AUTOLOAD> for the entire 
request.

=cut

sub handle_request {
    no warnings 'redefine';
    local *NEXT::AUTOLOAD = \&__hacked_next_autoload;
    shift->next::method(@_);
}

=head1 CAVEAT

Because calculating the MRO of every class every time ->NEXT::foo is used
from within it is too expensive, runtime manipulations of @ISA are prohibited.

=head1 AUTHOR

Brandon Black C<blblack@gmail.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
