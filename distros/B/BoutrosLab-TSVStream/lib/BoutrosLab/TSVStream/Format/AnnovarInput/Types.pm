# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::AnnovarInput::Types

=head1 SYNOPSIS

Collection of types used in AnnovarInput format fields.  Used internally in
BoutrosLab::TSVStream::Format::AnnovarInput::Role.

=cut

package BoutrosLab::TSVStream::Format::AnnovarInput::Types;

use MooseX::Types -declare => [
	qw(
		AI_Ref
		AI_ChrHuman
		AI_ChrHumanNoChr
		AI_ChrHumanWithChr
		AI_ChrHumanTag
		AI_ChrHumanTagNoChr
		AI_ChrHumanTagWithChr
		)
	];

use MooseX::Types::Moose qw( Int Str ArrayRef );
# use Type::Utils -all;

subtype AI_Ref,
	as        Str,
	where     { /^-$/ || /^[CGAT]+(?:,[CGAT]+)*$/i },
	message   {"AI_Ref must be '-' (dash), or one or more series of 'CGAT' characters separated by ','"};

sub _human_chr {
	my ($val, $allow_tag) = @_;
	return 1 if $allow_tag && $val =~ /^(?:chr)?Un_\S+$/;
	return 0 unless my ( $l, $v, $tag ) = $val =~ /^(?:chr)?(?:([XYM])|(\d+))(_\S+)?$/;
	return 1 if ($l || ( 1 <= $v && $v <= 22 )) && ($allow_tag || !$tag);
	return 0;
	}

sub _apply_chr_subtypes {
	my ($type, $wc, $nc) = @_;

	subtype   $wc,
		as    $type,
		where { /^chr/ };
	subtype   $nc,
		as    $type,
		where { /^(?!chr)/ };
	coerce $nc, from $wc, via { s/^chr//; $_ };
	coerce $wc, from $nc, via { s/^/chr/; $_ };
	}

my $notagmessage = " - must be '1'..'22', 'X', 'Y', or 'M'.  (A leading 'chr' string is optional.)";

subtype AI_ChrHuman,
	as        Str,
	where     { _human_chr($_) },
	message   { "$notagmessage Found: $_" };

_apply_chr_subtypes( AI_ChrHuman, AI_ChrHumanWithChr, AI_ChrHumanNoChr );

my $tagmessage = " - must be '1'..'22', 'X', 'Y', or 'M'; optionally followed a tag; or 'Un' followed by a (required) tag.  A tag must start with an underscore.  (A leading 'chr' string is optional.)";

subtype AI_ChrHumanTag,
	as        Str,
	where     { _human_chr($_, 1) },
	message   { "$tagmessage Found: $_" };

_apply_chr_subtypes( AI_ChrHumanTag, AI_ChrHumanTagWithChr, AI_ChrHumanTagNoChr );

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

