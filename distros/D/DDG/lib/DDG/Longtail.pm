package DDG::Longtail;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Longtail package for easy keywords
$DDG::Longtail::VERSION = '1018';
use strict;
use warnings;
use DDG::Meta;

sub import {
	my ( $class ) = @_;
	my $target = caller;

	DDG::Meta->apply_base_to_package($target);
	DDG::Meta->apply_longtail_keywords($target);
}


1;

__END__

=pod

=head1 NAME

DDG::Longtail - Longtail package for easy keywords

=head1 VERSION

version 1018

=head1 SYNOPSIS

  package DDG::Longtail::MyLongtail;
  # ABSTRACT: My cool Longtail!

  use DDG::Longtail;

  1;

=head1 DESCRIPTION

This is the Longtail Meta class. It injects all the keywords used for
ZeroClickInfo Longtail. For more information see L<DDG::Meta>.

=head1 SEE ALSO

L<http://duckduckhack.com/>

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
