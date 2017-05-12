# $Id: Table.pm 4 2007-09-13 10:16:35Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/lib/Class/Dot/Model/Table.pm $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
package Class::Dot::Model::Table;

use strict;
use warnings;
use version; our $VERSION = qv('0.1.3');
use 5.006_001;

use Carp                    qw(croak);
use English                 qw( -no_match_vars );
use Params::Util            qw(_ARRAY);
use Class::Dot::Model::Util qw(
    push_base_class run_as_call_class
    install_coderef FQDN
);

my $BASE_CLASS = 'DBIx::Class';

my @DEFAULT_DBIC_COMPONENTS = qw(
    PK::Auto
    Core
);

my $UPLEVEL = 2;

sub requires {
    my @requires = map { join q{::}, $BASE_CLASS, $_ } @DEFAULT_DBIC_COMPONENTS;
    unshift @requires, $BASE_CLASS;
    return @requires;
}

my %RELATIONSHIPS_FOR;

sub import {
    my $class     = shift;
    my $call_class = caller 0;

    push_base_class($BASE_CLASS => $call_class);

    run_as_call_class(
        $call_class, 'load_components', @DEFAULT_DBIC_COMPONENTS
    );

    return if not scalar @_;

    my @SUBS_TO_EXPORT = qw(
        Table 
        Columns
        Primary_Key
        RELATIONSHIPS
    );
    
    my %SUBROUTINES  = (
        Table           => sub {
            return $call_class->table(@_);
        },
        Columns         => sub {
            my @columns = @_;
            $call_class->add_columns(@columns);
            no strict 'refs'; ## no critic;
            *{ FQDN($call_class, 'COLUMNS') } = sub {
                return wantarray ? @columns : \@columns;
            };
        },
        Primary_Key     => sub {
            return $call_class->set_primary_key(@_);
        },
        Has_Many        => sub {
            $call_class->has_many(@_);
            $RELATIONSHIPS_FOR{$call_class}{$_[0]} = 1;
            return;
        },
        Belongs_To      => sub {
            $call_class->belongs_to(@_);
            $RELATIONSHIPS_FOR{$call_class}{$_[0]} = 1;
        },
        Many_To_Many    => sub {
            $call_class->many_to_many(@_);
            $RELATIONSHIPS_FOR{$call_class}{$_[0]} = 1;
            return;
        },
        Has_One         => sub {
            $call_class->has_one(@_);
            $RELATIONSHIPS_FOR{$call_class}{$_[0]} = 1;
        },
        RELATIONSHIPS   => sub {
            return $RELATIONSHIPS_FOR{$call_class};
        },
    );

    my %EXPORT_TAGS = (
        ':all'          => [ keys %SUBROUTINES                          ],
        ':std'          => [ keys %SUBROUTINES                          ],
        ':has_many'     => [ @SUBS_TO_EXPORT, 'Has_Many', 'Belongs_To', ],
        ':belongs_to'   => [ @SUBS_TO_EXPORT,             'Belongs_To'  ],
        ':child'        => [ @SUBS_TO_EXPORT,                           ],
        ':many_to_many' => [ @SUBS_TO_EXPORT, 'Many_To_Many',           ],
        ':has_one'      => [ @SUBS_TO_EXPORT, 'Has_One',                ],
    );

    for my $arg (@_) {
        if ($arg =~ m/^:/xms) {
            my $export_class_ref = $EXPORT_TAGS{$arg};
            croak "No such export class: $arg"
                if ! _ARRAY($export_class_ref);
            for my $export_sub (@{ $export_class_ref }) {
                install_coderef(
                    $SUBROUTINES{$export_sub} => $call_class, $export_sub
                );
            }
        }
        else {
            my $coderef = $SUBROUTINES{$arg};
             
            install_coderef(
                $coderef => $call_class, $arg
            );
        }
    }

    return;
}


1;

# TODO
#sub isa_Char {      ## no critic
#    my ($size) = @_;
#
#    return {
#        data_type   => 'char',
#        size        => $size,
#    }
#}
#
#sub isa_Varchar {   ## no critic
#    my ($size) = @_;
#
#    return {
#        data_type   => 'varchar',
#        size        => $size;
#    }
#}
#
#sub isa_ShortInt {  ## no critic
#    return isa_Integer(4);
#}
#
#sub isa_BigInt {    ## no critic
#    return isa_Integer(64);
#}
#
#sub isa_Integer {   ## no critic
#    my ($size) = @_;
#    
#    return {
#        data_type   => 'integer',
#        size        => $size,
#    }
#}
#
__END__


=begin wikidoc

= NAME

Class::Dot::Model::Table - Attach table to class.

= VERSION

This document describes Class::Dot::Model version v%%VERSION%%

= SYNOPSIS

    package My::Model::Cat;
    use Class::Dot::Model::Table qw(:std);

    Table       'cats';
    Columns     qw( id gender dna action colour );
    Primary_Key 'id';
    Has_Many    'memories'
        => 'My::Model::Cat::Memory';
    

= DESCRIPTION

Pretty way of defining a DBIx table class.

= SUBROUTINES/METHODS

== EXPORTED SUBROUTINES

=== {Table $database_table} 
=for apidoc VOID Table(string $database_table)

Set the database table this class should be connected to.

=== {Columns @columns|%$columns}
=for apidoc VOID Columns(ARRAY @columns | HASHREF %$columns)

A list of columns in the database table.

=== {Primary_Key $column_name}
=for apidoc Primary_Key(string $column_name)

Sets which column in the columns above that is the primary key for this table.

See [DBIx::Class::Relationships] for more information on relationships.

=== {Belongs_To $accessor_name => $related_class}
=for apidoc Belongs_To(string $accessor_name, _CLASS $related_class)

Create a belongs to relationship with a parent table.

See [DBIx::Class::Relationships] for more information on relationships.

=== {Has_Many $accessor_name => $related_class}
=for apidoc Has_Many(string $accessor_name, _CLASS $related_class)

Creates a one-to-many releationship with another database table.

See [DBIx::Class::Relationships] for more information on relationships.

=== {Many_To_Many $accessor_name => $link_rel_name, $foreign_rel_name, $opt_attr?}

Creates a many-to-many relationship from one table to another.

== PRIVATE SUBROUTINES

=== {requires()}

Used by L<Class::Dot::Model::Preload> to know which modules this module
requires.

= DIAGNOSTICS

None.

= CONFIGURATION AND ENVIRONMENT

This module uses no external configuration or environment variables.

= DEPENDENCIES

* [DBIx::Class]

* [Class::Dot]

* [Class::Plugin::Util]

* [Params::Util]

* [Config::PlConfig]

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-class-dot-model@rt.cpan.org|mailto:class-dot-model@rt.cpan.org], or through the web interface at
[CPAN Bug tracker|http://rt.cpan.org].

= SEE ALSO

== [Class::Dot::Model]

== [DBIx::Class]

== [Class::Dot]

== [DBIx::Class::Relationships]

== [DBIx::Class::Manual::Cookbook]

= AUTHOR

Ask Solem, [ask@0x61736b.net].

= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem [ask@0x61736b.net|mailto:ask@0x61736b.net].

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc


=for stopwords expandtab shiftround
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround

