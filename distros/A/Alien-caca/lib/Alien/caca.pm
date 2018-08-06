package Alien::caca;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Alien package for the Colored ASCII Art library 
$Alien::caca::VERSION = '0.0.3';
use strict;
use warnings;

use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::caca - Alien package for the Colored ASCII Art library 

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS 

In your Build.PL:

    use Module::Build;
    use Alien::caca;
    my $builder = Module::Build->new(
        ...
        configure_requires => {
            'Alien::caca' => '0',
            ...
        },
        extra_compiler_flags => Alien::caca->cflags,
        extra_linker_flags   => Alien::caca->libs,
        ...
    );
 
    $build->create_build_script;

In your Makefile.PL:

    use ExtUtils::MakeMaker;
    use Config;
    use Alien::caca;
    
    WriteMakefile(
    ...
    CONFIGURE_REQUIRES => {
        'Alien::caca' => '0',
    },
    CCFLAGS => Alien::caca->cflags . " $Config{ccflags}",
    LIBS    => [ Alien::caca->libs ],
    ...
    );

=head1 DESCRIPTION 

This distribution installs L<libcaca|http://caca.zoy.org/wiki/libcaca> so that it can be used by other Perl distributions.  Mostly L<Term::Caca>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
