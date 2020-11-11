use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Fields;

# ABSTRACT: Specify columns
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0107';

use Carp qw/croak/;
use List::Util qw/uniq/;
use List::SomeUtils qw/any/;
use boolean;
use Sub::Exporter::Progressive -setup => {
    exports => [qw/
        true
        false
        ForeignKey
        BitField
        TinyIntField
        SmallIntField
        MediumIntField
        IntegerField
        BigIntField
        SerialField
        BooleanField
        NumericField
        NonNumericField
        DecimalField
        FloatField
        DoubleField
        VarcharField
        CharField
        VarbinaryField
        BinaryField
        TinyTextField
        TextField
        MediumTextField
        LongTextField
        TinyBlobField
        BlobField
        MediumBlobField
        LongBlobField
        EnumField
        DateField
        DateTimeField
        TimestampField
        TimeField
        YearField
    /],
    groups => {
        fields => [qw/
            ForeignKey
            BitField
            TinyIntField
            SmallIntField
            MediumIntField
            IntegerField
            BigIntField
            SerialField
            BooleanField
            NumericField
            NonNumericField
            DecimalField
            FloatField
            DoubleField
            VarcharField
            CharField
            VarbinaryField
            BinaryField
            TinyTextField
            TextField
            MediumTextField
            LongTextField
            TinyBlobField
            BlobField
            MediumBlobField
            LongBlobField
            EnumField
            DateField
            DateTimeField
            TimestampField
            TimeField
            YearField
        /],
    },
};

use experimental qw/postderef signatures/;

sub merge($first, $second) {
    my $merged = do_merge($first, $second);

    if(!exists $merged->{'extra'}) {
        $merged->{'extra'} = {};
    }
    $merged->{'_smooth'} = {};

    for my $key (keys $merged->%*) {
        if($key =~ m{^-(.*)}) {
            my $clean_key = $1;
            $merged->{'extra'}{ $clean_key } = delete $merged->{ $key };
        }
        elsif($key eq 'many') {
            $merged->{'_smooth'}{'has_many'} = delete $merged->{'many'} || [];
        }
        elsif($key eq 'might') {
            $merged->{'_smooth'}{'might_have'} = delete $merged->{'might'} || [];
        }
        elsif($key eq 'one') {
            $merged->{'_smooth'}{'has_one'} = delete $merged->{'one'} || [];
        }
        elsif($key eq 'across') {
            my $acrosses = delete $merged->{'across'};
            for (my $i = 0; $i < scalar $acrosses->@*; ++$i) {
                my $from = $acrosses->[$i];
                my $to = $acrosses->[$i + 1];
                $merged->{'_smooth'}{'across'}{ $from }{ $to } = 1;
            }
        }
    }

    my %alias = (
        nullable => 'is_nullable',
        auto_increment => 'is_auto_increment',
        foreign_key => 'is_foreign_key',
        default => 'default_value',
    );

    for my $alias (keys %alias) {
        if(exists $merged->{ $alias }) {
            my $actual = $alias{ $alias };
            $merged->{ $actual } = delete $merged->{ $alias };
        }
    }

    if(exists $merged->{'default_sql'}) {
        if(!defined $merged->{'default_sql'}) {
            delete $merged->{'default_sql'};
            $merged->{'default_value'} = \'NULL';
        }
        else {
            my $default_sql = delete $merged->{'default_sql'};
            $merged->{'default_value'} = \$default_sql;
        }
    }

    if(!scalar keys $merged->{'_smooth'}->%*) {
        delete $merged->{'_smooth'};
    }
    if(!scalar keys $merged->{'extra'}->%*) {
        delete $merged->{'extra'};
    }
    return $merged;
}

sub do_merge($first, $second) {
    my $merged = {};
    for my $key (uniq (keys %{ $first }, keys %{ $second })) {
        if(exists $first->{ $key } && !exists $second->{ $key }) {
            $merged->{ $key } = $first->{ $key };
        }
        elsif(!exists $first->{ $key } && exists $second->{ $key }) {
            $merged->{ $key } = $second->{ $key };
        }
        else {
            if(ref $first->{ $key } ne 'HASH' && $second->{ $key } ne 'HASH') {
                $merged->{ $key } = $first->{ $key };
            }
            else {
                $merged->{ $key } = do_merge($first->{ $key }, $second->{ $key });
            }
        }
    }

    return $merged;
}

# this can only be used in the best case, where we can lift the definition from the primary key it points to
# and also does belongs_to<->has_many relationships
sub ForeignKey(%settings) {
    # 'sql' is the attr to the relationship
    # 'related_name' is the name of the inverse relationship, set to undef to skip creation
    # 'related_sql' is the attr to the inverse relationship
    my @approved_keys = qw/nullable indexed sql related_name related_sql/;
    my @keys_in_settings = keys %settings;

    KEY:
    for my $key (@keys_in_settings) {
        next KEY if any { $key eq $_ } @approved_keys;
        delete $settings{ $key };
    }

    return merge { _smooth_foreign_key => 1 }, \%settings;
}

# base fields
sub NumericField(%settings) {
    return merge { is_numeric => 1 }, \%settings;
}
sub NonNumericField(%settings) {
    return merge { is_numeric => 0 }, \%settings;
}

# data types - integers
sub BitField(%settings) {
    return NumericField(data_type => 'bit', %settings);
}
sub TinyIntField(%settings) {
    return NumericField(data_type => 'tinyint', %settings);
}
sub SmallIntField(%settings) {
    return NumericField(data_type => 'smallint', %settings);
}
sub MediumIntField(%settings) {
    return NumericField(data_type => 'mediumint', %settings);
}
sub IntegerField(%settings) {
    return NumericField(data_type => 'integer', %settings);
}
sub BigIntField(%settings) {
    return NumericField(data_type => 'bigint', %settings);
}
sub SerialField(%settings) {
    return NumericField(data_type => 'serial', %settings);
}
sub BooleanField(%settings) {
    return NumericField(data_type => 'boolean', %settings);
}

# data types - other numericals
sub DecimalField(%settings) {
    return NumericField(data_type => 'decimal', %settings);
}
sub FloatField(%settings)  {
    return NumericField(data_type => 'float', %settings);
}
sub DoubleField(%settings) {
    return NumericField(data_type => 'double', %settings);
}

# data types - strings
sub VarcharField(%settings) {
    return NonNumericField(data_type => 'varchar', %settings);
}
sub CharField(%settings) {
    return NonNumericField(data_type => 'char', %settings);
}
sub VarbinaryField(%settings) {
    return NonNumericField(data_type => 'varbinary', %settings);
}
sub BinaryField(%settings) {
    return NonNumericField(data_type => 'binary', %settings);
}

sub TinyTextField(%settings) {
    return NonNumericField(data_type => 'tinytext', %settings);
}
sub TextField(%settings) {
    return NonNumericField(data_type => 'text', %settings);
}
sub MediumTextField(%settings) {
    return NonNumericField(data_type => 'mediumtext', %settings);
}
sub LongTextField(%settings) {
    return NonNumericField(data_type => 'longtext', %settings);
}
sub TinyBlobField(%settings) {
    return NonNumericField(data_type => 'tinyblob', %settings);
}
sub BlobField(%settings) {
    return NonNumericField(data_type => 'blob', %settings);
}
sub MediumBlobField(%settings) {
    return NonNumericField(data_type => 'mediumblob', %settings);
}
sub LongBlobField(%settings) {
    return NonNumericField(data_type => 'longblob', %settings);
}

sub EnumField(%settings) {
    if(exists $settings{'extra'} && exists $settings{'extra'}{'list'}) {
        # all good
    }
    elsif(exists $settings{'-list'}) {
        $settings{'extra'}{'list'} = delete $settings{'list'};
    }
    else {
        croak qq{'enum' expects '-list => [qw/the possible values/]' or 'extra => { list => [qw/the possible values/] }'};
    }
    return merge { data_type => 'enum', is_numeric => 0 }, \%settings;
}

# data types - dates and times
sub DateField(%settings) {
    return NonNumericField(data_type => 'date', %settings);
}
sub DateTimeField(%settings) {
    return NonNumericField(data_type => 'datetime', %settings);
}
sub TimestampField(%settings) {
    return NonNumericField(data_type => 'timestamp', %settings);
}
sub TimeField(%settings) {
    return NonNumericField(data_type => 'time', %settings);
}
sub YearField(%settings) {
    return NonNumericField(data_type => 'year', %settings);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Fields - Specify columns

=head1 VERSION

Version 0.0107, released 2020-10-28.

=head1 SYNOPSIS

    package Your::Schema::Result::Book;

    use Your::Schema::Result -components => [qw//];
    use DBIx::Class::Smooth::Fields -all;

    primary id => IntegerField(auto_increment => true);
    belongs Publisher => ForeignKey();
        col isbn => VarcharField(size => 13);
        col title => VarcharField(size => 150);
        col published_date => DateField();
        col language => EnumField(indexed => 1, -list => [qw/english french german spanish/]);

=head1 DESCRIPTION

DBIx::Class::Smooth::Fields defines an alternative way to specify columns in DBIx::Class result sources. They make most sense when used together with the functions exported by L<Smooth::Helper::Row::Creation>.

These are just functions that return the hashes that you normally use to configure DBIx::Class columns. With a couple of exceptions, they only set C<data_type> and C<is_numeric>.

Any key-value pairs passed will be included in the returned hash. If you need to use other data types, you can use C<NumericalField> or C<NonNumericalField> which only sets C<is_numeric> to the expected value.

=head2 Relational fields

=head3 ForeignKey()

    belongs Publisher => ForeignKey();

This is not a field type at all, but helps define the relationship with another result source. The heavy lifting is done by C<belongs>, but in short there will be a field named C<publisher_id> with the C<size> and C<data_type> of the C<id> field in C<::Publisher>.

=head2 Numerical fields

These will all have C<is_numeric> set to C<1>, in addition to their respective C<data_type>:

    BitField         bit
    TinyIntField     tinyint
    SmallIntField    smallint
    MediumIntField   mediumint
    IntegerField     integer
    BigIntField      bigint
    SerialField      serial
    BooleanField     boolean
    DecimalField     decimal
    FloatField       float
    DoubleField      double

=head2 Non-numerical fields

These will all have C<is_numeric> set to C<0>, in addition to their respective C<data_type>:

    VarcharField     varchar
    CharField        char
    VarbinaryField   varbinary
    BinaryField      binary
    TinyTextField    tinytext
    TextField        text
    MediumTextField  mediumtext
    LongTextField    longtext
    TinyBlobField    tinyblob
    BlobField        blob
    MediumBlobField  mediumblob
    LongBlobField    longblod
    EnumField        enum
    DateField        date
    DateTimeField    datetime
    TimestampField   timestamp
    TimeField        time
    YearField        year

For C<EnumField>, you can do C<EnumField(-list => [qw/one to three/])> instead of C<EnumField(extra => { list => [qw/one two three/] })>.

=head1 SEE ALSO

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Smooth>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Smooth>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
