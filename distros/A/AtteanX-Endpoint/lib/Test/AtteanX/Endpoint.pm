=head1 NAME

Test::AtteanX::Endpoint - Shared code for testing AtteanX::Endpoint

=head1 VERSION

This document describes Test::AtteanX::Endpoint version 0.004

=head1 SYNOPSIS

  use Test::AtteanX::Endpoint;

=head1 DESCRIPTION

The Test::AtteanX::Endpoint class provides APIs for use in testing the
AtteanX::Endpoint module.

=head1 METHODS

=over 4

=cut


use v5.14;
use warnings;

package Test::AtteanX::Endpoint {
	our $VERSION	= "0.004";

	use Attean::RDF;
	use AtteanX::Endpoint;
	use Test::WWW::Mechanize::PSGI;
	use Test::AtteanX::Endpoint;

	sub mech_for_nquads {
		my $class			= shift;
		my $nquads			= pop;
		my %args			= @_;
		my $allow_update	= delete $args{'update'} // 0;
		my $gsp_path		= delete $args{'gsp_path'};
		my $graph			= delete $args{'graph'} // iri('http://example.org/graph');
		my $config			= {
			endpoint	=> {
				service_description => {},
				gsp_path			=> $gsp_path,
				html				=> {},
				load_data			=> 0,
				update				=> $allow_update,
			}
		};

		if (defined($gsp_path)) {
			$config->{endpoint}{gsp_path}	= $gsp_path;
		}
	
		my $store	= Attean->get_store('Memory')->new();
		my $model	= Attean::MutableQuadModel->new( store => $store );
		$model->load_triples('nquads', $graph => $nquads);
		
		my $end		= AtteanX::Endpoint->new( model => $model, conf => $config, graph => $graph );
		my $app	= sub {
			my $env 	= shift;
			my $req 	= Plack::Request->new($env);
			my $resp	= $end->run( $req );
			return $resp->finalize;
		};
	
		my $mech	= Test::WWW::Mechanize::PSGI->new(app => $app);
		return $mech;
	}
}

1;


__END__

=back

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/kasei/atteanx-endpoint/issues>.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) Gregory Todd Williams.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
