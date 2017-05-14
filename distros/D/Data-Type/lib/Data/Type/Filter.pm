
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Filter::Interface;

	use Attribute::Util;

	sub desc : Abstract method;

	sub info : Abstract method;

	sub filter : Abstract method;

package Data::Type::Filter::chomp;

	our @ISA = ( 'Data::Type::Filter::Interface' );

	our $VERSION = '0.01.25';

	sub desc : method { 'chomps' }

	sub info : method { 'chomps' }
    
	sub filter : method
	{
	    my $this = shift;

	    chomp $Data::Type::value;
	}
    
package Data::Type::Filter::lc;

	our @ISA = ( 'Data::Type::Filter::Interface' );

	our $VERSION = '0.01.25';

	sub desc : method { 'lowers case' }

	sub info : method { 'lowers cases' }

	sub filter : method
	{
		my $this = shift;

		$Data::Type::value = lc $Data::Type::value;		
	}

package Data::Type::Filter::uc;

	our @ISA = ( 'Data::Type::Filter::Interface' );

	our $VERSION = '0.01.25';

	sub desc : method { 'upper cases' }

	sub info : method { 'upper cases via "uc"' }

	sub filter : method
	{
		my $this = shift;

		$Data::Type::value = uc $Data::Type::value;
		
	}

package Data::Type::Filter::strip;

	our @ISA = ( 'Data::Type::Filter::Interface' );

	our $VERSION = '0.01.25';

	sub desc : method { 'strips text' }

	sub info : method { 'removes arbitrary substrings' }

	sub filter : method
	{
		my $this = shift;

		my $what = shift || die "strip requires one argument" ;

		$Data::Type::value =~ s/$what//go;
	}

package Data::Type::Filter::collapse;

	our @ISA = ( 'Data::Type::Filter::Interface' );

	our $VERSION = '0.01.32';

	sub desc : method { 'collapses repeats' }

	sub info : method { 'collapses any arbitrary repeats of characters to a single' }

	sub filter : method
	{
		my $this = shift;

		my $what = shift;

		$Data::Type::value =~ s/$what{2,}/$what/go;
	}
1;

__END__

=head1 NAME

Data::Type::Filter - cleans values before normally subjecting to facets

=head1 SYNOPSIS

  package Data::Type::Object::std_langcode;

    ...

    sub _filters : method 
    { 
       return ( [ 'strip', '\s' ], [ 'chomp' ], [ 'lc' ] ) 
    }

=head1 EXAMPLE

  package Data::Type::Filter::chomp;

    our @ISA = ( 'Data::Type::Filter::Interface' );

    our $VERSION = '0.01.25';

    sub desc : method { 'chomps' }

    sub info : method { 'chomps' }
    
    sub filter : method
    {
       my $this = shift;

       chomp $Data::Type::value;
    }

=head1 FILTERS

=head2 Data::Type::Filter::chomp

Chomps (as perl C<chomp()>).

=head2 Data::Type::Filter::lc

Lower cases (as perl C<lc()>).

=head2 Data::Type::Filter::uc

Upper cases (as perl C<uc()>).

=head2 Data::Type::Filter::strip( I<what> )

A simple s/I<what>// operation as

   $Data::Type::value =~ s/$what//go;

=head2 Data::Type::Filter::collapse( I<what> )

Collapses any arbitrary repeats of I<what> to a single.


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

