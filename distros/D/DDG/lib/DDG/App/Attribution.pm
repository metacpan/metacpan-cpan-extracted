package DDG::App::Attribution;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Application class for reading the attributions of a package
$DDG::App::Attribution::VERSION = '1017';
use MooX qw(
	Options
);

use Module::Runtime qw( use_module );
use lib ();
use Path::Class;

sub BUILD {
	my ( $self ) = @_;
	my $curdir = dir('lib')->absolute;
	lib->import($curdir->stringify);
	my @modules = @ARGV ? @ARGV : (); # TODO get complete list of all available modules on no args
	for (@modules) {
		use_module($_);
		if ($self->html) {
			print $_->get_attributions_html;
			print "\n";
		} else {
			my @attributions = @{$_->get_attributions};
			if (@attributions) {
				print "\nAttributions for ".$_.":\n\n";
				while (@attributions) {
					my $key = shift @attributions;
					my $value = shift @attributions;
					print " - ".$key." (".$value.")\n";
				}
			} else {
				print "\nNo attributions for ".$_."\n\n";
			}
		}
	}
	print "\n";
}

option 'html' => (
	is => 'ro',
	default => sub { 0 },
	negativable => 1,
);

1;

__END__

=pod

=head1 NAME

DDG::App::Attribution - Application class for reading the attributions of a package

=head1 VERSION

version 1017

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
