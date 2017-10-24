
use strict;
use warnings;

package Sample::Context::Singleton::Frame;

our $VERSION = v1.0.0;

package Sample::Context::Singleton::Frame::001::Unique::DB;
use parent 'Context::Singleton::Frame';

sub new {
    my ($class, @params) = @_;
    my $self = $class->SUPER::new (@params);

    unless (ref $class) {
        $self->{db} = $self->default_db_class->new;
        $self->contrive_builders if $self->can ('contrive_builders' );
    }

    return $self;
}

package Sample::Context::Singleton::Frame::002::Resolve::Dependencies;
our @ISA = 'Sample::Context::Singleton::Frame::001::Unique::DB';

sub contrive_builders {
    my ($self) = @_;

    $self->db->contrive (sum => (
        class => 'Calc',
        builder => 'sum',
        dep => [ 'a', 'b' ],
    ));

    $self->db->contrive (diff => (
        class => 'Calc',
        builder => 'diff',
        dep => [ 'a', 'b' ],
    ));

    $self->db->contrive (mul => (
        class => 'Calc',
        builder => 'mul',
        dep => [ 'a', 'b' ],
    ));

    $self->db->contrive (xmul => (
        class => 'Calc',
        builder => 'mul',
        dep => [ 'sum', 'diff' ],
    ));

    $self->db->contrive (without_dependencies => (
        value => 'value-42',
    ));

    $self->db->contrive (with_default => (
        as => sub { join '/', @_ },
        default => { foo => 'value', bar => 42 },
        dep => [ 'foo', 'bar' ],
    ));

    $self->db->contrive (with_deps => (
        as => sub { join '-', @_ },
        dep => [ 'foo', 'bar' ],
    ));

    $self->db->contrive (cascaded => (
        as => sub { join ':', 'cascaded', @_ },
        default => { param => 'param' },
        dep => [ 'param', 'with_deps' ],
    ));

    $self->db->trigger (with_trigger => sub {
        my $copy = 'copy_trigger';
        $self->proclaim ($copy, $_[0]) unless $self->is_deduced ($copy);
    });

    $self->proclaim ('Calc', 'Sample::Context::Singleton::Frame::003::Calc');
}

package Sample::Context::Singleton::Frame::003::Calc;

sub sum {
    my ($a, $b) = @_;

    return $a + $b;
}

sub diff {
    my ($a, $b) = @_;

    return $a - $b;
}
sub mul {
    my ($a, $b) = @_;

    return $a * $b;
}

package Sample::Context::Singleton::Frame::__::Basic;
our @ISA = 'Sample::Context::Singleton::Frame::001::Unique::DB';

sub contrive_builders {
    my ($self) = @_;

    $self->contrive (constant => (
        value => 'value-42',
    ));

    $self->contrive (cascaded => (
        dep => [ 'constant' ],
        as => sub { "cascaded:$_[0]" },
    ));

    $self->contrive (with_deps => (
        dep => [ 'unknown' ],
        as => sub { "with_deps:$_[0]" },
    ));

    $self->contrive (with_multi_deps => (
        dep => [ 'unknown', 'constant' ],
        as => sub { "with_deps:$_[0]:$_[1]" },
    ));

    $self->contrive (with_default => (
        dep => [ 'unknown', 'constant' ],
        default => { unknown => 'some' },
        as => sub { join ':', with_default => @_ },
    ));

    $self->contrive (inherited => (
        dep => [ 'with_multi_deps' ],
        as => sub { join ':', inherited => @_ },
    ));

    $self->contrive (with_default_ref => (
        dep => [ 'with_default' ],
        as => sub { my ($value) = @_; \ $value },
    ));

    $self->db->trigger (with_trigger => sub {
        my $copy = 'copy_trigger';
        $self->proclaim ($copy, $_[0]) unless $self->is_deduced ($copy);
    });
}

1;

