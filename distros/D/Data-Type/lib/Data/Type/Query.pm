
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Query;

use strict;

use DBI;

use Text::TabularDisplay;

Class::Maker::class
{
    version => '0.01',

    public =>
    {
	ref => [qw( dbh )],

        array => [qw( tables )],
    },
};

sub _DESTROY
{
    Carp::croak( "This shouldnt happen before end of publish" );
}

sub _postinit : method
{
    my $this = shift;
    
    $this->dbh( DBI->connect('dbi:AnyData(RaiseError=>1):') ) or Carp::croak "$DBI::errstr";
    
    my $aref_types = [ [qw(pkg_name exported export_prefix export_name version description)] ];
    
    foreach my $pkg_name ( sort { $a cmp $b } Data::Type::type_list_as_packages() )
    {	       	       
	push @$aref_types, 
	[ 
	  $pkg_name, 
	  Data::Type::_translate( $pkg_name ), 
	  $pkg_name->prefix,
	  $pkg_name->export,
	  ($pkg_name->VERSION || 0), 
	  $pkg_name->desc,	  
	  ];
    }
    
    $this->dbh->func( 'types', 'ARRAY', $aref_types, 'ad_import' ) || Carp::croak q{$this->dbh->func failed};
    
    push @{ $this->tables }, 'types';
    
    my $aref_facets = [ [qw(pkg_name version description)] ];
    
    foreach my $pkg_name ( sort { $a cmp $b } Data::Type::facet_list_as_packages() )
    {	       	       
	push @$aref_facets, 
	[ 
	  ($pkg_name || ''), 
	  ($pkg_name->VERSION || 0), 
	  ($pkg_name->desc || ''),	  
	  ];
    }
    
    $this->dbh->func( 'facets', 'ARRAY', $aref_facets, 'ad_import' )  || Carp::croak q{$this->dbh->func failed};

    push @{ $this->tables }, 'facets';



    my $aref_filters = [ [qw(pkg_name version desription)] ];

    foreach my $pkg_name ( sort { $a cmp $b } Data::Type::filter_list() )
    {	       	       
	push @$aref_filters, 
	[ 
	  $pkg_name, 
	  ($pkg_name->VERSION || 0), 
	  $pkg_name->desc 
	  ];
    }

    $this->dbh->func( 'filters', 'ARRAY', $aref_filters, 'ad_import' )  || Carp::croak q{$this->dbh->func failed};

    push @{ $this->tables }, 'filters';


    my $aref_regexps = [ [qw(id regexp description created_pkg created_file created_line)] ];
    
    foreach my $name ( keys %{ $Data::Type::rebox->_registry } ) 
    {
	push @$aref_regexps,
	[
	     $name,
	     $Data::Type::rebox->request( $name, 'regexp' ),
	     $Data::Type::rebox->request( $name, 'desc' ),
	     $Data::Type::rebox->request( $name, 'created' )->[0],
	     $Data::Type::rebox->request( $name, 'created' )->[1],
	     $Data::Type::rebox->request( $name, 'created' )->[2],
	];	      
    }

    $this->dbh->func( 'regexps', 'ARRAY', $aref_regexps, 'ad_import' ) || Carp::croak q{$this->dbh->func failed};

    push @{ $this->tables }, 'regexps';

    $this->dbh->func( 'infos', 'ARRAY', 
		[  
		   [ 'name', 'value' ],
		   
		   [ 'version', Data::Type->VERSION ],
		   
		   [ 'filters', 22 ],
		   ],
		
		'ad_import'
		
		)  || Carp::croak q{$this->dbh->func failed};

    push @{ $this->tables }, 'infos';

return $this;
}

sub catalog : method
{
	my $this = shift;

	Carp::croak "Must call catalog from a reference not package name" unless ref($this);

	Carp::croak "You must first call __PACKAGE__->new before you can call catalog()" unless $this->dbh;

	my $catalog = {};

	    foreach my $what ( $this->tables )
	    {
		my $t;
		
		my $sth = $this->dbh->prepare( "SELECT * FROM $what" ) || Carp::croak "$DBI::err";
		
		$sth->execute or Carp::croak "$DBI::errstr";
		
		while( my $href = $sth->fetchrow_hashref )
		{
		    $t = Text::TabularDisplay->new( keys %$href ) unless $t;
		    
		    $t->add(values %$href);
		}
		
		$catalog->{$what} = $t->render if $t;
	    }

return $catalog;
}

sub depends
{
    my $this = shift;

    my %result;

    foreach my $name ( Data::Type::type_list_as_packages() )
    {
		if( $name->can( 'depends' ) )
		{
			foreach my $mod ( $name->depends )
			{
			    unless( exists $Data::Type::_loaded->{$mod} )
				{
				  eval "use $mod";
		
				  Carp::croak "$@ $!" if $@;
				}
		
				$result{$mod}->{version} = ($mod->VERSION || 0) unless exists $result{$mod}->{version};
		
				$result{$mod}->{types} = [] unless exists $result{$mod}->{types};
		
				for ( $name->exported )
				{
					push @{ $result{$mod}->{types} }, { name => $_ };
				}
			}
		}
    }
	
    return \%result;
}

1;

__END__

=head1 NAME

Data::Type::Query - introspection of Data::Type library via DBI

=head1 SYNOPSIS
 
  use Data::Type qw(:all);

  use Data::Type::Query; 

    my $dtq = Data::Type::Query->new();

    foreach my $what ( $dtq->tables )
    {
      my $sth = $dtq->dbh->do( "SELECT * FROM $what" ) || Carp::croak "$DBI::err";
    
      while( my $href = $sth->fetchrow_hashref )
      {
        print join ', ', $href;
      }
    }

    $dtq->depends();

    print $dtq->toc();

    my $href = $dtq->catalog();

    print $href->{$_} for qw(types facets filters regexps);

=head1 Description

B<Data::Type> is planned to get big as more datatypes are added to collections. Therefore introspection and surfing through the collections will be essential. Especially when alternativ collections arent always installed and available. This module adds introspection/reflection of Data::Type datatypes, filters and documentation via L<DBI> (via *ingenous* L<DBD::AnyData>).

=head1 METHODS

=head2 Data::Type::Query->new

  my $dtq = Data::Type::Query->new;

The constructor does not require arguments.

=head2 $dtq->dbh;

Returns the DBI C<$dbh> handle ready for querying.

=head2 $dtq->catalog()

  my $href = $dtq->catalog();

Returns a hashref which hold prerendered tabular listings (as scalars). 

 print $href->{types};
 print $href->{regexps};
 print $href->{facets};
 print $href->{filters};

Valid keys of that hash are retrievable with $dtq->tables.

B<[NOTE]> Be carefull since the catalog is generated only one time (for the life time of your program) and latter calls return the cached version.

=head2 $dtq->toc()

  my $scalar = $dtq->toc;

Returns a static string containing a grouped listing of all know types.

=head2 $dtq->depends()

  my $href = $dtq->depends;

Generates a dependency tree. Which type depends on which module. Returns an hash reference with this something similar to this structure:

        {
          'Locale::Language' => {
                                  'types' => [
                                               {
                                                 'name' => 'LANGCODE'
                                               },
                                               {
                                                 'name' => 'LANGNAME'
                                               }
                                             ],
                                  'version' => '2.02'
                                },
          'Business::CreditCard' => {
                                      'types' => [
                                                   {
                                                     'name' => 'CREDITCARD'
                                                   }
                                                 ],
                                      'version' => '0.27'
                                    },
          'Email::Valid' => {
                              'types' => [
                                           {
                                             'name' => 'EMAIL'
                                           }
                                         ],
                              'version' => '0.14'
                            },
	}

B<[NOTE]> In future helps implementing clever runtime module loading for only types really used.


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

