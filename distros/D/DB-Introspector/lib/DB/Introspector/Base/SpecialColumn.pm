package DB::Introspector::Base::SpecialColumn;

use strict;

use base q(DB::Introspector::Base::Column);

sub new {
    my $class = shift;
    my $name = shift;
    my $real_type = shift;

    my $self = $class->SUPER::new($name);
    $self->{_real_type} = $real_type;
    return $self;
}

sub real_type {
    my $self = shift;
    return $self->{_real_type};
}

1;
__END__

=head1 NAME

DB::Introspector::Base::SpecialColumn

=head1 EXTENDS

DB::Introspector::Base::Column

=head1 SYNOPSIS

=over 4

use DB::Introspector::Base::SpecialColumn;

=back
     
=head1 DESCRIPTION

DB::Introspector::Base::SpecialColumn provides a way to distinguish a Special
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

The DB::Introspector::Base::SpecialColumn module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
