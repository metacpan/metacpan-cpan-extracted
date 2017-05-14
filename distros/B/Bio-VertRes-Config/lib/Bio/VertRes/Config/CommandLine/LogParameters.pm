package Bio::VertRes::Config::CommandLine::LogParameters;

# ABSTRACT: A class to represent multiple top level files. It splits out mixed config files into the correct top level files


use Moose;
use Bio::VertRes::Config::Exceptions;
use File::Basename;
use File::Path qw(make_path);

has 'args'           => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'    => ( is => 'ro', isa => 'Str',      required => 1 );
has 'log_file'       => ( is => 'rw', isa => 'Str',      default  => '/tmp/command_line.log' );
has '_output_string' => ( is => 'ro', isa => 'Str',      lazy     => 1, builder => '_build__output_string' );
has '_user_name'     => ( is => 'ro', isa => 'Str',      lazy     => 1, builder => '_build__user_name' );

sub BUILD {
    my ($self) = @_;

    # Build the variable just after object construction because the array ref gets modified by GetOpts
    $self->_output_string;
}


sub _build__user_name
{
  my ($self) = @_;
  getpwuid( $< );
}

sub _build__output_string {
    my ($self) = @_;
    my $output_str = time()." ";
    
    if ( defined( $self->_user_name))
    {
       $output_str .= $self->_user_name . " ";
    }
    
    if ( defined( $self->script_name ) ) {
        $output_str .= $self->script_name . " ";
    }

    if ( defined( $self->args ) && @{ $self->args } > 0 ) {
        $output_str .= join( ' ', @{ $self->args } );
    }
    $output_str .= "\n";

    return $output_str;
}

sub create {
    my ($self) = @_;

    my $mode = 0777;
    if ( !( -e $self->log_file ) ) {
        my ( $config_filename, $directories, $suffix ) = fileparse( $self->log_file );
        make_path($directories, {mode => $mode});
    }

    open( my $fh, '+>>', $self->log_file )
      or Bio::VertRes::Config::Exceptions::FileCantBeModified->throw(
        error => 'Couldnt open file for writing ' . $self->log_file );
    print {$fh} $self->_output_string;
    close($fh);
    chmod $mode, $self->log_file;

    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::LogParameters - A class to represent multiple top level files. It splits out mixed config files into the correct top level files

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class to represent multiple top level files. It splits out mixed config files into the correct top level files
   use Bio::VertRes::Config::CommandLine::LogParameters;

   Bio::VertRes::Config::CommandLine::LogParameters->new( args => \@ARGV, log_file => '/path/to/log/file')->create;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
