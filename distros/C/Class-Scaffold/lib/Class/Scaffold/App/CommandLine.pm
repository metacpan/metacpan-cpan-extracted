use 5.008;
use warnings;
use strict;

package Class::Scaffold::App::CommandLine;
BEGIN {
  $Class::Scaffold::App::CommandLine::VERSION = '1.102280';
}
# ABSTRACT: Base class for command line-based framework applications
use Class::Scaffold::Environment;
use Property::Lookup;
use parent qw(Class::Scaffold::App Getopt::Inherited);
use constant CONTEXT => 'generic/shell';
use constant GETOPT  => (qw(dryrun conf=s environment));

sub app_init {
    my $self = shift;
    $self->do_getopt;
    # Add a hash configurator layer for getopt before the superclass has a
    # chance to add the file configurator; this way, getopt definitions take
    # precedence over what's in the conf file.
    Property::Lookup->instance->add_layer(hash => scalar $self->opt);
    $self->SUPER::app_init(@_);
}

sub app_finish {
    my $self = shift;
    $self->delegate->disconnect;
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::App::CommandLine - Base class for command line-based framework applications

=head1 VERSION

version 1.102280

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

