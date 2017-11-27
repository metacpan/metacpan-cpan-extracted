package DDG::Meta::ZeroClickInfo;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Functions for generating a L<DDG::ZeroClickInfo> factory
$DDG::Meta::ZeroClickInfo::VERSION = '1018';
use strict;
use warnings;
use Carp;
use DDG::ZeroClickInfo;
use Package::Stash;

my %supported_zci_attributes = map { $_ => 1 } (qw(
      abstract
      abstract_text
      abstract_source
      abstract_url
      caller
      image
      heading
      answer
      answer_type
      definition
      definition_source
      definition_url
      type
      is_cached
      is_unsafe
      ttl
));



my %applied;

sub apply_keywords {
	my ( $class, $target ) = @_;

	return if exists $applied{$target};
	$applied{$target} = undef;

	my @parts = split('::',$target);
	shift @parts;
	shift @parts;
	my $answer_type = lc(join(' ',@parts));

	my $stash = Package::Stash->new($target);

	my %zci_params = (
        caller      => $target,
		answer_type => $answer_type,
	);



    $stash->add_symbol( '&zci', sub {
            my %kv = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
            while (my ($key, $value) = each(%kv)) {
                croak $key. " is not supported on DDG::ZeroClickInfo" unless (exists $supported_zci_attributes{$key});
                $zci_params{$key} = $value;
            }
        });


	$stash->add_symbol('&zci_new', sub {
		shift;
		DDG::ZeroClickInfo->new( %zci_params, ref $_[0] eq 'HASH' ? %{$_[0]} : @_ );
	});

}

1;

__END__

=pod

=head1 NAME

DDG::Meta::ZeroClickInfo - Functions for generating a L<DDG::ZeroClickInfo> factory

=head1 VERSION

version 1018

=head1 DESCRIPTION

=head1 EXPORTS FUNCTIONS

=head2 zci

This function applies default parameter to the L<DDG::ZeroClickInfo> that you
can generate via L</zci_new>. All keys given are checked through a list of
possible L<DDG::ZeroClickInfo> attributes.

  zci is_cached => 1;
  zci answer_type => 'random';

=head2 zci_new

This function gives back a L<DDG::ZeroClickInfo> set with the parameter given
on L</zci> and then overridden and extended through the parameter given to
this function.

=head1 METHODS

=head2 apply_keywords

Uses a given classname to install the described keywords.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
