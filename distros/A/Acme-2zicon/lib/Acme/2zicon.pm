package Acme::2zicon;
use 5.008001;
use strict;
use warnings;

use Carp  qw(croak);
use DateTime;

our $VERSION = "0.7";

my @members = qw(
    MatobaKarin
    NakamuraAkari
    NemotoNagi
    OkumuraNonoka
    ShigematsuYuka
    SuyamaEmiri
    TsurumiMoe
    OtsukaMiyu
    YamatoAo
);

sub new {
    my $class = shift;
    my $self  = bless {members => []}, $class;

    $self->_initialize;

    return $self;
}

sub members {
    my ($self, $type, @members) = @_;
    @members = @{$self->{members}} unless @members;

    return @members unless $type;
}

sub sort {
    my ($self, $type, $order, @members) = @_;
    @members = $self->members unless @members;

    # order by desc if $order is true
    if ($order) {
        return sort {$b->$type <=> $a->$type} @members;
    }
    else {
        return sort {$a->$type <=> $b->$type} @members;
    }
}

sub select {
    my ($self, $type, $number, $operator, @members) = @_;

    $self->_die('invalid operator was passed in')
        unless grep {$operator eq $_} qw(== >= <= > <);

    @members = $self->members unless @members;
    my $compare = eval "(sub { \$number $operator \$_[0] })";

    return grep { $compare->($_->$type) } @members;
}

sub _initialize {
    my $self = shift;

    for my $member (@members) {
        my $module_name = 'Acme::2zicon::'.$member;

        eval qq|require $module_name;|;
        push @{$self->{members}}, $module_name->new;
    }

    return 1;
}

sub _die {
    my ($self, $message) = @_;
    Carp::croak($message);
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::2zicon - It's new $module

=head1 SYNOPSIS

    use Acme::2zicon;

    my $nizicon = Acme::2zicon->new;

    # retrieve the members on their activities
    my @members         = $nizicon->members;

    # retrieve the members under some conditions
    my @sorted_by_age   = $nizicon->sort('age', 1);
    my @selected_by_age = $nizicon->select('age', 16, '>=');


=head1 DESCRIPTION

=head1 METHODS

=head2 new

    my $nizicon = Acme::2zicon->new;

    Creates and returns a new Acme::2zicon object.

=head2 members

    my @members = $nizicon->members();

=head2 sort ( $type, $order \[ , @members \] )

    my @sorted_members = $nizicon->sort('age', 1);

=head2 select ( $type, $number, $operator \[, @members\] )

    # $type can be one of the same values above:
    my @selected_members = $nizicon->select('age', 16, '>=');

    $number $operator $member_value


=head1 LICENSE

MIT License

=head1 AUTHOR

catatsuy E<lt>catatsuy@catatsuy.orgE<gt>

=head1 SEE ALSO

(Japanese text only)

=over 4

=item * 虹のコンキスタドール

L<http://pixiv-pro.com/2zicon/>

=item * プロフィール - 虹のコンキスタドール

L<http://pixiv-pro.com/2zicon/profile>

=back

=head1 NOTE

This product has nothing to do with pixiv Inc. and pixiv production Inc. and 2zicon.


=cut

