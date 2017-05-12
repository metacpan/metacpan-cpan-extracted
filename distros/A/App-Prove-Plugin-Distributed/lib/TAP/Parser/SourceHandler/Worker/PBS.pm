package TAP::Parser::SourceHandler::Worker::PBS;

use strict;
use Getopt::Long;
use Carp;
use vars (qw($VERSION @ISA));

use TAP::Parser::IteratorFactory       ();
use TAP::Parser::SourceHandler::Worker ();
@ISA = 'TAP::Parser::SourceHandler::Worker';

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

=head1 NAME

TAP::Parser::SourceHandler::Worker::PBS - Stream TAP from an L<IO::Handle> or a GLOB.

=head1 VERSION

Version 0.05

=cut

$VERSION = '0.05';

use constant iterator_class => 'TAP::Parser::Iterator::Worker::PBS';

=head3 C<@hosts>

Class static variable to keep track of hosts. 

=cut 

my %pbs_args;

=head3 C<get_active_workers>
  
  my @active_workers = $class->get_active_workers;

Returns list of active workers.

=cut

sub get_active_workers {
    my $class = shift;

    my @workers = $class->SUPER::get_active_workers;

    return unless (@workers);
    my @active;
    for my $worker (@workers) {
        if ( $worker->{pbs_job_id} ) {
            my @info = `qstat $worker->{pbs_job_id}`;
            unless ( $info[2] && $info[2] =~ /\s+(Q|R)\s+/ ) {
                $worker = undef;
                next;
            }
        }
        push @active, $worker if ($worker);
    }
    return @active;
}

=head3 C<load_options>
  
Setup the worker specific options.

  my @active_workers = $class->load_options($app_prove_object, \@ARGV);

Returns boolean.

=cut

sub load_options {
    my $class = shift;
    my ( $app, $args ) = @_;
    croak 'parent failed to load options.' unless($class->SUPER::load_options(@_));
    {
        local @ARGV = @$args;
        Getopt::Long::Configure(qw(no_ignore_case bundling pass_through));
        my %options;
        for my $arg (
            qw(server
            wd name script tracer host nodes ppn account
            partition queue begint ofile efile tfile pri mem pmem vmem pvmem cput
            pcput wallt nice pbsid cmd prev next depend stagein stageout vars
            shell maillist mailopt)
          )
        {
            $options{$arg . '=s'} = \$pbs_args{$arg};
        }

        # Don't add coderefs to GetOptions
        GetOptions(%options)
          or croak('Unable to continue');
    }
    return 1;
}

=head3 C<get_args>

Get PBS arguments.

Returns argument hash

=cut

sub get_args {
    return (%pbs_args);
}

END {
    for my $worker ( __PACKAGE__->workers ) {
        next unless ( $worker && $worker->{pbs_job_id} );
        my $command = 'qdel ' . $worker->{pbs_job_id};
        print join "\n", map { '#' . $_ } split /\n/, `$command`;
        print "\n";
    }
}

1;

__END__

##############################################################################
