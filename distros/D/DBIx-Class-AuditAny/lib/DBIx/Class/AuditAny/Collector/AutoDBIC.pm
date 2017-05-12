package DBIx::Class::AuditAny::Collector::AutoDBIC;
use strict;
use warnings;

# ABSTRACT: Collector class for recording AuditAny changes in auto-generated DBIC schemas

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
extends 'DBIx::Class::AuditAny::Collector::DBIC';

=head1 NAME

DBIx::Class::AuditAny::Collector::AutoDBIC - Collector class for recording AuditAny 
changes in auto-generated DBIC schemas

=head1 DESCRIPTION

This Collector facilitates recording ChangeSets, Changes, and Column Changes within a
clean relational structure into an automatically configured and deployed DBIC schema
using SQLite database files.

This class extends L<DBIx::Class::AuditAny::Collector::DBIC> which provides greater 
flexibility for configuration, can record to different forms of databases and tables,
and so on

=head1 ATTRIBUTES

Docs regarding the API/purpose of the attributes and methods in this class still TBD...

=head2 auto_deploy

=head2 change_data_rel

=head2 change_source_name

=head2 changeset_source_name

=head2 column_change_source_name

=head2 column_data_rel

=head2 deploy_info_source_name

=head2 reverse_change_data_rel

=head2 reverse_changeset_data_rel

=head2 sqlite_db

=head1 METHODS

=head2 get_context_column_infos

=head2 init_schema_namespace

=head2 deploy_schema

=head2 get_clean_md5

=cut

use DBIx::Class::AuditAny::Util;
use DBIx::Class::AuditAny::Util::SchemaMaker;
use String::CamelCase qw(decamelize);
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

has 'connect', is => 'ro', isa => ArrayRef, lazy => 1, default => sub {
	my $self = shift;
	my $db = $self->sqlite_db or die "no 'connect' or 'sqlite_db' specified.";
	return [ "dbi:SQLite:dbname=$db","","", { AutoCommit => 1 } ];
};

has 'sqlite_db', is => 'ro', isa => Maybe[Str], default => sub{undef};
has 'auto_deploy', is => 'ro', isa => Bool, default => sub{1};

has 'target_schema_namespace', is => 'ro', lazy => 1, default => sub {
	my $self = shift;
	return ref($self->AuditObj->schema) . '::AuditSchema';
};

has '+target_schema', default => sub {
	my $self = shift;
	
	my $class = $self->init_schema_namespace;
	my $schema = $class->connect(@{$self->connect});
	$self->deploy_schema($schema) if ($self->auto_deploy);
	
	return $schema;
};

has 'target_source', is => 'ro', isa => Str, lazy => 1, 
 default => sub { (shift)->changeset_source_name };

has 'changeset_source_name', 		is => 'ro', isa => Str, default => sub{'AuditChangeSet'};
has 'change_source_name', 			is => 'ro', isa => Str, default => sub{'AuditChange'};
has 'column_change_source_name',	is => 'ro', isa => Str, default => sub{'AuditChangeColumn'};
has 'deploy_info_source_name',	is => 'ro', isa => Str, default => sub{'DeployInfo'};

has 'changeset_table_name', is => 'ro', isa => Str, lazy => 1, 
 default => sub { decamelize((shift)->changeset_source_name) };
	
has 'change_table_name', is => 'ro', isa => Str, lazy => 1, 
 default => sub { decamelize((shift)->change_source_name) };
	
has 'column_change_table_name',	is => 'ro', isa => Str, lazy => 1, 
 default => sub { decamelize((shift)->column_change_source_name) };

has 'deploy_info_table_name',	is => 'ro', isa => Str, lazy => 1, 
 default => sub { decamelize((shift)->deploy_info_source_name) };

has '+change_data_rel', default => sub{'audit_changes'};
has '+column_data_rel', default => sub{'audit_change_columns'};
has 'reverse_change_data_rel', is => 'ro', isa => Str, default => sub{'change'};
has 'reverse_changeset_data_rel', is => 'ro', isa => Str, default => sub{'changeset'};

has 'changeset_columns', is => 'ro', isa => ArrayRef, lazy => 1,
 default => sub {
	my $self = shift;
	return [
		id => {
			data_type => "integer",
			extra => { unsigned => 1 },
			is_auto_increment => 1,
			is_nullable => 0,
		},
		$self->get_context_column_infos(qw(base set))
	];
};

has 'change_columns', is => 'ro', isa => ArrayRef, lazy => 1,
 default => sub {
	my $self = shift;
	return [
		id => {
			data_type => "integer",
			extra => { unsigned => 1 },
			is_auto_increment => 1,
			is_nullable => 0,
		}, 
		changeset_id => {
			data_type => "integer",
			extra => { unsigned => 1 },
			is_foreign_key => 1,
			is_nullable => 0,
		},
		$self->get_context_column_infos(qw(source change))
	];
};

has 'change_column_columns', is => 'ro', isa => ArrayRef, lazy => 1,
 default => sub {
	my $self = shift;
	return [
		id => {
			data_type => "integer",
			extra => { unsigned => 1 },
			is_auto_increment => 1,
			is_nullable => 0,
		}, 
		change_id => {
			data_type => "integer",
			extra => { unsigned => 1 },
			is_foreign_key => 1,
			is_nullable => 0,
		},
		$self->get_context_column_infos(qw(column))
	];
};

# Gets and validates DBIC column configs per supplied datapoint contexts
sub get_context_column_infos {
	my $self = shift;
	my @DataPoints = $self->AuditObj->get_context_datapoints(@_);
	return () unless (scalar @DataPoints > 0);
	
	my %reserved 		= map {$_=>1} qw(id changeset_id change_id);
	my %no_accessor 	= map {$_=>1} qw(new meta);
	
	my @cols = ();
	foreach my $DataPoint (@DataPoints) {
		my $name = $DataPoint->name;
		my $info = $DataPoint->column_info;
		$reserved{$name}		and die "Bad datapoint name '$name' - reserved keyword.";
		$no_accessor{$name}	and $info->{accessor} = undef;
		push @cols, ( $name => $info );
	}
	
	return @cols;
}


has 'schema_namespace_config', is => 'ro', isa => HashRef, init_arg => undef, lazy => 1,
 default => sub {
	my $self = shift;
	
	my $ColumnName = $self->AuditObj->get_datapoint_orig('column_name');
	my $col_context_uniq_const = $ColumnName ? 
		[ add_unique_constraint => ["change_id", ["change_id", $ColumnName->name]] ] : [];

	my $namespace = $self->target_schema_namespace;
	return {
		schema_namespace => $namespace,
		results => {
			$self->deploy_info_source_name => {
				table_name => $self->deploy_info_table_name,
				columns => [
					md5 => { 
						data_type => "char", 
						is_nullable => 0, 
						size => 32 
					},
					comment => { 
						data_type => "varchar", 
						is_nullable => 0, 
						size => 255 
					},
					deployed_ddl => {
						data_type	=> 'mediumtext',
						is_nullable	=> 0
					},
					deployed_ts	=> { 
						data_type => "datetime", 
						datetime_undef_if_invalid => 1, 
						is_nullable => 0 
					},
					auditany_params => {
						data_type	=> 'mediumtext',
						is_nullable	=> 0
					},
				],
				call_class_methods => [
					set_primary_key => ['md5'],
				]
			},
			$self->changeset_source_name => {
				table_name => $self->changeset_table_name,
				columns => $self->changeset_columns,
				call_class_methods => [
					set_primary_key => ['id'],
					has_many => [
						$self->change_data_rel,
						$namespace . '::' . $self->change_source_name,
						{ "foreign.changeset_id" => "self.id" },
						{ cascade_copy => 0, cascade_delete => 0 },
					]
				]
			},
			$self->change_source_name => {
				table_name => $self->change_table_name,
				columns => $self->change_columns,
				call_class_methods => [
					set_primary_key => ['id'],
					belongs_to => [
						$self->reverse_changeset_data_rel,
						$namespace . '::' . $self->changeset_source_name,
						{ id => "changeset_id" },
						{ is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
					],
					has_many => [
						$self->column_data_rel,
						$namespace . '::' . $self->column_change_source_name,
						{ "foreign.change_id" => "self.id" },
						{ cascade_copy => 0, cascade_delete => 0 },
					]
				]
			},
			$self->column_change_source_name => {
				table_name => $self->column_change_table_name,
				columns => $self->change_column_columns,
				call_class_methods => [
					set_primary_key => ['id'],
					@$col_context_uniq_const,
					#add_unique_constraint => ["change_id", ["change_id", "column_name"]],
					belongs_to => [
						  $self->reverse_change_data_rel,
							$namespace . '::' . $self->change_source_name,
							{ id => "change_id" },
							{ is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
					],
				]
			}
		}
	};
};

sub init_schema_namespace {
	my $self = shift;
	
	#scream($self->schema_namespace_config);
	
	return DBIx::Class::AuditAny::Util::SchemaMaker->initialize(
		%{ $self->schema_namespace_config }
	);
}


sub deploy_schema {
	my $self = shift;
	my $schema = shift;
	
	my $deploy_statements = $schema->deployment_statements;
	my $md5 = $self->get_clean_md5($deploy_statements);
	my $Rs = $schema->resultset($self->deploy_info_source_name);
	my $table = $Rs->result_source->from;
	my $deployRow;
	
	try {
		$deployRow = $Rs->find($md5);
	}
	catch {
		# Assume exception is due to not being deployed yet and try to deploy:
		$schema->deploy;
		
		# Save the actual AuditAny params, ->track() or ->new():
		local $Data::Dumper::Maxdepth = 3;
		my $auditany_params = $self->AuditObj->track_init_args ?
			Data::Dumper->Dump([$self->AuditObj->track_init_args],['*track']) :
			Data::Dumper->Dump([$self->AuditObj->build_init_args],['*new']);
			
		$Rs->create({
			md5					=> $md5,
			comment				=> 'DO NOT REMOVE THIS ROW',
			deployed_ddl		=> $deploy_statements,
			deployed_ts			=> $self->AuditObj->get_dt,
			auditany_params	=> $auditany_params
		});
	};
	
	# If we've already been deployed and the ddl checksum matches:
	return 1 if ($deployRow);
	
	my $count = $Rs->count;
	my $dsn = $self->connect->[0];
	
	die "Database error; deploy_info table ('$table') exists but is empty in audit database '$dsn'"
		unless ($count > 0);
		
	die "Database error; multiple rows in deploy_info table ('$table') in audit database '$dsn'"
		if ($count > 1);
	
	my $exist_md5 = $Rs->first->md5 or die "Database error; found deploy_info row in table '$table' " .
	 "in audit database '$dsn', but it appears to be corrupt (no md5 checksum).";
	 
	return 1 if ($md5 eq $exist_md5);
	
	die "\n\n" . join("\n",
	 "  The selected audit database '$dsn' already has a",
	 "  deployed Collector::AutoDBIC schema (md5 checksum: $exist_md5) but it does",
	 "  not match the current auto-generated schema (md5 checksum: $md5).",
	 "  This probably means datapoints or other options have been changed since this AutoDBIC ",
	 "  audit database was deployed. If you're not worried about existing audit logs, you can ",
	 "  fix this error by simply clearing/deleting the audit database so it can be reinitialized."
	) . "\n\n";
}

# Need to strip out comments and blank lines to make sure the md5s will be consistent
sub get_clean_md5 {
	my $self = shift;
	my $deploy_statements = shift;
	my $clean = join("\n", grep { ! /^\-\-/ && ! /^\s*$/ } split(/\r?\n/,$deploy_statements) );
	return md5_hex($clean);
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
