package CHI::Driver::MongoDB::t::CHIDriverTests;
$CHI::Driver::MongoDB::t::CHIDriverTests::VERSION = '0.0100';
# ABSTRACT: Wrapper for the CHI driver test suite

use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);

sub testing_driver_class {'CHI::Driver::MongoDB'}

# Flags indicating what each test driver supports
sub supports_clear              {1}
sub supports_expires_on_backend {1}
sub supports_get_namespaces     {1}


sub new_cache_options {
	my $self = shift;

	return (
		$self->SUPER::new_cache_options(),

		# Any necessary CHI->new parameters for your test driver
		connection_uri => defined( $ENV{'MONGODB_CONNECTION_URI'} ) ? $ENV{'MONGODB_CONNECTION_URI'} : 'mongodb://127.0.0.1:27017',
		db_name        => '_CHI_TESTING_',
	);
}


sub _drop_at_startup : Test(startup) {
	diag "Dropping database prior to running any tests...";
	goto &_drop_db;
}


sub _drop_at_setup : Test(setup) {
	goto &_drop_db;
}


sub _drop_at_shutdown : Test(shutdown) {
	diag "Dropping database after final test...";
	goto &_drop_db;
}


sub _drop_db {
	my $self = shift;

	my $cache = $self->new_cache;
	$cache->mongodb->get_database( $cache->db_name )->drop;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CHI::Driver::MongoDB::t::CHIDriverTests - Wrapper for the CHI driver test suite

=head1 VERSION

version 0.0100

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
