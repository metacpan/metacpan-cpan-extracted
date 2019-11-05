package My::Module::Meta;

use 5.008;

use strict;
use warnings;

use Carp;

sub new {
    my ( $class ) = @_;
    ref $class and $class = ref $class;
    my $self = {
	distribution => $ENV{MAKING_MODULE_DISTRIBUTION},
    };
    bless $self, $class;
    return $self;
}

sub build_requires {
    return +{
	'Test::More'	=> 0.88,	# Because of done_testing().
    };
}

sub distribution {
    my ( $self ) = @_;
    return $self->{distribution};
}

sub requires {
    my ( undef, @extra ) = @_;		# Invocant unused
    return {
	'Astro::Coord::ECI'		=> 0.077,
	'Astro::Coord::ECI::Moon'	=> 0.077,
	'Astro::Coord::ECI::Star'	=> 0.077,
	'Astro::Coord::ECI::Sun'	=> 0.077,
	'Astro::Coord::ECI::TLE'	=> 0.077,
	'Astro::Coord::ECI::TLE::Iridium'	=> 0.077,
	'Astro::Coord::ECI::TLE::Set'	=> 0.077,
	'Astro::Coord::ECI::Utils'	=> 0.077,	# for time_gm() ...
	'Carp'			=> 0,
	'Clone'			=> 0,
	'Cwd'			=> 0,
	'File::Glob'		=> 0,
	'File::HomeDir'		=> 0.93,	# For my_dist_config
	'File::Spec'		=> 0,
	'File::Temp'		=> 0,
	'Getopt::Long'		=> 2.39,	# For getoptionsfromarray
	'I18N::LangTags'	=> 0,
	'I18N::LangTags::Detect'	=> 0,
	'IO::File'		=> 1.14,
	'IO::Handle'		=> 0,
	'IPC::System::Simple'	=> 0,
	'List::Util'		=> 0,
##	'Params::Util'		=> 0.250,
	'POSIX'			=> 0,
	'Scalar::Util'		=> 1.26,	# For isdual()
##	'Task::Weaken'		=> 0,
	'Template'		=> 2.21,
	'Template::Constants'	=> 2.21,
	'Template::Provider'	=> 2.21,
	'Text::Abbrev'		=> 0,
	'Text::ParseWords'	=> 0,
	'Text::Wrap'		=> 0,
	'Time::Local'		=> 0,
	'constant'		=> 0,
	'parent'		=> 0,
	'strict'		=> 0,
	'warnings'		=> 0,
	@extra,
    };
}

sub requires_perl {
    return 5.008;
}

sub meta_merge {
    my ( undef, @extra ) = @_;
    return {
	'meta-spec'	=> {
	    version	=> 2,
	},
	dynamic_config	=> 1,
	no_index	=> {
	    directory	=> [ qw{ inc t xt } ],
	},
	resources	=> {
	    bugtracker	=> {
                web	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-App-Satpass2',
#                mailto  => 'wyant@cpan.org',
            },
	    license	=> 'http://dev.perl.org/licenses/',
	    repository	=> {
		type	=> 'git',
		url	=> 'git://github.com/trwyant/perl-Astro-App-Satpass2.git',
		web	=> 'https://github.com/trwyant/perl-Astro-App-Satpass2',
	    },
	},
	@extra,
    };
}

sub provides {
    -d 'lib'
	or return;
    local $@ = undef;
    my $provides = eval {
	require Module::Metadata;
	Module::Metadata->provides( version => 2, dir => 'lib' );
    } or return;
    return ( provides => $provides );
}


1;

__END__

=head1 NAME

My::Module::Meta - Information needed to build Astro::App::Satpass2

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Meta;
 my $meta = My::Module::Meta->new();
 use YAML;
 print "Required modules:\n", Dump(
     $meta->requires() );

=head1 DETAILS

This module centralizes information needed to build C<My::Module>. It
is private to the C<My::Module> package, and may be changed or
retracted without notice.

=head1 METHODS

This class supports the following public methods:

=head2 new

 use lib qw{ inc };
 my $meta = My::Module::Meta->new();

This method instantiates the class.

=head2 build_requires

 use YAML;
 print Dump( $meta->build_requires() );

This method computes and returns a reference to a hash describing the
modules required to build the C<Astro::Coord::ECI> package, suitable for
use in a F<Build.PL> C<build_requires> key, or a F<Makefile.PL>
C<< {META_MERGE}->{build_requires} >> key.

=head2 distribution

 if ( $meta->distribution() ) {
     print "Making distribution\n";
 } else {
     print "Not making distribution\n";
 }

This method returns the value of the environment variable
C<MAKING_MODULE_DISTRIBUTION> at the time the object was instantiated.

=head2 meta_merge

 use YAML;
 print Dump( $meta->meta_merge() );

This method returns a reference to a hash describing the meta-data which
has to be provided by making use of the builder's C<meta_merge>
functionality. This includes the C<dynamic_config>, C<no_index> and
C<resources> data.

Any arguments will be appended to the generated array.

=head2 provides

 use YAML;
 print Dump( [ $meta->provides() ] );

This method attempts to load L<Module::Metadata|Module::Metadata>. If
this succeeds, it returns a C<provides> entry suitable for inclusion in
L<meta_merge()|/meta_merge> data (i.e. C<'provides'> followed by a hash
reference). If it can not load the required module, it returns nothing.

=head2 requires

 use YAML;
 print Dump( $meta->requires() );

This method computes and returns a reference to a hash describing
the modules required to run the C<My::Module> package, suitable for
use in a F<Build.PL> C<requires> key, or a F<Makefile.PL> C<PREREQ_PM>
key. Any additional arguments will be appended to the generated hash. In
addition, unless L<distribution()|/distribution> is true,
configuration-specific modules may be added.

=head2 requires_perl

 print 'This package requires Perl ', $meta->requires_perl(), "\n";

This method returns the version of Perl required by the package.

=head1 ATTRIBUTES

This class has no public attributes.


=head1 ENVIRONMENT

=head2 MAKING_MODULE_DISTRIBUTION

This environment variable should be set to a true value if you are
making a distribution. This ensures that no configuration-specific
information makes it into F<META.yml>.


=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
