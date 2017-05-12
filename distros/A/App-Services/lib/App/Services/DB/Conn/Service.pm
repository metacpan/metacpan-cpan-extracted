package App::Services::DB::Conn::Service;
{
  $App::Services::DB::Conn::Service::VERSION = '0.002';
}

use Moo;

use common::sense;

with 'App::Services::Logger::Role';

use DBI;

has dsn => (
	is => 'rw',
	required => 1,
);

has db_user => (
	is => 'rw',
	required => 1,
);

has db_password => (
	is => 'rw',
	required => 1,
);

has dbh => (
	is => 'rw',
	default => \&dbh_builder,
	lazy => 1,
);

sub dbh_builder {
 my $s = shift;

 my $dbh = DBI->connect($s->dsn,$s->db_user,$s->db_password);

 unless ( $dbh ) {
	$s->log->error(DBI->errstr());
	return undef;
 }

 return $dbh;

}

no Moo;

1;

__END__

=pod

=head1 NAME

App::Services::DB::Conn::Service

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
