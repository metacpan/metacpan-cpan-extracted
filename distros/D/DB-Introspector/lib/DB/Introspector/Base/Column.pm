package DB::Introspector::Base::Column;

use base qw( DB::Introspector::Base::Object );

use strict;


sub new {
    my $class = shift;
    my $name = shift;

    my $self = bless({ _name => $name }, ref($class) || $class);

    return $self;
}

sub name {
    my $self = shift;
    return $self->{_name};
} 

sub nullable {
    my $self = shift;
    $self->{_nullable} = shift if(@_);
    return (exists $self->{_nullable}) ? $self->{_nullable} : 1;
}



1;
__END__

=head1 NAME

DB::Introspector::Base::Column

=head1 SYNOPSIS

=over 4

use DB::Introspector::Base::Column;

=back
     
=head1 DESCRIPTION

DB::Introspector::Base::Column 

=head1 METHODS

=over 4



=item DB::Introspector::Base::Column->new($name)

=over 4

Params:

=over 4

$name - the name of the column

=back

Returns: An instance of a new DB::Introspector::Base::Column

=back



=item $column->name

=over 4

Returns: the name of this column

=back



=item $column->nullable($optional_boolean)

=over 4

Params:

=over 4

$optional_boolean - 1 or 0. If this field is provided then the value is set on the $column instance.

=back

Returns: whether or not the $column is nullable. By default, this value is true
or 1.

=back


=back


=head1 TODO

Implement support for column level data check constraints

=head1 SEE ALSO

=over 4

L<DB::Introspector::Base::BooleanColumn>

L<DB::Introspector::Base::CharColumn>

L<DB::Introspector::Base::DateTimeColumn>

L<DB::Introspector::Base::IntegerColumn>

L<DB::Introspector::Base::StringColumn>


=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::Column module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
