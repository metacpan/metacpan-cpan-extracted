#
#   Copyright (C) 1997, 1998
#   	Free Software Foundation, Inc.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
package Catalog::db;
use strict;

use Catalog::tools::tools;

sub new {
    my($type) = @_;

    my($self) = {};
    bless($self, $type);
    $self->initialize();
    return $self;
}

sub initialize {
    my($self) = @_;

    my($config) = config_load("db.conf");
    error("missing db.conf") if(!defined($config));
    %$self = ( %$self , %$config );

    error("db_type not set") if(!$self->{'db_type'});

    $self->instance_load();
}

sub instance_load {
    my($self) = @_;

    my($db_package) = "Catalog::db::$self->{'db_type'}";

    eval "package Catalog::db::_firesafe; require $db_package";
    if ($@) {
	my($advice) = "";
	if($@ =~ /Can't find loadable object/) {
	    $advice = "Perhaps $db_package was statically linked into a new perl binary."
		 ."\nIn which case you need to use that new perl binary."
		 ."\nOr perhaps only the .pm file was installed but not the shared object file."
	} elsif ($@ =~ /Can't locate.*?.pm/) {
	    $advice = "Perhaps the $db_package perl module hasn't been installed\n";
	}
	error("$db_package failed: $@$advice\n");
    }
    my($instance);
    eval { $instance = $db_package->new() };
    error("$@") unless $instance;

    $self->{'instance'} = $instance;
}

sub connect_error_handler {
    my($self, $func) = @_;

    $self->{'instance'}->{'connect_error_handler'} = $func;
}

sub instance { shift->{'instance'}; }

sub quote { shift->instance()->quote(@_); }
sub date { shift->instance()->date(@_); }
sub datetime { shift->instance()->datetime(@_); }
sub connect { shift->instance()->connect(@_); }
sub logoff { shift->instance()->logoff(@_); }
sub insert { shift->instance()->insert(@_); }
sub dict_update { shift->instance()->dict_update(@_); }
sub mdelete { shift->instance()->mdelete(@_); }
sub update { shift->instance()->update(@_); }
sub tables { shift->instance()->tables(@_); }
sub table_exists { shift->instance()->table_exists(@_); }
sub databases { shift->instance()->databases(@_); }
sub exec_info { shift->instance()->exec_info(@_); }
sub exec { shift->instance()->exec(@_); }
sub select { shift->instance()->select(@_); }
sub exec_select_one { shift->instance()->exec_select_one(@_); }
sub table_schema { shift->instance()->table_schema(@_); }
sub info_table { shift->instance()->info_table(@_); }
sub exec_select { shift->instance()->exec_select(@_); }
sub sexec_select { shift->instance()->sexec_select(@_); }
sub sexec_select_one { shift->instance()->sexec_select_one(@_); }
sub sselect { shift->instance()->sselect(@_); }
sub walk { shift->instance()->walk(@_); }
sub parse_relations { shift->instance()->parse_relations(@_); }
sub dict_link { shift->instance()->dict_link(@_); }
sub dict_add { shift->instance()->dict_add(@_); }
sub dict_value2string { shift->instance()->dict_value2string(@_); }
sub dict_expand { shift->instance()->dict_expand(@_); }
sub dict_select_fix { shift->instance()->dict_select_fix(@_); }

sub resources_load {
    my($self, $name, $package) = @_;

    if(!exists($self->{$name})) {
	my($specific) = $package;
	$specific =~ s/(::\w+)$/::$self->{'db_type'}$1/;
	my(@packages) = ( $specific, $package );
	my($resource);

	foreach $package (@packages) {
	    eval "package Catalog::db::_firesafe; require $package";
	    if(!$@) {
		eval "\$resource = \$" . $package . '::resource';
		last if(defined($resource));
	    }
	}

	error("unable to load any of @packages") if(!defined($resource));
	$self->{$name} = $resource;
    }
}

sub schema {
    my($self, $name, $table) = @_;

    return $self->{$name}->{$table};
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
