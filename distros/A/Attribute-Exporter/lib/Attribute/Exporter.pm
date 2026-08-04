package Attribute::Exporter;

use 5.6.0;

use strict;
use warnings;

use Carp;

my %exports;
my %export_ok;
my $export_tags;

our $Verbose ||= 0;
our $VERSION = '0.02';
our $use_indirection ||= 0;

sub export_constant {
	my $src_pkg = shift;
	for my $arg (@_) {
		if (ref($arg)) {
			if (!defined(&$arg)) {
				die("undefined subroutine ${src_pkg}::$arg requested for export");
			}

			push(@{$exports{$src_pkg}}, $arg);
			next;
		}

		no strict 'refs';
		my $ref = *{"${src_pkg}::$arg"}{CODE};
		use strict;
		if (!defined($ref)) {
			die("unknown constant ${src_pkg}::$arg requested for export");
		}

		push(@{$exports{$src_pkg}}, $ref);
	}
}

sub _export_symbol {
	$use_indirection ? _indirect_symbol(@_) : _alias_symbol(@_);
}

sub _indirect_symbol {
	my ($src_pkg, $dest_pkg, $name, $type) = @_;

	$Verbose && warn "${src_pkg}::$name => indirect(${dest_pkg}::$name, $type)\n";

	no strict 'refs';
	if ($type eq 'CODE') {
		*{"${dest_pkg}::$name"} = sub {
			local *sym	= *{"${src_pkg}::${name}"};
			&sym(@_);
		};
	} elsif ($type eq 'SCALAR') {
		tie my $scalar, 'Attribute::Exporter::TieScalar', $src_pkg, $name;
		*{"${dest_pkg}::$name"} = \$scalar;
	} elsif ($type eq 'ARRAY') {
		die "not yet implemented";
	} elsif ($type eq 'HASH') {
		die "not yet implemented";
	} elsif ($type eq 'REF') {
		die "not yet implemented";
	}
	use strict;
}

sub _alias_symbol {
	my ($src_pkg, $dest_pkg, $name, $type) = @_;

	$Verbose && warn "${src_pkg}::$name => ${dest_pkg}::$name $type\n";

	no strict 'refs';
	if ($type eq 'ARRAY') {
		*{"${dest_pkg}::$name"} = \@{"${src_pkg}::$name"};
	} elsif ($type eq 'HASH') {
		*{"${dest_pkg}::$name"} = \%{"${src_pkg}::$name"};
	} elsif ($type eq 'SCALAR') {
		*{"${dest_pkg}::$name"} = \${"${src_pkg}::$name"};
	} elsif ($type eq 'REF') {
		*{"${dest_pkg}::$name"} = \${"${src_pkg}::$name"};
	} elsif ($type eq 'CODE') {
		*{"${dest_pkg}::$name"} = \&{"${src_pkg}::$name"};
	}
	use strict;
}

sub find_symbol_name {
	my ($src_pkg, $ref) = @_;

	my $reftype = ref($ref);

	if ($reftype eq 'REF') {
		$reftype = 'SCALAR';
	}

	my $ret = undef;

	no strict 'refs';
	for my $name (keys(%{"${src_pkg}::"})) {
		if ($name =~ m/::$/) {
			next;
		}
		local *sym = *{"${src_pkg}::$name"};

		if (*sym{$reftype} && *sym{$reftype} eq $ref) {
			$ret = $name;
			last;
		}
	}
	use strict;

	return $ret;
}

sub import {
	my $src_pkg = shift;

	my ($dst_pkg) = caller(0);

	# Export all the default exports to the caller
	if (!@_) {
		$Verbose && carp "importing all default symbols to $src_pkg";

		for my $ref (@{$exports{$src_pkg}}) {
			my $name = find_symbol_name($src_pkg, $ref);
			if (!$name) {
				$Verbose && warn "unable to find symbol name for ${src_pkg}::$ref";
				next;
			}
			_export_symbol($src_pkg, $dst_pkg, $name, ref($ref));
		}

		return;
	}

	$Verbose &&
		carp "importing ${src_pkg}::" . join(',', @_) . " symbols into $dst_pkg";

	# Export named exports to the caller
	for my $import (@_) {
		# Process tags
		if ($import =~ m/^:(.+)$/) {
			map {
				my $ref = $_;
				my $name = find_symbol_name($src_pkg, $ref);

				if (!$name) {
					$Verbose && carp "unable to find symbol name for ${src_pkg}::$ref";
				} else {
					_export_symbol($src_pkg, $dst_pkg, $name, ref($ref));
				}
			} @{$export_tags->{$src_pkg}->{$1}};

			next;
		}

		# Process individual items requested for import into the caller
		my %types = (
			'$' => 'SCALAR',
			'@' => 'ARRAY',
			'%' => 'HASH',
			'&' => 'CODE',
		);

		my ($sigil, $name) = $import =~ m/^(\$|\@|\%|\&)?(.+)$/;

		my $type = $sigil ? $types{$sigil} : 'CODE';

		_export_symbol($src_pkg, $dst_pkg, $name, $type);
	}
}

sub MODIFY_HASH_ATTRIBUTES {
	goto &_MODIFY_ATTRIBUTES;
}

sub MODIFY_SCALAR_ATTRIBUTES {
	goto &_MODIFY_ATTRIBUTES;
}

sub MODIFY_ARRAY_ATTRIBUTES {
	goto &_MODIFY_ATTRIBUTES;
}

sub MODIFY_CODE_ATTRIBUTES {
	goto &_MODIFY_ATTRIBUTES;
}

sub MODIFY_REF_ATTRIBUTES {
	goto &_MODIFY_ATTRIBUTES;
}

sub _MODIFY_ATTRIBUTES {
	my ($src_pkg, $ref, @attrs) = @_;

	my $reftype = ref($ref);

	$Verbose == 2 && warn "args " . join(',', @_) . "\n";
	$Verbose == 2 &&
		warn "processing $reftype ($ref) with attrs " . join(',', @attrs) . "\n";

	my %attrs = map { $_ => 1 } @attrs;

	# strip the handled attributes
	my $export_def_attr = delete($attrs{export_def});
	my $export_ok_attr = delete($attrs{export_ok});
	my @export_tag_attrs;
	for my $attr (keys(%attrs)) {
		if (my ($tag) = $attr =~ m/^export_tag\(([^)]+)\)$/) {
			if ($tag eq 'DEFAULT' || $tag eq 'OK') {
				carp "using $tag as an export tag clobbers internal $tag";
			}
			push(@export_tag_attrs, split(m/,/, $tag));
			delete($attrs{$attr})
		}
	}

	# save the unhandled attributes to pass back
	my @unhandled = keys(%attrs);

	if ($export_def_attr) {
		push(@{$exports{$src_pkg}}, $ref);
		push(@export_tag_attrs, 'DEFAULT');
	}

	if ($export_ok_attr) {
		push(@{$export_ok{$src_pkg}}, $ref);
		push(@export_tag_attrs, 'OK');
	}

	map {
		push(@{$export_tags->{$src_pkg}->{$_}}, $ref);
	} @export_tag_attrs;

	return @unhandled;
}

package Attribute::Exporter::TieScalar;

use strict;
use warnings;

sub TIESCALAR {
	my ($class, $src_pkg, $symbol) = @_;
	return bless({ src_pkg => $src_pkg, symbol => $symbol });
}

sub FETCH {
	my ($self) = @_;
	no strict 'refs';
	my $ret = ${$self->{src_pkg} . '::' . $self->{symbol}};
	use strict;
	return $ret;
}

sub STORE {
	my ($self, $store) = @_;
	${$self->{src_pkg} . '::' . $self->{symbol}} = $store;
	return $store;
}

1;

__END__

=head1 NAME

Attribute::Exporter

=head1 SYNOPSIS

In module F<YourModule.pm>

	package YourModule;
	use base qw(Attribute::Exporter);

	sub your_exported_sub :export_def {
		# will be exported into caller's symbol table
	}

	sub your_export_ok_sub :export_ok {
		# may be imported into caller's symbol table with:
		#	 use YourModule qw/your_export_ok_sub/;
	}

	sub your_export_tag_sub :export_tag(tag) {
		# may be imported into caller's symbol table with:
		#	 use YourModule qw/:tag/;
	}

	our $your_exported_scalar :export_ok = 1;

=head1 DESCRIPTION

The Attribute::Exporter module adds attributes which control how your 
package exports symbols into calling package symbol tables.

=head2 How to export

Subroutines, arrays, hashes, scalars and typeglobs may be exported by
setting their attributes.	The following attributes are currently supported:

=over 4

=item export_def

This attribute will export the corresponding reference by default.

=item export_ok

This attribute will allow callers to specify they wish to import the
symbol.

=item export_tag(tag)

This attribute will add the reference to a list of items to be exported
to the callers namespace when they request to import of ":tag", specifying
export_tag(tag1,tag2) will add the symbol to both sets tag1 and tag2.

=back 

=head2 How to import

Files which want to import your package's symbols into their namespace
can do so via the following mechanisms:

=over 4

=item C<use YourModule;>

This will import any of YourModule's symbols created with the :export_def
attribute.

=item C<use YourModule qw/your_export_ok_sub/;>

This will import the list of symbols specified on the 'use YourModule'
line.	It will not import the :export_def symbols unless they have been
requested.	If you want the full :export_def set as well as specific
additional symbols you can ask for qw/:DEFAULT your_export_ok_sub/

=item C<use YourModule ();>

This will not import any symbols.

=back

=head2 Exporting constants

Currently perl's syntax does not support specifying attributes on a
use constant line.	Instead you can explicitly:

use constant SOME_CONSTANT => 'some constant';
__PACKAGE__->export_constant('SOME_CONSTANT');

Or:

use constant SOME_CONSTANT => 'some constant';
__PACKAGE__->export_constant(\&SOME_CONSTANT);

=head2 Special modes

Attribute::Exporter currently supports 2 additional modes of operation,
Verbose mode and Indirect mode.

=over 4

=item Verbose mode

Verbose mode will print to STDERR some information about what symbols
are being exported and where.	It is enabled thus:

	BEGIN {
		$Attribute::Exporter::Verbose = 1;
	}

=item	Indirect mode

Indirect mode creates symbols in the importing package's namespace
but does not link them directly but instead creates an indirection 
layer.	This means that if the exporting package is reloaded the
importing package will be able to access the reloaded symbols rather
than the symbols found on first invocation.

Indirect mode is enabled by setting:

	BEGIN {
		$Attribute::Exporter::use_indirection = 1; 
	}

n.b. Indirect mode is currently only supported for CODE and SCALAR
data types although support for ARRAY and HASH is straighforward to add.

=back

=head1 AUTHOR

Andrew Wansink E<lt>andy@halogix.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is made available under the same terms as Perl itself.

=cut
