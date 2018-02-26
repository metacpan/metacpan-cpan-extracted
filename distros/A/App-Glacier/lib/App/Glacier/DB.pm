package App::Glacier::DB;
use strict;
use warnings;
require Exporter;
use parent 'Exporter';
use JSON;
use Storable;
use Carp;
use App::Glacier::Timestamp;

use constant {
    ENCODE => 0,
    DECODE => 1
};

my %transcode = (
    'storable' => [
	# Encoder
	\&Storable::freeze,
	# Decoder
	\&Storable::thaw
    ],
    'json' => [
	# Encoder
	sub { JSON->new->convert_blessed(1)->encode(shift) },
	# Decoder
	sub { JSON->
		  new->
		  filter_json_object(sub { timestamp_deserialize $_[0] })->
		  decode(shift) }
    ]
);

sub new {
    my $class = shift;
    local %_ = @_;
    my $v;
    my $self = bless { }, $class;

    if ($v = delete $_{encoding}) {
	croak "unsupported encoding $v"
	    unless exists $transcode{$v};
	$self->{_encode} = $transcode{$v}[ENCODE];
	$self->{_decode} = $transcode{$v}[DECODE];
    }

    if (keys(%_)) {
	croak "unrecognized parameters: ".join(', ', keys(%_));
    }

    return $self;
}

sub decode {
    my ($self, $val) = @_;
    return $val unless defined($self->{_decode});
    return &{$self->{_decode}}($val);
}

sub encode {
    my ($self, $val) = @_;
    return $val unless defined($self->{_encode});
    return &{$self->{_encode}}($val);
}

1;

    
