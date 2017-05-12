package DDG::Meta;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Main meta layer implementation factory... dark side of the moon...
$DDG::Meta::VERSION = '1016';
use strict;
use warnings;
use Carp;
require Data::Printer;

use DDG::Meta::RequestHandler;
use DDG::Meta::ZeroClickInfo;
use DDG::Meta::ZeroClickInfoSpice;
use DDG::Meta::Fathead;
use DDG::Meta::ShareDir;
use DDG::Meta::Block;
use DDG::Meta::Information;
use DDG::Meta::Helper;
use DDG::Meta::AnyBlock;
use DDG::Meta::CountryCodes;

use MooX ();

require Moo::Role;


sub apply_base_to_package {
	my ( $class, $target ) = @_;

	MooX->import::into($target, qw(
		+Data::Printer
	));
}


sub apply_goodie_keywords {
	my ( $class, $target ) = @_;
	DDG::Meta::ZeroClickInfo->apply_keywords($target);
	DDG::Meta::ShareDir->apply_keywords($target);
	DDG::Meta::Block->apply_keywords($target);
	DDG::Meta::Information->apply_keywords($target);
	DDG::Meta::Helper->apply_keywords($target);
	DDG::Meta::RequestHandler->apply_keywords($target,sub {
		shift->zci_new(
			scalar @_ == 1 && ref $_[0] eq 'HASH' ? $_[0] :
				@_ % 2 ? ( answer => @_ ) : @_
		);
	},'DDG::IsGoodie');
}


sub apply_spice_keywords {
	my ( $class, $target ) = @_;
	DDG::Meta::ZeroClickInfoSpice->apply_keywords($target);
	DDG::Meta::ShareDir->apply_keywords($target);
	DDG::Meta::Block->apply_keywords($target);
	DDG::Meta::Information->apply_keywords($target);
	DDG::Meta::Helper->apply_keywords($target);
	DDG::Meta::RequestHandler->apply_keywords($target,sub {
		shift->spice_new(@_);
	},'DDG::IsSpice');
}


sub apply_fathead_keywords {
    my ( $class, $target ) = @_;
    DDG::Meta::ZeroClickInfo->apply_keywords($target);
    DDG::Meta::ShareDir->apply_keywords($target);
    DDG::Meta::Fathead->apply_keywords($target);
    DDG::Meta::Information->apply_keywords($target);    
    DDG::Meta::AnyBlock->apply_keywords($target);
    Moo::Role->apply_role_to_package($target, "DDG::IsFathead");
}


sub apply_longtail_keywords {
    my ( $class, $target ) = @_;
    DDG::Meta::ZeroClickInfo->apply_keywords($target);
    DDG::Meta::ShareDir->apply_keywords($target);
    DDG::Meta::Information->apply_keywords($target);
    DDG::Meta::AnyBlock->apply_keywords($target);
    Moo::Role->apply_role_to_package($target, "DDG::IsLongtail");
}

1;

__END__

=pod

=head1 NAME

DDG::Meta - Main meta layer implementation factory... dark side of the moon...

=head1 VERSION

version 1016

=head1 SYNOPSIS

  DDG::Meta->apply_base_to_package("DDG::Goodie::MyGoodie");
  DDG::Meta->apply_goodie_keywords("DDG::Goodie::MyGoodie");

=head1 DESCRIPTION

This package gathers all the functions to apply the meta
layers used in DuckDuckGo. We try to apply easy keywords for
the package developer, so that its most easy for the beginners
to generate good plugins. This on the other side makes it
right now hard to see what magic happens behind the curtains.
L<DDG::Meta> functions shows up what is required to be some
specific plugin on the DuckDuckGo module system.

=head1 METHODS

=head2 apply_base_to_package

This function applies to the given target classname L<Moo> and
L<Data::Printer> as if they were used directly inside the given classname.
This is achieved with L<Import::Into> in combination with L<MooX>.

=head2 apply_goodie_keywords

This function applies a huge amount of keywords of other meta classes into
the package of the given target classname. Please see:

L<DDG::Meta::ZeroClickInfo>, L<DDG::Meta::ShareDir>, L<DDG::Meta::Block>,
L<DDG::Meta::Attribution>, L<DDG::Meta::Helper>, L<DDG::Meta::Helper>,
L<DDG::Meta::RequestHandler>

The goodie request handler is supposed to give back an array of 
L<DDG::ZeroClickInfo> objects or an empty array for nothing.

=head2 apply_spice_keywords

This function applies a huge amount of keywords of other meta classes into
the package of the given target classname. Please see:

L<DDG::Meta::ZeroClickInfoSpice>, L<DDG::Meta::ShareDir>, L<DDG::Meta::Block>,
L<DDG::Meta::Attribution>, L<DDG::Meta::Helper>, L<DDG::Meta::Helper>,
L<DDG::Meta::RequestHandler>

The spice request handler is supposed to give back an array of 
L<DDG::ZeroClickInfo::Spice> objects or an empty array for nothing.

=head2 apply_fathead_keywords

=head2 apply_longtail_keywords

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
