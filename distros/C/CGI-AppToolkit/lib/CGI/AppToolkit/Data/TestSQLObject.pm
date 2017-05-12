package CGI::AppToolkit::Data::TestSQLObject;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$CGI::AppToolkit::Data::TestSQLObject::VERSION = '0.05';

use base 'CGI::AppToolkit::Data::SQLObject';
use strict;


#-------------------------------------#

# initialize variables
sub init {
	my $self = shift;
	
	$self->set_table('test_shebang');
	$self->set_index('id');
	$self->set_all_insert_columns([qw/address zip password active verified html/]);
	$self->set_default_insert_columns({'start' => 'now()'});
	$self->set_all_update_columns($self->get_all_insert_columns);
	
	1;
}
	
#-------------------------------------#

# get a prepared db statement
sub get_db_statement_local {
	my $self = shift;
	my $name = shift;
	
	my $db = $self->get_kit->get_dbi();
	
	if ($name eq 'now') {
		return [$db->prepare('select CURRENT_DATE as now'), []];
	} elsif ($name eq 'date/<1') {
		return [$db->prepare('select * from people where birthday < ?'), [qw/date/]];
	}
	
	undef
}

1;

__DATA__

=head1 NAME

CGI::AppToolkit::Data::TestSQLObject - An example object, illustrating how to subclass C<CGI::AppToolkit::Data::SQLObject>.

=head1 SYNOPSIS

  package CGI::AppToolkit::Data::TestSQLObject;

  use base 'CGI::AppToolkit::Data::SQLObject';
  use strict;
  
  #-------------------------------------#
  
  # initialize variables
  sub init {
    my $self = shift;
    
    $self->set_table('test_shebang');
    $self->set_index('id');
    $self->set_all_insert_columns([qw/address zip password active verified html/]);
    $self->set_default_insert_columns({'start' => 'now()'});
    $self->set_all_update_columns($self->get_all_insert_columns);
    
    1;
  }
    
  #-------------------------------------#
  
  # get a prepared db statement
  sub get_db_statement_local {
    my $self = shift;
    my $name = shift;
    
    my $db = $self->get_kit->get_dbi();
    
    if ($name eq 'now') {
      return [$db->prepare('select CURRENT_DATE as now'), []];
    } elsif ($name eq 'date/<1') {
      return [$db->prepare('select * from people where birthday < ?'), [qw/date/]];
    }
    
    undef
  }
  
  1;

=cut