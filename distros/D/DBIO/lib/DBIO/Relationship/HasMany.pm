package DBIO::Relationship::HasMany;
# ABSTRACT: Declare a one-to-many relationship

use strict;
use warnings;
use Try::Tiny;
use namespace::clean;

our %_pod_inherit_config =
  (
   class_map => { 'DBIO::Relationship::HasMany' => 'DBIO::Relationship' }
  );


sub has_many {
  my ($class, $rel, $f_class, $cond, $attrs) = @_;

  unless (ref $cond) {

    my $pri = $class->result_source_instance->_single_pri_col_or_die;

    my ($f_key,$guess);
    if (defined $cond && length $cond) {
      $f_key = $cond;
      $guess = "caller specified foreign key '$f_key'";
    } else {
      $class =~ /([^\:]+)$/;  # match is safe - $class can't be ''
      $f_key = lc $1; # go ahead and guess; best we can do
      $guess = "using our class name '$class' as foreign key source";
    }

# FIXME - this check needs to be moved to schema-composition time...
#    # only perform checks if the far side appears already loaded
#    if (my $f_rsrc = try { $f_class->result_source_instance } ) {
#      $class->throw_exception(
#        "No such column '$f_key' on foreign class ${f_class} ($guess)"
#      ) if !$f_rsrc->has_column($f_key);
#    }

    $cond = { "foreign.${f_key}" => "self.${pri}" };
  }

  my $default_cascade = ref $cond eq 'CODE' ? 0 : 1;

  $class->add_relationship($rel, $f_class, $cond, {
    accessor => 'multi',
    join_type => 'LEFT',
    cascade_delete => $default_cascade,
    cascade_copy => $default_cascade,
    is_depends_on => 0,
    %{$attrs||{}}
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Relationship::HasMany - Declare a one-to-many relationship

=head1 VERSION

version 0.900001

=head1 METHODS

=head2 has_many

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
