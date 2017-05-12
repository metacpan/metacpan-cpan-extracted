use strict;
use Test;
BEGIN { plan tests => 31 }
use Config::Natural;

# check that the following functions are available
ok( exists &Config::Natural::new );       #01
ok( exists &Config::Natural::options );   #02

# create an object
my $obj = new Config::Natural;
ok( ref $obj and $obj->isa('Config::Natural') );  #03

# check that the following object methods are available
ok( ref $obj->can('options') );         #04
ok( ref $obj->can('read_source') );     #05
ok( ref $obj->can('write_source') );    #06
ok( ref $obj->can('param') );           #07
ok( ref $obj->can('all_parameters') );  #08
ok( ref $obj->can('delete') );          #09
ok( ref $obj->can('delete_all') );      #10
ok( ref $obj->can('clear') );           #11
ok( ref $obj->can('clear_params') );    #12
ok( ref $obj->can('dump_param') );      #13
ok( ref $obj->can('set_handler') );     #14
ok( ref $obj->can('has_handler') );     #15
ok( ref $obj->can('delete_handler') );  #16
ok( ref $obj->can('filter') );          #17
ok( ref $obj->can('value_of') );        #18
ok( ref $obj->can('param_tree') );      #19

# check that all the accessors are present
ok( defined $obj->comment_line_symbol );    #20
ok( defined $obj->affectation_symbol );     #21
ok( defined $obj->multiline_begin_symbol ); #22
ok( defined $obj->multiline_end_symbol );   #23
ok( defined $obj->list_begin_symbol );      #24
ok( defined $obj->list_end_symbol );        #25
ok( defined $obj->include_symbol );         #26
ok( defined $obj->case_sensitive );         #27
ok( defined $obj->auto_create_surrounding_list );  #28
ok( defined $obj->read_hidden_files );      #29
ok( defined $obj->strip_indentation );      #30

# delete an object
undef $obj;
ok( $obj, undef );  #31
