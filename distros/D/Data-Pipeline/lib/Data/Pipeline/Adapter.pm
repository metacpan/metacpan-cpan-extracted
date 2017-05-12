package Data::Pipeline::Adapter;

use Moose;

use MooseX::Types::Moose qw(GlobRef CodeRef);

use Data::Pipeline::Types qw( Iterator IteratorSource );

use Data::Pipeline::Aggregator::Machine;
use Data::Pipeline::Iterator::Output;
use Data::Pipeline::Iterator::Source;

has preamble => (
    is => 'rw',
    isa => 'Str|CodeRef',
    predicate => 'has_preamble',
    lazy => 1,
    default => sub { '' }
);

has postamble => (
    is => 'rw',
    isa => 'Str|CodeRef',
    predicate => 'has_postamble',
    lazy => 1,
    default => sub { '' }
);

has source => (
    is => 'rw',
    isa => IteratorSource,
    lazy => 1,
    coerce => 1,
    default => sub {
        Data::Pipeline::Iterator::Source -> new(
            get_next => sub { },
            has_next => sub { 0 }
        );
    }
);

sub transform {
    my($self, $iterator, $options) = @_;

    return Data::Pipeline::Iterator::Output -> new(
        iterator => $iterator,
        serializer => $self,
        options => ($options||{})
    );
}

sub serialize {
    my($self, $iterator, $target) = @_;

    my($pre, $post);

    $pre = (is_CodeRef($self -> preamble) ? $self -> preamble -> () : $self -> preamble);
    $post = (is_CodeRef($self -> postamble) ? $self -> postamble -> () : $self -> postamble);
    if( UNIVERSAL::isa($target, 'IO::Handle') || is_GlobRef($target) ) {
        print $target $pre;
        print $target $self -> inner until $iterator -> finished;
        print $target $post;
    }
    elsif( is_CodeRef( $target ) ) {
        $target -> ($pre);
        $target -> ($self -> inner);
        $target -> ($post);
    }
    elsif( ref( $target ) ) {
        $$target = $pre;
        $$target .= $self -> inner until $iterator -> finished;
        $$target .= $post;
    }
    else {
        # not a ref... what to do...?
    }
}

sub duplicate {
    my($self, %options) = @_;
    
    # we want to build a new iterator source that should start over
    # we avoid private attributes and {get|has}_next
    # if those are required, we can't duplicate
    
    
    my @attrs;
    
    @attrs = $self -> can_duplicate or
        Carp::croak "Unable to duplicate adapter (".($self -> meta -> name).")";
    
    my %defaults;
    my $meta = $self -> meta;
    $defaults{$_} = $self -> $_
        foreach grep { !/^_/ && $meta->get_attribute($_)->has_value($self) } (@attrs);

    delete $defaults{source};
       
    return $self -> new(%defaults, %options);
}

sub can_duplicate {
    my($self) = @_;
     
    my @attrs = $self -> meta -> get_attribute_list;

    # we return @attrs as an optimization
    return @attrs;
    return;
}   

no Moose;

1;

__END__

=head1 NAME

Data::Pipeline::Adapter - data format i/o adapter

=head1 SYNOPSIS

=head2 Creating an Adapter

 package My::Adapter;

 use Moose;
 extends 'Data::Pipeline::Adapter';

 has '+source' => (
    default => sub {
        my($self) = @_;

        # build Data::Pipeline::Iterator::Source
    }
 );

=head3 Serializing to the default handling of targets:

 augment serialize => sub {
     my($self, $iterator, $target) = @_;

     # return serialized form of one item from iterator
 };

=head3 Overriding how targets are handled:

 override serialize => sub {
     my($self, $iterator, $target) = @_;

     # serialize $iterator to $target
 };

=head2 Using an Adapter

 use My::Adapter;

 my $out = My::Adapter -> new( ... ) -> transform( $iterator );

 $out -> to( \$string ); # $string now contains serialization

 my $iterator = $pipeline -> transform( My::Adapter -> new( ... ) );

=head1 DESCRIPTION


