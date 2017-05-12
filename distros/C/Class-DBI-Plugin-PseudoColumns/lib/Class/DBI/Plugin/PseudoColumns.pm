package Class::DBI::Plugin::PseudoColumns;

use strict;
use warnings;
use Carp;
use Data::Dumper ();
use vars qw($VERSION);
$VERSION = 0.03;

sub import {
    my $class = shift;
    my $pkg   = caller;

    return unless $pkg->isa('Class::DBI');
    if ($pkg->isa('Class::DBI')) {
        $pkg->mk_classdata('_p_column_groups');
        $pkg->mk_classdata('_serializer');
    }

    no strict 'refs';

    *{"$pkg\::pseudo_columns"} = sub {
        my $class = shift;
        croak "You must set table before call pseudo_columns()"
            unless defined $class->table;
        my $parent_column = shift;
        my $p_col_groups = $class->_p_column_groups;
        if (defined $_[0]) {
            my @colnames = @_;
            $p_col_groups->{$class}->{$parent_column} = \@colnames;
            $class->_p_column_groups($p_col_groups);
            for my $p_column (@colnames) {
                *{"$class\::$p_column"} = sub {
                    my $self = shift;
                    my $property = $self->__deserialize($parent_column);
                    if (@_) {
                        $property->{$p_column} = shift;
                        my $serialized =
                            $self->__serialize($parent_column => $property);
                        $self->$parent_column($serialized);
                    }
                    return $property->{$p_column};
                };
            }
        }
        elsif (defined $parent_column) {
            return unless ref($p_col_groups) eq 'HASH' &&
                ref($p_col_groups->{$class}) eq 'HASH' &&
                    ref($p_col_groups->{$class}->{$parent_column}) eq 'ARRAY';
            return @{$p_col_groups->{$class}->{$parent_column}};
        }
        else {
            return unless ref($p_col_groups) eq 'HASH' &&
                ref($p_col_groups->{$class}) eq 'HASH';
            my @pseudo_cols = ();
            for my $col (keys %{$p_col_groups->{$class}}) {
                next unless ref($p_col_groups->{$class}->{$col}) eq 'ARRAY';
                push @pseudo_cols, @{$p_col_groups->{$class}->{$col}};
            }
            return @pseudo_cols;
        }
    };

    my $super_create = $pkg->can('create');
    croak "create() method can not be called in $pkg" unless $super_create;
    *{"$pkg\::create"} = sub {
        my($class, $hashref) = @_;
        croak "create needs a hashref" unless ref($hashref) eq 'HASH';
        croak "You must set table before call create()"
            unless defined $class->table;
        my %cols_check = map { $_ => 1 } $class->pseudo_columns;
        my %p_values = ();
        for my $col (keys %$hashref) {
            next unless $cols_check{$col};
            $p_values{$col} = delete $hashref->{$col};
        }
        my $row = $class->$super_create($hashref); # create()
        if (%p_values) {
            for my $col (keys %p_values) {
                $row->$col($p_values{$col});
            }
            $row->update;
        }
        return $row;
    };

    my $super_set = $pkg->can('set');
    croak "set() method can not be called in $pkg" unless $super_set;
    *{"$pkg\::set"} = sub {
        my $self = shift;
        my $column_values = {@_};
        my $class = ref($self) || $self;
        my %cols_check = map { $_ => 1 } $class->pseudo_columns;
        my %p_values = ();
        for my $col (keys %$column_values) {
            next unless $cols_check{$col};
            $p_values{$col} = delete $column_values->{$col};
        }
        $self->$super_set(%$column_values) if %$column_values;
        if (%p_values) {
            for my $col (keys %p_values) {
                $self->$col($p_values{$col});
            }
        }
    };

    for my $export (qw(__serialize __deserialize serializer deserializer)) {
        *{"$pkg\::$export"} = \&$export;
    }
}

sub serializer {
    my($class, $parent_column, $subref) = @_;
    croak "You must set table before call serializer()"
        unless defined $class->table;
    my $serializer = $class->_serializer;
    if (ref($subref) eq 'CODE') {
        $serializer->{serializer} = { $parent_column => $subref };
        $class->_serializer($serializer);
    }
    else {
        carp "Usage: __PACKAGE__->serializer(parent_column => \$subref)";
    }
}

sub deserializer {
    my($class, $parent_column, $subref) = @_;
    croak "You must set table before call deserializer()"
        unless defined $class->table;
    my $serializer = $class->_serializer;
    if (ref($subref) eq 'CODE') {
        $serializer->{deserializer} = { $parent_column => $subref };
        $class->_serializer($serializer);
    }
    else {
        carp "Usage: __PACKAGE__->deserializer(parent_column => \$subref)";
    }
}

sub __serialize {
    my($self, $column, $var) = @_;
    my $class = ref($self) || $self;
    croak "Can't lookup the table name via table() method."
        unless defined $class->table;
    my $serializer = $class->_serializer;
    if (ref($serializer->{serializer}) eq 'HASH' &&
        exists $serializer->{serializer}->{$column} &&
            ref($serializer->{serializer}->{$column}) eq 'CODE') {
        return $serializer->{serializer}->{$column}->($var);
    }
    else {
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        return Data::Dumper::Dumper($var);
    }
}

sub __deserialize {
    my($self, $column) = @_;
    my $class = ref($self) || $self;
    croak "Can't lookup the table name via table() method."
        unless defined $class->table;
    my $prop;
    my $dumped = $self->$column;
    if (defined $dumped) {
        my $serializer = $class->_serializer;
        if (ref($serializer->{deserializer}) eq 'HASH' &&
            exists $serializer->{deserializer}->{$column} &&
                ref($serializer->{deserializer}->{$column}) eq 'CODE') {
            $prop = $serializer->{deserializer}->{$column}->($dumped);
        }
        else {
            $prop = eval qq{ $dumped };
        }
    }
    return $prop if defined $prop && ref($prop) eq 'HASH';
    return {};
}

1;

__END__

=head1 NAME

Class::DBI::Plugin::PseudoColumns - an interface to use some pseudo columns

=head1 SYNOPSIS

 package Music::CD;
 use base 'Music::DBI';
 
 Music::CD->table('cd');
 Music::CD->columns(All => qw/cdid artist title year reldate properties/);
 use Class::DBI::Plugin::PseudoColumns;
 Music::CD->pseudo_columns(properties => qw/asin tag/);
 
 use Music::CD;
 my $cds = Music::CD->search(artist => 'Steve Vai');
 while (my $cd = $cds->next) {
     if ($cd->title =~ /^Real\s+Illusions/i) {
         $cd->asin('B0007GADZO');
     }
     $cd->tag(['rock', 'guitar', 'tricky play']);
     $cd->update;
 }

 my $bought_cd = Music::CD->create({
     artist  => 'Rolling Stones',
     title   => 'A Bigger Bang',
     year    => 2005,
     reldate => '2005-11-22',
     asin    => 'B000BP86LE',
     tag     => ['rock', 'blues', 'favorite'],
 });
 $bought_cd->set(
     artist => 'The Rolling Stones',
     title  => 'A Bigger Bang - Special Edition',
 );
 $bought_cd->update;

=head1 DESCRIPTION

This module provides an easy way to use B<pseudo> column in your C<Class::DBI> based table classes.
The ``pseudo column'' means a kind of column that is including an optical hashref string (via C<Data::Dumper>, by default).
You can get and set with using the pseudo column accessors (same as always).
But, you can't use the columns' name into your SQL, SQL interfaced methods, C<ORDER BY> clause and C<GROUP BY> clause, etc.
This module is useful when you'd like to add an unimportant column without issuing C<ALTER TABLE>, and when you'd like to have related multiple data without normalizing table.

=head1 HOW TO USE

=head2 Create a column

You should create a huge size column into your table. like this:

 CREATE TABLE cd (
   cdid int UNSIGNED auto_increment,
   artist varchar(255),
   title varchar(255),
   year int,
   reldate date,
   properties text, # create for using pseudo column
   PRIMARY KEY (cdid)
 );

=head2 Create a table class

Almost same as usual.

 package Music::CD;
 use base 'Music::DBI';
 
 Music::CD->table('cd');
 Music::CD->columns(All => qw/cdid artist title year reldate properties/);

=head2 Use it

You will be able to use pseudo column with only to C<use> this module.

 use Class::DBI::Plugin::PseudoColumns;

=head2 Set your pseudo columns as your like

 Music::CD->pseudo_columns(properties => qw/asin tag/);

=head1 METHOD

This module provides following class methods.

=over 4

=item * create(\%data);

C<create> method works almost same as C<Class::DBI::create()> if there's some pseudo column in C<%data>.

=item * set(column => value[, column2 => value2, ...]);

C<set> method works almost same as C<Class::DBI::set()> if there's some pseudo column in argument.

=item * pseudo_columns([parent_colname => ('pseudo_column1'[, 'pseudo_column2' ...])]);

You can set a pseudo columns' name with parent column's name. ``pseudo_column1'' ... will provide to you each pseudo column's accessor.

if you want to take a list of pseudo columns, you can pass one argument to this method when you want to specify grouped parent column name.

 my @p_columns = Music::CD->pseudo_columns('properties');

And if you want to take all columns list of pseudo columns, you don't need to pass any argument to this method.

 my @all_p_columns = Music::CD->pseudo_columns();

=item * serializer(parent_colname => \&serializer_sub);

You can set a specific serializing function for your pseudo columns.

 use Storable ();
 __PACKAGE__->serializer(properties => \&Storable::nfreeze);

The default serializer is C<Data::Dumper::Dumper> (when you don't specify).

=item * deserializer(parent_coluname => \&deserializer_sub);

You can set a specific deserializing function for your pseudo columns.

 use Storable ();
 __PACKAGE__->deserializer(properties => \&Storable::thaw);

The default deserializer calls C<eval()> (when you don't specify) for the dumped optical hashref string.

NOTE: The subref for serializer/deserializer must return a really ``storable'' string for your database.
example of above works under a MySQL environment, but you have to change to use some another ``storable'' filter (like C<MIME::Base64>) under SQLite environment (see t/05_serializer.t)

=back

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 COPYRIGHT

Copyright (c) 2006 Koichi Taniguchi. Japan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Data::Dumper>

=cut
