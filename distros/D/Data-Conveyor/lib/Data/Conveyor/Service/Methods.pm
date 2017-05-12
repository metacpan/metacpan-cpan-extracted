use 5.008;
use strict;
use warnings;

package Data::Conveyor::Service::Methods;
BEGIN {
  $Data::Conveyor::Service::Methods::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

#
# Wrapper around service methods coming from different classes. This class
# exists to avoid the situation where every service interface has to know the
# location of each service methods.
use Error ':try';
use parent 'Data::Conveyor::Service';

# generate parameter specs from an efficient getopt-like input format
sub PARAMS {
    my ($self, @spec) = @_;

    # spec could be something like:
    #
    # "+domain|d=s Domain name.",
    # "?logtest|l  Don't delete the domain, just write the log ticket.",
    # "?force|f    Disregard the 'SPR' flag.",
    #
    # <necessity><name>|<short>[=<type>][><default>]
    #
    # necessity:
    #   '+' = mandatory
    #   '?' = optional
    # name, short: parameter names
    # type: '=s' for string, none for boolean
    #
    # type and default are optional
    my @params;
    for my $spec (@spec) {
        my ($getopt, $description) = split /\s+/, $spec, 2;
        $getopt =~ /^([+?])(\w+)(\|\w+)?(=\w+)?(>.*)?$/
          or die
qq!Can't parse service method's parameter specification "$getopt" - use the "<necessity><name>[|<short>][=<type>][><default>]" format!;
        my ($necessity, $name, $short, $type, $default) = ($1, $2, $3, $4, $5);
        defined($_) || ($_ = '') for $necessity, $name, $short, $type, $default;
        $short =~ s/^\|//;
        my %necessity_map = (
            '+' => $self->delegate->SIP_MANDATORY,
            '?' => $self->delegate->SIP_OPTIONAL,
        );
        $necessity =
          length $necessity
          ? $necessity_map{$necessity}
          : $self->delegate->SIP_MANDATORY;
        my %type_map = ('=s' => $self->delegate->SIP_STRING,);
        $type = length $type ? $type_map{$type} : $self->delegate->SIP_BOOLEAN;
        $default =~ s/^>//;

        # The 'description' may yet contain 'alias' definitions - if so, split
        # them up. Note that not all service interfaces need to support
        # aliases - typically, a shell interface won't, but a SOAP interface
        # might, to support legacy SOAP calls.
        my $aliases = [];
        if ($description =~ /^=([\w,]+)\s+(.*)$/) {
            $description = $2;
            $aliases = [ split /,/ => $1 ];
        }
        push @params => {
            name        => $name,
            short       => $short,
            type        => $type,
            necessity   => $necessity,
            aliases     => $aliases,
            description => $description,
            (length $default ? (default => $default) : ()),
        };
    }
    return (params => \@params);
}

sub SERVICE_METHODS {
    dump => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
            "?raw|r      Dump ticket as-is, not comparable",
        ),
        description => 'Uses Data::Dumper to dump a ticket.',
      },
      ydump => {
        object => 'ticket',
        $_[0]->PARAMS("+ticket|t=s Ticket number",),
        description => 'Uses YAML to dump a ticket.',
      },
      get_ticket_payload => {
        object => 'ticket',
        $_[0]->PARAMS("+ticket|t=s Ticket number",),
        description => "Show the given ticket's payload.",
      },
      exceptions => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
            "?raw|r      Print raw exception, not stringified",
        ),
        description => 'Shows all exceptions of a ticket.',
      },
      clear_exceptions => {
        object => 'ticket',
        $_[0]->PARAMS("+ticket|t=s Ticket number",),
        description => 'Shows all exceptions of a ticket.',
      },
      exceptions_structured => {
        object  => 'ticket',
        aliases => ['get_errors'],
        $_[0]->PARAMS(
            "+ticket|t=s  Ticket number",
            "?object|o=s  Restrict to this object type (e.g., 'person')",
        ),
        description => "Get a ticket's exceptions in a structured form.",
      },
      delete_exception => {
        object  => 'ticket',
        aliases => ['del_error'],
        $_[0]->PARAMS(
            "+ticket|t=s  Ticket number",
            "+uuid|u=s    UUID of the exception to delete",
        ),
        description => "Delete an exception from a ticket.",
        examples    => [
            {   ticket => '200707301444.003384594',
                uuid   => '4162F712-1DD2-11B2-B17E-C09EFE1DC403',
            },
        ],
      },
      journal => {
        object => 'ticket',
        $_[0]->PARAMS("+ticket|t=s Ticket number",),
        description => 'Shows the journal of a ticket.',
      },
      set_stage => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s =ticket_no Ticket number",
            "+stage|g=s  Set to this stage (e.g., 'starten_policy')",
        ),
        description => "Set a ticket's stage.",
      },
      top => {
        object => 'monitor',
        $_[0]->PARAMS(
            "?all|a  Report all relevant status values (will be slower)",
        ),
        description =>
"Show how many tickets there are currently in each stage. Unless the 'all' argument is given, only running and 'on hold' tickets (status 'R' and 'H') are reported.",
      },
      ;
}

sub get_method_names {
    my $self = shift;
    $self->{_service_methods} ||= $self->every_hash('SERVICE_METHODS');
    my %methods = %{ $self->{_service_methods} };
    my @keys    = keys %methods;
    wantarray ? @keys : \@keys;
}

sub get_spec_for_method {
    my ($self, $method) = @_;
    $self->{_service_methods} ||= $self->every_hash('SERVICE_METHODS');
    $self->{_service_methods}{$method}
      or throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => sprintf 'no service method [%s]',
        $method
      );
}

sub get_params_for_method {
    my ($self, $method) = @_;
    my $params = $self->get_spec_for_method($method)->{params};
    $params = [] unless defined $params;
    wantarray ? @$params : $params;
}

sub get_description_for_method {
    my ($self, $method) = @_;
    $self->get_spec_for_method($method)->{description};
}

sub get_summary_for_method {
    my ($self, $method) = @_;
    my $summary = $self->get_spec_for_method($method)->{summary};
    return $summary if defined($summary) && length($summary);

    # if we don't have a summary, lowercase the first sentence - up to the
    # first full stop - of the description
    $summary = lc($self->get_description_for_method($method));
    $summary =~ s/\..*//s;    # remove everything from the first full stop
    $summary;
}

sub get_examples_for_method {
    my ($self, $method) = @_;
    my $examples = $self->get_spec_for_method($method)->{examples};
    $examples = [] unless defined $examples;
    wantarray ? @$examples : $examples;
}

sub get_aliases_for_method {
    my ($self, $method) = @_;
    my $aliases = $self->get_spec_for_method($method)->{aliases};
    $aliases = [] unless defined $aliases;
    wantarray ? @$aliases : $aliases;
}

sub apply_param_aliases_and_defaults {
    my ($self, $method, $opts_ref) = @_;
    for my $param ($self->get_params_for_method($method)) {

        # If the parameter is defined in its standard form, don't care about
        # aliases or defaults.
        next if defined $opts_ref->{ $param->{name} };

        # If the parameter is present in one of its alias forms, copy it to
        # the standard parameter and delete the alias. We take the first
        # aliased form we encounter, in case there are several ones.
        for my $alias (@{ $param->{aliases} || [] }) {
            next unless defined $opts_ref->{$alias};
            $opts_ref->{ $param->{name} } = $opts_ref->{$alias};
            delete $opts_ref->{$alias};
        }
        next unless defined $param->{default};
        $opts_ref->{ $param->{name} } = $param->{default};
    }
}

sub run_method {
    my ($self, $method, %opt) = @_;
    my $result;
    try {
        my $spec        = $self->get_spec_for_method($method);
        my $object_type = $spec->{object};
        my $object_method =
          exists $spec->{method}
          ? $spec->{method}
          : "sif_$method";
        $result =
          $self->delegate->make_obj($object_type)->$object_method (%opt);
    }
    catch Data::Conveyor::Exception::ServiceMethodHelp with {

        # this exception will be handled higher up
        $_[0]->throw;
    }
    catch Error::Hierarchy with {
        my $E = shift;
        $result = $self->delegate->make_obj('service_result_scalar');
        $result->exception($E);
    };
    $result;
}

# Also allow service methods to be called directly on the service methods
# object:
#
# $svc->foobar(...)
#
# is to be the same as
#
# $svc->run_method('foobar', ...);
sub DEFAULTS { () }
sub DESTROY  { }

sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;
    $self->run_method($method, @_);
}
1;


__END__
=pod

=for stopwords PARAMS

=head1 NAME

Data::Conveyor::Service::Methods - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 DEFAULTS

FIXME

=head2 PARAMS

FIXME

=head2 SERVICE_METHODS

FIXME

=head2 apply_param_aliases_and_defaults

FIXME

=head2 get_aliases_for_method

FIXME

=head2 get_description_for_method

FIXME

=head2 get_examples_for_method

FIXME

=head2 get_method_names

FIXME

=head2 get_params_for_method

FIXME

=head2 get_spec_for_method

FIXME

=head2 get_summary_for_method

FIXME

=head2 run_method

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

