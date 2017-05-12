use 5.008;
use strict;
use warnings;

package Data::Conveyor::Service::Interface::Shell;
BEGIN {
  $Data::Conveyor::Service::Interface::Shell::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use Data::Conveyor::Service::Methods;
use Data::Dumper;    # for the debug command
use Data::Miscellany 'is_defined';
use Error ':try';
use Error::Hierarchy;
use Getopt::Long;
use Pod::Text;
use IO::Pager;       # not used really, just determines a pager at BEGIN time
use once;

# It's ok to inherit from Data::Conveyor::Service::Interface as well; new()
# will be found in Term::Shell::Enhanced first.
use parent qw(
  Term::Shell::Enhanced
  Data::Conveyor::Service::Interface
);
__PACKAGE__->mk_hash_accessors(qw(sth))->mk_integer_accessors(qw(num))
  ->mk_scalar_accessors(
    qw(
      base hostname limit log name prompt_spec ticket_no pager
      )
  );

# These aren't the constructor()'s DEFAULTS()!  Because new() comes from
# Term::Shell, not Class::Scaffold::Base, we don't have the convenience of
# the the mk_constructor()-generated constructor. Therefore,
# Term::Shell::Enhanced defines its own mechanism.
sub DEFAULTS {
    my $self = shift;
    (   name        => 'dcsh',
        longname    => 'Data-Conveyor Shell',
        ticket_no   => '',
        limit       => 10,
        prompt_spec => ': \n_(\d)_[\t]:\#; ',
        pager       => $ENV{PAGER},             # as set by IO::Pager
    );
}

sub PROMPT_VARS {
    my $self = shift;
    (   t => $self->ticket_no            || '',
        d => $self->svc->storage->dbname || 'n/a',
    );
}

sub init {
    my $self = shift;
    $self->delegate->test_mode(1);    # force log to STDOUT

    # can't do $self->SUPER::init(@_), because that would find only
    # Term::Shell::Enhanced::init(), but not the
    # Data::Conveyor::Service::Interface::init().
    $self->Term::Shell::Enhanced::init(@_);
    $self->Data::Conveyor::Service::Interface::init(@_);
    my %args = @{ $self->{API}{args} };
    $self->base($args{base}) unless defined $self->base;

    # generate methods for handling generic service commands
    ONCE {

        # Generate handlers for all methods listed in the Service Methods
        # object. They are being generated into this package. If you need
        # custom implementations for some handlers, override them in the
        # appropriate subclass.
        for my $command ($self->svc->get_method_names) {
            no strict 'refs';

            # separate lexical vars ($meth1, $meth2, $meth3) for closures
            # smry_* method
            my $meth1 = sprintf "smry_%s" => $command;
            unless (defined *{$meth1}{CODE}) {
                $::PTAGS && $::PTAGS->add_tag($meth1, __FILE__, __LINE__ + 1);
                *$meth1 = sub {
                    local $DB::sub = local *__ANON__ =
                      "Data::Conveyor::Service::Interface::Shell::${meth1}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->summary_for_service_method($command);
                };
            }

            # help_* method
            my $meth2 = sprintf "help_%s" => $command;
            unless (defined *{$meth2}{CODE}) {
                $::PTAGS && $::PTAGS->add_tag($meth2, __FILE__, __LINE__ + 1);
                *$meth2 = sub {
                    local $DB::sub = local *__ANON__ =
                      "Data::Conveyor::Service::Interface::Shell::${meth2}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->get_help_for_service_method($command);
                };
            }

            # run_* method
            my $meth3 = sprintf "run_%s" => $command;
            unless (defined *{$meth3}{CODE}) {
                $::PTAGS && $::PTAGS->add_tag($meth3, __FILE__, __LINE__ + 1);
                *$meth3 = sub {
                    local $DB::sub = local *__ANON__ =
                      "Data::Conveyor::Service::Interface::Shell::${meth3}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->execute_service_method($command, @_);
                };
            }
            $self->{handlers}{$command} = {
                smry => $meth1,
                help => $meth2,
                run  => $meth3,
            };
        }
    };
}

# override run() to disconnect from all storages so that changes are visible
# immediately, not just when the shell exits.
sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    $self->delegate->disconnect;
}

# ========================================================================
# utility methods
# ========================================================================
sub check_ticket_no {
    my ($self, $ticket_no) = @_;
    require Data::Conveyor::Value::Ticket::Number;
    return 1 if Data::Conveyor::Value::Ticket::Number->check($ticket_no);
    printf "[%s] doesn't look like a valid ticket number.\n", $ticket_no;
    return 0;
}

sub check_limit {
    my ($self, $limit) = @_;
    if ($limit =~ /^\d+$/) {
        return 1;
    } else {
        printf "[%s] doesn't look like a valid limit (should be a digit).\n",
          $limit;
        return 0;
    }
}

# ========================================================================
# service method helpers
# ========================================================================
sub getopt_spec_for_method {
    my ($self, $method) = @_;
    my @getopt;
    for my $param ($self->svc->get_params_for_method($method)) {
        my $getopt = $param->{name};
        if ($param->{short}) { $getopt .= '|' . $param->{short} }
        if ($param->{type} eq $self->delegate->SIP_STRING) {
            $getopt .= '=s';
        }
        push @getopt => $getopt;
    }
    wantarray ? @getopt : \@getopt;
}

sub get_param_help_for_method {
    my ($self, $method) = @_;
    my $help = '';
    for my $param ($self->svc->get_params_for_method($method)) {
        my $item = '--' . $param->{name};
        if ($param->{short}) { $item .= ', -' . $param->{short} }
        my %map = (
            $self->delegate->SIP_STRING    => 'String',
            $self->delegate->SIP_BOOLEAN   => 'Boolean',
            $self->delegate->SIP_MANDATORY => 'Mandatory',
            $self->delegate->SIP_OPTIONAL  => 'Optional',
        );
        my $description = '['
          . $map{ $param->{type} } . '] ['
          . $map{ $param->{necessity} } . '] ';
        $description .= "[Default: $param->{default}] "
          if defined $param->{default};
        $description .= $param->{description};
        if (   $param->{name} eq 'ticket'
            && $param->{necessity} eq $self->delegate->SIP_MANDATORY) {
            my $ticket_no = $self->ticket_no;
            $ticket_no = 'none'
              unless is_defined($ticket_no) && length $ticket_no;
            $description .= sprintf
              ' Unless given, the current ticket number (%s) will be used.',
              $ticket_no;
        }
        if ($param->{name} eq 'limit') {
            $description .= sprintf
              ' Unless given, the current limit (%s) will be used.',
              (is_defined($self->limit) ? $self->limit : 'none');
        }
        $help .= "=item $item\n\n$description\n\n";
    }
    return "\n\n=over 4\n\n$help\n\n=back\n\n";
}

sub get_example_help_for_method {
    my ($self, $method) = @_;
    my $example_pod   = '';
    my $example_count = 0;
    for my $example ($self->svc->get_examples_for_method($method)) {
        $example_count++;
        $example_pod .= "=item $method";
        while (my ($name, $value) = each %$example) {
            $example_pod .= " --$name";
            $example_pod .= " $value" if defined $value;
        }
        $example_pod .= "\n\n";
    }
    if (length $example_pod) {
        $example_pod = "=over 4\n\n$example_pod\n\n=back\n\n";
    }
    if ($example_count == 1) {
        $example_pod = "Example:\n\n$example_pod";
    } elsif ($example_count > 1) {
        $example_pod = "Examples:\n\n$example_pod";
    }
    $example_pod;
}

sub pod_to_text {
    my ($self, $pod) = @_;
    open my $pod_fh, '<', \$pod
      or die "can't open filehandle to scalar \$pod";
    my $text = '';
    open my $text_fh, '>', \$text
      or die "can't open filehandle to scalar \$text";
    my $parser = Pod::Text->new;
    $parser->parse_from_filehandle($pod_fh, $text_fh);
    close $pod_fh  or die "can't close filehandle to scalar \$pod";
    close $text_fh or die "can't close filehandle to scalar \$text";
    $text;
}

sub summary_for_service_method {
    my ($self, $method) = @_;
    $self->svc->get_summary_for_method($method);
}

# don't call this just "help_for_service_method", or Term::Shell's
# find_handler() will find it and assume that there's a command
# "for_service_method".
sub get_help_for_service_method {
    my ($self, $method) = @_;
    my $description = $self->svc->get_description_for_method($method);
    my $param_help  = $self->get_param_help_for_method($method);
    my $example_pod = $self->get_example_help_for_method($method);
    my $pod         = <<EOPOD;
=pod

$method

$description

$param_help

$example_pod

=cut
EOPOD
    $self->pod_to_text($pod);
}

# Don't call this run_service_method, or Term::Shell will think it's a
# command.
sub execute_service_method {
    my $self   = shift;
    my $method = shift;
    local @ARGV = @_;
    my %opt;
    GetOptions(\%opt, $self->getopt_spec_for_method($method))
      or return $self->run_help($method);
    if (@ARGV) {
        print "extraneous arguments [@ARGV]\n\n";
        return $self->run_help($method);
    }
    my $params = $self->svc->get_params_for_method($method);

    # if there's a mandatory 'ticket' param, it defaults to the current ticket
    # number
    if ((   grep {
                     $_->{name} eq 'ticket'
                  && $_->{necessity} eq $self->delegate->SIP_MANDATORY
            } @$params
        )
        && !(defined $opt{ticket})
      ) {
        my $ticket_no = $self->ticket_no;
        unless ($ticket_no) {
            print
              "--ticket not given and there is no current ticket number.\n\n";
            return $self->run_help($method);
        }
        $opt{ticket} = $ticket_no;
    }

    # if there's a 'limit' param, it defaults to the current limit
    if ((grep { $_->{name} eq 'limit' } @$params) && !(defined $opt{limit})) {
        $opt{limit} = $self->limit;
    }

    # check other mandatory parameters
    my @params = $self->svc->get_params_for_method($method);
    for my $param (@params) {
        next if defined $opt{ $param->{name} };

        # If the method only has one parameter and there is something left in
        # @ARGV (unparsed by GetOptions), assume it's that parameter's value.
        #
        # This way, you can say "somecmd somevalue" instead of "somecmd -d
        # somevalue" if "-d" is the only arguments. It's just a little bit
        # more convenient and intuitive.
        if ((@params == 1) && (@ARGV >= 1)) {
            $opt{ $param->{name} } = shift @ARGV;
            next;
        }
        next unless $param->{necessity} eq $self->delegate->SIP_MANDATORY;
        print "missing mandatory parameter [$param->{name}]\n\n";
        return $self->run_help($method);
    }
    $self->svc->apply_param_aliases_and_defaults($method, \%opt);
    try {
        $self->print_result($self->svc->run_method($method, %opt));
    }
    catch Data::Conveyor::Exception::ServiceMethodHelp with {
        print $_[0]->custom_message . "\n\n";
        $self->run_help($method);
    }
    catch Error with {
        print "$_[0]\n";
    };
}

# print a service result object
sub print_result {
    my ($self, $result) = @_;

    # just stringify, but make sure there is a newline at the end
    chomp($result);
    $result .= "\n";
    if ($self->pager) {
        my $pager = $self->pager;
        ## no critic (ProhibitTwoArgOpen)
        open my $fh, "| $pager" or die "can't pipe to $pager: $!\n";
        print $fh $result;

        # close() doesn't work because of broken pipe...
    } else {
        print $result;
    }
}

# ========================================================================
# pager
# ========================================================================
sub smry_pager { 'get or set the current pager' }
sub help_pager {
    <<'END' }
pager [<pager>]
  Get or set the current pager. If the value is "off", no pager will be used.

END

sub run_pager {
    my $self = shift;
    if (@_) {
        my $pager = shift;
        $pager = '' if lc($pager) eq 'off';
        $self->pager($pager);
    }
    printf "Current pager is [%s]\n", $self->pager;
}

# ========================================================================
# ticket
# ========================================================================
sub smry_ticket { 'get or set the current ticket number' }
sub help_ticket {
    <<'END' }
ticket [<ticket_no>]
  Get or set the current ticket number.

END

sub run_ticket {
    my $self = shift;
    if (@_) {
        my $ticket_no = shift;
        $self->check_ticket_no($ticket_no) and $self->ticket_no($ticket_no);
    }
    printf "Current ticket no is [%s]\n", $self->ticket_no;
}

# ========================================================================
# limit
# ========================================================================
sub smry_limit {
    'get or set the current limit (max. rows returned by a command)';
}
sub help_limit {
    <<'END' }
limit [<limit>]
  Get or set the current limit (max. rows returned by a command).

END

sub run_limit {
    my $self = shift;
    if (@_) {
        my $limit = shift;
        $self->check_limit($limit) and $self->limit($limit);
    }
    printf "Current limit is [%s]\n", $self->limit;
}

# ========================================================================
# debug
# ========================================================================
sub smry_debug { 'print debugging information' }
sub help_debug {
    <<'END' }
debug
  Prints the current state of some internal variables for debugging
  purposes.
END

# subclasses can extend this
sub debug_lines {
    my $self  = shift;
    my @debug = (
        "CF_CONF: $ENV{CF_CONF}",
        sprintf("environment: %s", $self->delegate->configurator->environment),
        scalar(Data::Dumper->Dump([ scalar($self->delegate->OR) ], [qw/OR/])),
    );
}

sub run_debug {
    my $self = shift;
    try {
        $self->print_result($_) for $self->debug_lines;
    }
    catch Error with { print "$_[0]\n" };
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Service::Interface::Shell - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 DEFAULTS

FIXME

=head2 PROMPT_VARS

FIXME

=head2 check_limit

FIXME

=head2 check_ticket_no

FIXME

=head2 debug_lines

FIXME

=head2 execute_service_method

FIXME

=head2 get_example_help_for_method

FIXME

=head2 get_help_for_service_method

FIXME

=head2 get_param_help_for_method

FIXME

=head2 getopt_spec_for_method

FIXME

=head2 help_debug

FIXME

=head2 help_limit

FIXME

=head2 help_pager

FIXME

=head2 help_ticket

FIXME

=head2 pod_to_text

FIXME

=head2 print_result

FIXME

=head2 run

FIXME

=head2 run_debug

FIXME

=head2 run_limit

FIXME

=head2 run_pager

FIXME

=head2 run_ticket

FIXME

=head2 smry_debug

FIXME

=head2 smry_limit

FIXME

=head2 smry_pager

FIXME

=head2 smry_ticket

FIXME

=head2 summary_for_service_method

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

