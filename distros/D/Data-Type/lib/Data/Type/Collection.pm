
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Collection;

our %EXPORT_COLLECTION_TAGS = 
( 
  'all' => [ids()],
);

our @EXPORT_COLLECTION_OK = ( @{ $EXPORT_COLLECTION_TAGS{'all'} } );

our @EXPORT_COLLECTION = ();

our $_ids = 
{ 
	STD => 'Std.pm',  
	BIO => 'Bio.pm',  
	DB => 'DB.pm',  
	W3C => 'W3C.pm',  
        CHEM => 'Chem.pm',
};

our $_arg_to_pkg = 
{ 
	STD => 'Std',  
	BIO => 'Bio',  
	Bio => 'Bio',  
	DB => 'DB',  
	W3C => 'W3C',  
        CHEM => 'Chem',
};

our $_stds = [qw(STD)];

sub ids
{
	return keys %$_ids;
}

           # a list of collections requested for export

        sub _types 
        {
	    my %types;

	    foreach ( type_list_as_packages() )
	    {
		my $prefix = $_->prefix;
		
		$prefix =~ s/::$//;
		
		@{ $types{ $prefix } } = [] unless exists $types{$prefix };
		
		push @{ $types{ $prefix } }, $_->exported;
	    }

	    return \%types;
	}

1;

__END__

=head1 NAME

Data::Type::Collection - a group of datatypes somehow related

=head1 SYNOPSIS

  package Data::Type::Collection::My::Interface;

    our @ISA = qw(Data::Type::Object::Interface);

    our $VERSION = '0.01.25';

    sub prefix : method {'My::'} 

    sub pkg_prefix : method {'my_'} 

=head1 SUPPORTED COLLECTIONS


All types are grouped and though belong to a B<collection>. The collection is identified by a short id. All members are living in a namespace that is prefixed with it (uppercased).

=over 3

=item L<Standard Collection ('STD')|Data::Type::Collection::Std>

This is a heterogenous collection of datatypes which is loaded by default. It contains various issues from CPAN modules (i.e. business, creditcard, email, markup, regexps and etc.) and some everyday things. See L<Data::Type::Collection::Std>.

=item L<W3C/XML-Schema Collection ('W3C')|Data::Type::Collection::W3C>

A nearly 1-to-1 use of L<XML::Schema> datatypes. It is nearly complete and works off the shelf. Please visit the XMLSchema L<http://www.w3.org/TR/xmlschema-2/> homepage for sophisticated documentation. See L<Data::Type::Collection::W3C>.

=item L<Database Collection ('DB')|Data::Type::Collection::DB>

Common database table types (VARCHAR, TINYTEXT, TIMESTAMP, etc.). See L<Data::Type::Collection::DB>.

=item L<Biological Collection ('BIO')|Data::Type::Collection::Bio>

Everything that is related to biological matters (DNA, RNA, etc.). See L<Data::Type::Collection::Bio>.

=item L<Chemistry Collection ('CHEM')|Data::Type::Collection::Chem>

Everything that is related to chemical matters (Atoms, etc.). See L<Data::Type::Collection::Chem>.

=item L<Perl5 Collection ('PERL')|Data::Type::Collection::Perl>

Reserved and undecided. See L<Data::Type::Collection::Perl>.

=item L<Perl6 Apocalypse Collection ('PERL6')|Data::Type::Collection::Perl6>

Placeholder for the Apocalypse and Synopsis 6 suggested datatypes for perl6. See L<Data::Type::Collection::Perl6>.

=back

B<[Note]> L<C<ALL>|Data::Type/EXPORT> is a an alias for all available collections at once.



=head1 DESCRIPTION

This is a service class for collections. When creating a new collection one would inherit from L<Data::Type::Object::Interface>.

=head1 API

=head2 our $_ids = HREF

This is a listing of the shipped collections within the L<Data::Type> module. It is helpfull in conjunction with L<Data::Type:::Query> but also for other introspective uses.

 our $_ids = 
 { 
	STD => 'Std.pm',  
	BIO => 'Bio.pm',  
	DB => 'DB.pm',  
	W3C => 'W3C.pm',  
        CHEM => 'Chem.pm',
 };

=head2 our $_stds = AREF 

Contains the list of standard type collections which get B<always> loaded per default when L<Data::Type> is used.

 our $_stds = [qw(STD)];


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

