package Ambrosia::core::Object;
use strict;
use warnings;
use Carp;
use integer;

use XML::LibXML();
use Data::Serializer;

use overload '%{}' => \&__get_hash, fallback => 1;

use Ambrosia::error::Exceptions;
use Ambrosia::core::Nil;
use Ambrosia::Assert;

our $VERSION = 0.010;

unless ( $::__AMBROSIA_ACCESS_ALLOW )
{
    *__get_hash = sub {
        $_[0]->[1] ||= {};
        return $_[0]->[1] if $::__AMBROSIA_ACCESS_ALLOW;
        my $pkg = caller(0);

        my $self = shift;

        if ( $pkg eq ref $self || $self->isa($pkg) )
        {
            return $self->[1];
        }
        else
        {
            throw Ambrosia::error::Exception::AccessDenied("Access denied for $pkg in $self (@_); caller0: " . join ';', grep {$_} caller(0) );
        }
    };
}
else
{
    *__get_hash = sub { return $_[0]->[1] ||= {}; };
}

### constructor ###
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if ($class->__AMBROSIA_IS_ABSTRACT__)
    {
        throw Ambrosia::error::Exception 'You cannot instance abstract class ' . $class;
    }

    my $self = bless [[]], $class;
    $self->_init(@_);
    return $self;
}

sub fields
{
    return ();
}

### run from new ###
sub _init
{
    my $self = shift;

    return $self unless scalar @_;
    my %params = @_ == 1 ? %{$_[0]} : @_;

    foreach ( keys %params )
    {
        if ( eval {$self->can($_)} )
        {
            $self->$_ = $params{$_};
        }
        else
        {
            croak 'Not found property ' . $_ . ' in ' . ref($self);
        }
    }

    return $self;
}

sub value
{
    my $self = shift;

    my %FLDS; @FLDS{$self->fields} = ();

    my @res = map { $self->$_ } @_ ? (grep {exists $FLDS{$_} || throw Ambrosia::error::Exception::AccessDenied 'value: access denied - ' . $_} @_) : $self->fields;
    return wantarray ? @res : \@res;
}

sub string_dump
{
    return Data::Serializer->new(serializer => 'Storable', compress => 1)->serialize($_[0]);
}

sub string_restore
{
    my $dump = shift;
    return new Ambrosia::core::Nil unless $dump;

    my $obj = Data::Serializer->new(serializer => 'Storable')->deserialize($dump);

    reflection( sub {
            if ( my $refObj = ref $_[0] )
            {
                Ambrosia::core::ClassFactory::load_class($refObj)
            }
        }, $obj );

    my $caller = ref $obj;
    no strict 'refs';

    foreach my $f ( keys %{"$caller\::__AMBROSIA_INTERNAL_FLDS__"} )
    {
        reflection( sub {
                if ( my $refObj = ref $_[0] )
                {
                    Ambrosia::core::ClassFactory::load_class($refObj)
                }
            }, $obj->$f );
    }

    return $obj;
}

sub reflection #(&@)
{
    my $filter = shift;
    my $value = shift;
    my $refValue = ref $value;

    if ( $refValue eq 'ARRAY' )
    {
        return [ map { reflection($filter, $_) } @$value ];
    }
    elsif ( $refValue eq 'HASH' )
    {
        return { map { $_ => reflection($filter, $_) } keys %$value };
    }
    elsif ( $refValue eq 'CODE' )
    {
        my $r = $filter->($value->());
        return \$r;
    }
    else
    {
        return $filter->($value);
    }
}

sub as_hash
{
    my $self = shift;
    my $ignore = shift;
    my @methods = grep {$_} @_;

    my $hash = {};
    foreach my $f ( $self->fields )
    {
        $hash->{$f} = reflection( sub {
                my $v = shift;
                if ( ref $v eq 'SCALAR' )
                {
                    return $$v;
                }
                elsif ( ref $v && eval{ $v->can('as_hash') } )
                {
                    return $v->as_hash($ignore, $f);
                }
                else
                {
                    return $v;
                }
            }, $self->$f );
    }
    foreach ( @methods )
    {
        eval
        {
            my($m, $a, $p, @P);
            @P = ();
            if ( ($m, $a, $p) = ( $_ =~ /^(.+?)(?::(.+?))?\{(.*)\}$/s ) )
            {
                while ( $p =~ /^\s*(.+?(?:\{(?:.*?)\})?)\s*(?:,|$)(.*)/s )
                {
                    $p = $2;
                    push @P, $1;
                }
            }
            elsif ( ($m, $a) = ( $_ =~ /^(.+?)(?::(.+?))$/s ) )
            {
                
            }
            else
            {
                $m = $_;
            }
            $hash->{$a||$m} = reflection( sub {
                    my $v = shift;
                    if ( ref $v eq 'SCALAR' )
                    {
                        return $$v;
                    }
                    elsif ( ref $v && eval{ $v->can('as_hash') } )
                    {
                        return $v->as_hash($ignore, $p);
                    }
                    else
                    {
                        return $v;
                    }
                }, $self->$m(@P) );
        };
        if ( $@ )
        {
            throw Ambrosia::error::Exception $@ unless $ignore;
        };
    }
    return $hash;
}

sub copy_to
{
    my $self = shift;
    my $dest = shift;
    throw Ambrosia::error::Exception("Cannot copy $self to $dest.") unless ref $self eq ref $dest;
    foreach my $f ( $self->fields )
    {
        $dest->$f = $self->$f;
    }
}

sub clone
{
    no strict 'refs';
    my $self = shift;
    my $deep = shift;

    my $obj = $self->new();

    my $pkg = ref $self;# || die 'clone: for object context only!';
    assert {$pkg} 'clone: for object context only!';

    my @__FIELDS__ = (keys(%{"$pkg\::__AMBROSIA_INTERNAL_FLDS__"}), $self->parent_fields());

    if ( $deep )
    {
        foreach my $fn ( @__FIELDS__ )
        {
            eval
            {
            $obj->$fn = reflection( sub {
                    my $v = shift;
                    my $refV = ref $v;
                    if( $refV eq 'SCALAR' )
                    {
                        my $t = $$v;
                        return \$t;
                    }
                    elsif ( $refV eq 'GLOB' || $refV eq 'CODE' )
                    {
                        return $v;
                    }
                    elsif ( $refV && eval{$v->isa( __PACKAGE__ )} )
                    {
                        return $v->clone(1);
                    }
                    elsif ( $refV && eval{$v->can( 'clone' )} )
                    {
                        return $v->clone;
                    }
                    else
                    {
                        #die "cannot clone $v";
                        return $v;
                    }
                }, $self->$fn );
            };
            if ( $@ )
            {
                croak "$@\n";
                throw Ambrosia::error::Exception "FOR $fn CANNOT CLONE " . $self->$fn . ' :(', $@;
            }
        }
    }
    else
    {
        foreach my $f ( @__FIELDS__ )
        {
            $obj->$f = $self->$f;
        }
    }
    return $obj;
}

sub proces_node
{
    my $document = shift;
    my $node = shift;
    my $name = shift;
    my $value = shift;
    my $error_ignore = shift;

    unless (defined $value)
    {
        $value = '';
    }

    if ( ref $value )
    {
        as_xml_nodes($document, $node, $name, $value, $error_ignore);
    }
    else
    {
        $node->setAttribute( $name, $value );
    }
    return $node;
}

sub as_xml_nodes #( $document, $node, $p, $v, $params{error_ignore} )
{
    my $document = shift;
    my $ex_node = shift;
    my $p = shift;
    my $v = shift;
    my $error_ignore = shift;
    my $force_node = shift;
    my $refV = ref $v;
    local $@;

    if ( $refV eq 'ARRAY' )
    {
        as_xml_nodes($document, $ex_node, $p, $_, $error_ignore, $p) foreach @$v;
    }
    elsif ( $refV eq 'HASH' )
    {
        my $node = $document->createElement($p);
        proces_node( $document, $node, $_, $v->{$_}, $error_ignore ) foreach keys %$v;
        $ex_node->addChild($node);
    }
    elsif ( $refV eq 'SCALAR' )
    {
        $ex_node->setAttribute( $p, $$v);
    }
    elsif ( $refV && eval{$v->as_hash} )
    {
        my $node = $document->createElement($p);
        my $h = $v->as_hash;
        proces_node( $document, $node, $_, $h->{$_}, $error_ignore ) foreach keys %$h;
        $ex_node->addChild($node);
    }
    elsif ( $refV eq 'CODE' )
    {
        as_xml_nodes($document, $ex_node, $p, $v->(), $error_ignore);
    }
    elsif ( $refV && eval{$v->can('as_xml')} )
    {
        $ex_node->addChild($v->as_xml(
                                document => $document,
                                name => $p,
                                error_ignore => $error_ignore,
                                need_node => 1,
                            ));
    }
    elsif( $force_node )
    {
        my $node = $document->createElement($force_node);
        proces_node($document, $node, $force_node, $v, $error_ignore);
        $ex_node->addChild($node);
    }
    else
    {
        $ex_node->setAttribute( $p, $v );
    }
    return $ex_node;
}

# Parameters
#    document => 'xml_document', #optional. If not defined then the document will be created.
#    charset => 'charset_of_xml_document', #if not defined document. Optional. Default is 'utf8'
#    name => 'name_of_root_node', #optional. If nod present then the name will be making from '$self'
#    error_ignore => 'true or false in perl notation (1 or 0))', #optional. default is true
#    methods => [], #optional. See 
#

sub as_xml
{
    my $self = shift;
    my %params = @_;

    my ($name_node, $document);

    unless ( $name_node = $params{name} )
    {
        $name_node = ref $self;
        $name_node =~ s/::/_/gs;
    }

    unless ( $document = $params{document} )
    {
        $document = XML::LibXML->createDocument( '1.0', $params{charset} || 'UTF-8' );
    }

    my $node = $document->createElement($name_node);

    my $addChild = sub {
            my $p = shift;
            my $v = shift;

            if ( ref $v )
            {
                $node->addChild($_) foreach as_xml_nodes( $document, $node, $p, $v, $params{error_ignore} );
            }
            else
            {
                $node->setAttribute($p, $v);
            }
        };

    foreach ( $self->fields )
    {
        $addChild->($_, $self->$_);
    }

    foreach ( @{$params{methods}} )
    {
        eval
        {   # --== BNF ==--
            # mlist := method+
            # method := 'class_method_real_name'[[:alias]{method+}]
            # alias := 'alternative_name'
            #
            my($m, $a, $p, @P);
            @P = ();
            if ( ($m, $a, $p) = ( $_ =~ /^(.+?)(?::(.+?))?\{(.*)\}$/s ) )
            {
                while ( $p =~ /^\s*(.+?(?:\{(?:.*?)\})?)\s*(?:,|$)(.*)/s )
                {
                    $p = $2;
                    push @P, $1;
                }
            }
            elsif ( ($m, $a) = ( $_ =~ /^(.+?)(?::(.+?))$/s ) )
            {
                
            }
            else
            {
                $m = $_;
            }
            $node->addChild($_) foreach as_xml_nodes($document, $node, $a||$m, $self->$m(@P));
        };
        if ( $@ )
        {
            throw Ambrosia::error::Exception $@ unless $params{error_ignore};
        };
    }

    if ( $params{need_node} )
    {
        return $node;
    }
    else
    {
        $document->setDocumentElement($node);
        return $document;
    }
}

sub __fields_equal
{
    my $f1 = shift;
    my $f2 = shift;
    my $ref1 = ref $f1;
    my $ref2 = ref $f2;

    return 0 if $ref1 ne $ref2;
    if ( $ref1 eq 'ARRAY' )
    {
        return 0 if scalar @$f1 != scalar @$f2;
        for( my ($i,$j)=(0, scalar @$f1); $i < $j; ++$i )
        {
            unless ( my $res = __fields_equal($f1->[$i],$f2->[$i]) )
            {
                return $res;
            }
        }
        return 1;
    }
    elsif ( $ref1 eq 'HASH' )
    {
        my @keys = keys %$f1;
        return 0 if scalar @keys != scalar keys %$f2;
        return 0 if scalar @keys != scalar grep {exists $f2->{$_}} @keys;
        foreach ( @keys )
        {
            unless ( my $res = __fields_equal($f1->{$_}, $f2->{$_}) )
            {
                return $res;
            }
        }
        return 1;
    }
    elsif ( $ref1 eq 'SCALAR' )
    {
        return $f1 == $f2 || $$f1 eq $$f2;
    }
    elsif ( $ref1 eq 'CODE' )
    {
        return undef;#__fields_equal($f1->(), $f2->());
    }
    elsif ( $ref1 && $f1->isa('Ambrosia::core::Object') )
    {
        return $f1->equal($f2,1);
    }
    return $f1 eq $f2;
}

sub __deep_equal
{
    no strict 'refs';
    my $self = shift;
    my $other = shift;

    local $::__AMBROSIA_ACCESS_ALLOW = 1;

    my $selfRef = ref $self;
    my $otherRef = ref $other;

    my @SELF__FIELDS__ = keys %{"$selfRef\::__AMBROSIA_INTERNAL_FLDS__"};
    my $res = 1;
    my @isa = @{"$selfRef\::ISA"};

    while($res)
    {
        foreach (@SELF__FIELDS__)
        {
            unless(__fields_equal($self->{$_}, $other->{$_}))
            {
                #warn "$_ : " . $self->{$_} . ' ne ' . $other->{$_};
                $res = 0;
                last;
            }
        }
        last unless scalar @isa;
        my $PKG = pop @isa;
        @SELF__FIELDS__ = keys %{"$PKG\::__AMBROSIA_INTERNAL_FLDS__"};
    }
    return $res;
}

sub __equal
{
    my $self = shift;
    my $other = shift;
    my $deep = shift;

    if ( $deep )
    {
        return $self->__deep_equal($other);
    }
    else
    {
        no strict 'refs';
        my $otherRef = ref $other;
        my $alias = \%{"$otherRef\::__AMBROSIA_ALIAS_FIELDS__"};
        my $res = 1;
        foreach ( $self->fields )
        {
            my $p = $alias->{$_} || $_;
            my $v1 = $self->{$_};
            if ( ref $v1 )
            {
                unless ($v1 == $other->$p)
                {
                    $res = 0;
                    last;
                }
            }
            else
            {
                unless ($v1 eq $other->$p)
                {
                    $res = 0;
                    last;
                }
            }
        }
        return $res;
    }
}

sub equal
{
    my $self = shift;
    my $other = shift;
    my $deep = shift;
    my $identical = shift;

    return ($identical && int($self) == int($other))
            || (ref($self) eq ref($other) && $self->__equal($other, $deep));
}

################################################################################
sub __AMBROSIA_ATTR_ACTION__ { return {}; }

sub MODIFY_CODE_ATTRIBUTES
{
    my ($package, $subref, @attrs) = @_;

    no strict 'refs';
    no warnings 'redefine';
    my $h = $package->__AMBROSIA_ATTR_ACTION__();
    *{"${package}::__AMBROSIA_ATTR_ACTION__"} = sub { return { %$h, $subref => [$package, $subref, \@attrs] } };
    return;
}

sub FETCH_CODE_ATTRIBUTES
{
    #my ($package, $subref) = @_;
    #my $attrs = $attrs{ refaddr $subref };
    #return @$attrs;
}

1;

__END__

=head1 NAME

Ambrosia::core::Object - an abstract base class for classes that are created by Ambrosia::Meta.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    # file Foo.pm
    package Foo;
    use strict;
    
    use Ambrosia::Meta;
    class
    {
        public    => [qw/foo_pub1 foo_pub2/],
        protected => [qw/foo_pro1 foo_pro2/],
        private   => [qw/foo_pri1 foo_pri2/],
    };
    
    sub _init
    {
        my $self = shift;
        $self->SUPER::_init(@_);

        $self->foo_pub1 ||= 'foo_pub1';
        $self->foo_pub2 ||= 'foo_pub2';
        $self->foo_pri1 ||= 'foo_pri1';
        $self->foo_pri2 ||= 'foo_pri2';
        $self->foo_pro1 ||= 2;
        $self->foo_pro2 ||= 'foo_pro2';
    }
    
    sub count
    {
        shift->foo_pro1
    }
    
    1;
    
    # file Bar.pm
    package Bar;
    use strict;
    
    use Ambrosia::Meta;
    class sealed
    {
        extends   => [qw/Foo/],
        public    => [qw/bar_pub1 bar_pub2/],
        protected => [qw/bar_pro1 bar_pro2/],
        private   => [qw/bar_pri1 bar_pri2 list/],
    };
    
    sub _init
    {
        my $self = shift;

        #Ignore all input data
        $self->SUPER::_init(foo_pri1=>4);
        $self->bar_pub1 = 'bar_pub1';
        $self->bar_pub2 = 'bar_pub2';
        $self->bar_pri1 = 'bar_pri1';
        $self->bar_pri2 = 'bar_pri2';
        $self->bar_pro1 = 'bar_pro1';
        $self->bar_pro2 = 'bar_pro2';

        $self->list = [] unless defined $self->list;

        push @{$self->list}, (new Foo(foo_pub1 => 'list1.1', foo_pub2 => 'list1.2'),
                              new Foo(foo_pub1 => 'list2.1', foo_pub2 => 'list2.2')
                              );
    }

    1;

    # file test.pl

    #!/usr/bin/perl -w
    use strict;
    use Data::Dumper;
    use Bar;

    my $obj1 = new Bar;

    $obj1->foo_pub1 = 1;
    print $obj1->foo_pub1, "\n";

    use Time::HiRes qw ( time );

    my $s = 0;

    my $t1=time;

    foreach ( 1..10000 )
    {
        $s += $obj1->count;
    }
    print "time:",(time-$t1), "\n";

    print "sum=$s\n";

    $t1=time;

    foreach ( 1..10000 )
    {
        my $obj1 = Bar->new;
    }
    print "time:",(time-$t1), "\n";

    print Dumper($obj1);

    my $r;
    read STDIN, $r, 1;

    print $r;

    ############################################################################

=head1 DESCRIPTION

C<Ambrosia::core::Object> is the abstract base class for classes that are created by Ambrosia::Meta.

=head1 CONSTRUCTOR

=head2 new

This method creates the new object of specified type.
Input params is a hash or a reference to hash.
The hash keys are the fields of the class that have been created by Ambrosia::Meta

=head2 _init

C<_init> is called from C<new> to initialize fields (include private and protected fields) of an object by input parameters.
This method may be overriden in child class.

=head1 METHODS

=head2 fields

Returns public fields of class (include public fields of parent classes) that have been created by Ambrosia::Meta.

=head2 value

Returns values of specified public fields or values of all public fields if not stated.

=head2 string_dump

Returns the dump of the object as string to store.
C<print $obj-E<gt>string_dump()>

=head2 string_restore($string_dump)

Static method of class (package).
Restores the object from dump created early by method C<string_dump()>.
C<my $obj = Ambrosia::core::Object::string_restore($obj-E<gt>string_dump())>

B<WARNING!> When restoring an object from dump this method does not call C<_init>.
Also see documentation in L<Data::Serializer>.

=head2 as_hash ($error_ignore, @methods)

If C<$error_ignore> is true all errors occurred in this method will be ignored.

Returns the object as hash structure.
You can also declare methods of class that will be called and their returned values will also be stored in hash.

Rule for declare methods.
C<real_method_of_class:name_for_key_in_hash(params_for_method_split_by_comma){methods_of_returned_objects}>

Or in BNF (in square brackets is optional):
    methods := method_declare[,methods]
    method_declare := method[{methods_of_class_of_returned_object}]
    method := real_name_of_method_in_class[:alias[(params)]]
    params := param[,params] #just any data
    methods_of_class_of_returned_object := methods #if method return reference to another object then you can present any methods of that result object and etc.

For example:

    {
        package Bar;
        Ambrosia::Meta;
        class
        {
            public => [qw/b1 b2/],
        };
    
        sub join
        {
            my $self = shift;
            return $self->b1 . ';' . $self->b2;
        }
    
        1;
    }
    {
        package Foo;
        Ambrosia::Meta;
        class
        {
            public => [qw/f1 f2 bar/],
        };
        
        sub m1
        {
            return 'method of m1 run with: ' . $_[1];
        }
        
        sub getBar
        {
            return $_[0]->bar;
        }
        
        sub dump
        {
            my $self = shift;
            return $self->as_hash(1, 'm1:method1(123)', 'getBar{join}');
        }
        1;
    }

=head2 copy_to ($dest)

Makes copy of the source object to the destination object (only public fields are copied).
    C<$source-E<gt>copy_to($dest)>

=head2 clone ($deep)

Makes clone of object.
If C<$deep> is true it will create a deep clone.
And vice versa if C<$deep> is false it will create a simple clone.
If a field is a reference to some data then the field of simple clone will also refer to these data.

Note for deep clone: if any field is the reference to any object, this object will also be cloned but only if it has the method C<clone>

=head2 as_xml ($document, $charset, $name, $error_ignore, @methods)

Converts the object to the XML Document (L<XML::LibXML::Document>).
Is called with the following params

=over 4

=item document

The xml document. Optional. If not defined, the document will be created.

=item charset

Charset of xml document if it has not been defined. Optional. Default is 'utf8'.

=item name

Name of root node. Optional. If not presented, the class name will be used.

=item error_ignore ($bool)

True or false in perl notation (1 or 0). Optional. Default value is true.
In the case of error and if C<$bool> is true, the error will be ignored.

item methods

Optional. See L<as_hash>.

=back

=head2 equal ($other_object, $deep, $identical)

Compares two objects.
$object->equal($other_object, $deep, $identical);
If $deep is true, deep compare will be executed.
If $identical is true, only references of objects will be compared.

    my $obj = new SomeObject();
    my $ref = $obj;
    my $obj2 = new SomeObject();

    $obj->equal($ref,0,1); #is true
    $obj->equal($obj2,0,1); #is false
    $obj->equal($obj2); #is true
    $obj->equal($obj2,1); #is true

=head1 DEPENDENCIES

L<XML::LibXML>
L<Data::Serializer>
L<Ambrosia::error::Exceptions>
L<Ambrosia::core::Nil>

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 SEE ALSO

L<Ambrosia::Meta>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
