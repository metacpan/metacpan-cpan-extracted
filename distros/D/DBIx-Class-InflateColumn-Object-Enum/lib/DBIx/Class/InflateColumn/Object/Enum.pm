package DBIx::Class::InflateColumn::Object::Enum;
$DBIx::Class::InflateColumn::Object::Enum::VERSION = '0.06';
use warnings;
use strict;
use Carp qw/croak confess/;
use Object::Enum;

=head1 NAME

DBIx::Class::InflateColumn::Object::Enum - Allows a DBIx::Class user to define a Object::Enum column

=head1 VERSION

Version 0.03

=cut

# Dist::Zill should handle this now
# ABSTRACT:  Allows a DBIx::Class user to define a Object::Enum column
#our $VERSION = '0.04';


=head1 SYNOPSIS

Load this module via load_components and utilize is_enum and values property
to define Enumuration columns via Object::Enum

    package TableClass;
    
    use strict;
    use warnings;
    use base 'DBIx::Class';
    
    __PACKAGE__->load_components(qw/InflateColumn::Object::Enum Core/);
    __PACKAGE__->table('testtable');
    __PACKAGE__->add_columns(
        color => {
            data_type => 'varchar',
            is_enum => 1,
            extra => {
                list => [qw/red green blue/]
            }
        }
        color_native => { # works inline with native enum type
            data_type => 'enum',
            is_enum => 1,
            extra => {
                list => [qw/red green blue/]
            }
        }
    );
    
    1;
    
Now you may treat the column as an L<Object::Enum> object.
    
    my $table_rs = $db->resultset('TableClass')->create({
        color => undef
    });
    
    $table_rs->color->set_red; # sets color to red
    $table_rs->color->is_red; # would return true
    $table_rs->color->is_green; # would return false
    print $table_rs->color->value; # would print 'red'
    $table_rs->color->unset; # set the value to 'undef' or 'null'
    $table_rs->color->is_red; # returns false now

=head1 METHODS

=head2 register_column

Internal chained method with L<DBIx::Class::Row/register_column>.
Users do not call this directly!

=cut

sub register_column {
    my $self = shift;
    my ($column, $info) = @_;
    
    $self->next::method(@_);
    
    return unless defined $info->{is_enum} and $info->{is_enum};
    
    croak("Object::Enum '$column' missing 'extra => { list => [] }' column configuration")
        unless (
            defined $info->{extra}
            and ref $info->{extra}  eq 'HASH'
            and defined $info->{extra}->{list}
        );
        
    croak("Object::Enum '$column' value list (extra => { list => [] }) must be an array reference")
        unless ref $info->{extra}->{list} eq 'ARRAY';

    croak("Object::Enum requires a default value when a column is nullable")
        if exists $info->{is_nullable}
           and $info->{is_nullable}
           and !$info->{default_value};

    my $values = $info->{extra}->{list};
    my %values = map { $_ => 1 } @{$values};

    push(@{$values},$info->{default_value})
        if defined($info->{default_value})
        && !exists $values{$info->{default_value}};

    $self->inflate_column(
        $column => {
            inflate => sub {
                my $val = shift;

                my $c = {values => $values};
                $c->{unset} = $info->{is_nullable}
                    if exists $info->{is_nullable}
                       and $info->{is_nullable};
                $c->{default} = $info->{default_value}
                    if exists $info->{default_value};

                my $e = Object::Enum->new($c);
                $e->value($val);

                return $e;
            },
            deflate => sub {
                return shift->value
            }
        }
    );
    
}

=head1 AUTHOR

Jason M. Mills, C<< <jmmills at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-inflatecolumn-object-enum at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-InflateColumn-Object-Enum>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 CAVEATS

=over 2

=item * Please note that when a column definition C<is_nullable> then L<Object::Enum> will insist that there be a C<default_value> set.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::InflateColumn::Object::Enum


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-InflateColumn-Object-Enum>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-InflateColumn-Object-Enum>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-InflateColumn-Object-Enum>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-InflateColumn-Object-Enum>

=back


=head1 SEE ALSO

L<Object::Enum>, L<DBIx::Class>, L<DBIx::Class::InflateColumn::URI>


=head1 COPYRIGHT & LICENSE

Copyright 2008 Jason M. Mills, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DBIx::Class::InflateColumn::Object::Enum
