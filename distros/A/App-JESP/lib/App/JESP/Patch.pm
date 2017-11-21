package App::JESP::Patch;
$App::JESP::Patch::VERSION = '0.015';
use Moose;

use File::Spec;

=head1 NAME

App::JESP::Patch - A patch

=cut

has 'jesp' => ( is => 'ro', isa => 'App::JESP', required => 1, weak_ref => 1);

has 'id' => ( is => 'ro', isa => 'Str', required => 1 );

# config:
has 'file' => ( is => 'ro', isa => 'Str' );
has 'sql' => ( is => 'ro', isa => 'Maybe[Str]' , lazy_build => 1 );

# Will be the absolute filename of the script
has 'script_file' => ( is => 'ro', isa => 'Maybe[Str]', lazy_build => 1);

# Slurping stuff from files
has 'file_data' => ( is => 'ro' , lazy_build => 1 );

#Transient properties:
has 'applied_datetime' => ( is => 'rw', isa => 'Str', required => 0 );

sub _build_file_data{
    my ($self) = @_;
    unless( $self->file() ){ return };

    my $file = $self->_abs_file_name( $self->file() );

    unless( ( -e $file ) && ( -r $file ) ){ die "Cannot read file '$file'\n"; }
    return File::Slurp::read_file( $file );
}

sub _abs_file_name{
    my ($self, $filename) = @_;
    my $file =
        File::Spec->file_name_is_absolute( $filename ) ?
        $filename :
        File::Spec->catfile( $self->jesp()->home() , $filename);
}

sub _build_script_file{
    my ($self) = @_;
    unless( $self->file() ){ return; }
    my $file = $self->_abs_file_name( $self->file() );#
    unless( -r $file ){
        confess("File '$file' is not readable (or there)");
    }
    # A script is executable
    if( -x $file ){
        return $file;
    }
    return;
}

sub _build_sql{
    my ($self) = @_;
    unless ( $self->file() =~ /\.sql$/ ){
        return;
    }
    return $self->file_data();
}

__PACKAGE__->meta()->make_immutable();
1;
