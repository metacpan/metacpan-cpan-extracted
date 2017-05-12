package DDG::Spice;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Spice package for easy keywords
$DDG::Spice::VERSION = '1016';
use strict;
use warnings;
use DDG::Meta;

sub import {
	my ( $class ) = @_;
	my $target = caller;

	DDG::Meta->apply_base_to_package($target);
	DDG::Meta->apply_spice_keywords($target);
}


1;

__END__

=pod

=head1 NAME

DDG::Spice - Spice package for easy keywords

=head1 VERSION

version 1016

=head1 SYNOPSIS

  package DDG::Spice::MySpice;
  # ABSTRACT: My cool spice!

  use DDG::Spice;

  triggers startend => "cool";
  spice to => 'http://ownage.cool/?t=$1&callback={{callback}}';

  handle remainder => sub { $_ ? $_ : "" };

  1;

=head1 DESCRIPTION

This is the Spice Meta class. It injects all the keywords used for
ZeroClickInfo Spice. For more information see L<DDG::Meta>.

Use the B<server> command of L<App::DuckPAN> for testing your spice!

=head1 SEE ALSO

L<http://duckduckhack.com/>

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
