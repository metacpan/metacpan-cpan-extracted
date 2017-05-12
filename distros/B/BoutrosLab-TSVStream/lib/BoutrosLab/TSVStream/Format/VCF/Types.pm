# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::VCF::Types

=head1 SYNOPSIS

Collection of types used in VCF format fields.  Used internally in
BoutrosLab::TSVStream::Format::VCF::Role.

=cut

package BoutrosLab::TSVStream::Format::VCF::Types;

use MooseX::Types -declare => [
	qw(
	    Str_No_Whitespace
		VCF_Chrom
		VCF_Ref
		VCF_Ref_Full
		VCF_Alt
		VCF_Alt_Full
		VCF_KV_Str
		)
	];

use MooseX::Types::Moose qw( Int Str ArrayRef HashRef );

subtype Str_No_Whitespace,
	as      Str,
	where   { /^\S+$/ },
	message {"may not contain whitespace characters"};

subtype VCF_Chrom, as Str_No_Whitespace;

subtype VCF_Ref,
	as      Str,
	where   { /^-$/ || /^[.CGAT]+$/i },
	message {"VCF_Ref must be '-' (dash), or a series of '.CGAT' characters"};

subtype VCF_Ref_Full,
	as      Str,
	# where   { /^-$/ || /^[CGAT]+$/i },
	# message {"VCF_Ref must be '-' (dash), or a series of 'CGAT' characters"}
;

subtype VCF_Alt,
	as      Str,
	where   { /^-$/ || /^[CGAT]+(?:,[CGAT]+)*$/i },
	message {"VCF_Alt must be '-' (dash), or one or more comma-separated series of 'CGAT' characters"};

subtype VCF_Alt_Full,
	as      Str,
	# where   { /^-$/ || /^[CGAT]+(?:,[CGAT]+)*$/i },
	# message {"VCF_Alt must be '-' (dash), or one or more comma-separated series of 'CGAT' characters"}
;

subtype VCF_KV_Str,
	as		'BoutrosLab::TSVStream::Format::VCF::Types::KeyValueString';

coerce VCF_KV_Str,
	from Str,
	via { BoutrosLab::TSVStream::Format::VCF::Types::KeyValueString->new($_) };


package BoutrosLab::TSVStream::Format::VCF::Types::KeyValueString;

use overload
	'""' => 'stringify';

sub new {
	my ($class, $data) = @_;
	$class = ref($class) || $class;
	my $data_hash = {};
	if (ref($data)) { # copy if it is already a HashRef (or KeyValueString object)
		while (my ($key, $value) = each %$data) {
			$data_hash->{$key} = $value;
			}
		}
	else { # split up a Str
		my @split = split(';', $data);
		foreach my $kv_pair (@split) {
			my ($key, $value) = split('=', $kv_pair);
			$data_hash->{$key} = $value;
			}
		}
	return bless $data_hash, $class;
	}

sub clone {
	my $self = shift;
	return $self->new($self);
	}

sub stringify {
	my ($self) = @_;
	my $str = '';
	foreach my $key (sort keys %{$self}) {
		my $val = $self->{$key};
		$str .= $key;
		$str .= "=$val" if defined $val;
		$str .= ";";
		} 
	$str =~ s/;$//;
	return $str;
	}


=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

