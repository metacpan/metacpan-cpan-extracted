package App::JESP::Plan;
$App::JESP::Plan::VERSION = '0.010';
use Moose;
use JSON;
use File::Slurp;

use App::JESP::Patch;

=head1 NAME

App::JESP::Plan - Represents a patching plan

=cut

has 'jesp' => ( is => 'ro' , isa => 'App::JESP', required => 1, weak_ref => 1);

has 'file' => ( is => 'ro', isa => 'Str', required => 1 );
has 'patches' => ( is => 'ro' , isa => 'ArrayRef[App::JESP::Patch]', lazy_build => 1 );

has 'raw_data' => ( is => 'ro', isa => 'HashRef' , lazy_build => 1);

sub _build_raw_data{
    my ($self) = @_;
    my $content = File::Slurp::read_file( $self->file() );
    return JSON::decode_json( $content );
}

sub _build_patches{
    my ($self) = @_;
    unless( $self->raw_data()->{patches} ){
        die "Missing 'patches' in plan file ".$self->file()."\n";
    }

    my @patches = ();
    foreach my $raw_patch ( @{ $self->raw_data()->{patches} } ){
        push @patches , App::JESP::Patch->new({
            %$raw_patch,
            jesp => $self->jesp()
        });
    }
    return \@patches;
}

__PACKAGE__->meta->make_immutable();
1;
