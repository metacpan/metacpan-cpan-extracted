package DB::Introspector::Base::StringColumn;

use strict;

use base qw( DB::Introspector::Base::Column );

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

sub min_length {
    my $self = shift;
    return $self->{_min};
}

sub max_length {
    my $self = shift;
    return $self->{_max};
}

1;
__END__

=head1 NAME

DB::Introspector::Base::StringColumn

=head1 EXTENDS

DB::Introspector::Base::Column

=head1 SYNOPSIS

=over 4

use DB::Introspector::Base::StringColumn;

=back
     
=head1 DESCRIPTION

DB::Introspector::Base::StringColumn provides a way to distinguish a String
type from another column type.

=head1 SEE ALSO

=over 4

L<DB::Introspector::Base::Column>


=back

=head1 TODO

Provide a way to specify min and max length values for String columns.

=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::StringColumn module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
