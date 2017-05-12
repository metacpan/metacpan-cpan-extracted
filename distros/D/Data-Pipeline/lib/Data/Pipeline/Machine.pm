package Data::Pipeline::Machine;

use Moose;
use Sub::Exporter;
use Sub::Name 'subname';
use Class::MOP ();
use Carp ();

use namespace::autoclean;
            
#use Data::Pipeline::Aggregator::Machine;
use Data::Pipeline::Machine::Surrogate;
use Data::Pipeline::Iterator::Options;

use MooseX::Types::Moose qw(HashRef);  

use Data::Pipeline::Types qw(Iterator IteratorSource Aggregator IteratorOutput);
                        
BEGIN {
    Class::MOP::load_class('Data::Pipeline::Aggregator::Machine');
    Class::MOP::load_class('Data::Pipeline::Aggregator::Pipeline');
}

has _m => (
    isa => 'Object',
    is => 'rw',
    lazy => 1,
    default => sub {
        _machine( $_[0] -> meta -> name )
    },
    handles => [qw( from transform )]
);

{
my %machines;
sub _machine {
    my($class) = @_;

    $machines{$class} ||= Data::Pipeline::Aggregator::Machine -> new( );
}
}

sub import {
    my($own_class) = @_;
        
    my $CALLER = caller();

    # see Moose.pm for explanation :-)
    strict->import;
    warnings->import;

    return if $CALLER eq 'main';

    my $machine = _machine($CALLER);

    my %exports;


#    $exports{connect} = sub {
#        my $class = $CALLER;
#        my $machine = _machine($class);
#        return subname "Data::Pipeline::Machine::connect" => sub {
#            my($from, $to);
#            while( ($from, $to) = splice @_, 2) {
#                $machine -> connect($from, $to);
#            }
#        };
#    };

    $exports{pipeline} = sub {
        subname "Data::Pipeline::Machine::pipeline" => sub {
            my $n;
            if(ref $_[0]) {
                $n = 'finally';
            }
            else {
                $n = shift;
            }
            if( @_ > 1 ) {
                $machine -> add_pipeline($n => [ @_ ]);
            }
            else {
                $machine -> add_pipeline($n =>  @_ );
            }
        };
    };

    # initial caps because this is used as if it were an action
    $exports{Option} = sub {
        my $class = $CALLER;
        my $machine = _machine($class);
        return subname "Data::Pipeline::Machine::Option" => sub {
            my($name, %options) = @_;
            return Data::Pipeline::Iterator -> new( coded_source => sub {
                #print STDERR caller(), "\n";
                #print STDERR "$machine -> Option( $name )\n";
                #print STDERR "has option\n" if Data::Pipeline::Machine::has_option($name);
                #print STDERR "options available: ", join(", ", keys %Data::Pipeline::Macine::current_options), "\n";
		#print STDERR "$name => ", Data::Pipeline::Machine::get_option($name), "\n";
                to_IteratorSource( Data::Pipeline::Machine::has_option($name) ?
                    Data::Pipeline::Machine::get_option($name) :
                    $options{default}
                );
            } )
            ;
        };
    };

    $exports{Pipeline} = sub {
        my $class = $CALLER;
        my $machine = _machine($class);
        return subname "Data::Pipeline::Machine::Pipeline" => sub {
            my($name, %options) = @_;

            return Data::Pipeline::Machine::Surrogate -> new(
                    machine => $machine,
                    named_pipeline => $name,
                    options => \%options
                );
        };
    };
    
    my $exporter = Sub::Exporter::build_exporter({
        exports => \%exports,
        groups => { default => [':all'] }
    });


    Moose::init_meta($CALLER, for_class => 'Data::Pipeline::Machine');

    goto &$exporter;
}

our %current_options = ( ); # should be thread-safe since it's not shared

sub get_option {
    my($o) = shift;
    my $cos = +{ %current_options };
    #print STDERR "returning sub for value for option $o\n";
    return sub {
        #print STDERR "returning: ", $cos->{$o}, "\n";
        $cos -> {$o};
    };
}

sub has_option {
    my($o) = shift;

    #print "current option keys: ", join(", ", keys %current_options), "\n";

    return exists( $current_options{$o} );
}

sub with_options(&$) {
    my($code, $options) = @_;

    local(%current_options);
    @current_options{keys %$options} = (values %$options);

    #print STDERR "current local options are set for: ", join(", ", keys %current_options), "\n";

    my $r = $code -> ();
    #print "r: $r\n";
    $r -> iterator -> source -> _prime() if is_Iterator($r);
    #print STDERR "current local options being reverted ... returning $r\n";
    $r;
}

1;

__END__

=head1 NAME

Data::Pipeline::Machine - easy-to-use machine building

=head1 SYNOPSIS

=head2 Machine Definition

 package Data::Pipeline::AdapterX::GoogleScholar;
 
 use Data::Pipeline::Machine;
 
 use Data::Pipeline qw( FetchPage Regex StringReplace UrlBuilder );
 
 pipeline(
     FetchPage(
         cut_start => '<p class=g>',
         cut_end => '</table>',
         split => '<p class=g>',
         url => UrlBuilder(
             base => 'http://scholar.google.com/scholar',
             query => {
                 q => Option( q => ( default => 'biology' ) ),
                 hl => 'en',
                 lr => '',
                 scoring => 'r',
                 as_ylo => Option( year => ( default => '2007' ) ),
                 num => 100,
                 safe => 'off'
             }
         ),
     ),
     Rename(
         copies => {
             content => 'description',
             content => 'title'
         },
         renames => {
             content => 'link'
         }
     ),
     Regex(
         rules => [
             title => sub { s/^<span class="w">.*?<a.+?>(.+?)/$1/gs },
             title => sub { s/(.+?)</a.+/$1/gs },
             title => sub { s/&hellip;//gs },
             link => sub { s{.+?http://(.+?)".+}{http://$1}gs },
             title => sub { s/<.+?>//gs },
             title => sub { s/&nbsp;//gs },
             description => sub { s{+?<span class="a">.+?- (.+?) -.+}{$1}gs },
             description => sub { s{<.+?>}{}gs }
         ]
     )
 ); # pipeline
 
=head2 Machine use

 use Data::Pipeline qw( Pipeline GoogleScholar CSV );

 my $pipe = Pipeline(
     GoogleScholar,
     CSV( column_names => [qw(title link)] )
 ); 

 $pipe -> from( q => 'physics' ) -> to( \*STDOUT );

=head1 DESCRIPTION

This package makes it easy to construct collections of pipelines that
together act as an action or an adapter.

=head1 CONSTRUCTORS

Several constructors are exported automatically by the package.

=head2 Option( $name => %options )

This constructs an object that will supply an optional argument for
the transformation.  A default value can be supplied in the options.

The value is pulled from the argument $name given when calling C<from> on the
machine.  In the example in the synopsis, the Option( q => ... ) in the
machine definition pulls its value from the C<q> value supplied when the
machine is used in a pipeline and the pipeline is instantiated.  Likewise,
the Option( year => ... ) supplies its default value because no year is
given.

=head2 pipeline( [ $name => ] pipeline definition )

This defines a pipeline with an optional name.

If the name is not given, it is assumed to be 'finally'.  Only one pipeline
should be defined without an explicit name.  The pipeline named 'finally' is
the default pipeline to start with when constructing an unnamed pipeline using C<from> or C<transform>.

=head2 Pipeline

Instead of defining a pipeline as the similar method would do if imported from
Data::Pipeline, this allows you to call another pipeline in the machine with
arguments.

=head1 AUTHOR

James Smith
        
=head1 LICENSE
       
Copyright (c) 2008  Texas A&M University.
    
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

