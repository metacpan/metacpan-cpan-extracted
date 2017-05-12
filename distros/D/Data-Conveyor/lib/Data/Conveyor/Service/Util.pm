use 5.008;
use strict;
use warnings;

package Data::Conveyor::Service::Util;
BEGIN {
  $Data::Conveyor::Service::Util::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

#
# Mixin class for making service interface method implementations easier. It
# helps in interacting with the storage object. However, these helper methods
# make assumptions about the structure of the underlying storage calls. If
# these assumptions apply to your storage, you may find these methods useful.
use Error ':try';
use Error::Hierarchy::Util 'assert_nonempty_arrayref';

sub svc_check_arguments {
    my ($self, $passed_args, $supported_list) = @_;
    assert_nonempty_arrayref $supported_list,
      'list of supported parameters is empty';
    my $container = $self->delegate->make_obj('exception_container');
    my %supported = map { $_ => 1 } @$supported_list;
    my $exception;
    for my $arg (keys %$passed_args) {
        next if exists $supported{$arg};
        $container->record(
            'Error::Hierarchy::Internal::CustomMessage',
            custom_message => sprintf(
                "Unsupported parameter '%s'. (Supported: %s)" => $arg,
                join ', ' => @$supported_list
            )
        );
        $exception++;
    }
    $container->throw if $exception;
}

# FIXME
#
# This method makes assumptions on the structure of underlying storage calls,
# and is used by Registry::NICAT::Channel::Mail::Output and
# Registry::NICAT::Confirm.
#
# Is there a better place for it?
sub svc_result_for_storage_call {
    my ($self, $storage_call, $supported_args, %args) = @_;
    assert_nonempty_arrayref $supported_args,
      'list of supported parameters is empty';
    $storage_call
      || throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => sprintf "bad call parameter '$storage_call'");
    $self->svc_check_arguments(\%args, $supported_args);
    $self->delegate->make_obj('service_result_scalar',
        result => scalar $self->storage->$storage_call(@args{@$supported_args})
    );
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Service::Util - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 svc_check_arguments

FIXME

=head2 svc_result_for_storage_call

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

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

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

