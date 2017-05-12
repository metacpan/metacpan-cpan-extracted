
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 35;

use Class::DBI::FormBuilder::DBI::Test; 


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'id=1&_submitted=1';

# basic tests
{
#    my $dbaird = Person->retrieve( 1 );
    
#    my $html = $form->render;

    my $form = Person->as_form;
    
    my $dbaird = Person->retrieve_from_form( $form );
    
    isa_ok( $dbaird, 'Class::DBI' );
    
    my $html = $form->render;
    
    # got a validation function for every column
    foreach my $col ( qw( name town street ) )
    {
        like( $html, qr(var $col) );
    }
    
    # except id                  
    unlike( $html, qr(var id) );
    
}

# -----------------------------------------------
# form_builder_defaults->{auto_validate} options


# validate
{
    Person->form_builder_defaults->{auto_validate}->{validate} = { name => [qw(nate jim bob)] };
    
    my $dbaird = Person->retrieve( 1 );
    
    my $dbhtml = $dbaird->as_form->render;
    
    like( $dbhtml, qr/\Q(name == null || (name != 'nate' && name != 'jim' && name != 'bob'))\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( name town street ) )
    {
        like( $dbhtml, qr(var $col) );
    }
                                                           
    # except id                  
    unlike( $dbhtml, qr(var id) );

    delete Person->form_builder_defaults->{auto_validate}->{validate};
}

# skip_columns
{
    Person->form_builder_defaults->{auto_validate}->{skip_columns} = [ 'name' ];
    
    my $dbaird = Person->retrieve( 1 );
    
    my $dbhtml = $dbaird->as_form->render;
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street ) )
    {
        like( $dbhtml, qr(var $col) );
    }
                                                           
    # except id and name           
    foreach my $col ( qw( id name ) )
    {
        unlike( $dbhtml, qr(var $col) );
    }

    delete Person->form_builder_defaults->{auto_validate}->{skip_columns};
}

# match_columns
{
    Person->form_builder_defaults->{auto_validate}->{match_columns} = { qr(^(name|town)$) => [ qw( small medium large ) ] };
    
    my $dbaird = Person->retrieve( 1 );
    
    my $dbhtml = $dbaird->as_form->render;
    
    #warn $html;
    
    like( $dbhtml, qr/\Qname != 'small' && name != 'medium' && name != 'large'\E/ );
    like( $dbhtml, qr/\Qtown != 'small' && town != 'medium' && town != 'large'\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street name ) )
    {
        like( $dbhtml, qr(var $col) );
    }
                                                           
    # except id  
    foreach my $col ( qw( id  ) )
    {
        unlike( $dbhtml, qr(var $col) );
    }

    delete Person->form_builder_defaults->{auto_validate}->{match_columns};
}

# validate_types
{
    Person->form_builder_defaults->{auto_validate}->{validate_types} = { varchar => '/[1-5]{1,3}/' };
    
    my $dbaird = Person->retrieve( 1 );
    
    my $dbhtml = $dbaird->as_form->render;
    
    #warn $html;
    
    my $match = '.match(/[1-5]{1,3}/)';
    
    like( $dbhtml, qr/\Qstreet$match\E/ );
    like( $dbhtml, qr/\Qname$match\E/ );
    unlike( $dbhtml, qr/\Qtown$match\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street name ) )
    {
        like( $dbhtml, qr(var $col) );
    }
                                                           
    # except id  
    foreach my $col ( qw( id  ) )
    {
        unlike( $dbhtml, qr(var $col) );
    }

    delete Person->form_builder_defaults->{auto_validate}->{validate_types};
}


# match_types
{
    Person->form_builder_defaults->{auto_validate}->{match_types} = { qr(var|int) => '/yabadabadoo/' };
    
    my $dbaird = Person->retrieve( 1 );
    
    my $dbhtml = $dbaird->as_form->render;
    
    #warn $html;
    
    my $match = '.match(/yabadabadoo/)';
    
    like( $dbhtml, qr/\Qstreet$match\E/ );
    like( $dbhtml, qr/\Qname$match\E/ );
    like( $dbhtml, qr/\Qtown$match\E/ );
    unlike( $dbhtml, qr/\Qid$match\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street name ) )
    {
        like( $dbhtml, qr(var $col) );
    }
                                                           
    # except id  
    foreach my $col ( qw( id  ) )
    {
        unlike( $dbhtml, qr(var $col) );
    }
    
    delete Person->form_builder_defaults->{auto_validate}->{match_types};
}
