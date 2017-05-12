package Class::Lite;
# Choose minimum perl interpreter version; delete the rest.
# Do you want to enforce the bugfix level?
#~ use 5.008008;   # 5.8.8     # 2006  # oldest sane version
#~ use 5.008009;   # 5.8.9     # 2008  # latest 5.8
#~ use 5.010001;   # 5.10.1    # 2009  # say, state, switch
#~ use 5.012003;   # 5.12.5    # 2011  # yada
#~ use 5.014002;   # 5.14.3    # 2012  # pop $arrayref, copy s///r
#~ use 5.016002;   # 5.16.2    # 2012  # __SUB__
use strict;
use warnings;
use version; our $VERSION = qv('v0.1.0');

# Alternate uses
#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

## use
#============================================================================#

#=========# CLASS METHOD
#~ my $self    = My::Class->new(@_);
#
#   Classic hashref-based-object constructor.
#   Passes any arguments to init().
#   
sub new {
    my $class   = shift;
    my $self    = {};
    bless ( $self => $class );
    $self->init(@_);
    return $self;
}; ## new

#=========# OBJECT METHOD
#~ $self->init(@_);
#
#   Abstract method does nothing. Override in your class.
#   
sub init {
    return shift;
}; ## init

#=========# CLASS METHOD
#~ use Class::Lite qw| attr1 attr2 attr3 |;
#~ use Class::Lite qw|             # Simple base class with get/put accessors
#~     attr1
#~     attr2
#~     attr3
#~ |;
#
#   @
#   
sub import {
    no warnings 'uninitialized';
    my $class       = shift;
    my $caller      = caller;
    my $bridge      = qq{Class::Lite::$caller};
    ### $class
    ### $bridge
    ### $caller
    
    # In case caller is eager.
    my @args        = $class->fore_import(@_);
    ### @args
    
    # Do most work in the bridge class.    
    eval join qq{\n},
        qq* package $bridge;                                            *,
        qq* our  \@ISA;                                                 *,
        qq* push \@ISA, '$class';                                       *,
        map {
            defined and ! ref and /^[^\W\d]\w*\z/s
                or die "Invalid accessor name '$_'";
              qq* sub get_$_ { return \$_[0]->{$_} };                   *
            . qq* sub put_$_ { \$_[0]->{$_} = \$_[1]; return \$_[0] };  *
        } @args,
    ;
    # <xiong> I cannot figure out a way to make this eval fail.
    #           When you find out, please let me know. 
    # uncoverable branch true
    die "Failed to generate $bridge: $@" if $@;
    
    # Make caller inherit from bridge.
    eval join qq{\n},
        qq* package $caller;                                            *,
        qq* our  \@ISA;                                                 *,
        qq* push \@ISA, '$bridge';                                      *,
    ;
    # This second eval fails in case recursive inheritance is attempted.
    die "Failed to generate $caller: $@" if $@;
    
    # In case caller must get the last word.
    $class->rear_import(@_);
    
    return 1;    
}; ## import

# Dummy methods do nothing.
sub fore_import { shift; return @_ };
sub rear_import { shift; return @_ };

## END MODULE
1;
#============================================================================#
__END__

=head1 NAME

Class::Lite - Simple base class with get/put accessors

=head1 VERSION

This document describes Class::Lite version v0.1.0

=head1 SYNOPSIS

    package Toy::Class;
    use Class::Lite qw| foo bar baz |;              # make get/put accessors
    
    package Any::Class;
    use Toy::Class;
    my $toy     = Toy::Class->new;
    $toy->init(@_);                                 # does nothing; override
    $toy->put_foo(42);
    my $answer  = $toy->get_foo;
    
    use Class::Lite;                                # no accessors

=head1 DESCRIPTION

=over

I<< Nature's great masterpiece, an elephant, 
The only harmless great thing.  >> 
-- John Donne

=back

The hashref-based base class that does no more than it must. Your 
constructor and accessors are defined in a bridge package so you can 
override them easily. 

=head1 Why?

Computer programmers are clever people who delight in evading restrictions.
Create an L<< inside-out|Class::Std >> (flyweight) class to enforce 
encapsulation and another fellow will L<< hack in|PadWalker >>. The only 
way to win the ancient game of locksmith and lockpick is never to begin. 
If someone misuses your class then it's not your responsibility. 
Hashref-based objects are traditional, well-understood, even expected in 
the Perl world; tools exist with which to work with them. 

Similarly, C<< Class::Lite >> provides no read-only accessors. If your client 
developer wants to alter an attribute he will; you may as well provide a 
method for the purpose. You might warn against the practice by overriding 
the default method: 

    sub put_foo {
        warn q{Please don't write to the 'foo' attribute.};
        my $self    = shift;
        return $self->SUPER::put_foo(@_);
    };

B<< set >> is too similar to B<< get >> in one way, not enough in another. 
Also B<< set >> is one of those heavily overloaded words, like "love" or 
"data", that I prefer to avoid using at all. I say B<< put >> is equally 
short, clearer in intent, not easily misread for B<< get >>; and the first 
character's descender points in the opposite direction.

I eschew single-method C<< foo() >> accessors. 

I have long defined C<< init() >> as a shortcut method to fill up a new 
object; but this is a blatant violation of encapsulation, no matter who 
does it. No more. 

If accessors are defined in your calling package then you will raise a 
warning if you attempt to redefine them; if they are defined in 
C<< Class::Lite >> itself then they will be available to all that inherit 
from it. So your accessors are defined in an intermediate "bridge" package 
generated at compile-time. 

=head1 USE-LINE

    package Toy::Class;
    use Class::Lite qw| foo bar baz |;              # make get/put accessors
    use Class::Lite;                                # no accessors

Makes C<< Class::Lite >> a base class for Toy::Class. If arguments are 
given then simple get and put accessors will be created in caller's 
namespace for each argument. The accessors do no validation. 

B<< This is probably all you need to know. >> Read on if you intend to do tricky stuff in a superclass. 

=head1 INHERITED METHODS 

=head2 import()

    Class::Lite->import(@_);
    A::Subclass->import(@_);

Called by use() as usual and does all the work. Inherited by caller so 
your further subclasses can also take advantage of C<< Class::Lite >> 
features. 

Since this is merely inherited you may define your own C<< import() >> with 
impunity. If you want to have your cake and eat it, too, beware: 

    package Big;
    sub import {
        my $class       = shift;
        # Do specific stuff...
        $class->SUPER::import(@_);
        return 1;
    };
    
    package Tot;
    use Big (@args);

This will not work as you expect! C<< SUPER::import() >> will think Big is 
its C<< caller() >>, which is true. So instead of making Big a parent of 
Tot and defining accessors for Tot; C<< SUPER::import() >> will attempt to 
make Big a parent of itself... at which point the fatal error relieves us 
of further worry. 

=head2 fore_import()

    package Big;
    sub fore_import {
        my $class       = shift;
        my $args        = shift;
        my $hoge        =    $args->{hoge}      // 'default'     ;
        my @accessors   = @{ $args->{accessors} // []           };
        _do_hoge{$hoge};
        return @accessors;
    };
    
    package Tot;
    use Big {
        hoge        => 'piyo',
        accessors   => [qw| chim chum choo |],
    };

To solve the difficulty previously mentioned: Leave C<< import() >> 
untouched and do whatever you like to the use-line argument list in a 
redefined C<< fore_import() >>. Just be sure to return a flat list of 
arguments so C<< import() >> can do its work. 

The default method does nothing and merely returns its arguments. 

=head2 rear_import()

If you just have to get the last word, redefine C<< rear_import() >> 
instead, or also. You'll be passed all the use-line arguments, not just 
what C<< fore_import() >> returned; and your return value will be 
discarded. 

The default method does nothing and merely returns its arguments. 

NOTE that neither of these methods must be employed if all you want to do in your class is override C<< Class::Lite::import() >> completely. 

=head2 new()

    my $obj = My::Class->new(@_);

Blesses an anonymous hash reference into the given class which inherits 
from C<< Class::Lite >>. Passes all its args to C<< init() >>. 

=head2 init()

    my $obj = $old->init(@_);

This abstract method does nothing at all and returns its object. 
You may wish to override it in your class. 

=head1 GENERATED METHODS 

Accessor methods are generated for each argument on the use-line. 
They all do just what you'd expect. No validation is done. 

    $self   = $self->put_attr($foo);
    $foo    = $self->get_attr;

Put accessors return the object. Get accessors discard any arguments.

=head1 MULTIPLE INHERITANCE

C<< Class::Lite::import() >> is something of a black magic method; it tinkers in caller's package, create a bridge package (in memory), defines methods. It should probably only be called by C<< use() >> or at least from within a C<< BEGIN >> block; no attempt is made to define its behavior if called otherwise. 

Even at compile-time there are questions raised when your class inherits from both C<< Class::Lite >> and some other superclass: 

    package My::Class;
    use Class::Lite qw| foo bar baz |;              # make get/put accessors
    use parent 'Big::Fat::Super';

If the other superclass is pedestrian and just defines methods for you to 
inherit then there's little likelihood of interaction. If the other 
superclass is also trying to define methods with the same names as 
generated accessors then who can say? So don't do that. 

Diamond inheritance is a special case: 

    package My::Big;
    use Class::Lite qw| big1 big2 big3 |;
    
    package My::Tot;
    # I want to inherit from My::Big but I also want Class::Lite's acc's.
    use My::Big;
    use Class::Lite qw| big3 tot1 tot2 |;

This works, regardless of which superclass is use'd first, even if the 
accessor lists overlap. If the My::Big superclass does funny stuff, though, 
all bets are off. Anybody with a use case is welcome to open an issue. 

=head1 SEE ALSO

L<< Object::Tiny|Object::Tiny >>, L<< Mouse|Mouse >>

=head1 INSTALLATION

This module is installed using L<< Module::Build|Module::Build >>. 

=head1 DIAGNOSTICS

=over

=item C<< Invalid accessor name... >>

You passed something horrible on the use-line. Valid arguments to 
C<< import >> need to be quoted strings and valid Perl identifiers. If you 
have in your class some C<< '-$/' >> attribute (which is a valid hash key) 
then you'll have to write your own accessors for it. You won't be able to 
call them, for example, C<< get_-$/() >>. 

This error will attempt to display the offending argument but may not succeed.

=item C<< Failed to generate (package) >>

Something evil happened while doing the heavy lifting: getting into your 
package, getting into the bridge package, setting up the ISA 
relationships, or defining requested accessors. This should not happen and 
isn't your fault (unless you've tried to inherit recursively). Please make 
a bug report. 

=begin for_later

=item C<< some error message >>

Some explanation. 

=item C<< some error message >>

Some explanation. 

=end for_later

=back

=head1 CONFIGURATION AND ENVIRONMENT

None. 

=head1 DEPENDENCIES

There are no non-core dependencies. 

=begin html

<!--

=end html

L<< version|version >> 0.99 E<10> E<8> E<9>
Perl extension for Version Objects

=begin html

-->

<DL>

<DT>    <a href="http://search.cpan.org/perldoc?version" 
            class="podlinkpod">version</a> 0.99 
<DD>    Perl extension for Version Objects

</DL>

=end html

This module should work with any version of perl 5.8.8 and up. 
However, you may need to upgrade some core modules. 

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

This is an early release. Reports and suggestions will be warmly welcomed. 

Please report any issues to: 
L<< https://github.com/Xiong/class-lite/issues >>.

=head1 DEVELOPMENT

This project is hosted on GitHub at: 
L<< https://github.com/Xiong/class-lite >>. 

=head1 THANKS

Adam Kennedy (ADAMK) for L<< Object::Tiny|Object::Tiny >>,  on which much of 
this module's code is based. 

=head1 AUTHOR

Xiong Changnian C<< <xiong@cpan.org> >>

=head1 LICENSE

Copyright (C) 2013 
Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<< http://www.opensource.org/licenses/artistic-license-2.0.php >>

=cut





