package TAP::Parser::Iterator::Worker;

use strict;
use Sys::Hostname;
use IO::Socket::INET;
use IO::Select;
use Cwd;

use TAP::Parser::Iterator::Process ();

use vars qw($VERSION @ISA);
@ISA = 'TAP::Parser::Iterator::Process';

=head1 NAME

TAP::Parser::Iterator::Worker - Iterator for worker TAP sources

=head1 VERSION

Version 0.08

=cut

$VERSION = '0.08';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head3 C<new>

Make a new worker.

=cut

sub _initialize {
    my ( $self, $args ) = @_;
    return unless ( $args->{spec} );
    $self->{spec}            = $args->{spec};
    $self->{start_up}        = $args->{start_up};
    $self->{tear_down}       = $args->{tear_down};
    $self->{error_log}       = $args->{error_log};
    $self->{switches}        = $args->{switches};
    $self->{detach}          = $args->{detach};
    $self->{test_args}       = $args->{test_args};
    $self->{sync_type}       = $args->{sync_type};
    $self->{source_dir}      = $args->{source_dir};
    $self->{destination_dir} = $args->{destination_dir};
    return
      unless (
        $self->SUPER::_initialize(
            { command => [ $self->initialize_worker_command->[0] ] }
        )
      );
    return $self;
}

=head3 C<initialize_worker_command>

Initialize the command to be used to initialize worker.

For your specific command, you can subclass this to put your command in this method.

=cut

sub initialize_worker_command {
    my $self = shift;
    if (@_) {
        $self->{initialize_worker_command} = shift;
    }
    unless ( $self->{initialize_worker_command} ) {

        #LSF: Get hostname and port.
        my @args    = ( '--manager=' . $self->{spec} );
        my $type    = ref($self);
        my $package = __PACKAGE__;
        $type =~ s/^$package//;
        $type =~ s/::/-/g;
        if ( $self->{sync_type} && !$self->{source_dir} ) {
            my $cwd = File::Spec->rel2abs('.');

            #LSF: The trailing '/' must be there for source to prevent
            #     creating the source directory at destination directory
            $self->{source_dir} = $cwd . '/';
        }

   #my $option_name = '--worker' . ( $type ? '-' . lc($type) : '' ) . '-option';
        my $option_name = '--worker-option';
        for my $option (
            qw(start_up tear_down error_log detach sync_type source_dir destination_dir)
          )
        {
            my $name = $option;
            $name =~ s/_/-/g;
            if ( $option eq 'detach' && $self->{$option} ) {
                push @args, "--$name";
                next;
            }
            push @args, "--$name=" . $self->{$option} if ( $self->{$option} );
        }

        #LSF: Find the library path.
        my $path;
        $package =~ s/::/\//g;
        $package .= '.pm';
        if ( $INC{$package} ) {
            $path = $INC{$package};
            $path =~ s/$package//;
        }
        my $switches = '';
        if ( $self->{switches} ) {
            $switches = join ' ', @{ $self->{switches} };
        }
        my $abs_path = Cwd::abs_path($path);
        $self->{initialize_worker_command} = [
                "perl -I $abs_path -S prove $switches -PDistributed='"
              . ( join ',', @args ) . "'"
              . (
                $self->{test_args} && @{ $self->{test_args} }
                ? ' :: ' . ( join ' ', @{ $self->{test_args} } )
                : ''
              )
        ];
    }
    return $self->{initialize_worker_command};
}

1;

__END__

##############################################################################
