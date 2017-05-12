package AnyEvent::Groonga::Result::Select;
use strict;
use warnings;
use Encode;
use base qw(AnyEvent::Groonga::Result);

sub hit_num {
    my $self = shift;
    return $self->body->[0]->[0]->[0];
}

sub columns {
    my $self = shift;
    my @cols = ();
    if ( ref $self->body eq 'ARRAY' ) {
        for ( @{ $self->body->[0]->[1] } ) {
            push @cols, $_->[0];
        }
    }
    return \@cols;
}

sub items {
    my $self       = shift;
    my $cols       = $self->columns;
    my @item_array = ();
    if ( ref $self->body eq 'ARRAY' ) {
        for my $i ( 2 .. int @{ $self->body->[0] } - 1 ) {
            my $row = $self->body->[0]->[$i];
            my $item;
            for my $j ( 0 .. int @$cols - 1 ) {
                my $key   = $cols->[$j];
                my $value = $row->[$j];
                $item->{$key} = $value;
            }
            push @item_array, $item;
        }
    }
    return \@item_array;
}

1;
__END__

=head1 NAME

AnyEvent::Groonga::Result::Select - Result class for AnyEvent::Gronnga that specialized 'select' command 

=head1 SYNOPSIS

  my $result = $groonga->call( select => $args_ref )->recv;

  my $hit_num = $result->hit_num;  
  my $columns = $result->columns;
  my $items   = $result->items; 

=head1 DESCRIPTION

Result class for AnyEvent::Groonga specialzied "select" command.
It derived from AnyEvent::Groonga::Result class.

=head1 METHOD

=head2 new

=head2 hit_num 

=head2 columns 

=head2 items 


=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
