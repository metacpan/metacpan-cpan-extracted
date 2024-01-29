# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequirePodSections)
package Date::Extract::P800Picture::Module::Build v1.1.7;

use 5.014000;

use strict;
use warnings;

use Carp;
use English qw($OS_ERROR $EXECUTABLE_NAME -no_match_vars);

use parent 'Date::Extract::P800Picture::Module::Build::Standard';

## no critic (Capitalization)
sub ACTION_nytprof {
## use critic
    my ($self) = @_;
    $self->depends_on('build');
    $self->_run_nytprof();
    return;
}

sub _run_nytprof {
    my ($self) = @_;
    eval { require Devel::NYTProf; 1 }
      or Carp::croak 'Devel::NYTProf is required to run nytprof';
    eval { require File::Which; File::Which->import('which'); 1 }
      or Carp::croak 'File::Which is required to run nytprof';
    my $nytprofhtml = File::Which::which('nytprofhtml')
      or Carp::croak 'Could not find nytprofhtml in your PATH';
    my $this_perl = $EXECUTABLE_NAME;
    my @perl_args = qw(-Iblib/lib -d:NYTProf bin/p800date 36LC0079.jpg);
    warn qq{Running: $this_perl @perl_args\n};
    my $status = system $this_perl, @perl_args;

    if ( 1 == $status ) {
        Carp::croak qq{p800date failed with status $status};
    }
    $status = system $nytprofhtml;
    if ($status) {
        Carp::croak qq{nytprofhtml failed with status $status};
    }
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords nytprof profiler Ipenburg

=head1 NAME

Date::Extract::P800Picture::Module::Build - Customization of L<Module::Build>
for L<Date::Extract::P800Picture>.

=head1 DESCRIPTION

This is a custom subclass of L<Module::Build> (actually,
L<Date::Extract::P800Picture::Module::Build::Standard>) that enhances existing
functionality and adds more for the benefit of installing and developing
L<Date::Extract::P800Picture>.  The following actions have been added or
redefined:

=head1 ACTIONS

=over

=item nytprof

Runs C<perlcritic> under the L<Devel::NYTProf> profiler and generates
an HTML report in F<nytprof/index.html>.

=back

=head1 AUTHOR

Roland van Ipenburg <roland@rolandvanipenburg.com>, based on the work of Elliot
Shank <perl@galumph.com> in L<Perl::Critic>.

=head1 COPYRIGHT

Copyright (c) 2024 Roland van Ipenburg.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
