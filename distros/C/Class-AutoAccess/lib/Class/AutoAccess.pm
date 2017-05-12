package Class::AutoAccess;

use warnings;
use strict ;

=head1 NAME

Class::AutoAccess - Zero code dynamic accessors implementation.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

Base class for automated accessors implementation.

If you implement a class as a blessed hash reference, this class helps you not
to write the fields accessors yourself. It uses the AUTOLOAD method to implement accessors
on demand. Since the accessor is *REALLY* implemented the first time it is attempted to be used,
using this class does NOT affect the performance of your program.

Inheriting from this class does not impose accessors. If you want to implement your own accessors for any reason
(checking, implementation change ... ), just write them and they will be used in place of automated ones.


This class uses the AUTOLOAD method, so be careful when you 
implement your own AUTOLOAD method in subclasses.

If you want to keep this feature functionnal in this particular case,
evaluate SUPER::AUTOLOAD in your own AUTOLOAD method before doing anything else.


=head1 SYNOPSIS

    package Foo ;

    use base qw/Class::AutoAccess/ ;  # Just write this

    sub new{
        my ($class) = @_ ;
        my $self = {
                'bar' => undef ,
                'baz' => undef ,
                'toCheck' => undef
        };
     return bless $self, $class ;
    }

    sub toCheck{
        my ($self , $value ) = @_ ;
        # Behave the way you want. This accessor will be used in place of automated ones.
    }

    1;

    package main ;

    my $o = Foo->new();
    
    # Since there is a bar attribute, the accessor will be implemented at the first use:
    $o->bar();
    # This time, the bar accessor is really implemented so there is no performance lost.
    $o->bar("new value");

    # Idem.
    $o->baz() ;
    
    # If you wrote your own accessor, it will be used (this is a Perl feature)
    $o->toCheck("value");

=head1 AUTHOR

Jerome Eteve, C<< <jerome@eteve.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to
C<bug-class-autoaccess@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-AutoAccess>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005-2010 Jerome Eteve, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use Carp ;

our $AUTOLOAD ;


sub AUTOLOAD{
	my ($self,$value)= @_ ;
	
	# $AUTOLOAD contains the full name of the missing method.

	# Avoid implicit ovverriding of destroy method.
	return if $AUTOLOAD =~ /::DESTROY$/ ;

	my $attname = $AUTOLOAD;
	# Removing packagename from the attname.
	$attname =~ s/.*::// ;

	if(! exists $self->{$attname}){
		confess("Attribute $attname does not exists in $self");
	}

	# If attribute exists, got to set up the method
	# in order to avoid calling this everytime

	my $pkg = ref($self ) ;
        my $methCode = sub{
            my $obj = shift ;
            @_ ? $obj->{$attname} = shift : $obj->{$attname} ;
        };
        
        ## Install method as $pkg::$attname
        {
            no strict 'refs' ;
            *{$pkg.'::'.$attname}  = $methCode ;
        }
        
        # Let's use our shiny new method
	goto &$AUTOLOAD ;
		
}

1; # End of Class::AutoAccess
