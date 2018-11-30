use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::ResultBase;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Core';

use experimental qw/signatures/;

sub sqlt_deploy_hook($self, $table) {
    my $indices = {};
    for my $column_name ($self->columns) {
        my $info = $self->column_info($column_name);

        if($info->{'indexed'}) {

            my $indexvalues = ref $info->{'indexed'} ne 'ARRAY' ? [ $info->{'indexed'} ] : $info->{'indexed'};

            for my $indexvalue (@$indexvalues) {

                if(length $indexvalue == 1 && $indexvalue) {
                    my $index_name = sprintf '%s_idxa_%s', $table, $column_name;
                    $indices->{ $index_name } = [$column_name];
                }
                elsif(length $indexvalue > 1) {
                    my $index_name = sprintf '%s_idxm_%s', $table, $indexvalue;

                    if(!exists $indices->{ $index_name }) {
                        $indices->{ $index_name } = [];
                    }
                    push @{ $indices->{ $index_name } } => $column_name;
                }
            }
        }
    }

    if(scalar keys %$indices) {
        for my $index_name (keys %$indices) {
            $table->add_index(name => $index_name, fields => $indices->{ $index_name });
        }
    }
    $self->next::method(@_) if $self->next::can;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::ResultBase - Short intro

=head1 VERSION

Version 0.0101, released 2018-11-29.

=head1 SYNOPSIS

    # in MyApp::Schema::Result::YourResultClass, instead of inheriting from DBIx::Class::Core
    use base 'DBIx::Class::Sweeten::Result::Base';

    # DBIx::Class::Candy is always nice
    use DBIx::Class::Candy;

    column last_name => {
        data_type => 'varchar',
        size => 150,
        indexed => 1,
    };

=head1 DESCRIPTION

Adding indices (apart from primary keys and unique constraints) requires creating a C<sqlt_deploy_hook> method and calling C<add_index> manually. This module
adds the C<indexed> column attribute.

=head2 Possible values

C<indexed> behaves differently depending on the value it is given:

=over 4

=item *

If given a one-character value, that evaluates to true, an index is created named C<[table_name]_idxa_[column_name]>.

=item *

If given a more-than-one-character value an index is created name C<[table_name]_idxm_[index_name]>. If multiple columns are given the same name a composite index is created.

=item *

If given an array reference each value in it is treated according to the two rules above.

=back

With these column definitions:

    table('Author');
    column first_name => {
        data_type => 'varchar',
        size => 150,
        indexed => 'name',
    };
    column last_name => {
        data_type => 'varchar',
        size => 150,
        indexed => [1, 'name'],
    };
    column country => {
        data_type => 'varchar',
        size => 150,
        indexed => 1,
    };

The following indices are created:

=over 4

=item *

C<Author_idxm_name> for C<first_name> and C<last_name>

=item *

C<Author_idxa_last_name> for C<last_name>

=item *

C<Author_idxa_country> for C<country>

=back

=head2 Still need a custom sqlt_deploy_hook?

If you need an C<sqlt_deploy_hook> method in a result source just call the parent's C<sqlt_deploy_hook> in your local sqlt_deploy_hook:

    sub sqlt_deploy_hook {
        my $self = shift;
        my $table = shift;

        $self->next::method($table);

        ...

    }

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
