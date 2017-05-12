package DDG::Meta::Helper;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Helper functions for easy access to important functions
$DDG::Meta::Helper::VERSION = '1016';
use strict;
use warnings;
use Carp qw( croak );
use Package::Stash;
use HTML::Entities;
use URI::Escape;


my %applied;

sub apply_keywords {
	my ( $class, $target ) = @_;

	return if exists $applied{$target};
	$applied{$target} = undef;

	my $stash = Package::Stash->new($target);


	$stash->add_symbol('&html_enc', sub { return (wantarray) ? map { encode_entities($_) } @_ : encode_entities(join '', @_) });


	$stash->add_symbol('&uri_esc', sub { return (wantarray) ? map { uri_escape($_) } @_ : uri_escape(join '', @_) });


    $stash->add_symbol('&true', sub { 1 });
    $stash->add_symbol('&false', sub { 0 });
}

1;

__END__

=pod

=head1 NAME

DDG::Meta::Helper - Helper functions for easy access to important functions

=head1 VERSION

version 1016

=head1 SYNOPSIS

In your goodie, for example:

  return "text from random source: ".$text."!",
    html => "<div>text from random source: ".html_enc($text)."!</div>";

Or use JSON-like booleans:

  { option1 => true, option2 => false }

=head1 DESCRIPTION

This meta class installs some helper functions.

=head1 EXPORTS FUNCTIONS

=head2 html_enc

encodes entities to safely post random data on HTML output.

=head2 uri_esc

Encodes entities to safely use it in URLs for links in the Goodie, for
example.

B<Warning>: Do not forget that the return value from a spice will
automatically get url encoded for the path. It is not required to url encode
values there, this will just lead to double encoding!

=head2 Booleans (true/false)

Use booleans true and false to set options.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
