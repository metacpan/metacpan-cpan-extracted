package Data::Focus::LensTester;
use strict;
use warnings;
use Carp;
use Test::More;
use Data::Focus qw(focus);
use Scalar::Util qw(refaddr);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        map { ($_ => $args{$_}) } qw(test_whole test_part parts)
    }, $class;
    foreach my $key (qw(test_whole test_part)) {
        croak "$key must be a code-ref" if ref($self->{$key}) ne "CODE";
    }
    croak "parts must be an array-ref" if ref($self->{parts}) ne "ARRAY";
    return $self;
}

sub parts {
    return @{$_[0]->{parts}};
}

sub test_lens_laws {
    my ($self, %args) = @_;
    my @args = _get_args(%args);
    my $exp_focal_points = $args[2];
    $self->_test_focal_points(@args);
    $self->_test_set_set(@args);
    if($exp_focal_points == 0) {
        $self->_test_get_set(@args);
    }elsif($exp_focal_points == 1) {
        $self->_test_get_set(@args);
        $self->_test_set_get(@args);
    }else {
        $self->_test_set_get(@args);
    }
}

sub _get_args {
    my (%args) = @_;
    my $lens = $args{lens};
    croak "lens must be Data::Focus::Lens object" if !eval { $lens->isa("Data::Focus::Lens") };
    my $target = $args{target};
    croak "target must be a code-ref" if ref($target) ne "CODE";
    my $exp_focal_points = $args{exp_focal_points};
    croak "exp_focal_points must be Int" if !defined($exp_focal_points) || $exp_focal_points !~ /^\d+$/;
    return ($target, $lens, $exp_focal_points);
}

sub _test_focal_points {
    my ($self, $target, $lens, $exp_focal_points) = @_;
    subtest "focal points" => sub {
        my @ret = focus($target->())->list($lens);
        is scalar(@ret), $exp_focal_points, "list() returns $exp_focal_points focal points";
    };
}

sub _test_set_set {
    my ($self, $target, $lens, $exp_focal_points) = @_;
    subtest "set-set law" => sub {
        foreach my $i1 (0 .. $#{$self->{parts}}) {
            foreach my $i2 (0 .. $#{$self->{parts}}) {
                next if $i1 == $i2;
                my ($part1, $part2) = @{$self->{parts}}[$i1, $i2];
                my $left_target = $target->();
                my $right_target = $target->();
                my $left_result = focus( focus($left_target)->set($lens, $part1) )->set($lens, $part2);
                my $right_result = focus($right_target)->set($lens, $part2);
                $self->{test_whole}->($left_result, $right_result);
            }
        }
    };
}

sub _test_set_get {
    my ($self, $target, $lens, $exp_focal_points) = @_;
    subtest "set-get law" => sub {
        foreach my $part (@{$self->{parts}}) {
            my $left_target = $target->();
            my $left_set = focus($left_target)->set($lens, $part);
            my @left_parts = focus($left_set)->list($lens);
            $self->{test_part}->($_, $part) foreach @left_parts;
        }
    };
}

sub _test_get_set {
    my ($self, $target, $lens, $exp_focal_points) = @_;
    subtest "get-set law" => sub {
        foreach my $part (@{$self->{parts}}) {
            my $left_target = $target->();
            my $left_result = focus($left_target)->set($lens, focus($left_target)->get($lens));
            $self->{test_whole}->($left_result, $target->());
        }
    };
}

foreach my $method_base (qw(set_set set_get get_set)) {
    no strict "refs";
    my $method_impl = "_test_$method_base";
    *{"test_$method_base"} = sub {
        my ($self, %args) = @_;
        my @args = _get_args(%args);
        $self->_test_focal_points(@args);
        $self->$method_impl(@args);
    };
}

1;
__END__

=pod

=head1 NAME

Data::Focus::LensTester - tester for Lens implementations

=head1 SYNOPSIS

    use Test::More;
    use Data::Focus::LensTester;
    use Data::Focus::Lens::HashArray::Index;
    
    my $tester = Data::Focus::LensTester->new(
        test_whole => sub { is_deeply($_[0], $_[1]) },
        test_part  => sub { is($_[0], $_[1]) },
        parts => [undef, 1, "str"]
    );
    
    my $create_target = sub {
        +{ foo => "bar" }
    };
    
    my $lens = Data::Focus::Lens::HashArray::Index->new(
        index => "foo"
    );
    
    $tester->test_lens_laws(
        lens => $lens, target => $create_target,
        exp_focal_points => 1
    );

=head1 DESCRIPTION

L<Data::Focus::LensTester> tests some common properties for lenses. They are called the "lens laws".

Concepturally, the lens laws are described as follows.

=over

=item set-get law

    focus( focus($target)->set($lens, $part) )->get($lens) == $part

You get the exact C<$part> you just set.

=item get-set law

    focus($target)->set( $lens, focus($target)->get($lens) ) == $target

If you put back the part you just got out of the C<$target>, it changes nothing.

=item set-set law

    focus( focus($target)->set($lens, $part1) )->set($lens, $part2) == focus($target)->set($lens, $part2)

The C<$lens>'s focal point is consistent, so C<$part1> is overwritten by C<$part2>.

=back

L<Data::Focus::LensTester> tests these laws with given set of C<$part>s.

=head2 Tests and Focal Points

Depending on how many focal points the lens creates on the target, C<test_lens_laws()> method tests the following laws.

=over

=item 0 focal point

It tests "get-set" and "set-set" laws. "set-get" law cannot be met.

=item 1 focal point

It tests all three laws.

=item more than one focal points

It tests "set-get" and "set-set" laws.

In "set-get" law, the C<set()> method should set all focal points to the same value.

=back

=head2 Exception

Not all lenses meet all the lens laws.

Consider the following code for example.

    use strict;
    use warnings;
    use Data::Dumper;
    
    my $undef;
    $undef->[0] = $undef->[0]; ## get and set
    print Dumper $undef;
    
    ## => $VAR1 = [
    ## =>           undef
    ## =>         ];

If we think of C<< ->[0] >> as a lens, the above example clearly breaks the "get-set" law because of autovivification.

If you expect that kind of behavior, do not use C<test_lens_laws()> method.
Use C<test_set_get()> etc instead.

=head1 CLASS METHODS

=head2 $tester = Data::Focus::LensTester->new(%args)

The constructor. Fields in C<%args> are:

=over

=item C<test_whole> => CODE (mandatory)

A code-ref that tests if two "whole" data are the same.
A whole data is a data whose level of complexity is the same as the target data.

This code-ref is called like:

    $test_whole->($whole1, $whole2)

C<$test_whole> must test equality between C<$whole1> and C<$whole2> in a L<Test::More> way.

=item C<test_part> => CODE (mandatory)

A code-ref that tests if two "part" data are the same.
A part data is a data that can be included in a whole data.

This code-ref is called like:

    $test_part->($part1, $part2)

C<$test_part> must test equality between C<$part1> and C<$part2> in a L<Test::More> way.

=item C<parts> => ARRAYREF_OF_PARTS (mandatory)

List of "part" data used for testing. At least two parts are necessary.

=back

=head1 OBJECT METHODS

=head2 $tester->test_lens_laws(%args)

Test a L<Data::Focus::Lens> object to see if it follows the lens law. See L</Tests and Focal Points>.

Fields in C<%args> are:

=over

=item C<lens> => L<Data::Focus::Lens> object (mandatory)

The lens to be tested.

=item C<target> => CODE (mandatory)

A code-ref that returns the target object. It is called without argument.

    $target_data = $target->()

The C<$target> code-ref must return a brand-new C<$target_data> object for every call.

=item C<exp_focal_points> => INT (mandatory)

Expected number of focal points the lens creates for the target.

=back

=head2 $tester->test_set_get(%args)

=head2 $tester->test_get_set(%args)

=head2 $tester->test_set_set(%args)

Test individual lens laws. C<%args> are the same as C<test_lens_laws()> method.

=head2 @parts = $tester->parts

Get the parts passed in C<new()> method.

=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
