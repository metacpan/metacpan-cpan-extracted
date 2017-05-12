package Data::Pipeline::Types;

use Class::MOP;

use MooseX::Types -declare => [qw(
    Iterator
    IteratorSource
    IteratorOutput
    Adapter
    AdapterClass
    Action
    ActionClass
    Aggregator
    AggregatorClass
    Machine
    MachineClass
)];

use MooseX::Types::Moose qw( ClassName Object ArrayRef Str CodeRef );

subtype Iterator,
    as Object,
    where { $_ -> isa('Data::Pipeline::Iterator') }
;

subtype IteratorSource,
    as Object,
    where { $_ -> isa('Data::Pipeline::Iterator::Source') }
;

subtype IteratorOutput,
    as Object,
    where { UNIVERSAL::isa($_, 'Data::Pipeline::Iterator::Output') }
;

subtype AdapterClass,
    as ClassName,
    where { UNIVERSAL::isa($_, "Data::Pipeline::Adapter") },
;

subtype Adapter,
    as Object,
    where { UNIVERSAL::isa($_, "Data::Pipeline::Adapter") },
;

subtype AggregatorClass,
    as ClassName,
    where { UNIVERSAL::isa($_, "Data::Pipeline::Aggregator") },
;

subtype Aggregator,
    as Object,
    where { UNIVERSAL::isa($_, "Data::Pipeline::Aggregator") || UNIVERSAL::isa($_, "Data::Pipeline::Machine::Surrogate") }
;

subtype ActionClass,
    as ClassName,
    where { $_ -> does('Data::Pipeline::Action') }
;

subtype Action,
    as Object,
    where { $_ -> does('Data::Pipeline::Action') }
;

subtype MachineClass,
    as ClassName,
    where { $_ -> isa('Data::Pipeline::Aggregator::Machine') }
;

subtype Machine,
    as Object,
    where { $_ -> isa('Data::Pipeline::Aggregator::Machine') }
;

coerce Adapter,
    from ArrayRef,
    via { Class::MOP::load_class("Data::Pipeline::Adapter::Array"); Data::Pipeline::Adapter::Array -> new( array => $_ ) }
;

coerce Adapter,
    from Str,
    via { Class::MOP::load_class("Data::Pipeline::Adapter::Array"); Data::Pipeline::Adapter::Array -> new( array => [ $_ ] ) }
;

coerce IteratorSource,
    from Adapter,
    via { $_ -> source }
;

coerce IteratorSource,
    from Str,
    via { Class::MOP::load_class("Data::Pipeline::Adapter::Array"); Data::Pipeline::Adapter::Array -> new( array => [ $_ ] ) -> source }
;

coerce IteratorSource,
    from Iterator,
    via { my $it = $_; Data::Pipeline::Iterator::Source -> new( has_next => sub { !$it -> finished }, get_next => sub { $it -> next } ); }
;

coerce IteratorSource,
    from ArrayRef,
    via { Class::MOP::load_class("Data::Pipeline::Adapter::Array"); Data::Pipeline::Adapter::Array -> new( array => $_ ) -> source }
;

coerce IteratorSource,
    from IteratorOutput,
    via { $_ -> iterator -> source }
;

coerce IteratorSource,
    from Aggregator,
    via { to_Iterator( $_ ) -> source  }
;

coerce Iterator,
    from CodeRef,
    via { warn "CodeRef->Iterator\n";  to_Iterator( to_IteratorSource( $_ -> () ) ) }
;

coerce Iterator,
    from IteratorSource,
    via { Class::MOP::load_class("Data::Pipeline::Iterator"); Data::Pipeline::Iterator -> new( source => $_ ) }
;

coerce Iterator,
    from Str,
    via { to_Iterator( to_Adapter( $_ ) ) }
;

coerce Iterator,
    from Adapter,
    via { Class::MOP::load_class("Data::Pipeline::Iterator"); Data::Pipeline::Iterator -> new( source => $_ -> source ) }
;

coerce Iterator,
    from ArrayRef,
    via { to_Iterator( to_IteratorSource( $_ ) ); }
;

coerce Iterator,
    from Aggregator,
    via { to_Iterator( $_ -> from( %{$Data::Pipeline::Machine::current_options || {}} ) ) }
;


coerce IteratorSource,
    from CodeRef,
    via { to_IteratorSource( $_ -> ( ) ) }
;

coerce Iterator,
    from IteratorOutput,
    via { to_Iterator( $_ -> iterator ) }
;

coerce Adapter,
    from Iterator,
    via { Data::Pipeline::Adapter -> new( source => to_IteratorSource($_) ) }
;

coerce Adapter,
    from IteratorOutput,
    via { Data::Pipeline::Adapter -> new( source => to_IteratorSource( to_Iterator( $_ ) ) ) }
;

coerce Aggregator,
    from CodeRef,
    via { $_ -> (); }
;

1;

__END__
