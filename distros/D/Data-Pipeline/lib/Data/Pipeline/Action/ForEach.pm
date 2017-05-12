package Data::Pipeline::Action::ForEach;

use Moose;
with 'Data::Pipeline::Action';

use namespace::autoclean;

use MooseX::Types::Moose qw( CodeRef );
use Data::Pipeline::Types qw( Iterator );

use Data::Pipeline::Machine;

has pipeline => (
    isa => 'Object',
    is => 'rw',
    required => 1
);

sub transform {
    my($self, $option_iterator) = @_;

    $option_iterator = to_Iterator($option_iterator);

    my $options = { %Data::Pipeline::Machine::current_options, %{$option_iterator -> next || {}} };

    #print STDERR "Foreach making the following options available: ", join(", ", map { "$_ => " . $options -> {$_} } keys %$options), "\n";
    my $iterator = to_Iterator(Data::Pipeline::Machine::with_options(sub{
    #print STDERR "Options available: ", join(", ", map { "$_ => " . $Data::Pipeline::Machine::current_options{$_} } keys %Data::Pipeline::Machine::current_options), "\n";
                       $self -> pipeline -> from( %$options )
                   }, $options));

    return Data::Pipeline::Iterator -> new(
        source => Data::Pipeline::Iterator::Source -> new(
            has_next => sub {
                my $i = !($option_iterator -> finished && $iterator -> finished);
                #print STDERR "ForEach finished? ", ($i ? 'no' : 'yes'), "\n";
                return $i;
            },
            get_next => sub {
                if($iterator -> finished) {
                    if($option_iterator -> finished) {
                        return;
                    }
                    $options = { %Data::Pipeline::Machine::current_options, %{$option_iterator -> next || {}} };
    #print STDERR "Foreach making the following options available for a new iterator: ", join(", ", map { "$_ => " . $options -> {$_} } keys %$options), "\n";
                    #print STDERR "iterator before: $iterator\n";
                    $iterator = to_Iterator(Data::Pipeline::Machine::with_options(sub{
    #print STDERR "Options available: ", join(", ", map { "$_ => " . $Data::Pipeline::Machine::current_options{$_} } keys %Data::Pipeline::Machine::current_options), "\n";
                                    $self -> pipeline -> from( %$options )
                                }, $options));
                    #print STDERR "iterator after: $iterator\n";
                }

                my $n = $iterator -> next;
                #print STDERR "it: @{[$iterator->finished]} option: @{[$option_iterator->finished]} n: $n\n";
                return $n;
            },
        )
    );
}

1;

__END__

