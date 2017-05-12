package App::Services::Logger::Service;
{
  $App::Services::Logger::Service::VERSION = '0.002';
}

use Moo;

use common::sense;

use Log::Log4perl;

has log_conf => (
	is => 'rw',

);

has log_category => (
	is      => 'rw',
	default => sub { ref( $_[0] ) },
	lazy    => 1,

);

has log => (    #-- The actual Log::Log4perl logger. Type?
	is      => 'rw',
	default => sub {
		$_[0]->log_category( ref($_[0]) );
		$_[0]->get_logger();
	},
	lazy => 1,
);

sub get_logger {

	my $s = shift or die;
	my $category = shift;

	$category = $s->log_category unless $category;

	my $log_conf = $s->log_conf;

	unless ($log_conf) {
		die("Log4perl conf is empty!");
	}

	unless ( Log::Log4perl->initialized() ) {
		Log::Log4perl->init($log_conf);
	}

	my $log = Log::Log4perl->get_logger($category);
	$log->debug("Created logger for category '$category'");

	return $log;
}

no Moo;

1;

__END__

=pod

=head1 NAME

App::Services::Logger::Service

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
