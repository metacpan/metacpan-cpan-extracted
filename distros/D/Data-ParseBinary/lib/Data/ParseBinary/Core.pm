use strict;
use warnings;

package Data::ParseBinary::BaseConstruct;
use Carp qw{confess};

our $DefaultPass;
my $HOOK_BEFORE_ACTION = "HOOK_BEFORE_ACTION";
my $HOOK_AFTER_ACTION = "HOOK_AFTER_ACTION";
my $OBJECT_STACK = "OBJECT_STACK";

sub create {
    my ($class, $name) = @_;
    return bless { Name => $name }, $class;
}

sub _get_name {
    my $self = shift;
    return $self->{Name};
}

sub parse {
    my ($self, $data) = @_;
    my $stream = Data::ParseBinary::Stream::Reader::CreateStreamReader($data);
    my $parser = Data::ParseBinary::Parser->new();
    if (defined $Data::ParseBinary::print_debug_info) {
        my $tab = 0;
        my $before = sub {
            my ($loc_parser, $construct) = @_;
            print " " x $tab, "Parsing ", $construct->_pretty_name(), "\n";
            $tab += 3;
        };
        my $after = sub {
            $tab -= 3;
        };
        $parser->{$HOOK_BEFORE_ACTION} = [$before];
        $parser->{$HOOK_AFTER_ACTION} = [$after];
    }
    $parser->push_stream($stream);
    my $results;
    eval {
        $results = $parser->_parse($self);
    };
    return $results unless $@;
    confess $parser->_informative_exception($@);
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    die "Bad Shmuel: sub __parse was not implemented for " . ref($self);
}

sub build {
    my ($self, $data, $source_stream) = @_;
    my $stream = Data::ParseBinary::Stream::Writer::CreateStreamWriter($source_stream);
    my $parser = Data::ParseBinary::Parser->new();
    if (defined $Data::ParseBinary::print_debug_info) {
        my $tab = 0;
        my $before = sub {
            my ($loc_parser, $construct, $data) = @_;
            print " " x $tab, "Building ", _pretty_name($construct), "\n";
            $tab += 3;
        };
        my $after = sub {
            $tab -= 3;
        };
        $parser->{$HOOK_BEFORE_ACTION} = [$before];
        $parser->{$HOOK_AFTER_ACTION} = [$after];
    }
    $parser->push_stream($stream);
    eval {
        $parser->_build($self, $data);
    };
    confess $parser->_informative_exception($@) if $@;
    return $stream->Flush();
}

sub _pretty_name {
    my ($self) = @_;    
    my $name = $self->_get_name();
    my $type = ref $self;
    $type =~ s/^Data::ParseBinary:://;
    $name ||= "<unnamed>";
    return "$type $name";
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Bad Shmuel: sub _build was not implemented for " . ref($self);
}

sub _size_of {
    my ($self, $context) = @_;
    die "This Construct (".ref($self).") does not know his own size";
}

package Data::ParseBinary::WrappingConstruct;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $subcon) = @_;
    my $self = $class->SUPER::create($subcon->_get_name());
    $self->{subcon} = $subcon;
    return $self;
}

sub subcon {
    my $self = shift;
    return $self->{subcon};
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    return $parser->_parse($self->{subcon});
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    return $parser->_build($self->{subcon}, $data);
}

sub _size_of {
    my ($self, $context) = @_;
    return $self->{subcon}->_size_of($context);
}

package Data::ParseBinary::Adapter;
our @ISA = qw{Data::ParseBinary::WrappingConstruct};

sub create {
    my ($class, $subcon, @params) = @_;
    my $self = $class->SUPER::create($subcon);
    $self->_init(@params);
    return $self;
}

sub _init {
    my ($self, @params) = @_;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $value = $self->SUPER::_parse($parser, $stream);
    my $tvalue = $self->_decode($value);
    return $tvalue;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $value = $self->_encode($data);
    $self->SUPER::_build($parser, $stream, $value);
}

sub _decode {
    my ($self, $value) = @_;
    die "An Adapter class should override the _decode sub";
    #my $tvalue = transform($value);
    #return $tvalue;
}

sub _encode {
    my ($self, $tvalue) = @_;
    die "An Adapter class should override the _decode sub";
    #my $value = transform($tvalue);
    #return $value;
}

package Data::ParseBinary::Validator;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _decode {
    my ($self, $value) = @_;
    die "Validator error at " . $self->_get_name() unless $self->_validate($value);
    return $value;
}

sub _encode {
    my ($self, $tvalue) = @_;
    die "Validator error at " . $self->_get_name() unless $self->_validate($tvalue);
    return $tvalue;
}

sub _validate {
    my ($self, $value) = @_;
    die "An Validator class should override the _validate sub";
}

package Data::ParseBinary::Parser;

my $EVALS = 'EVAL_MARKER';

sub new {
    my ($class) = @_;
    return bless {ctx=>[], obj=>undef, $EVALS=>[], $OBJECT_STACK=>[] }, $class;
}

sub obj {
    my $self = shift;
    return $self->{obj};
}

sub set_obj {
    my ($self, $new_obj) = @_;
    $self->{obj} = $new_obj;
}

sub ctx {
    my ($self, $level) = @_;
    $level ||= 0;
    die "Parser: ctx level $level does not exists" if $level >= scalar @{ $self->{ctx} };
    return $self->{ctx}->[$level];
}

sub push_ctx {
    my ($self, $new_ctx) = @_;
    unshift @{ $self->{ctx} }, $new_ctx;
}

sub pop_ctx {
    my $self = shift;
    return shift @{ $self->{ctx} };
}

sub push_stream {
    my ($self, $new_stream) = @_;
    unshift @{ $self->{streams} }, $new_stream;
}

sub pop_stream {
    my $self = shift;
    return shift @{ $self->{streams} };
}

sub stream {
    my $self = shift;
    return $self->{streams}->[0];
}

sub eval_enter {
    my ($self) = @_;
    my $streams_count = @{ $self->{streams} };
    my $objects_count = @{ $self->{$OBJECT_STACK} };
    my $eval_rec = { stream_count => $streams_count, objects_count => $objects_count };
    push @{ $self->{$EVALS} }, $eval_rec;
}

sub eval_leave {
    my ($self) = @_;
    my $eval_rec = pop @{ $self->{$EVALS} };
    my $streams_count = $eval_rec->{stream_count};
    if ($streams_count < @{ $self->{streams} }) {
        splice( @{ $self->{streams} }, 0, @{ $self->{streams} } - $streams_count, ());
    }
    my $objects_count = $eval_rec->{objects_count};
    if ($objects_count < @{ $self->{$OBJECT_STACK} }) {
        splice( @{ $self->{$OBJECT_STACK} }, $objects_count, @{ $self->{$OBJECT_STACK} } - $objects_count, ());
    }
}

sub _build {
    my ($self, $construct, $data) = @_;
    my $streams_count = @{ $self->{streams} };
    push @{ $self->{$OBJECT_STACK} }, $construct;
    if (exists $self->{$HOOK_BEFORE_ACTION}) {
        foreach my $hba ( @{ $self->{$HOOK_BEFORE_ACTION} } ) {
            $hba->($self, $construct, $data);
        }
    }

    $construct->_build($self, $self->{streams}->[0], $data);

    if (exists $self->{$HOOK_AFTER_ACTION}) {
        foreach my $hba ( @{ $self->{$HOOK_AFTER_ACTION} } ) {
            $hba->($self, $construct, undef);
        }
    }
    pop @{ $self->{$OBJECT_STACK} };
    if ($streams_count < @{ $self->{streams} }) {
        splice( @{ $self->{streams} }, 0, @{ $self->{streams} } - $streams_count, ());
    }
}

sub _parse {
    my ($self, $construct) = @_;
    my $streams_count = @{ $self->{streams} };
    push @{ $self->{$OBJECT_STACK} }, $construct;
    if (exists $self->{$HOOK_BEFORE_ACTION}) {
        foreach my $hba ( @{ $self->{$HOOK_BEFORE_ACTION} } ) {
            $hba->($self, $construct, undef);
        }
    }

    my $data = $construct->_parse($self, $self->{streams}->[0]);

    if (exists $self->{$HOOK_AFTER_ACTION}) {
        foreach my $hba ( @{ $self->{$HOOK_AFTER_ACTION} } ) {
            $hba->($self, $construct, $data);
        }
    }
    pop @{ $self->{$OBJECT_STACK} };
    if ($streams_count < @{ $self->{streams} }) {
        splice( @{ $self->{streams} }, 0, @{ $self->{streams} } - $streams_count, ());
    }
    return $data;
}

sub _informative_exception {
    my ($self, $msg) = @_;
    $msg =~ s/ at (.*)//;
    my $ex = "Got Exception $msg\n";
    $ex .= "Streams location:\n";
    my $ix = 1;
    foreach my $stream ( @{ $self->{streams} } ) {
        my $stream_ref = ref $stream;
        $stream_ref =~ s/^Data\:\:ParseBinary\:\:Stream\:\://;
        $ex .= "$ix: Stream " . $stream_ref . " in byte #" . $stream->tell() . "\n";
        $ix++;
    }
    $ex .= "Constructs Stack:\n";
    $ix = 1;
    foreach my $object (reverse @{ $self->{$OBJECT_STACK} }) {
        $ex .= "$ix: " . $object->_pretty_name() . "\n";
        $ix++;
    }
    return $ex;
}

sub runCodeRef {
    my ($self, $coderef) = @_;
    if (not ($coderef and ref($coderef) and UNIVERSAL::isa($coderef, "CODE"))) {
        return $coderef;
    }
    local $_ = $self;
    return $coderef->();
}

1;