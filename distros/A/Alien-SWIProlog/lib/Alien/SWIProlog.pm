package Alien::SWIProlog;
# ABSTRACT: Alien package for the SWI-Prolog Prolog interpreter
$Alien::SWIProlog::VERSION = '0.002';
use strict;
use warnings;

use base qw(Alien::Base);
use Role::Tiny::With qw( with );
use Class::Method::Modifiers;
use Alien::SWIProlog::Util;
use Env qw(
	$SWI_HOME_DIR
);

with 'Alien::Role::Dino';

before import => sub {
	my $class = shift;

	$SWI_HOME_DIR = $class->runtime_prop->{home};
	my @swi_lib_dirs = $class->rpath;
	require DynaLoader;
	unshift @DynaLoader::dl_library_path, @swi_lib_dirs;
	my ($dlfile) = DynaLoader::dl_findfile('-lswipl');
	DynaLoader::dl_load_file($dlfile);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SWIProlog - Alien package for the SWI-Prolog Prolog interpreter

=head1 VERSION

version 0.002

=head1 SEE ALSO

L<SWI-Prolog|https://www.swi-prolog.org/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
