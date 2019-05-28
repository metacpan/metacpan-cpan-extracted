# App::hopen::Phase::Gen - generation-phase operations
package App::hopen::Phase::Gen;
use Data::Hopen;
use Data::Hopen::Base;
#use parent 'Exporter';

our $VERSION = '0.000010';

#use Class::Tiny ;#qw(TODO);

# Docs {{{1

=head1 NAME

Data::Hopen::Phase::Gen - Generate build files

=head1 SYNOPSIS

Gen runs second.  Gen reads:

=over

=item *

the capability file from Probe

=item *

the options file from Probe, possibly with user edits

=item *

any context files identified by Probe

=item *

a recipes file specifying the build graph

=back

Gen outputs one or more blueprint files for a build system, such as make
or Ninja.

=cut

# }}}1

=head1 FUNCTIONS

=head2 todo

TODO

=cut

sub todo {
    my $self = shift or croak 'Need an instance';
    ...
} #todo()

#our @EXPORT = qw();
#our @EXPORT_OK = qw();
#our %EXPORT_TAGS = (
#    default => [@EXPORT],
#    all => [@EXPORT, @EXPORT_OK]
#);

#sub import {    # {{{1
#} #import()     # }}}1

#1;
__END__
# vi: set fdm=marker: #
