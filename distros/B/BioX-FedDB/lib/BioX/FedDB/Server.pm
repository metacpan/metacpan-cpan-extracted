package BioX::FedDB::Server;
use base qw(BioX::FedDB::Base);
use Class::Std;
use Class::Std::Utils;
#use Parallel::Simple qw(prun);
use LWP::Simple;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

{
        my %servers_of  :ATTR( :get<servers>   :set<servers>   :default<[]>    :init_arg<servers> );
                
        sub BUILD {
                my ($self, $ident, $arg_ref) = @_;

                return;
        }

        sub query_count {
                my ( $self, $id ) = @_;
                return $self->_query( 'query_count', $id );
        }

        sub subject_count {
                my ( $self, $id ) = @_;
                return $self->_query( 'subject_count', $id );
        }

        sub query {
                my ( $self, $id ) = @_;
                return $self->_query( 'query', $id );
        }

        sub subject {
                my ( $self, $id ) = @_;
                return $self->_query( 'subject', $id );
        }

        sub version { return $VERSION; }

        sub _query {
                my ( $self, $method, $id ) = @_;
		my $servers                = $self->get_servers();
		my @results                = ();

		foreach my $server ( @$servers ) {
			my $url = 'http://' . $server . 'feddb/' . $method . $id;
			print STDERR " Getting $url \n";

			# Get the partial results for server
			my $result = get( $url );
			push @results, $result;
		}

		# Return joined results
		return $self->_join( $method, @results );
        }

        sub _join {
                my ( $self, $method, @results ) = @_;
		if ( $method =~ /_count/ ) { return $self->_sum( @results ); }
		else                       { return join( "\n", @results );  }
        }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

BioX::FedDB::Server - Query Multiple Databases via Web Service


=head1 VERSION

This document describes BioX::FedDB::Server version 0.0.1


=head1 SYNOPSIS

See BioX::FedDB.
  
=head1 DESCRIPTION


=head1 INTERFACE 


=head1 DIAGNOSTICS

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

BioX::FedDB::Server requires no configuration files or environment variables.


=head1 DEPENDENCIES

See BioX::FedDB.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dbix-feddb-server@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Roger A Hall  C<< <rogerhall@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyleft (c) 2009, Roger A Hall C<< <rogerhall@cpan.org> >>. 

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
