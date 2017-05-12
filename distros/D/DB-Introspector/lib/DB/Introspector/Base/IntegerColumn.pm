package DB::Introspector::Base::IntegerColumn;

use strict;

use base q(DB::Introspector::Base::Column);

sub new {
    my $class = shift;
    my $name = shift;

    my $min = shift;
    my $max = shift;

    my $self = $class->SUPER::new($name);
    $self->{_min} = $min;
    $self->{_max} = $max;

    return $self;
}

sub min {
    my $self = shift;
    return $self->{_min};
}

sub max {
    my $self = shift;
    return $self->{_max};
}

1;
__END__

=head1 NAME

DB::Introspector::Base::IntegerColumn

=head1 EXTENDS

DB::Introspector::Base::Column

=head1 SYNOPSIS

=over 4

use DB::Introspector::Base::IntegerColumn;

=back
     
=head1 DESCRIPTION

DB::Introspector::Base::IntegerColumn provides a way to distinguish a Integer
type from another column type.

=head1 SEE ALSO

=over 4

L<DB::Introspector::Base::Column>


=back

=head1 TODO

Provide a way to specify min and max values for integer columns.

=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::IntegerColumn module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
