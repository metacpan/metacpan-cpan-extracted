package Crop::Util;

=pod

=head1 NAME

Crop::Util - Utility functions for the Crop framework

=head1 SYNOPSIS

    use Crop::Util;
    # ...usage...

=head1 DESCRIPTION

Crop::Util provides general utility functions for the Crop framework.

=head1 AUTHORS

Euvgenio (Core Developer)

Alex (Contributor)

=head1 COPYRIGHT AND LICENSE

Apache 2.0

=cut

use base qw/ Exporter /;

=begin nd
Package: Crop::Util
	General purose functions.
	
	Non-OOP module.
=cut

use strict;
use v5.14;

use Crop::Error;
use Crop::Debug;

=begin nd
Variable: our @EXPORT_OK
	Functions exported by order:

	- expose_hashes
	- load_class
	- split_by_3
	- trim
=cut
our @EXPORT    = qw/ expose_hashes /;
our @EXPORT_OK = qw/ load_class /;

=begin nd
Method: expose_hashes (\@hash)
	Expose arrayref to hash.

	References in even position will be dereferenced.
	
Parameters:
	\@hash - hash elements packed to an array

Returns:
	hash reference
=cut
sub expose_hashes {
	my $src = shift;
	return warn "|ERR: expose_hashes() expects one argument exactly" if @_;
	return warn "|ERR: expose_hashes() expects arrayref" unless ref $src eq 'ARRAY';
	
	my (@dst, $position);
	for (@$src) {
		if (++$position % 2 and ref $_ eq 'HASH') {  # expose reference in a key position
			push @dst, %$_;
			++$position;
		} else {
			push @dst, $_;
		}
	}

	+{@dst};  # ref - not a block instruction
}

=begin nd
Function: load_class ($module)
	Load a class by name.
	
	>load_class(My::Module)
	
Parameters:
	$module - name of module in form of Perl (My::Module)
	
Returns:
	true  - if module successed
	false - otherwise
=cut
sub load_class {
	my $module = shift;

	$module =~ s!::!/!g;
	$module .= '.pm';

	require $module or warn "OBJECT: Failed to load a module from $module";
}

1;
