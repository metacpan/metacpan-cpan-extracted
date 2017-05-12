# NAME

Chef::REST::Client

# VERSION

1.1

# SYNOPSIS

use Chef::REST::Client;

	my $obj = new Chef::REST::Client
   	       ( 'chef\_client\_name' => $chef\_client\_name )
	$obj->name( $chef\_client\_name );
  	$obj->roles('vagrant')->details;
  	$obj->roles('vagrant','environments')->details
  	$obj->roles->list;
   

  	$obj->search( 'secrets' , {  q => 'id:centrify', rows => 1 } )->details
    

  	$obj->environments(<env_name>,'cookbooks' , <cookbook_name>)->details;

  	$obj->environments(<env_name>,'cookbooks_versions'
                                 ,{ 'method' => 'post'
                                 , 'data' => { 'runlist' => [ 'ms-scribe'] }
                                   }
                      );
 	$obj->roles(<role_name>)->details->override_attributes;
                    

# DESCRIPTION

This is the interface to the Chef server api methods listed on opscode documentation 
[opscode Chef Api](http://docs.opscode.com/api\_chef\_server.html)
currently it provides implementation for only GET methods

# METHODS

## role( $role )

returns new [Chef::REST::Client::role](http://search.cpan.org/perldoc?Chef::REST::Client::role) object
used by other classes

## roles ( @roles )

makes a GET request to the chef server for all the @roles and returns and [Chef::REST::Client::roles](http://search.cpan.org/perldoc?Chef::REST::Client::roles) object.
you can directly get details for all the roles as $obj->role( 'role1', 'role2' )->details;

this inturn will return [Chef::REST::Client::role](http://search.cpan.org/perldoc?Chef::REST::Client::role) 

	/roles

	$obj->roles->list 

	/roles/<role\_name>

	$obj->roles(<role\_name>)->details

	$obj->roles(<role\_name>)->details->run\_list;

	$obj->roles(<role\_name>)->details->override\_attributes;

## runlist ( @$recipes )

returns new [Chef::REST::Client::runlist](http://search.cpan.org/perldoc?Chef::REST::Client::runlist) object. it takes a list of recipies as parameter.
used by other classes

## sandboxes

returns new [Chef::REST::Client::sandboxes](http://search.cpan.org/perldoc?Chef::REST::Client::sandboxes) object. $obj->sandboxes->list;

	/sandboxes

	$obj->sandboxes->list 

	/sandboxes/<id>

	$obj->sandboxes(<id>)->details

## search

returns new [Chef::REST::Client::search](http://search.cpan.org/perldoc?Chef::REST::Client::search) 

	/search

	$obj->search->listen

	/search/<index>

	$obj->search(<index>)->details

	/search/ query id:centrify and get rows 1

	$obj->search( 'secrets' , {  q => 'id:centrify', rows => 1 } )->details

## recipe

returns new [Chef::REST::Client::recipe](http://search.cpan.org/perldoc?Chef::REST::Client::recipe) object. used by other classes

## principals

returns new [Chef::REST::Client::principals](http://search.cpan.org/perldoc?Chef::REST::Client::principals) object. $obj->principals->details;

	/principals

	$obj->principals->list 

	/principals/<name>

	$obj->principals(<name>)->details

## node

returns new [Chef::REST::Client::node](http://search.cpan.org/perldoc?Chef::REST::Client::node) object. $obj->node->details;
used by other classes
 

## nodes

returns new [Chef::REST::Client::nodes](http://search.cpan.org/perldoc?Chef::REST::Client::nodes) object. $obj->nodes->list;

	/nodes

	$obj->nodes->listen

	/nodes/<node\_name>

	$obj->nodes(<node\_name>)->details 

## envrunlist

returns new [Chef::REST::Client::envrunnlist](http://search.cpan.org/perldoc?Chef::REST::Client::envrunnlist) object. used by other classes

## environment

returns new [Chef::REST::Client::environment](http://search.cpan.org/perldoc?Chef::REST::Client::environment) object. used by other classes

## environments

returns new [Chef::REST::Client::environments](http://search.cpan.org/perldoc?Chef::REST::Client::environments) object.

	/environment/<env\_name>

	$obj->environments(<env\_name>)->details;

	/environment/<env\_name>/cookbooks/<cookbook\_name>

	$obj->environments(<env\_name>,'cookbooks' , <cookbook\_name>)->details;

	/environment/<env\_name>/cookbooks

	$obj->environments(<env\_name>,'cookbooks')

	POST /environments/<env\_name>/cookbooks\_versions

	$obj->environments(<env\_name>,'cookbooks\_versions'
        	                     ,{ 'method' => 'post'
                	              , 'data' => { 'runlist' => \[ 'ms-scribe'\] }
                        	      }
                   	);

## databag

returns new [Chef::REST::Client::databag](http://search.cpan.org/perldoc?Chef::REST::Client::databag) object.

## data

returns new [Chef::REST::Client::data](http://search.cpan.org/perldoc?Chef::REST::Client::data) object.

	/data

	$obj->data->list

	/data/<var\_name>

	$obj->data( <var\_name> )->details

## cookbook

returns new [Chef::REST::Client::cookbook](http://search.cpan.org/perldoc?Chef::REST::Client::cookbook) object.

## cookbooks

returns new [Chef::REST::Client::cookbooks](http://search.cpan.org/perldoc?Chef::REST::Client::cookbooks) object.

	/cookbooks

	$obj->cookbooks->list 

	/cookbooks/<cookbook\_name>

	$obj->cookbooks(<cookbook\_name>)->details 

	$obj->cookbooks(<cookbook\_name> , '\_latest' )->details->recipes;

	$obj->cookbooks(<cookbook\_name> , '\_latest' )->details->attributes;

## cookbook\_version

returns new [Chef::REST::Client::cookbook\_version](http://search.cpan.org/perldoc?Chef::REST::Client::cookbook\_version) object.
used by other classes

## cookbook\_versions

returns new [Chef::REST::Client::cookbook\_versions](http://search.cpan.org/perldoc?Chef::REST::Client::cookbook\_versions) object.
collection of [Chef::REST::Client::cookbook\_version](http://search.cpan.org/perldoc?Chef::REST::Client::cookbook\_version)

## clients

returns new [Chef::REST::Client::clients](http://search.cpan.org/perldoc?Chef::REST::Client::clients) object.

	/clients

	$obj->clients->list 

	/clients/<client\_name>/

	$obj->clients(<client\_name>)->details



## attribute

returns new [Chef::REST::Client::attribute](http://search.cpan.org/perldoc?Chef::REST::Client::attribute) object.
used by other classes to structure data

## attributes

returns new [Chef::REST::Client::attributes](http://search.cpan.org/perldoc?Chef::REST::Client::attributes) object.
collection of [Chef::REST::Client::attribute](http://search.cpan.org/perldoc?Chef::REST::Client::attribute)

# KNOWN BUGS

# SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

# COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)
