package Algorithm::DLX;

use strict;
use warnings;

our $VERSION = 0.03;

# Node structure for DLX
package DLX::Node;
sub new {
    my ($class, $row, $col) = @_;
    my $self = {
        row     => $row,
        col     => $col,
        left    => undef,
        right   => undef,
        up      => undef,
        down    => undef,
        column  => undef,
    };
    bless $self, $class;
    return $self;
}

# Column structure for DLX
package DLX::Column;
use base 'DLX::Node';
sub new {
    my ($class, $col) = @_;
    my $self = $class->SUPER::new(undef, $col);
    $self->{size}   = 0;
    $self->{name}   = $col;
    $self->{column} = $self;
    bless $self, $class;
    return $self;
}

# Main DLX package
package Algorithm::DLX;

sub new {
    my ($class) = @_;
    my $self = {
        header      => DLX::Column->new('header'),
        solution    => [],
        solutions   => [],
    };

    # Initialize header links
    $self->{header}->{left}     = $self->{header};
    $self->{header}->{right}    = $self->{header};
    bless $self, $class;

    return $self;
}

sub add_column {
    my ($self, $col_name) = @_;
    my $col = DLX::Column->new($col_name);

    $col->{left}    = $self->{header}->{left};
    $col->{right}   = $self->{header};
    $self->{header}->{left}->{right} = $col;
    $self->{header}->{left} = $col;
    $col->{up}      = $col;
    $col->{down}    = $col;

    return $col;
}

sub add_row {
    my ($self, $row, @cols) = @_;
    my $first;

    for my $col (@cols) {
        my $node = DLX::Node->new($row, $col->{name});
        $node->{column}     = $col;
        $col->{size}++;
        $node->{up}         = $col->{up};
        $node->{down}       = $col;
        $col->{up}->{down}  = $node;
        $col->{up}          = $node;
        if ($first) {
            $node->{left}   = $first->{left};
            $node->{right}  = $first;
            $first->{left}->{right} = $node;
            $first->{left}  = $node;
        } else {
            $first = $node;
            $node->{left}   = $node;
            $node->{right}  = $node;
        }
    }
}

sub cover {
    my ($self, $col) = @_;

    $col->{right}->{left} = $col->{left};
    $col->{left}->{right} = $col->{right};

    for (my $row = $col->{down}; $row != $col; $row = $row->{down}) {
        for (my $node = $row->{right}; $node != $row; $node = $node->{right}) {
            $node->{down}->{up} = $node->{up};
            $node->{up}->{down} = $node->{down};
            $node->{column}->{size}--;
        }
    }
}

sub uncover {
    my ($self, $col) = @_;

    for (my $row = $col->{up}; $row != $col; $row = $row->{up}) {
        for (my $node = $row->{left}; $node != $row; $node = $node->{left}) {
            $node->{column}->{size}++;
            $node->{down}->{up} = $node;
            $node->{up}->{down} = $node;
        }
    }

    $col->{right}->{left} = $col;
    $col->{left}->{right} = $col;
}

sub search {
    my ($self, $k, $number_of_solutions) = @_;

    if ($self->{header}->{right} == $self->{header}) {
        push @{$self->{solutions}}, [@{$self->{solution}}];
        return;
    }

    if ($number_of_solutions && @{$self->{solutions}} >= $number_of_solutions) {
        return;
    }

    my $col = $self->{header}->{right};
    for (my $c = $col->{right}; $c != $self->{header}; $c = $c->{right}) {
        $col = $c if $c->{size} < $col->{size};
    }

    $self->cover($col);
    for (my $row = $col->{down}; $row != $col; $row = $row->{down}) {
        push @{$self->{solution}}, $row->{row};
        for (my $node = $row->{right}; $node != $row; $node = $node->{right}) {
            $self->cover($node->{column});
        }
        $self->search($k + 1, $number_of_solutions);
        for (my $node = $row->{left}; $node != $row; $node = $node->{left}) {
            $self->uncover($node->{column});
        }
        pop @{$self->{solution}};
    }

    $self->uncover($col);
}

sub solve {
    my ($self, %params) = @_;

    my $number_of_solutions = $params{number_of_solutions};

    $self->search(0, $number_of_solutions);

    return $self->{solutions};
}

1;

__END__

=head1 NAME

DLX - Dancing Links Algorithm for Exact Cover Problems

=head1 SYNOPSIS

  use Algorithm::DLX;

  my $dlx = Algorithm::DLX->new();

  my $col_A = $dlx->add_column('A');
  my $col_B = $dlx->add_column('B');
  my $col_C = $dlx->add_column('C');
  my $col_D = $dlx->add_column('D');

  $dlx->add_row('row1', $col_A, $col_C);
  $dlx->add_row('row2', $col_B, $col_D);
  $dlx->add_row('row3', $col_A, $col_D);

  my $solutions = $dlx->solve();

=head1 DESCRIPTION

This module implements the Dancing Links (DLX) algorithm for solving exact cover problems.

=head1 METHODS

=head2 new

Constructor.

=head2 add_column($col_name)

Add a column with the given name.

=head2 add_row($row, @cols)

Add a row with the given identifier and columns.

=head2 solve

Solve the exact cover problem and return the solutions.

=head1 AUTHOR

James Hammer <james.hammer3@gmail.com>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut
