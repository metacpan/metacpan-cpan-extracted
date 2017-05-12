package TestML::Compiler::Pegex::AST;

use TestML::Base;
extends 'Pegex::Tree';

use TestML::Runtime;

has points => [];
has function => sub { TestML::Function->new };

# sub final {
#     my ($self, $match, $top) = @_;
#     XXX $match;
# }
# __END__

sub got_code_section {
    my ($self, $code) = @_;
    $self->function->{statements} = $code;
}

sub got_assignment_statement {
    my ($self, $match) = @_;
    return TestML::Assignment->new(
        name => $match->[0],
        expr => $match->[1],
    );
}

sub got_code_statement {
    my ($self, $list) = @_;
    my ($expression, $assertion);
    my $points = $self->points;
    $self->{points} = [];

    for (@$list) {
        if (ref eq 'TestML::Assertion') {
            $assertion = $_;
        }
        else {
            #if (ref eq 'TestML::Expression') {
            $expression = $_;
        }
    }
    return TestML::Statement->new(
        $expression ? ( expr => $expression ) : (),
        $assertion ? ( assert => $assertion ) : (),
        @$points ? ( points => $points ) : (),
    );
}

sub got_code_expression {
    my ($self, $list) = @_;
    my $calls = [];
    push @$calls, shift @$list if @$list;
    $list = shift @$list || [];
    for (@$list) {
        my $call = $_->[0]; #->{call_call}[0][0];
        push @$calls, $call;
    }
    return $calls->[0] if @$calls == 1;
    return TestML::Expression->new(
        calls => $calls,
    );
}

sub got_string_object {
    my ($self, $string) = @_;
    return TestML::Str->new(
        value => $string,
    );
}

sub got_double_quoted_string {
    my ($self, $string) = @_;
    $string =~ s/\\n/\n/g;
    return $string;
}

sub got_number_object {
    my ($self, $number) = @_;
    return TestML::Num->new(
        value => $number + 0,
    );
}

sub got_point_object {
    my ($self, $point) = @_;
    $point =~ s/^\*// or die;
    push @{$self->points}, $point;
    return TestML::Point->new(
        name => $point,
    );
}

sub got_assertion_call {
    my ($self, $call) = @_;
    # XXX $call strangley becomes an array when $PERL_PEGEX_DEBUG is on.
    # Workaround for now, until I figure it out.
    $call = $call->[0] if ref $call eq 'ARRAY';
    my ($name, $expr);
    for (qw( eq has ok )) {
        if ($expr = $call->{"assertion_$_"}) {
            $name = uc $_;
            $expr =
                $expr->{"assertion_operator_$_"}[0] ||
                $expr->{"assertion_function_$_"}[0];
            last;
        }
    }
    return TestML::Assertion->new(
        name => $name,
        $expr ? (expr => $expr) : (),
    );
}

sub got_assertion_function_ok {
    my ($self, $ok) = @_;
    return {
        assertion_function_ok => [],
    }
}

sub got_function_start {
    my ($self) = @_;
    my $function = TestML::Function->new;
    $function->outer($self->function);
    $self->{function} = $function;
    return 1;
}

sub got_function_object {
    my ($self, $object) = @_;

    my $function = $self->function;
    $self->{function} = $function->outer;

    if (ref($object->[0]) and ref($object->[0][0])) {
        $function->{signature} = $object->[0][0];
    }
    $function->{statements} = $object->[-1];

    return $function;
}

sub got_call_name {
    my ($self, $name) = @_;
    return TestML::Call->new(name => $name);
}

sub got_call_object {
    my ($self, $object) = @_;
    my $call = $object->[0];
    my $args = $object->[1][-1];
    if ($args) {
        $args = [
            map {
                ($_->isa('TestML::Expression') and @{$_->calls} == 1 and
                (
                    $_->calls->[0]->isa('TestML::Point') ||
                    $_->calls->[0]->isa('TestML::Object')
                )) ? $_->calls->[0] : $_;
            } @$args
        ];
        $call->args($args)
    }
    return $call;
}

sub got_call_argument_list {
    my ($self, $list) = @_;
    return $list;
}

sub got_call_indicator {
    my ($self) = @_;
    return;
}

sub got_data_section {
    my ($self, $data) = @_;
    $self->function->data($data);
}

sub got_data_block {
    my ($self, $block) = @_;
    return TestML::Block->new(
        label => $block->[0][0][0],
        points => +{map %$_, @{$block->[1]}},
    );
}

sub got_block_point {
    my ($self, $point) = @_;
    return {
        $point->[0] => $point->[1],
    };
}

1;
