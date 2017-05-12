package App::JESP::Patch;
$App::JESP::Patch::VERSION = '0.008';
use Moose;

use File::Spec;

=head1 NAME

App::JESP::Patch - A patch

=cut

has 'jesp' => ( is => 'ro', isa => 'App::JESP', required => 1, weak_ref => 1);

has 'id' => ( is => 'ro', isa => 'Str', required => 1 );
has 'file' => ( is => 'ro', isa => 'Str' );
has 'sql' => ( is => 'ro', isa => 'Maybe[Str]' , lazy_build => 1 );

has 'file_data' => ( is => 'ro' , lazy_build => 1 );

sub _build_file_data{
    my ($self) = @_;
    unless( $self->file() ){ return };

    my $file =
        File::Spec->file_name_is_absolute( $self->file() ) ?
        $self->file() :
        File::Spec->catfile( $self->jesp()->home() , $self->file() );

    unless( ( -e $file ) && ( -r $file ) ){ die "Cannot read file '$file'\n"; }
    return File::Slurp::read_file( $file );
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
