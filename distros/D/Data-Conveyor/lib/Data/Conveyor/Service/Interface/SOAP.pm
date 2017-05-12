use 5.008;
use strict;
use warnings;

package Data::Conveyor::Service::Interface::SOAP;
BEGIN {
  $Data::Conveyor::Service::Interface::SOAP::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error ':try';
use once;
use parent 'Data::Conveyor::Service::Interface';

sub init {
    my $self = shift;
    ONCE {

        # Generate handlers for all methods listed in the Service Methods
        # object. They are being generated into this package. If you need
        # custom implementations for some handlers, override them in the
        # appropriate subclass.
        for my $command ($self->svc->get_method_names) {

            # Generate a separate method for each alias, but not that the
            # service method for the standard name will be called!
            for my $method ($command,
                $self->svc->get_aliases_for_method($command)) {
                no strict 'refs';

                # separate lexical var ($meth1) for closures
                my $meth1 = $method;
                unless (defined *{$meth1}{CODE}) {
                    $::PTAGS
                      && $::PTAGS->add_tag($meth1, __FILE__, __LINE__ + 1);
                    *$meth1 = sub {
                        local $DB::sub = local *__ANON__ =
                          "Data::Conveyor::Service::Interface::SOAP::${meth1}"
                          if defined &DB::DB && !$Devel::DProf::VERSION;
                        my $self = shift;
                        $self->run_service_method($command, $self->args);
                    };
                }
            }
        }
    };
}

sub run_service_method {
    my ($self, $method, %opt) = @_;
    $self->svc->apply_param_aliases_and_defaults($method => \%opt);
    my $result_object;
    try {
        $result_object = $self->svc->run_method($method, %opt);
    }
    catch Error::Hierarchy with {
        my $E = shift;
        $result_object = $self->delegate->make_obj('service_result_scalar');
        $result_object->exception($E);
    };

    # Apparently the most preferred of all the fucked-up output formats, so we
    # use it as a default here. If the SOAP user expects something even more
    # idiotic, subclass the specific SOAP method and munge the output.
    unless ($result_object->is_ok) {
        return +{
            message => sprintf("%s", $result_object->exception),
            state   => 1,
        };
    }
    if (exists($opt{pure_result}) && $opt{pure_result}) {
        return +{
            state  => 0,
            result => $result_object,
        };
    }

    # FIXME: Convince the SOAP user to accept standard results, then make this
    # cruft go away.
    my $soap_result;
    if ($self->delegate->isa_type($result_object, 'service_result_tabular')) {
        $soap_result = {
            state  => 0,
            result => scalar($result_object->result_as_list_of_hashes),
        };
    } elsif (ref $result_object->result eq 'HASH') {

        # scalar result object, but contains a hash
        $soap_result = {
            state => 0,
            %{ $result_object->result },
        };
    } else {

        # scalar result object, doesn't contain a hash
        $soap_result = {
            state  => 0,
            result => scalar($result_object->result),
        };
    }

    # Something to munge, sir?
    # You can specify something like
    #
    # use constant MUNGE_OUTPUT => (
    #     foobar => [ frobnicate => 'some_key1', 'some_key2' ],
    # );
    #
    # and this code will effectively call
    #
    # $self->munge_frobnicate($soap_result, 'some_key1', 'some_key2');
    my %munge_output = $self->every_hash('MUNGE_OUTPUT');
    return $soap_result unless exists $munge_output{$method};
    my ($munge_method, @munge_args) = @{ $munge_output{$method} };
    $munge_method = "munge_$munge_method";
    $self->$munge_method($soap_result, @munge_args);
}

# keep this close to the code where it is being used so that when sanity
# prevails, it can be deleted quickly.
use constant MUNGE_OUTPUT => ();
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Service::Interface::SOAP - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 run_service_method

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

