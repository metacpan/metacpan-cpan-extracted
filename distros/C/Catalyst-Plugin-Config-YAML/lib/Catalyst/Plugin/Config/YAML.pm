package Catalyst::Plugin::Config::YAML;

use strict;
use warnings;

use UNIVERSAL 'isa';

use NEXT;
use YAML 'LoadFile';
use Path::Class 'file';

our $VERSION = '0.04';

=head1 NAME

Catalyst::Plugin::Config::YAML - Configure your Catalyst application via an 
external YAML file

=head1 SYNOPSIS

    use Catalyst 'Config::YAML';
    
    __PACKAGE__->config('config_file' => 'config.yml');

=head1 DESCRIPTION

This Catalyst plugin enables you to configure your Catalyst application with an 
external YAML file instead of somewhere in your application code.

This is useful for example if you want to quickly change the configuration for 
different deployment environments (like development, testing or production) 
without changing your code.

The configuration file is assumed to be in your application home. Its name can 
be specified with the config parameter C<config_file> (default is 
F<config.yml>).

The config parameter C<config_file> can also be an array of locations (relative 
or absolute), each found file will be loaded in order.

=head2 EXTENDED METHODS

=over

=item setup

=cut

sub setup {
	my $c = shift;
	my @config_files;
	if ( defined $c->config->{'config_file'} && ref $c->config->{'config_file'} eq 'ARRAY' ) {
		@config_files = @{$c->config->{'config_file'}};
	} else {
		my $config_file = $c->config->{'config_file'} || 'config.yml';
		push @config_files, $config_file;
	}
	foreach my $config_file ( @config_files ) {
		$config_file = file($c->config->{'home'}, $config_file) unless file($config_file)->is_absolute;
		next unless -e $config_file;
		my $options = LoadFile($config_file);
		$c->config($options);
	}
	$c->NEXT::setup;
}

=back

=head1 SEE ALSO

L<Catalyst>, L<YAML>.

=head1 AUTHOR

Bernhard Bauer, E<lt>bauerb@in.tum.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Bernhard Bauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
