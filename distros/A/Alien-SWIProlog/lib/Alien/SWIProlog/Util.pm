package Alien::SWIProlog::Util;
# ABSTRACT: Utilities for SWI-Prolog configuration
$Alien::SWIProlog::Util::VERSION = '0.002';
use Capture::Tiny qw(capture_stdout);
use File::Spec;

use constant SWIPL_ARGS => qw(
	--dump-runtime-variables
	-dump-runtime-variables
);

sub get_plvars {
	my ($pl_bin) = @_;
	for my $arg ( SWIPL_ARGS() ) {
		my ($out, $exit) = capture_stdout {
			system( $pl_bin, $arg );
		};
		my $plvars = parse_plvars($out);
		return $plvars;
	}
}

sub plvars_to_props {
	my ($pl, $plvars) = @_;

	# older swipl have PLLDFLAGS but no PLLIBDIR
	my $gen_PLLIBDIR;
	if( ! exists $plvars->{PLLIBDIR} ) {
		$gen_PLLIBDIR = File::Spec->catfile(
			$plvars->{PLBASE},
			'lib',
			$plvars->{PLARCH}, )
	}

	return +{
		'swipl-bin' => $pl,
		home => $plvars->{PLBASE},
		cflags => "-I$plvars->{PLBASE}/include",
		libs => ( exists $plvars->{PLLIBDIR}
			? join(' ', "-L$plvars->{PLLIBDIR}", $plvars->{PLLIB})
			: join(' ', "-L$gen_PLLIBDIR", $plvars->{PLLDFLAGS}, $plvars->{PLLIB}),
			),
		rpath => [
			( exists $plvars->{PLLIBDIR}
			?  $plvars->{PLLIBDIR}
			:  $gen_PLLIBDIR
			)
		],
		_PLVARS => $plvars,
	}
}

sub parse_plvars {
	my ($pl_dump_output) = @_;
	return +{ $pl_dump_output =~ /^(PL.*?)="(.*)";$/mg };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SWIProlog::Util - Utilities for SWI-Prolog configuration

=head1 VERSION

version 0.002

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
