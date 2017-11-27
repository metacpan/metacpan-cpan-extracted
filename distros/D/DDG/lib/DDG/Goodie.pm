package DDG::Goodie;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Goodie package for easy keywords
$DDG::Goodie::VERSION = '1018';
use strict;
use warnings;
use Carp;
use DDG::Meta;


sub import {
	my ( $class ) = @_;
	my $target = caller;

	#
	# Make base
	#

	DDG::Meta->apply_base_to_package($target);
	
	#
	# Apply keywords
	#

	DDG::Meta->apply_goodie_keywords($target);
	
}

1;

__END__

=pod

=head1 NAME

DDG::Goodie - Goodie package for easy keywords

=head1 VERSION

version 1018

=head1 DESCRIPTION

This is the Goodie Meta class. It injects all the keywords used for
ZeroClickInfo Goodies. For more information see L<DDG::Meta>.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
