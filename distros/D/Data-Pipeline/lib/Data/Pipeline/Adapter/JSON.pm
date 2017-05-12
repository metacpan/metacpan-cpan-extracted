package Data::Pipeline::Adapter::JSON;

use Moose;
extends 'Data::Pipeline::Adapter';

use JSON;
use Data::Pipeline::Adapter::Array;

our $j = JSON -> new -> pretty -> utf8(1);

has '+preamble' => (
    default => sub { '{ items: [' }
);

has '+postamble' => (
    default => sub { '] }' }
);

has file => (
    is => 'rw',
    isa => 'Str|GlobRef',
    predicate => 'has_file',
);

augment serialize => sub {
    my($self, $iterator) = @_;

    $j -> encode( $iterator -> next ) . ( $iterator -> finished ? '' : ', ' );
};

has '+source' => (
    default => sub {
        my($self) = @_;
    
        # we delay doing anything with the file until we need it.
        # we don't want open file descriptors lying aroung that we
        # don't need.

        Carp::croak "Unable to create source adapter without a file" unless $self -> has_file;
    
        my $s;
        $s = Data::Pipeline::Iterator::Source -> new(
            get_next => sub {
                my $io;
    
                my $content;
                unless($content = $self -> content) {
                    if(blessed($self -> file)) {
                        $io = IO::Handle -> new;
                        $io -> fdopen( $self -> file );
                    }
                    elsif(ref($self -> file)) {
                        $io = IO::Handle -> new;
                        $io -> fdopen( fileno( $self -> file ) );
                    }
                    else {
                        $io = IO::File -> new($self -> file, 'r')
                              or die "Unable to open " . $self -> file . " for reading: $!";
                    }
                    local($/) = undef;
                    $content = <$io>;
                }

                my $data = $j -> decode($content);

#
# TODO: make $data->{items} parameterized so we can use something other
#       than Exhibit JSON files as input
#
                my $source = Data::Pipeline::Adapter::Array -> new(
                    array => $data -> {items}
                ) -> source;


                $s -> get_next( $s -> get_next );
                $s -> has_next( $s -> has_next );

                return $s -> get_next -> () if $s -> has_next -> ();
                return undef;
            },

            has_next => sub { 1 } # for now - until we open the file
        );
    }
);

1;

__END__
