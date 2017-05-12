package Data::Pipeline;

our $VERSION = '0.02';

use Sub::Exporter;
use Sub::Name 'subname';
use Class::MOP ();
use Carp ();

use Data::Pipeline::Iterator;

use MooseX::Types::Moose qw(HashRef);

sub import {
    my($class, @methods) = @_;

    my $CALLER = caller();

    my %exports;

    for my $method (@methods) {

        my $impl_class = _find_class($method);

        if($impl_class =~ m{^Data::Pipeline::(Action|Adapter)X?::} || $impl_class -> isa('Data::Pipeline::Aggregator::Machine')) {
            $exports{$method} = sub {
                my $class = $CALLER;
                return subname "Data::Pipeline::$method" => sub {
                    return $impl_class -> new( @_ );
                };
            };
        }
        elsif($impl_class =~ m{^Data::Pipeline::Aggregator}) {
            $exports{$method} = sub {
                my $class = $CALLER;
                return subname "Data::Pipeline::$method" => sub {
                    my @actions = map {
                        ref($_) ? $_ :
                        ($c = _find_class($_)) ? $c -> new() :
                        Carp::croak "Unable to incorporate $_ into pipeline"
                    } @_;   
                    return $impl_class -> new( actions => \@actions );
                };
            };
        }

    }

    my $exporter = Sub::Exporter::build_exporter({
        exports => \%exports,
        groups => { default => [':all'] }
    }); 

    goto &$exporter;
}

sub _find_class($) {
    my($type) = @_;

    #return $type if eval { Class::MOP::load_class($type) };

    #my $class="Data::Pipeline::$type";

    #return $class if eval { Class::MOP::load_class($class) };

    for my $p (qw(Aggregator Adapter Action AggregatorX AdapterX ActionX)) {

        $class="Data::Pipeline::${p}::${type}";
 
        return $class if eval { Class::MOP::load_class($class) };
    }

    Carp::croak "Unable to find an implementation for $type";
}

1;

__END__

=pod

=for readme stop

=head1 NAME

Data::Pipeline - manage aggregated data filters

=head1 SYNOPSIS

 use Data::Pipeline qw( Pipeline Truncate Count Array );

 my $p = Pipeline(
    CSV,
    Truncate( length => 5 ),
 );

 my $iterator = $p -> from( file => $filename );

 until( $iterator -> finished ) {
    my $v = $iterator -> next;
    # get the first five items in a CSV file
 }

If combining the output of multiple pipelines:

 use Data::Pipeline qw( Pipeline Union );

 my $u = Union(
    Pipeline( ... ),
    Pipeline( ... ),
    ...
 );

 my $iterator = $u -> transform( $source1, $source2, ... );

=for readme continue

=begin readme

                         Data::Pipeline 0.01

            toolkit for building data processing pipelines

=head1 INSTALLATION

Installation follows standard Perl CPAN module installation steps:

 cpan> install Data::Pipeline

or, if not using the CPAN tool, then from within the unpacked distribution:

 % perl Makefile.PL
 % make
 % make test
 % make install


=for readme stop


=head1 DESCRIPTION

A Data::Pipeline pipeline is a linear sequence of actions taken on a stream of
data elements.  Data is pulled from an iterator as needed, with each action
and pipeline presenting itself to the next stage as an iterator.

Using an iterator interface allows actions and pipelines to be combined in
a wide range of configurations while preserving the lazy nature of
iterator evaluation when running the pipeline.

=head1 CONSTRUCTORS

Convenience methods are exported for all of the various classes based on the
name of the class.  These are the name of the class without any of the
preceeding package namespace.

For example, Pipeline refers to Data::Pipeline::Pipeline while
JSON refers to Data::Pipeline::Adapter::JSON.

=head2 Aggregators

Aggregators allow multiple actions to be strung together.

=head2 Adapters

Adapters provide the interface between pipelines and data.  Most adapters
can be used for both input and output, but a few, such as the SPARQL adapter,
are specialized for only input or output due to the nature of the data
source they are working with.

Documentation is available for each adapter under the 
Data::Pipeline::Adapter:: namespace.

=head2 Actions

Actions transform data in a stream.

Documentation is available for each action under the 
Data::Pipeline::Action:: namespace.

=head1 SEE ALSO

L<Data::Pipeline::Cookbook> for examples.

L<Data::Pipeline::Machine>,
L<Data::Pipeline::Aggregator>,
L<Data::Pipeline::Action>,
L<Data::Pipeline::Adapter>.

=for readme continue

=head1 BUGS

There are probably quite a few.  Certain machine features don't work 
as expected.  There has been no profiling or optimization, so the pipelines
will run much slower than they should.  The interface design should be good 
though.

Bugs may be reported on rt.cpan.org or by e-mailing bug-Data-Pipeline at
rt.cpan.org.

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>
 
=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
