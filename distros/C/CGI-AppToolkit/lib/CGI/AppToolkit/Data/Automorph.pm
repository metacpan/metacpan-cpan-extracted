package CGI::AppToolkit::Data::Automorph;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$CGI::AppToolkit::Data::Automorph::VERSION = '0.05';

use base 'CGI::AppToolkit::Data::SQLObject';
use strict;

#-------------------------------------#
# OO Methods                          #
#-------------------------------------#

sub init {
	my $self = shift;
	
	my $key_map = $self->get_key_map() || {};
	
	if ($self->{'table'}) {
		$self->{'index'} = 'id';
	} else {
		$self->{'table'} = $self->init_table() || return undef;
	}
	
	my $sql = 'select * from ' . $self->{'table'};
	my $db = $self->get_kit->get_dbi();
	my $sth = $db->prepare($sql);
	my $statement = [$sth, []];
	$self->set_db_statement('-all', $statement);
	
	$sth->execute();
	
	$self->{'all_columns'} = [grep {$_ ne $self->{'index'}} @{$sth->{'NAME_lc'}}];

	$self->{'column_types'} = {};
	@{$self->{'column_types'}}{@{$self->{'all_columns'}}} = map {$db->type_info($_)->{'TYPE_NAME'}} @{$sth->{'TYPE'}};

	$self->{'column_max_size'} = {};
	@{$self->{'column_max_size'}}{@{$self->{'all_columns'}}} = @{$sth->{'PRECISION'}};

	$self->{'column_scale'} = {};
	@{$self->{'column_scale'}}{@{$self->{'all_columns'}}} = @{$sth->{'SCALE'}};

	$self->{'column_nullable'} = {};
	@{$self->{'column_nullable'}}{@{$self->{'all_columns'}}} = @{$sth->{'NULLABLE'}};

	if (ref $self->{'default_insert_columns'} eq 'HASH') {
		$self->{'all_insert_columns'} = [grep {! exists $self->{'default_insert_columns'}->{$_}} @{$self->{'all_columns'}}];
	}

	if (ref $self->{'default_update_columns'} eq 'HASH') {
		$self->{'all_update_columns'} = [grep {! exists $self->{'default_update_columns'}->{$_}} @{$self->{'all_columns'}}];
	}
	
	$sth->finish();
	
	1;
}



#-------------------------------------#

# init_table -- if we get here (this method is not overriden)
# then we don't know what table we are getting data from.
sub init_table {
	my $self = shift;
	
	$CGI::AppToolkit::Data::ERROR = "CGI::AppToolkit::Data::init_table: I don't know what table you want data from, called";

	undef
}



#-------------------------------------#

# get a prepared db statement
sub get_db_statement_local {
	my $self = shift;
	my $name = shift;
	
	my $db = $self->get_kit->get_dbi();
	
	if ($name eq 'now') {
		return [$db->prepare('select CURRENT_DATE as now'), []];
	}
	
	undef
}

1;
__DATA__

=head1 NAME

B<CGI::AppToolkit::Data::Automorph> - A SQL data source component of L<B<CGI::AppToolkit>|CGI::AppToolkit> that inherits from L<B<CGI::AppToolkit::Data::SQLObject>|CGI::AppToolkit::Data::SQLObject> and adds the ability to 'interrogate' the DBD to gather information about the database table. You can occasionally use B<CGI::AppToolkit::Data::Automorph> directly. For most projects, you shoould still create a module that inherits from B<CGI::AppToolkit::Data::Automorph>, often only overriding two methods.

=head1 DESCRIPTION

=over 4

=item B<init_table()>

This is the equivalent to B<init()> from B<CGI::AppToolkit::Data::SQLObject>, which B<CGI::AppToolkit::Data::Automorph> overrides and calls this method from. You must at set the B<index> parameter from here, if you override this method. See L<B<CGI::AppToolkit::Data::SQLObject-E<gt>init()>|CGI::AppToolkit::Data::SQLObject/"item_init">.

=item B<get_db_statement_local()>

See L<B<CGI::AppToolkit::Data::SQLObject-E<gt>get_db_statement_local()>|CGI::AppToolkit::Data::SQLObject/"item_get_db_statement_local">.

=back

=head1 AUTHOR

Copyright 2002 Robert Giseburt (rob@heavyhosting.net).  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please visit http://www.heavyhosting.net/AppToolkit/ for complete documentation.

=cut