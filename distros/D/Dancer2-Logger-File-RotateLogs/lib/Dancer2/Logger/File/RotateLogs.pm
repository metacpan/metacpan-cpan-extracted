package Dancer2::Logger::File::RotateLogs;
$Dancer2::Logger::File::RotateLogs::VERSION = '0.01';

use Moo;
use File::Spec;
use File::RotateLogs;
use Dancer2::Core::Types;

with 'Dancer2::Core::Role::Logger'; 

my $ROTATELOGS;

has environment => (
    is       => 'ro',
    required => 1,
);

has location => (
    is       => 'ro',
    required => 1,
);

has log_dir => (
    is      => 'rw',
    isa     => sub {
        my $dir = shift;
        
        if ( !-d $dir && !mkdir $dir ) {
            die "log directory \"$dir\" does not exist and unable to create it.";
        }
        if ( !-w $dir ) {
            die "log directory \"$dir\" is not writable."
        }
    },
    lazy    => 1,
    builder => '_build_log_dir',
);

has logfile => (
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        File::Spec->catfile(File::Spec->rel2abs($self->log_dir), $self->environment.'.log').".%Y%m%d%H";
    },
);

has linkname => (
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        File::Spec->catfile(File::Spec->rel2abs($self->log_dir), $self->environment.'.log');
    },
);

has rotationtime => (
    is       => 'ro',
    required => 1,
    default  => sub { 86400 },
);

has maxage => (
    is       => 'ro',
    required => 1,
    default  => sub { 86400 * 7 },
    coerce   => sub { 
        $_[0] =~ /^\d+$/ ? $_[0] : int eval($_[0])
    },
);

sub BUILD {
    my ($self) = @_;

    $ROTATELOGS = File::RotateLogs->new({
        logfile      => $self->logfile,
        linkname     => $self->linkname,
        rotationtime => $self->rotationtime,
        maxage       => $self->maxage,
    });
}

sub _build_log_dir {
    File::Spec->catdir( $_[0]->location, 'logs' );
}

sub log {
    my ( $self, $level, $message ) = @_; 
    $ROTATELOGS->print($self->format_message( $level => $message ));
}

1;
__END__

=pod

=head1 NAME

Dancer2::Logger::File::RotateLogs - an automated logrotate.

=head1 SYNOPSIS

    # development.yml or production.yml
    logger: "File::RotateLogs"

    # options (It's possible to omit)
    engines:
      logger:
        File::RotateLogs:
          logfile: '/[absolute path]/logs/error.log.%Y%m%d%H'
          linkname: '/[absolute path]/logs/error.log'  
          rotationtime: 86400
          maxage: 86400 * 7 
        


=head1 DESCRIPTION

This module allows you to initialize File::RotateLogs within the application's configuration. 
File::RotateLogs is utility for file logger and very simple logfile rotation. 

=head1 SEE ALSO

=over 1

=item L<File::RotateLogs>

=back


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masaaki Saito E<lt>masakyst.public@gmail.comE<gt>

=cut

