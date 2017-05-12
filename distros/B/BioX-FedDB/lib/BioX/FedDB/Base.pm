package BioX::FedDB::Base;
use Class::Std;
use Class::Std::Utils;
use DBIx::MySperqlOO;
use File::Spec;
use YAML qw(DumpFile LoadFile);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

{
	my %dbh_of        :ATTR();
        my %attribute_of  :ATTR( :get<attribute>   :set<attribute>   :default<''>    :init_arg<attribute> );
                
	sub dbh              { my ( $self ) = @_; return $dbh_of{ident $self}; }

        sub BUILD {
                my ($self, $ident, $arg_ref) = @_;
        
		$dbh_of{$ident}     = DBIx::MySperqlOO->new( $arg_ref->{connection} );

                return;
        }

        sub _sum {
                my ( $self, @values ) = @_;
		my $total             = 0;
		foreach my $value ( @values ) {
			$total += $value;
		}
		return $total;
        }

	sub _sql_escape { 
		my ( $self, $string ) = @_;
		if ($string) { $string =~ s/(['"\\])/\\$1/g; }
		return $string; 
	}
	
	sub _html_to_sql {
		my ( $self, $string ) = @_;
		$string = $self->_html_unescape( $string );
		$string = $self->_sql_escape( $string );
		return $string;
	}
	
	sub _html_escape {
		my ( $self, $string ) = @_;
		$string =~ s/'/&#39;/g;
		$string =~ s/"/&#34;/g;
		return $string;
	}
		
	sub _html_encode {
		my ( $self, $string ) = @_;
		$string =~ s/ /%20/g;
		$string =~ s/'/%27/g;
		$string =~ s/\{/%7B/g;
		$string =~ s/\}/%7D/g;
		return $string;
	}
		
	sub _html_unescape {
		my ( $self, $string ) = @_;
		$string =~ s/&#39;/'/g;
		$string =~ s/&#34;/"/g;
		$string =~ s/%20/ /g;
		return $string;
	}
	
	sub _phone_format {
		my ( $self, $string ) = @_;
		$string =~ s/(\d{3})(\d{3})(\d{4})/($1) $2-$3/;
		return $string;
	}
	
	sub _phone_unformat {
		my ( $self, $string ) = @_;
		$string =~ s/[^\d]//g;
		return $string;
	}
	
	sub _commify { # Perl Cookbook 2.17
		my ( $self, $string ) = @_;
		my $text = reverse $string;
		$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
		return scalar reverse $text;
	}
	


}

1; # Magic true value required at end of module
__END__

=head1 NAME

BioX::FedDB::Base - Select/Resort a Federated BLAST Database with Catalyst and MySQL.


=head1 VERSION

This document describes BioX::FedDB::Base version 0.0.1


=head1 SYNOPSIS

    use BioX::FedDB::Base;

  
=head1 DESCRIPTION


=head1 INTERFACE 



=head1 CONFIGURATION AND ENVIRONMENT

BioX::FedDB::Base requires no configuration files or environment variables.


=head1 DEPENDENCIES


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-BioX-feddb-base@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Roger A Hall  C<< <rogerhall@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyleft (c) 2009, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
