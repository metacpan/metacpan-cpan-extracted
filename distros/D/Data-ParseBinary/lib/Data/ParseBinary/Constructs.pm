package Data::ParseBinary::RoughUnion;
use strict;
use warnings;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, @subcons) = @_;
    my $self = $class->SUPER::create($name);
    $self->{subcons} = \@subcons;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $hash = {};
    $parser->push_ctx($hash);
    my $w_stream = Data::ParseBinary::Stream::StringBufferReader->new($stream);
    $parser->push_stream($w_stream);
    my $pos = $w_stream->tell();
    foreach my $sub (@{ $self->{subcons} }) {
        my $name = $sub->_get_name();
        my $value = $parser->_parse($sub);
        $w_stream->seek($pos);
        next unless defined $name;
        $hash->{$name} = $value;
    }
    $w_stream->ReadBytes($self->{size});
    $parser->pop_ctx();
    return $hash;
}

sub _union_build {
    my ($self, $parser, $string_stream, $data) = @_;
    my $field_found = 0;
    my $pos = $string_stream->tell();
    foreach my $sub (@{ $self->{subcons} }) {
        my $name = $sub->_get_name();
        next unless exists $data->{$name} and defined $data->{$name};
        $parser->_build($sub, $data->{$name});
        $string_stream->seek($pos);
        $field_found = 1;
    }
    return $field_found;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $s_stream = Data::ParseBinary::Stream::StringWriter->new();
    $parser->push_stream($s_stream);
    my $field_found = $self->_union_build($parser, $s_stream, $data);
    die "Union build error: not found any data" unless $field_found;
    $parser->pop_stream();
    $stream->WriteBytes($s_stream->Flush());
}

package Data::ParseBinary::Union;
our @ISA = qw{Data::ParseBinary::RoughUnion};

sub create {
    my ($class, $name, @subcons) = @_;
    my $self = $class->SUPER::create($name, @subcons);
    my $size = $subcons[0]->_size_of();
    foreach my $sub (@subcons) {
        my $temp_size = $sub->_size_of();
        $size = $temp_size if $temp_size > $size;
    }
    $self->{size} = $size;
    return $self;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $s_stream = Data::ParseBinary::Stream::StringWriter->new();
    $parser->push_stream($s_stream);
    my $field_found = $self->_union_build($parser, $s_stream, $data);
    die "Union build error: not found any data" unless $field_found;
    $parser->pop_stream();
    my $string = $s_stream->Flush();
    if ($self->{size} > length($string)) {
        $string .= "\0" x ( $self->{size} - length($string) );
    }
    $stream->WriteBytes($string);
}

sub _size_of {
    my ($self, $context) = @_;
    return $self->{size};
}

package Data::ParseBinary::Select;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, @subconstructs) = @_;
    die "Empty Struct is illigal" unless @subconstructs;
    my $self = $class->SUPER::create(undef);
    $self->{subs} = \@subconstructs;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $orig_pos = $stream->tell();
    my $upper_hash = $parser->ctx();
    foreach my $sub (@{ $self->{subs} }) {
        $stream->seek($orig_pos);
        my $hash = {};
        $parser->push_ctx($hash);
        $parser->eval_enter();
        my $name = $sub->_get_name();
        my $value;
        eval {
            $value = $parser->_parse($sub);
        };
        $parser->eval_leave();
        $parser->pop_ctx();
        next if $@;
        $hash->{$name} = $value if defined $name;
        while (my ($key, $val) = each %$hash) {
            $upper_hash->{$key} = $val;
        }
        return;
    }
    die "Problem with Select: no matching option";
}


sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $upper_hash = $parser->ctx();
    foreach my $sub (@{ $self->{subs} }) {
        my $hash = { %$upper_hash };
        my $inter_stream = Data::ParseBinary::Stream::StringWriter->new();
        $parser->push_ctx($hash);
        $parser->push_stream($inter_stream);
        $parser->eval_enter();
        my $name = $sub->_get_name();
        eval {
            $parser->_build($sub, defined $name? $hash->{$name} : undef);
        };
        $parser->eval_leave();
        $parser->pop_stream();
        $parser->pop_ctx();
        next if $@;
        %$upper_hash = %$hash;
        $stream->WriteBytes($inter_stream->Flush());
        return;
    }
    die "Problem with Select: no matching option";
}

package Data::ParseBinary::Restream;
our @ISA = qw{Data::ParseBinary::WrappingConstruct};

sub create {
    my ($class, $subcon, $stream_name) = @_;
    my $self = $class->SUPER::create($subcon);
    $self->{stream_name} = $stream_name;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $sub_stream = Data::ParseBinary::Stream::Reader::CreateStreamReader($self->{stream_name} => $stream);
    $parser->push_stream($sub_stream);
    return $parser->_parse($self->{subcon});
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $sub_stream = Data::ParseBinary::Stream::Writer::CreateStreamWriter($self->{stream_name} => Wrap => $stream);
    $parser->push_stream($sub_stream);
    $parser->_build($self->{subcon}, $data);
}

package Data::ParseBinary::ConditionalRestream;
our @ISA = qw{Data::ParseBinary::Restream};

sub create {
    my ($class, $subcon, $stream_name, $condition) = @_;
    my $self = $class->SUPER::create($subcon, $stream_name);
    $self->{condition} = $condition;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    if ($parser->runCodeRef($self->{condition})) {
        return $self->SUPER::_parse($parser, $stream);
    } else {
        return $parser->_parse($self->{subcon});
    }
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    if ($parser->runCodeRef($self->{condition})) {
        $self->SUPER::_build($parser, $stream, $data);
    } else {
        $parser->_build($self->{subcon}, $data);
    }
}

package Data::ParseBinary::TunnelAdapter;
our @ISA = qw{Data::ParseBinary::WrappingConstruct};

sub create {
    my ($class, $subcon, $inner_subcon) = @_;
    my $self = $class->SUPER::create($subcon);
    $self->{inner_subcon} = $inner_subcon;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $inter = $parser->_parse($self->{subcon});
    my $inter_stream = Data::ParseBinary::StringStreamReader->new($inter);
    return $parser->_parse($self->{inner_subcon});
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $inter_stream = Data::ParseBinary::Stream::StringWriter->new();
    $parser->push_stream($inter_stream);
    $parser->_build($self->{inner_subcon}, $data);
    $parser->pop_stream();
    $parser->_build($self->{subcon}, $inter_stream->Flush());
}

package Data::ParseBinary::Peek;
our @ISA = qw{Data::ParseBinary::WrappingConstruct};

sub create {
    my ($class, $subcon, $distance) = @_;
    my $self = $class->SUPER::create($subcon);
    $self->{distance} = $distance || 0;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $pos = $stream->tell();
    my $distance = $parser->runCodeRef($self->{distance});
    $stream->seek($pos + $distance);
    my $res = $parser->_parse($self->{subcon});
    $stream->seek($pos);
    return $res;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    # does nothing
}

sub _size_of {
    my ($self, $context) = @_;
    # the construct size is 0
    return 0;
}

package Data::ParseBinary::Value;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $func) = @_;
    my $self = $class->SUPER::create($name);
    $self->{func} = $func;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    return $parser->runCodeRef($self->{func});
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    $parser->ctx->{$self->_get_name()} = $parser->runCodeRef($self->{func});
}

sub _size_of {
    my ($self, $context) = @_;
    # the construct size is 0
    return 0;
}

package Data::ParseBinary::LazyBound;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $boundfunc) = @_;
    my $self = $class->SUPER::create($name);
    $self->{bound} = undef;
    $self->{boundfunc} = $boundfunc;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    return $parser->_parse($parser->runCodeRef($self->{boundfunc}));
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    return $parser->_build($parser->runCodeRef($self->{boundfunc}), $data);
}

package Data::ParseBinary::Terminator;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub _parse {
    my ($self, $parser, $stream) = @_;
    eval { $stream->ReadBytes(1) };
    if (not $@) {
        die "Terminator expected end of stream";
    }
    return;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    return;
}

sub _size_of {
    my ($self, $context) = @_;
    # the construct size is 0
    return 0;
}

package Data::ParseBinary::NullConstruct;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub _parse {
    my ($self, $parser, $stream) = @_;
    return;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    return;
}

sub _size_of {
    my ($self, $context) = @_;
    # the construct size is 0
    return 0;
}

package Data::ParseBinary::Pointer;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $posfunc, $subcon) = @_;
    my $self = $class->SUPER::create($subcon->_get_name());
    $self->{subcon} = $subcon;
    $self->{posfunc} = $posfunc;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $newpos = $parser->runCodeRef($self->{posfunc});
    my $origpos = $stream->tell();
    $stream->seek($newpos);
    my $value = $parser->_parse($self->{subcon});
    $stream->seek($origpos);
    return $value;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $newpos = $parser->runCodeRef($self->{posfunc});
    my $origpos = $stream->tell();
    $stream->seek($newpos);
    $parser->_build($self->{subcon}, $data);
    $stream->seek($origpos);
}

sub _size_of {
    my ($self, $context) = @_;
    # the construct size is 0
    return 0;
}

package Data::ParseBinary::Switch;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $keyfunc, $cases, %params) = @_;
    die "Switch expects code ref as keyfunc"
        unless $keyfunc and ref($keyfunc) and UNIVERSAL::isa($keyfunc, "CODE");
    die "Switch expects hash-ref as a list of cases"
        unless $cases and ref($cases) and UNIVERSAL::isa($cases, "HASH");
    my $self = $class->SUPER::create($name);
    $self->{keyfunc} = $keyfunc;
    $self->{cases} = $cases;
    $self->{default} = $params{default};
    $self->{default} = Data::ParseBinary::NullConstruct->create() if $self->{default} and $self->{default} == $Data::ParseBinary::BaseConstruct::DefaultPass; 
    return $self;
}

sub _getCont {
    my ($self, $parser) = @_;
    my $key = $parser->runCodeRef($self->{keyfunc});
    if (exists $self->{cases}->{$key}) {
        return $self->{cases}->{$key};
    }
    if (defined $self->{default}) {
        return $self->{default};
    }
    die "Error at Switch: got un-declared value, and no default was defined";
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $value = $self->_getCont($parser);
    return unless defined $value;
    return $parser->_parse($value);
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $value = $self->_getCont($parser);
    return unless defined $value;
    return $parser->_build($value, $data);
}

sub _size_of {
    my ($self, $context) = @_;
    my $size = -1;
    foreach my $subcon (values %{ $self->{cases} }) {
        my $sub_size = $subcon->_size_of($context);
        if ($size == -1) {
            $size = $sub_size;
        } else {
            die "This Switch have dynamic size" unless $size == $sub_size;
        }
    }
    if ($self->{default}) {
        my $sub_size = $self->{default}->_size_of($context);
        die "This Switch have dynamic size" unless $size == $sub_size;
    }
    return $size;
}

package Data::ParseBinary::StaticField;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $len) = @_;
    my $self = $class->SUPER::create($name);
    $self->{len} = $len;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $data = $stream->ReadBytes($self->{len});
    return $data;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Invalid Value" unless defined $data and not ref $data;
    $stream->WriteBytes($data);
}

sub _size_of {
    my ($self, $context) = @_;
    return $self->{len};
}

package Data::ParseBinary::MetaField;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $coderef) = @_;
    die "MetaField $name: must have a coderef" unless ref($coderef) and UNIVERSAL::isa($coderef, "CODE");
    my $self = $class->SUPER::create($name);
    $self->{code} = $coderef;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $len = $parser->runCodeRef($self->{code});
    my $data = $stream->ReadBytes($len);
    return $data;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Invalid Value" unless defined $data and not ref $data;
    $stream->WriteBytes($data);
}

package Data::ParseBinary::BitField;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $length) = @_;
    my $self = $class->SUPER::create($name);
    $self->{length} = $length;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $data = $stream->ReadBits($self->{length});
    my $pad_len = 32 - $self->{length};
    my $parsed = unpack "N", pack "B32", ('0' x $pad_len) . $data;
    return $parsed;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $binaryString = unpack("B32", pack "N", $data);
    my $string = substr($binaryString, -$self->{length}, $self->{length});
    $stream->WriteBits($string);
}

package Data::ParseBinary::ReversedBitField;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $length) = @_;
    my $self = $class->SUPER::create($name);
    $self->{length} = $length;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $data = $stream->ReadBits($self->{length});
    $data = join '', reverse split '', $data;
    my $pad_len = 32 - $self->{length};
    my $parsed = unpack "N", pack "B32", ('0' x $pad_len) . $data;
    return $parsed;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $binaryString = unpack("B32", pack "N", $data);
    my $string = substr($binaryString, -$self->{length}, $self->{length});
    $string = join '', reverse split '', $string;
    $stream->WriteBits($string);
}

package Data::ParseBinary::Padding;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $count) = @_;
    my $self = $class->SUPER::create(undef);
    $self->{count_code} = $count;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    if ($stream->isBitStream()) {
        $stream->ReadBits($parser->runCodeRef($self->{count_code}));
    } else {
        $stream->ReadBytes($parser->runCodeRef($self->{count_code}));
    }
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    if ($stream->isBitStream()) {
        $stream->WriteBits("0" x $parser->runCodeRef($self->{count_code}));
    } else {
        $stream->WriteBytes("\0" x $parser->runCodeRef($self->{count_code}));
    }
}

package Data::ParseBinary::RepeatUntil;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $coderef, $sub) = @_;
    die "Empty MetaArray is illigal" unless $sub and $coderef;
    die "MetaArray must have a sub-construct" unless ref $sub and UNIVERSAL::isa($sub, "Data::ParseBinary::BaseConstruct");
    die "MetaArray must have a length code ref" unless ref $coderef and UNIVERSAL::isa($coderef, "CODE");
    my $name =$sub->_get_name();
    my $self = $class->SUPER::create($name);
    $self->{sub} = $sub;
    $self->{len_code} = $coderef;
    return $self;
}

sub _shouldStop {
    my ($self, $parser, $value) = @_;
    $parser->set_obj($value);
    my $ret = $parser->runCodeRef($self->{len_code});
    $parser->set_obj(undef);
    return $ret;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $list = [];
    $parser->push_ctx($list);
    while (1) {
        my $value = $parser->_parse($self->{sub});
        push @$list, $value;
        last if $self->_shouldStop($parser, $value);
    }
    $parser->pop_ctx();
    return $list;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Invalid Sequence Value" unless defined $data and ref $data and UNIVERSAL::isa($data, "ARRAY");
    
    $parser->push_ctx($data);
    for my $item (@$data) {
        $parser->_build($self->{sub}, $item);
        last if $self->_shouldStop($parser, $item);
    }
    $parser->pop_ctx();
}

package Data::ParseBinary::MetaArray;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $coderef, $sub) = @_;
    die "Empty MetaArray is illigal" unless $sub and $coderef;
    die "MetaArray must have a sub-construct" unless ref $sub and UNIVERSAL::isa($sub, "Data::ParseBinary::BaseConstruct");
    die "MetaArray must have a length code ref" unless ref $coderef and UNIVERSAL::isa($coderef, "CODE");
    my $name =$sub->_get_name();
    my $self = $class->SUPER::create($name);
    $self->{sub} = $sub;
    $self->{len_code} = $coderef;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $len = $parser->runCodeRef($self->{len_code});
    my $list = [];
    $parser->push_ctx($list);
    for my $ix (1..$len) {
        my $value = $parser->_parse($self->{sub});
        push @$list, $value;
    }
    $parser->pop_ctx();
    return $list;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Invalid Sequence Value" unless defined $data and ref $data and UNIVERSAL::isa($data, "ARRAY");
    my $len = $parser->runCodeRef($self->{len_code});
    
    die "Invalid Sequence Length (length param is $len, actual input is ".scalar(@$data).")" if @$data != $len;
    $parser->push_ctx($data);
    for my $item (@$data) {
        $parser->_build($self->{sub}, $item);
    }
    $parser->pop_ctx();
}

package Data::ParseBinary::Range;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $min, $max, $sub) = @_;
    die "Empty Struct is illigal" unless $sub;
    die "Repeater must have a sub-construct" unless ref $sub and UNIVERSAL::isa($sub, "Data::ParseBinary::BaseConstruct");
    my $name =$sub->_get_name();
    my $self = $class->SUPER::create($name);
    $self->{sub} = $sub;
    $self->{max} = $max;
    $self->{min} = $min;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $list = [];
    $parser->push_ctx($list);
    my $max = $self->{max};
    if (defined $max) {
        for my $ix (1..$max) {
            my $value;
            eval {
                $value = $parser->_parse($self->{sub});
            };
            if ($@) {
                die $@ if $ix <= $self->{min};
                last;
            }
            push @$list, $value;
        }
    } else {
        my $ix = 0;
        while (1) {
            $ix++;
            my $value;
            eval {
                $value = $parser->_parse($self->{sub});
            };
            if ($@) {
                die $@ if $ix <= $self->{min};
                last;
            }
            push @$list, $value;
        }
    }
    $parser->pop_ctx();
    return $list;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Invalid Sequence Value" unless defined $data and ref $data and UNIVERSAL::isa($data, "ARRAY");
    die "Invalid Sequence Length (min)" if @$data < $self->{min};
    die "Invalid Sequence Length (max)" if defined $self->{max} and @$data > $self->{max};
    $parser->push_ctx($data);
    for my $item (@$data) {
        $parser->_build($self->{sub}, $item);
    }
    $parser->pop_ctx();
}

package Data::ParseBinary::Sequence;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, @subconstructs) = @_;
    die "Empty Struct is illigal" unless @subconstructs;
    my $self = $class->SUPER::create($name);
    $self->{subs} = \@subconstructs;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $list = [];
    $parser->push_ctx($list);
    foreach my $sub (@{ $self->{subs} }) {
        my $name = $sub->_get_name();
        my $value = $parser->_parse($sub);
        next unless defined $name;
        push @$list, $value;
    }
    $parser->pop_ctx();
    return $list;
}


sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $subs_count = @{ $self->{subs} };
    die "Invalid Sequence Value" unless defined $data and ref $data and UNIVERSAL::isa($data, "ARRAY");
    die "Invalid Sequence Length" if @$data > $subs_count;
    $parser->push_ctx($data);
    for my $ix (0..$#$data) {
        my $sub = $self->{subs}->[$ix];
        my $name = $sub->_get_name();
        if (defined $name) {
            die "Invalid Sequence Length" if $ix >= $subs_count;
            $parser->_build($sub, $data->[$ix]);
        } else {
            $parser->_build($sub, undef);
            redo;
        }
    }
    $parser->pop_ctx();
}

sub _size_of {
    my ($self, $context) = @_;
    my $size = 0;
    foreach my $sub (@{ $self->{subs} }) {
        $size += $sub->_size_of($context);
    }
    return $size;
}

package Data::ParseBinary::Struct;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, @subconstructs) = @_;
    die "Empty Struct is illigal" unless @subconstructs;
    my $self = $class->SUPER::create($name);
    $self->{subs} = \@subconstructs;
    return $self;
}


sub _parse {
    my ($self, $parser, $stream) = @_;
    my $hash = {};
    $parser->push_ctx($hash);
    foreach my $sub (@{ $self->{subs} }) {
        my $name = $sub->_get_name();
        my $value = $parser->_parse($sub);
        next unless defined $name;
        $hash->{$name} = $value;
    }
    $parser->pop_ctx();
    return $hash;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Invalid Struct Value" unless defined $data and ref $data and UNIVERSAL::isa($data, "HASH");
    $parser->push_ctx($data);
    foreach my $sub (@{ $self->{subs} }) {
        my $name = $sub->_get_name();
        $parser->_build($sub, defined $name? $data->{$name} : undef);
    }
    $parser->pop_ctx();
}

sub _size_of {
    my ($self, $context) = @_;
    my $size = 0;
    foreach my $sub (@{ $self->{subs} }) {
        $size += $sub->_size_of($context);
    }
    return $size;
}

package Data::ParseBinary::Primitive;
our @ISA = qw{Data::ParseBinary::BaseConstruct};

sub create {
    my ($class, $name, $sizeof, $pack_param) = @_;
    my $self = $class->SUPER::create($name);
    $self->{sizeof} = $sizeof;
    $self->{pack_param} = $pack_param;
    return $self;
}

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $data = $stream->ReadBytes($self->{sizeof});
    my $number = unpack $self->{pack_param}, $data;
    return $number;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    die "Invalid Primitive Value" unless defined $data;
    # FIXME and not ref $data;
    my $string = pack $self->{pack_param}, $data;
    $stream->WriteBytes($string);
}

sub _size_of {
    my ($self, $context) = @_;
    return $self->{sizeof};
}

package Data::ParseBinary::ReveresedPrimitive;
our @ISA = qw{Data::ParseBinary::Primitive};

sub _parse {
    my ($self, $parser, $stream) = @_;
    my $data = $stream->ReadBytes($self->{sizeof});
    my $r_data = join '', reverse split '', $data;
    my $number = unpack $self->{pack_param}, $r_data;
    return $number;
}

sub _build {
    my ($self, $parser, $stream, $data) = @_;
    my $string = pack $self->{pack_param}, $data;
    my $r_string = join '', reverse split '', $string;
    $stream->WriteBytes($r_string);
}

sub _size_of {
    my ($self, $context) = @_;
    return $self->{sizeof};
}

1;