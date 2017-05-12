package Class::Trait::Base;

use strict;
use warnings;
require Class::Trait;

our $VERSION = '0.31';

sub apply {
    my ($trait, $instance) = @_;
    Class::Trait->apply($instance, $trait);
    return $trait;
}

# all that is here is an AUTOLOAD method which is used to fix the SUPER call
# method resolution problem introduced when a trait calls a method in a SUPER
# class since SUPER should be bound after the trait is flattened and not
# before.

sub AUTOLOAD {
    my $auto_load = our $AUTOLOAD;

    # we dont want to mess with DESTORY
    return if ( $auto_load =~ m/DESTROY/ );

    # if someone is attempting a call to
    # SUPER, then we need to handle this.
    if ( my ($super_method) = $auto_load =~ /(SUPER::.*)/ ) {

        # get our arguemnts
        my ( $self, @args ) = @_;

        # lets get the intended method name
        $super_method = scalar( caller 1 ) . '::' . $super_method;
        return $self->$super_method(@args);
    }

    # if it was not a call to SUPER, then
    # we need to let this fail, as it is
    # not our problem
    die "undefined method ($auto_load) in trait\n";
}

1;

__END__

=head1 NAME

Class::Trait::Base - Base class for all Traits

=head1 SYNOPSIS

This class needs to be inherited by all traits so they can be identified as
traits.

	use Class::Trait 'base';

=head1 DESCRIPTION

Not much going on here, just an AUTOLOAD method to help properly dispatch
calls to C<SUPER::> and an C<apply> method.

##############################################################################

=head2 apply

  require TSomeTrait;
  TSomeTrait->apply($object);

This method allows you to apply a trait to an object.  It returns the trait so
you can then reapply it:

 TTricks->apply($dog_object)
        ->apply($cat_object);

This is merely syntactic sugar for the C<Class::Trait::apply> method:

 Class::Trait->apply($dog_object, 'TTricks');
 Class::Trait->apply($cat_object, 'TTricks');

=cut

=head1 SEE ALSO

B<Class::Trait>, B<Class::Trait::Config>

=head1 MAINTAINER

Curtis "Ovid" Poe, C<< <ovid [at] cpan [dot] org> >>

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com> 

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
