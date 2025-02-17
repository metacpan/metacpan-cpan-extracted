package Cache::CodeBlock;
our $VERSION = '0.04';
use 5.006; use strict; use warnings; use feature qw/state/;
use CHI;

state $CACHE;

sub import {
	my ($package, %chi) = @_;
	$CACHE = CHI->new(
		driver => 'Memory',
		global => 1,
		%chi
	);
	do {
		no strict 'refs';
		my $package = caller();
		*{"${package}::cache"} = \&cache;
	};
}

sub cache (&@) {
        my ($code, $timeout, $unique) = @_;
	my @caller = caller();
	my $addr = sprintf("%s-%s-%s-%s", $caller[0], $caller[1], $caller[2], $unique || 'default');
	return $CACHE->get($addr) // do {
		my $value = $code->();
		$CACHE->set( $addr, $value, (defined $timeout ? $timeout : ()) );
		return $value;
	};
}

1;

__END__

=head1 NAME

Cache::CodeBlock - caching via a code block

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Cache::CodeBlock (
		%CHI
	);

	sub my_data {
		my ($self, @params) = @_;
		my $historical = cache {
			...
			return $data;
		};
		...
		my $neoteric = cache {
			...
			return $data;
		} 60, $id;
	}

=head1 EXPORT

=head2 cache

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cache-codeblock at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cache-CodeBlock>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cache::CodeBlock

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Cache-CodeBlock>

=item * Search CPAN

L<https://metacpan.org/release/Cache-CodeBlock>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022->2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
