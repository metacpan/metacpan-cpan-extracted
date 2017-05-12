use 5.008;
use warnings;
use strict;

package Class::Scaffold::Context;
BEGIN {
  $Class::Scaffold::Context::VERSION = '1.102280';
}
# ABSTRACT: Holds execution and job context
use parent 'Class::Scaffold::Base';
__PACKAGE__->mk_scalar_accessors(qw(execution job));

# types of execution context: cron, apache, shell, soap
# types of job context: mail, sif, epp
# takes something like 'run/epp' and sets execution and job context
sub parse_context {
    my ($self, $spec) = @_;
    if ($spec =~ m!^(\w+)/(\w+)$!) {
        my ($job, $execution) = ($1, $2);
        $self->execution($execution);
        $self->job($job);
    } else {
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => "Invalid context specification [$spec]",);
    }
    $self;
}

sub as_string {
    my $self = shift;
    sprintf '%s/%s',
      (defined $self->job       ? $self->job       : 'none'),
      (defined $self->execution ? $self->execution : 'none');
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Context - Holds execution and job context

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 parse_context

Parses a context that is given as a slash-separated string, for example
C<foo/bar>, into the job and execution parts and stores them.

=head2 as_string

Joins the job and execution contexts with a slash and returns them as a
string. If either part is undefined, C<none> will be used in its place.

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

