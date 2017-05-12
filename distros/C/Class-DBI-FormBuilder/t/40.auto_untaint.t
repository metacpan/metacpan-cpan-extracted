
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 33;
use Class::DBI::FormBuilder::DBI::Test; 


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = '_submitted=1';

# basic tests
{
    my $html2 = Person->as_form->render;
    
    # got a validation function for every column
    foreach my $col ( qw( name town street ) )
    {
        like( $html2, qr(var $col) );
    }
    
    # except id
    unlike( $html2, qr(var id) );
}

# -----------------------------------------------
# form_builder_defaults->{auto_validate} options


# validate
{
    Person->form_builder_defaults->{auto_validate}->{validate} = { name => [qw(nate jim bob)] };
    
    my $html   = Person->as_form->render;
    
    # This changed after moving pks from keepextras to stripping them out of required in 0.343, 
    # not sure why. 
    like( $html,   qr/\Q(name == null || (name != 'nate' && name != 'jim' && name != 'bob'))\E/ );
    #like( $html,   qr/\Q(name != null && name != "" && (name != 'nate' && name != 'jim' && name != 'bob'))\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( name town street ) )
    {
        like( $html, qr(var $col) );
    }
                                                           
    # except id                  
    unlike( $html, qr(var id) );

    delete Person->form_builder_defaults->{auto_validate}->{validate};
}

# skip_columns
{
    Person->form_builder_defaults->{auto_validate}->{skip_columns} = [ 'name' ];
    
    my $html   = Person ->as_form->render;
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street ) )
    {
        like( $html, qr(var $col) );
    }
                                                           
    # except id and name           
    foreach my $col ( qw( id name ) )
    {
        unlike( $html, qr(var $col) );
    }

    delete Person->form_builder_defaults->{auto_validate}->{skip_columns};
}

# match_columns
{
    Person->form_builder_defaults->{auto_validate}->{match_columns} = { qr(^(name|town)$) => [ qw( small medium large ) ] };
    
    my $html   = Person ->as_form->render;
    
    #warn $html;
    
    like( $html, qr/\Qname != 'small' && name != 'medium' && name != 'large'\E/ );
    like( $html, qr/\Qtown != 'small' && town != 'medium' && town != 'large'\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street name ) )
    {
        like( $html, qr(var $col) );
    }
                                                           
    # except id  
    foreach my $col ( qw( id  ) )
    {
        unlike( $html, qr(var $col) );
    }

    delete Person->form_builder_defaults->{auto_validate}->{match_columns};
}

# validate_types
{
    Person->form_builder_defaults->{auto_validate}->{validate_types} = { varchar => '/[1-5]{1,3}/' };
    
    my $html   = Person ->as_form->render;
    
    #warn $html;
    
    my $match = '.match(/[1-5]{1,3}/)';
    
    like( $html, qr/\Qstreet$match\E/ );
    like( $html, qr/\Qname$match\E/ );
    unlike( $html, qr/\Qtown$match\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street name ) )
    {
        like( $html, qr(var $col) );
    }
                                                           
    # except id  
    foreach my $col ( qw( id  ) )
    {
        unlike( $html, qr(var $col) );
    }

    delete Person->form_builder_defaults->{auto_validate}->{validate_types};
}


# match_types
{
    Person->form_builder_defaults->{auto_validate}->{match_types} = { qr(var|int) => '/yabadabadoo/' };
    
    my $html   = Person ->as_form->render;
    
    #warn $html;
    
    my $match = '.match(/yabadabadoo/)';
    
    like( $html, qr/\Qstreet$match\E/ );
    like( $html, qr/\Qname$match\E/ );
    like( $html, qr/\Qtown$match\E/ );
    
    # and still got a validation function for every column 
    foreach my $col ( qw( town street name ) )
    {
        like( $html, qr(var $col) );
    }
                                                           
    # except id  
    foreach my $col ( qw( id  ) )
    {
        unlike( $html, qr(var $col) );
    }
    
    delete Person->form_builder_defaults->{auto_validate}->{match_types};
}
