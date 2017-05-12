package Catalyst::Plugin::Config::JSON;

use strict;
use warnings;

use UNIVERSAL 'isa';

use NEXT;
use JSON;
use Path::Class 'file';

our $VERSION = '0.03';

=head1 NAME

Catalyst::Plugin::Config::JSON - Configure your Catalyst application via an external
JSON file

=head1 SYNOPSIS

    use Catalyst 'Config::JSON';
    
    __PACKAGE__->config('config_file' => 'config.json');

=head1 DESCRIPTION

This Catalyst plugin enables you to configure your Catalyst application with an 
external JSON file instead of somewhere in your application code.

This is useful for example if you want to quickly change the configuration for 
different deployment environments (like development, testing or production) 
without changing your code.

The configuration file is assumed to be in your application home. Its name can 
be specified with the config parameter C<config_file> (default is F<config.json>).

For any keys in the configuration file that start with C<Catalyst::>, the 
corresponding value is taken as the configuration for that class.

=head2 EXTENDED METHODS

=over

=item setup

=cut

sub setup {
	my $c = shift;
	my $config_file = $c->config->{'config_file'} || 'config.json';
	$config_file = file($c->config->{'home'}, $config_file) unless file($config_file)->is_absolute;
	open CONFIG, "<$config_file"
	    or die "failed to open $config_file for reading; $!";
	local($/)=undef;
	my $config = <CONFIG>;
	close CONFIG;
	my $options = jsonToObj($config);
	foreach my $key (keys %$options) {
		if (isa($key, 'Catalyst::Base')) {
			$key->config(delete $options->{$key});
		}
	}
	$c->config($options);
	$c->NEXT::setup;
}

=back

=head1 SEE ALSO

L<Catalyst>, L<JSON>.

=head1 AUTHOR

Catalyst::Plugin::Config::YAML by Bernhard Bauer,
E<lt>bauerb@in.tum.deE<gt>

Tweaked for JSON by Sam Vilain, E<lt>samv@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Sam Vilain

Portions

Copyright 2005 by Bernhard Bauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
