{
    package Class::DBI::FormBuilder::DBI::Test;
    use base 'Class::DBI';
    use Class::DBI::FormBuilder PrettyPrint => 1;
    # use the db set up in 01.create.t
    Class::DBI::FormBuilder::DBI::Test->set_db("Main", "dbi:SQLite2:dbname=test.db");
}

{   # might_have
    package Job;
    use base 'Class::DBI::FormBuilder::DBI::Test';
    Job->table( 'job' );
    Job->columns( All => qw/id person jobtitle employer salary/ );
    Job->columns( Stringify => qw/jobtitle/ );  
    Job->has_a( person => 'Person' );  
}
 
{   # has_a
    package Town;
    use base 'Class::DBI::FormBuilder::DBI::Test';
    #Town->form_builder_defaults( { smartness => 3 } );
    Town->table("town");
    Town->columns(All => qw/id name pop lat long country/);
    Town->columns(Stringify => qw/name/);
}

{   # has_many
    # this one must be declared before Person, because Person will 
    # examine the has_a in Toy when setting up its has_many toys.
    package CDBIFB::Toy;
    use base 'Class::DBI::FormBuilder::DBI::Test';
    CDBIFB::Toy->table('toy');
    CDBIFB::Toy->columns( All => qw/id person name descr/ );
    CDBIFB::Toy->columns( Stringify => qw/name/ );
    CDBIFB::Toy->has_a( person => 'Person' );
}

{    
    package Person;
    use base 'Class::DBI::FormBuilder::DBI::Test';
    #Person->form_builder_defaults( { smartness => 3 } );
    Person->table("person");
    Person->columns(All => qw/id name town street/);
    Person->columns(Stringify => qw/name/);
    Person->has_a( town => 'Town' );
    Person->has_many( toys => 'CDBIFB::Toy' );
    Person->might_have( job => Job => qw/jobtitle employer salary/ );
}

{    
    package Wackypk;
    use base 'Class::DBI::FormBuilder::DBI::Test';
    Wackypk->table("wackypk");
    # wooble is the pk
    Wackypk->columns(All => qw/flooble wooble flump poo/);
    Wackypk->columns(Primary => 'wooble'); # or put wooble 1st in the list above
}

{
    package CDBIFB::Alias;
    use base 'Class::DBI::FormBuilder::DBI::Test';
    CDBIFB::Alias->table( 'alias' );
    CDBIFB::Alias->columns(All => qw/id colour fruit town/);
    CDBIFB::Alias->columns(Stringify => 'fruit' );
    
    CDBIFB::Alias->has_a( town => 'Town' );
    
    CDBIFB::Alias->has_many( alias_has_many => 'AliasHasMany' );
    CDBIFB::Alias->might_have( job => Job => qw/jobtitle employer salary/ );
    
    
    sub accessor_name { "get_$_[1]" } # deprecated somewhere
    sub mutator_name  { "set_$_[1]" } # deprecated somewhere
    sub accessor_name_for { "get_$_[1]" }
    sub mutator_name_for  { "set_$_[1]" }
}

{
    package AliasHasMany;
    use base 'Class::DBI::FormBuilder::DBI::Test';
    AliasHasMany->table( 'alias_has_many' );
    AliasHasMany->columns( All => qw/id alias foo/ );
    AliasHasMany->columns( Stringify => 'foo' );
    AliasHasMany->has_a( alias => 'CDBIFB::Alias' );
}    
    
    
1;
