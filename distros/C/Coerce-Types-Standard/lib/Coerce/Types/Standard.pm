package Coerce::Types::Standard;

use 5.006;
use strict;
use warnings;
use Scalar::Util qw/blessed reftype refaddr/;
use parent 'Types::Standard';

our @EXPORT_OK = ( Types::Standard->type_names );

our $meta = __PACKAGE__->meta;
our $VERSION = '0.000004';

our (%entity, %recurse, %compare, $esc, $unesc, $path);
BEGIN {
	%entity = ( 
		encode => {
			q{&} => q{&amp;}, q{"} => q{&quot;}, q{'} => q{&apos;}, q{<} => q{&lt;}, q{>} => q{&gt;} 
		}
	);
	my @keys = keys %{$entity{encode}};
	$entity{decode} = +{ map {
		$entity{encode}->{$_} => $_
	} @keys };	
	$entity{encode}->{regex} = join "|", map { quotemeta($_) } @keys;
	$entity{decode}->{regex} = join "|", map { quotemeta($_) } keys %{$entity{decode}};
	$entity{escape} = +{
		map {
			chr($_) => sprintf("%%%02X", $_)
		} (0..255)
	};
	$entity{unescape} = +{
		map {
			$entity{escape}->{$_} => $_
		} keys %{$entity{escape}}
	};
	$esc = qr/[^A-Za-z0-9\-\._~]/;
	$unesc = qr/[0-9A-Fa-f]{2}/;
	$path = qr|^(([a-z][a-z0-9+\-.]*):(!?\/\/([^\/?#]+))?)?([a-z0-9\-._~%!\$\&'()*+,;=:@\/]*)?(\?[a-z0-9\-._~%!\$\&'()*+,;=:@\/]*)?(#[a-z0-9\-._~%!\$\&'()*+,;=:@\/]*)|;
	%recurse = (
		ARRAY => sub { return map { recurse($_, $_[1], $_[2]) } @{ $_[0] } },
		HASH => sub {  do { $_[0]->{$_} = recurse($_[0]->{$_}, $_[1], $_[2]) } for keys %{ $_[0] }; $_[0] },
		SCALAR => sub { ${$_[0]} =~ m/^[0-9.]+$/g ? $_[0] : do { ${$_[0]} =~ s/^(.*)$/recurse(${$_[1]})/e; $_[0]; }; }, 
	);
	%compare = (
		ARRAY => sub { 
			my $recurse = shift;
			my @length = sort { $a < $b } map { scalar @{ $_ } } (@_);
			for my $i (0 .. $length[0] - 1) { compare($recurse, map { $_->[$i] } @_) or return 0; }
			1;
		},
		HASH => sub {  
			my $recurse = shift;
			for my $k (combine_keys(@_)) {
				compare($recurse, map { $_->{$k} } @_) or return 0;
			}
			1;
		},
		SCALAR => sub { compare(shift, map {${$_}} @_) }, 
		MAGIC => sub { my %t; shift; map { $t{$_}++ } @_; scalar keys %t == 1; },
	);
}
{
	# all powerfull
	no strict 'refs';
	my $counter = 0;
	*{"Type::Tiny::by"} = sub {
		my ($pn, $parent, $hide, $act) = ($_[0]->name, shift, shift);
		$act = ref $hide ? sub { compare(\%compare, @_) } : sub { $_[0] =~ m/$_[1]/; };
		my $self = do {
			$_ =~ m/^$pn/ && exists $meta->{types}->{$_}->{abuse}
				&& $act->($meta->{types}->{$_}->{abuse}, $hide)
					and return $meta->{types}->{$_} foreach $meta->type_names; 
			undef; 
		} || $meta->add_type({ 
			name => $parent->name . $counter++,
			parent => $parent->{abuse_parent} && $parent->{abuse_parent}->($hide) || $parent,
			coercion => $parent->{abuse}->($hide),
			abuse => $hide,
			($parent->{abuse_constraint} ? (constraint => $parent->{abuse_constraint}->($hide)) : ())
		});
		return $self;
	};
}

$meta->add_type({
	name => 'StrToArray',
	parent => scalar $meta->ArrayRef, 
	abuse => \&_strToArray
});

sub _strToArray {
	my $hide = shift;
	return sub { 
		defined $_[0] ? [split $hide, $_[0]] : $_[0];
	}
}

$meta->add_type({
	name => 'StrToHash',
	parent => scalar $meta->HashRef, 
	abuse => \&_strToHash
});

sub _strToHash {
	my $hide = shift;
	return sub {
		defined $_[0] ? +{split $hide, $_[0]} : $_[0];
	}
}

$meta->add_type({
	name => 'ArrayToHash',
	parent => scalar $meta->HashRef,
	coercion => sub {
		+{ 
			@{ $_[0] }
		};
	},
	abuse => \&_hash
});

sub _hash {
	my $hide = sprintf "array_to_hash_%s", shift;
	return \&$hide;
}

# issues with the following is that arrays are not always flat *|o|*  
sub array_to_hash_reverse {
	my @array = @{$_[0]}; 
	my %hash;
	while (@array) {
		my ($even, $odd) = (shift @array, shift @array);
		$hash{$odd} = $even
	}
	return \%hash;
}

sub array_to_hash_odd {
	my @array = @{$_[0]}; 
	return +{ (map {$array[$_]} grep {$_ & 1} 1 .. scalar @array - 1) };
}

sub array_to_hash_even {
	my @array = @{$_[0]}; 
	return +{ (map {$array[$_]} grep {not $_ & 1} 0 .. scalar @array - 1) };
}

sub array_to_hash_flat {
	return +{ _flat($_[0]) };
}

sub array_to_hash_merge {
	return +{ 
		map { %{$_} } grep { ref $_ eq 'HASH' } @{$_}
	}
}

$meta->add_type({
	name => 'HashToArray',
	parent => scalar $meta->ArrayRef,
	coercion => sub {
		defined $_[0] ? [
			map { $_, $_[0]->{$_} } sort keys %{ $_[0] }
		] : $_[0];
	},
	abuse => \&_arrays
});

sub _arrays {
	my $hide = sprintf ('hash_to_array_%s', shift); 
	\&$hide;
}

sub hash_to_array_keys {
	return [ sort keys %{ $_[0] } ];
}

sub hash_to_array_values {
	return [ sort values %{ $_[0] } ];
}

sub hash_to_array_flat {
	return [_flat($_[0])];
}

sub _flat { 
	my @lazy;
	my %r = (
		ARRAY => sub { map { recurse($_[0], $_) } @{ $_[1] } },
		HASH => sub { do { recurse($_[0], $_) && recurse($_[0], $_[1]->{$_}); } for sort keys %{ $_[1] }; },
		SCALAR => sub { recurse($_[0], ${$_[1]}) }, 
		MAGIC => sub { push @lazy, $_[1] },
	);
	recurse(\%r, $_[0]);
	return @lazy;
}

$meta->add_type({
	name => 'HTML',
	parent => scalar $meta->Str,
	abuse_constraint => \&_html_constraint,
	abuse => \&_html
});

sub _html_constraint {
	my $hide = sprintf('constraint_%s', shift);
	\&$hide;
}

sub _html {
	my $hide = sprintf('%s', shift);
	\&$hide;
}

sub constraint_encode_entity {
	my ($str, %encode) = (shift,  %{ $entity{encode} });
	$str =~ m/($encode{regex})(?![a-z#]+;)/ ? 0 : 1;
}

sub encode_entity {
	my ($str, %encode) = (shift, %{ $entity{encode} });
	$str =~ s/($encode{regex})/$encode{$1}/eg;
	return $str;
}

sub constraint_decode_entity {
	shift =~ m/&([a-z#]+;)/ ? 0 : 1;
}

sub decode_entity {
	my ($str, %decode) = (shift, %{ $entity{decode} });
	$str =~ s/($decode{regex})/$decode{$1}/eg;
	return $str;
}

$meta->add_type({
	name => 'URI',
	parent => scalar $meta->Object,
	constraint => sub {
		my $obj = ref $_[0];
		$obj =~ m!^URI! ? 1 : 0;	
	},
	coercion => sub {
		require URI;
		my @args = ref $_[0] ? @{ $_[0] } : $_[0];
		my $queryForm = pop @args if ref $args[scalar @args - 1] eq 'HASH'; 
		my $uri = URI->new(@args);
		$uri->query_form($queryForm) if $queryForm;
		return $uri;
	},
	abuse_parent => \&_uri_change,
	abuse_constraint => \&_uri_constraint,
	abuse => \&_uri
});

sub _uri_change {
	my $hide = shift;
	return scalar $meta->Str if $hide =~ m/^escape|unescape|schema|host|path|query_string|fragment$/;
	return scalar $meta->HashRef;
}

sub _uri_constraint {
	my $hide = sprintf "constraint_uri_%s", shift;	
	\&$hide;
}

# I don't know why, just don't ask
sub constraint_uri_schema {
	$_[0] =~ m/$path/;
	$4 || $5 || $6 || $7 ? 0 : 1;
}

sub constraint_uri_host {
	$_[0] =~ m/$path/;
	$2 || $5 || $6 || $7 ? 0 : 1;
}

sub constraint_uri_path {
	$_[0] =~ m/$path/;
	$2 || $4 || $6 || $7 ? 0 : 1;
}

sub constraint_uri_query_string {
	$_[0] =~ m/$path/;
	$2 || $4 || $5 || $7 ? 0 : 1;
}

sub constraint_uri_fragment {
	$_[0] =~ m/$path/;
	$2 || $4 || $5 || $6 ? 0 : 1;
}

sub constraint_uri_query_form {
	ref $_[0] eq 'HASH' ? 1 : 0;
}

sub constraint_uri_escape {
	$_[0] =~ m/($esc)(?!$unesc)/ ? 0 : 1;
}

sub constraint_uri_unescape {
	$_[0] =~ m/%$unesc/ ? 0 : 1;
}

sub _uri {
	my $hide = sprintf "uri_%s", shift;
	\&$hide;
}

sub uri_schema {
	$_[0] =~ m/$path/;
	return $2;
}

sub uri_host {
	$_[0] =~ m/$path/;
	return $4;
}

sub uri_path {
	$_[0] =~ m/$path/;
	return $5;
}

sub uri_query_string {
	$_[0] =~ m/$path/;
	return uri_unescape($6);
}

sub uri_fragment {
	$_[0] =~ m/$path/;
	return $7;
}

sub uri_query_form {
	$_[0] =~ m/$path/;
	my $query_string = uri_unescape($6);
	$query_string =~ s,^\?,,;
	return +{
		split '=', $query_string
	};
}

sub uri_escape {
	my ($string, %escape) = (shift, %{ $entity{escape} }); 
	$string =~ s/($esc)/$escape{$1}/eg;
	$string;
}

sub uri_unescape {
	my ($string, %unescape) = (shift, %{ $entity{unescape} });
	$string =~ s/(%$unesc)/$unescape{$1}/eg;
	$string;
}

$meta->add_type({
	name => 'Count',
	parent => scalar $meta->Str,
	abuse_constraint => \&_count_constraint,
	abuse => \&_html,
	coercion => sub {
		my $ref = ref $_[0];
		return $ref eq 'ARRAY' ? scalar @{$_[0]} : scalar keys %{$_[0]};
	},
});

$meta->add_type({
	name => 'JSON',
	parent => scalar $meta->Any,
	constraint => sub {
		my $ref = ref $_[0];
		$ref ? 1 : 0;
	},
	coercion => sub {
		require JSON;
		my $json = JSON->new;
		return $json->decode($_[0]);
	},	
	abuse_parent => \&_json_change,
	abuse => \&_json
});

sub _json_change {
	my $ref = ref $_[0];
 	return unless ! $ref || $ref eq 'ARRAY';
	my $key = $ref eq 'ARRAY' ? $_[0]->[0] : $_[0];
	my $type = eval{ $meta->$key };
	$type ? shift @{$_[0]} : do { $type = $meta->Str if $key eq 'encode'; };
	$type;
}

sub _json {
	require JSON;
	my $json = JSON->new;
	my $ref = ref $_[0];
	my $type = $ref ? $_[0]->[0] : $_[0];
	map { $json = $json->$_ } @{ $_[0]->[1] } if ( $ref && ref $_[0]->[1] eq 'ARRAY' );
	return sub {  $json->$type($_[0]) };
}

sub compare {
	my ($recurse, %same) = shift;
	$same{reftype $_ || 'MAGIC'}++ for @_;
	return 0 if scalar keys %same != 1;
	return $recurse->{[(keys %same)]->[0]}->($recurse, @_);
}

sub recurse {
	my ($recurse, $ref) = shift;
	$ref = reftype($_[0]) || 'MAGIC';
	$recurse->{$ref}->($recurse, $_[0]) if (exists $recurse->{$ref});
	$_[0];
}

# TODO a little documentations
# TBC .....

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Coerce::Types::Standard - Coercing

=head1 VERSION

Version 0.000004

=cut

=head1 SYNOPSIS

	package Headache;

	use Coerce::Types::Standard qw/Str HashRef ArrayRef StrToHash StrToArray/;

	attributes(
		[qw/sleep/] => [StrToHash->by(' '), {coe}]
	);

=head1 Exports

Coerce::Types::Standard extends Types::Standard it exports Nothing by default. The following outlines the additional types that can be exported using this module.

=head2 StrToArray

Accepts a string and coerces it into a ArrayRef, You can specify how to split the string by instantiating with *by*.

	StrToArray->by('--')->coerce('mid--flight--documenter');
	*-*-*-*-*-*-*
	[qw/mid flight documenter/]
	
=head2 StrToHash 

Accepts a string and coerces it into a HashRef, You can specify how to split the string by instantiating with *by*.

	StrToHash->by(", ")->coerce('I, drink, way, too, much, coffee');
	*-*-*-*-*-*-*
	{
		I => 'drink',
		way => 'too',
		much => 'coffee',
	}

=head2 ArrayToHash

Accepts an ArrayRef and coerces it into a HashRef, the default behaviour here is to just dereference the array into a hash.

	ArrayToHash->coerce([qw/north south east west/]);
	*-*-*-*-*-*-*
	{
		north => 'south',
		east => 'west'
	}

You can also instantiate this object via *by* and passing in a *mode*, currently the following are your options.

=over

=item odd

Only build my hash out of the odd **index** of the array (1, 3, 5, 7 .....)

	ArrayToHash->by('odd')->coerce([qw/zero one two three/]);
	*-*-*-*-*-*-*
	{
		one => 'three',
	}

=item even

Only build my hash out of the even **index** of the array (0, 2, 4, 6 .....)

	ArrayToHash->by('even')->coerce([qw/zero one two three/]);
	*-*-*-*-*-*-*
	{
		zero => 'two',
	}

=item reverse

Reverse the default behavior so keys are values and values are keys.
	
	ArrayToHash->by('reverse')->coerce([qw/north south east west/]);
	*-*-*-*-*-*-*
	{
		south => 'north',
		west => 'east'
	}

=item flat

Should convert any struct into a one level Hash.

	ArrayToHash->by('flat')->coerce([{ ux => 'ui', analyst => [qw/document support meeting/] }, [qw/sysAdmin backend db deploy/]]);	
	*-*-*-*-*-*-*
	{
		analyst => 'document',
		ux => 'ui',
		support => 'meeting',
		db => 'deploy',
		sysAdmin => 'backend'
	}


=item merge

Simple single level merge of an array of hash references.

	ArrayToHash->by('merge')->coerce([{ simple => 'merge' }, { simple => 'life' }]);
	*-*-*-*-*-*-*
	{
		simple => 'life'
	}

=back

=head2 HashToArray

Accepts a HashRef and coerces it into a ArrayRef, the default behaviour here is to just dereference the hash into a array.

	HashToArray->coerce({ 
		Malaysia => 'KL', 
		Austrailia => 'Sydney',   
		Indonesia => 'Bali',
	});
	*-*-*-*-*-*-*
	[qw/Austrailia Sydney Indonesia Bali Malaysia KL/]

You can also instantiate this object via *by* and passing in a *mode*, currently the following are your options.

=over

=item keys

Only coerce the hash references keys into an array refernce.

	HashToArray->by('keys')->coerce({ 
		Malaysia => 'KL', 
		Austrailia => 'Sydney',   
		Indonesia => 'Bali',
	});
	*-*-*-*-*-*-*
	[qw/Austrailia Indonesia Malaysia/]

=item values

Only coerce the hash references values into an array refernce.

	HashToArray->by('values')->coerce({ 
		Malaysia => 'KL', 
		Austrailia => 'Sydney',   
		Indonesia => 'Bali',
	});
	*-*-*-*-*-*-*
	[qw/Bali KL Sydney/]

=item flat

Should convert any struct into a single level Array.

	HashToArray->by('flat')->coerce({ ux => ['ui'], analyst => [qw/document support meeting/] });	
	*-*-*-*-*-*-*
	[
		qw/analyst document ux ui support meeting/
	]

=back

=head2 HTML

=over

=item encode_entity

=item decode_entity

=back

=head2 URI

=over

=item schema

=item host

=item path

=item query_string

=item query_form

=item fragment

=item params

=item escape

=item unescape

=item 

=back

=head2 Count

=head2 JSON

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-coerce-types-standard at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Coerce-Types-Standard>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Coerce::Types::Standard

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Coerce-Types-Standard>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Coerce-Types-Standard>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Coerce-Types-Standard>

=item * Search CPAN

L<http://search.cpan.org/dist/Coerce-Types-Standard/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Coerce::Types::Standard
