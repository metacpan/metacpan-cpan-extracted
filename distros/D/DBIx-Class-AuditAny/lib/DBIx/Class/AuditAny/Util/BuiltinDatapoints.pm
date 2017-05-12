package # Hide from PAUSE 
    DBIx::Class::AuditAny::Util::BuiltinDatapoints;

# ABSTRACT: Built-in datapoint configs for DBIx::Class::AuditAny

=head1 NAME

DBIx::Class::AuditAny::Util::BuiltinDatapoints - Built-in datapoint configs for DBIx::Class::AuditAny

=head1 DESCRIPTION

These are just lists of predefined hashref configs ($cnf) - DataPoint constructor arg
i.e. my $DataPoint = DBIx::Class::AuditAny::DataPoint->new(%$cnf);

This module is used internally and should not need to be called directly

=head1 METHODS

=cut

use strict;
use warnings;


=head2 all_configs

Return all the builtin configs

=cut
sub all_configs {(
	&_base_context,
	&_source_context,
	&_set_context,
	&_change_context,
	&_column_context,
)}


sub _base_context {
	map {{ context => 'base', %$_ }} (
		{
			name 			=> 'schema', 
			method		=> sub { ref((shift)->AuditObj->schema) },
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 255 } 
		},
		{
			name 			=> 'schema_ver', 
			method		=> sub { (shift)->AuditObj->schema->schema_version },
			column_info	=> { data_type => "varchar", is_nullable => 1, size => 16 } 
		}
	)
}

# set 'method' as a direct passthrough to $Context->'name' per default (see DataPoint class)
sub _source_context {
	map {{ context => 'source', method => $_->{name}, %$_ }} (
		{
			name 			=> 'source', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 255 } 
		},
		{
			name 			=> 'class', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 255 } 
		},
		{
			name 			=> 'from_name', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 128 } 
		},
		{
			name 			=> 'table_name', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 128 } 
		},
		{
			name 			=> 'pri_key_column', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 64 } 
		},
		{
			name 			=> 'pri_key_count', 
			column_info	=> { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 } 
		}
	)
}

# set 'method' as a direct passthrough to $Context->'name' per default (see DataPoint class)
sub _set_context {
	map {{ context => 'set', method => $_->{name}, %$_ }} (
		{
			name 			=> 'changeset_ts', 
			column_info	=> { 
				data_type => "datetime",
				datetime_undef_if_invalid => 1,
				is_nullable => 0
			} 
		},
		{
			name 			=> 'changeset_finish_ts', 
			column_info	=> { 
				data_type => "datetime",
				datetime_undef_if_invalid => 1,
				is_nullable => 0
			} 
		},
		{
			name 			=> 'changeset_elapsed', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 16 } 
		},
	)
}

# set 'method' as a direct passthrough to $Context->'name' per default (see DataPoint class)
sub _change_context {
	map {{ context => 'change', method => $_->{name}, %$_ }} (
		{
			name 			=> 'change_ts', 
			column_info	=> { 
				data_type => "datetime",
				datetime_undef_if_invalid => 1,
				is_nullable => 0
			} 
		},
		{
			name 			=> 'action', 
			column_info	=> { data_type => "char", is_nullable => 0, size => 6 }
		},
		{
			name 			=> 'action_id', 
			column_info	=> { data_type => "integer", is_nullable => 0 }
		},
		{
			name 			=> 'pri_key_value', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 255 } 
		},
		{
			name 			=> 'orig_pri_key_value', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 255 } 
		},
		{
			name 			=> 'change_elapsed', 
			column_info	=> { data_type => "varchar", is_nullable => 0, size => 16 } 
		},
		{
			name 			=> 'column_changes_json', 
			column_info	=> { data_type => "mediumtext", is_nullable => 1 } 
		},
		{
			name 			=> 'column_changes_ascii', 
			column_info	=> { data_type => "mediumtext", is_nullable => 1 } 
		},
	)
}

# set 'method' as a direct passthrough to $Context->'name' per default (see DataPoint class)
sub _column_context {
	map {{ context => 'column', method => $_->{name}, %$_ }} (
		{
			name 			=> 'column_name', 
			column_info	=>  { data_type => "varchar", is_nullable => 0, size => 128 } 
		},
		{
			name 			=> 'old_value', 
			column_info	=> { data_type => "mediumtext", is_nullable => 1 } 
		},
		{
			name 			=> 'new_value', 
			column_info	=> { data_type => "mediumtext", is_nullable => 1 } 
		},
		
		# TODO: add 'diff' datapoint
		
	)
}


1;

__END__

=head1 SEE ALSO

=over

=item *

L<DBIx::Class::AuditAny>

=item *

L<DBIx::Class>

=back

=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut