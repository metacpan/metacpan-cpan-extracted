
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Collection::Bio::Interface;

  our @ISA = qw(Data::Type::Object::Interface);

  our $VERSION = '0.01.25';

  sub prefix : method { 'Bio::' }

  sub pkg_prefix : method { 'bio_' }

	# BIO stuff
	
	# Resources: http://users.rcn.com/jkimball.ma.ultranet/BiologyPages/C/Codons.html
	# CPAN: Bio::Tools::CodonTable
	
package Data::Type::Object::bio_dna;

  our @ISA = qw(Data::Type::Collection::Bio::Interface Data::Type::Collection::Std::Interface::Logic);

  our $VERSION = '0.01.03';

  sub export { ('DNA') }

  sub desc : method { 'dna fragment' }

  sub info : method { q{dna sequence} }

  sub usage : method { 'sequence of [ATGC]' }

  sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ] ) }

  sub _test : method
  {
      my $this = shift;
      
      #warn "dt test \$Data::Type::value '$Data::Type::value'";
            
      Data::Type::ok( 1, Data::Type::Facet::match( 'bio/dna' ) );
  }

package Data::Type::Object::bio_rna;

	our @ISA = qw(Data::Type::Collection::Bio::Interface Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.03';

	sub export { ('RNA') }

	sub desc : method { 'RNA fragment' }

	sub info { qq{rna sequence} }

	sub usage { 'sequence of [ATUC]' }

	sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ] ) }
	
	sub _test
	{
		my $this = shift;

		        Data::Type::ok( 1, Data::Type::Facet::match( 'bio/rna' ) );
	}

package Data::Type::Object::bio_codon;

	our @ISA = qw(Data::Type::Collection::Bio::Interface Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.03';

	sub export { ('CODON') }

        sub desc : method { 'DNA/RNA triplet' }

        sub info : method { qq{DNA (default) or RNA nucleoside triphosphates triplet} }

	sub usage : method { 'triplet of DNA or RNA' }
	

        sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ], [ 'uc' ] ) }

	sub _test
	{
		my $this = shift;
			
			my $kind = lc( $this->[0] || 'DNA' );

			Carp::croak( sprintf "'%s' expects 'DNA' or 'RNA' as an argument and not '%s'",$this->export,$kind ) unless $kind eq 'dna' || $kind eq 'rna';

		        Data::Type::ok( 1, Data::Type::Facet::match( 'bio/triplet', $kind ) );
	}

1;

=head1 NAME

Data::Type::Collection::Bio - datatypes for biology

=head1 SYNOPSIS

        print "found dna" if shift and is BIO::DNA;

	valid 'AUGGGAAAU',	BIO::RNA;
	valid 'ATGCAAAT',	BIO::DNA;

	try
	{
		typ ENUM( qw(DNA RNA) ), \( my $a, my $b );

		print "a is typ'ed" if istyp( $a );

		$a = 'DNA';		# $alias only accepts 'DNA' or 'RNA'
		$a = 'RNA';
		$a = 'xNA';		# throws exception

		untyp( $alias );
	}
	catch Data::Type::Exception with
	{
		printf "Expected '%s' %s at %s line %s\n",
			$e->value,
			$e->type->info,
			$e->file,
			$e->line;
	};

 valid 'AUGGGAAAU', BIO::RNA;
 valid 'ATGCAAAT',  BIO::DNA;

=head1 DESCRIPTION

Everything that is related to biological matters.

[Note] Also have a glimpse on 'Chem' collection.

=head1 TYPES


=head2 BIO::CODON (since 0.01.03)

DNA/RNA triplet

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

triplet of DNA or RNA

=head2 BIO::DNA (since 0.01.03)

dna fragment

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

sequence of [ATGC]

=head2 BIO::RNA (since 0.01.03)

RNA fragment

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

sequence of [ATUC]



=head1 INTERFACE


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

