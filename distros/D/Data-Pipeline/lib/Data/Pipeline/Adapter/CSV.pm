package Data::Pipeline::Adapter::CSV;

use Moose;
extends 'Data::Pipeline::Adapter';

use Data::Pipeline::Iterator::Source;

use IO::Handle;
use IO::File;
use Text::CSV;

has file => (
    is => 'rw',
    isa => 'Str|GlobRef',
    predicate => 'has_file',
);

has file_has_header => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);
     
has column_names => (
    is => 'ro',
    isa => 'ArrayRef',
    predicate => 'has_column_names',
    default => sub { [ ] }
);

has sep_char => (
    is => 'ro',
    isa => 'Str',
    default => ','
);

has quote_char => (
    is => 'ro',
    isa => 'Str',
    default => '"'
);

has allow_loose_quotes => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has escape_char => (
    is => 'ro',
    isa => 'Str',
    default => sub { $_[0] -> quote_char },
    lazy => 1
);

has eol => (
    is => 'ro',
    isa => 'Str',
    default => sub { $/ },
    lazy => 1
);

has allow_loose_escapes => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has allow_whitespace => (
    is => 'ro',
    isa => 'Bool',
    default => 0
);

has csv => (
    is => 'rw',
    isa => 'Text::CSV',
    lazy => 1,
    default => sub {
        my $self = shift;
        Text::CSV -> new({
           quote_char => $self -> quote_char,
           escape_char => $self -> escape_char,
           sep_char => $self -> sep_char,
           eol => $self -> eol,
           allow_loose_quotes => $self -> allow_loose_quotes,
           allow_loose_escapes => $self -> allow_loose_escapes,
           allow_whitespace => $self -> allow_whitespace
        });
    }
);

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

                if(blessed($self -> file)) {
                    $io = IO::Handle -> new;
                    $io -> fdopen( $self -> file, "r" );
                }
                elsif(ref($self -> file)) {
                    $io = IO::Handle -> new;
                    $io -> fdopen( fileno( $self -> file ), "r" );
                }
                else {
                    $io = IO::File -> new($self -> file, 'r')
                          or die "Unable to open " . $self -> file . " for reading: $!";
                }

                my $csv = $self -> csv;

                if( $self -> file_has_header ) {
                    my $names = $csv -> getline( $io );
                    $csv -> column_names( @{$names} );
                }
                if( $self -> has_column_names ) {
                    $csv -> column_names( @{$self -> column_names} );
                }

                if($self -> has_column_names || $self -> file_has_headers) {
                    $s -> get_next( sub { $csv -> getline_hr( $io ); } );
                }
                else {
                    $s -> get_next( sub { $csv -> getline( $io ); } );
                }

                $s -> has_next( sub { !$io -> eof } );

                return $s -> get_next -> () if $s -> has_next -> ();
                return undef;
            },

            has_next => sub { 1 } # for now - until we open the file
        );
    }
);

has '+preamble' => (
    lazy => 1,
    default => sub { 
        my($self) = shift;
        Carp::croak "Unable to serialize without column_names" unless $self -> has_column_names;

        return sub {
            return '' unless $self -> file_has_header;
            $self -> csv -> combine( @{$self -> column_names} );
            return $self -> csv -> string;
        };
    }
);

augment serialize => sub {
    my($self, $iterator) = @_;

    my $item = $iterator -> next;
    #print STDERR "CSV item: $item\n";
    $self -> csv -> combine( @{$item}{@{$self -> column_names}} );
    return $self -> csv -> string;
};

1;

__END__
