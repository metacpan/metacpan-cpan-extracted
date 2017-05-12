package DBIx::Class::MaterializedPath;
{
  $DBIx::Class::MaterializedPath::VERSION = '0.002001';
}

# ABSTRACT: efficiently retrieve and search trees with DBIx::Class

use strict;
use warnings;

use Module::Runtime 'use_module';
use Try::Tiny;
use base 'DBIx::Class::Helper::Row::OnColumnChange';

use English;

use Class::C3::Componentised::ApplyHooks
   -before_apply => sub {
      die 'class (' . $_[0] . ') must implement materialized_path_columns method!'
         unless $_[0]->can('materialized_path_columns')
   },
   -after_apply => sub {
      my %mat_paths = %{$_[0]->materialized_path_columns};

      for my $path (keys %mat_paths) {
         $_[0]->_install_after_column_change($mat_paths{$path});
         $_[0]->_install_full_path_rel($mat_paths{$path});
         $_[0]->_install_reverse_full_path_rel($mat_paths{$path});
      }
   };

sub insert {
   my $self = shift;

   my $ret = $self->next::method;

   my %mat_paths = %{$ret->materialized_path_columns};
   for my $path (keys %mat_paths) {
      $ret->_set_materialized_path($mat_paths{$path});
   }

   return $ret;
}

sub _set_materialized_path {
   my ($self, $path_info) = @_;

   my $parent     = $path_info->{parent_column};
   my $parent_fk  = $path_info->{parent_fk_column};
   my $path       = $path_info->{materialized_path_column};
   my $parent_rel = $path_info->{parent_relationship};

   # XXX: Is this completely necesary?
   $self->discard_changes;

   my $path_separator = $path_info->{separator} || '/';
   if ($self->get_column($parent)) { # if we aren't the root
      $self->set_column($path,
         $self->$parent_rel->get_column($path) .
            $path_separator .
            $self->get_column($parent_fk)
      );
   } else {
      $self->set_column($path, $self->$parent_fk );
   }

   $self->update
}

sub _install_after_column_change {
   my ($self, $path_info) = @_;

   my $method;

   if ($PERL_VERSION >= 5.016) {
      require DBIx::Class::MaterializedPath::NativeRecursion;
   } else {
      require DBIx::Class::MaterializedPath::SubCurrentRecursion;
   }

   $method = $self->_get_column_change_method( $path_info );

   for my $column (map $path_info->{$_}, qw(parent_column materialized_path_column)) {
      $self->after_column_change($column => {
         txn_wrap => 1,

         # XXX: is it worth installing this?
         method => $method,
      })
   }
}

sub _introspector {
   my $d = use_module('DBIx::Introspector')
      ->new(drivers => '2013-12.01');

   $d->decorate_driver_unconnected(MSSQL => concat_sql => sub { '%s + %s' });
   $d->decorate_driver_unconnected(mysql => concat_sql => sub { 'CONCAT( %s, %s )' });

   $d
}

my $d;
sub _get_concat {
   my ($self, $rsrc, @substrings) = @_;

   my $storage = $rsrc->storage;
   $storage->ensure_connected;

   $d ||= $self->_introspector;

   my $format = try { $d->get($storage->dbh, undef, 'concat_sql') } catch { '%s || %s' };

   return sprintf $format, @substrings;
}

sub _install_full_path_rel {
   my ($self, $path_info) = @_;

   $self->has_many(
      $path_info->{full_path} => $self,
      sub {
         my $args = shift;

         my $path_separator = $path_info->{separator} || '/';
         my $rest = "$path_separator%";

         my $fk = $path_info->{parent_fk_column};
         my $mp = $path_info->{materialized_path_column};
         my @me = (
            $path_info->{include_self_in_path}
            ?  {
               "$args->{self_alias}.$fk" => { -ident => "$args->{foreign_alias}.$fk" }
            }
            : ()
         );
         my $concat = $self->_get_concat(
            $args->{self_resultsource},
            "$args->{foreign_alias}.$mp",
            q{?},
         );

         return ([{
               "$args->{self_alias}.$mp" => {
                  # TODO: add stupid storage mapping
                  -like => \[$concat,
                     [ {} => $rest ]
                  ],
               }
            },
            @me
         ],
         $args->{self_rowobj} && {
            "$args->{foreign_alias}.$fk" => {
               -in => [
                  grep {
                     $path_info->{include_self_in_path}
                        ||
                      $_ ne $args->{self_rowobj}->$fk
                  # TODO: should we use accessor instead of direct $mp?
                  } split qr(\Q$path_separator\E), $args->{self_rowobj}
                     ->get_column($mp)
               ]
            },
         });
      }
   );
}

sub _install_reverse_full_path_rel {
   my ($self, $path_info) = @_;

   $self->has_many(
      $path_info->{reverse_full_path} => $self,
      sub {
         my $args = shift;

         my $path_separator = $path_info->{separator} || '/';
         my $rest = "$path_separator%";

         my $fk = $path_info->{parent_fk_column};
         my $mp = $path_info->{materialized_path_column};

         my @me = (
            $path_info->{include_self_in_reverse_path}
            ?  {
               "$args->{foreign_alias}.$fk" => { -ident => "$args->{self_alias}.$fk" }
            }
            : ()
         );
         my $concat = $self->_get_concat(
            $args->{self_resultsource},
            "$args->{self_alias}.$mp",
            q{?},
         );
         return [{
            "$args->{foreign_alias}.$mp" => {
               -like => \[$concat,
                  [ {} => $rest ]
               ],
            }
         }, @me ]
      }
   );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::MaterializedPath - efficiently retrieve and search trees with DBIx::Class

=head1 VERSION

version 0.002001

=head1 SYNOPSIS

 package A::Schema::Result::Category;

 use strict;
 use warnings;

 use base 'DBIx::Class::Core';

 __PACKAGE__->table('category');

 __PACKAGE__->load_components('MaterializedPath');

 __PACKAGE__->add_columns(
    id => {
       data_type => 'int',
       is_auto_increment => 1,
    },

    parent_id => {
       data_type => 'int',
       is_nullable => 1, # root
    },

    parent_path => {
       data_type => 'varchar',
       size      => 256,
       is_nullable => 1,
    },

    name => {
       data_type => 'varchar',
       size      => 256,
    },
 );

 __PACKAGE__->set_primary_key('id');

 __PACKAGE__->belongs_to(
   parent_category => 'A::Schema::Result::Category', 'parent_id'
 );

 __PACKAGE__->has_many(
   child_categories => 'A::Schema::Result::Category', 'parent_id'
 );

 sub materialized_path_columns {
    return {
       parent => {
          parent_column                => 'parent_id',
          parent_fk_column             => 'id',
          materialized_path_column     => 'parent_path',
          include_self_in_path         => 1,
          include_self_in_reverse_path => 1,
          separator                    => '/',
          parent_relationship          => 'parent_category',
          children_relationship        => 'child_categories',
          full_path                    => 'ancestors',
          reverse_full_path            => 'descendants',
       },
    }
 }

 1;

Elsewhere...

 my $child_rows = $row->descendants;

or better yet

 my $awesome_kids = $rs->search({ awesome => 1 })
   ->related_resultset('descendants');

=head1 DESCRIPTION

L<Materialized path|https://communities.bmc.com/communities/docs/DOC-9902> is a
way to store trees in relational databases that results in very efficient
retrieval, at the expense of space and more write-time queries.

This module makes using matpaths easy.  The interface is somewhat unusual, but
the benefit is that it creates actual relationships for the both directions of
the tree, allowing you to use the powerful querying L<DBIx::Class> already gives
you.

The first strange part of the interface is that the call to C<load_components>
B<must> come after the call to C<table>.  The next strange bit is that the way
you define all of the metadata about your matpath is by defining a subroutine
called C<materialized_path_columns>.  The subroutine must return a hashref
where the key is name of your path (currently unused) and the value is the
metadata for the path.  Here are the parts that need to be defined in the
metadata:

=over 2

=item * C<parent_column> - the column that points directly to the parent row,
for example C<parent_id>.

=item * C<parent_fk_column> - the column that C<parent_column> points to, for
example C<id>.

=item * C<materialized_path_column> - the column that contains the materialized
path.  One thing to note here is that the B<width> of the column defines how
deep your tree can be.  For example if the number of digits for most of your
C<id>'s is three, and your materialized path column is 255 characters wide, you
can support a depth of something like 63 levels, because each level in the tree
is C<< q(/) . "$id" >>, so C<< 255/4 ~~ 63 >>.  An example for this might be
C<parent_materialized_path>.

=item * C<parent_relationship> - the direct relationship to your parent row

=item * C<children_relationship> - the direct relationship to your child rows

=item * C<full_path> - the name of the relationship that this materialized path
will define for all parents.  For example, C<ancestry>.

=item * C<reverse_full_path> - the name of the relationship that this
materialized path will define for all children.  For example, C<descendants>.

=item * C<include_self_in_path> - (optional) I've found that it's often
helpful to include the current row in the full ancestry.  For example if
your path is a for categorization system you probably want to turn this on.

=item * C<include_self_in_reverse_path> - (optional) see above, but for chilren
instead of parents

=item * C<separator> - (optional) defaults to C</>.  If you don't know what
this is for just ignore it.

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
