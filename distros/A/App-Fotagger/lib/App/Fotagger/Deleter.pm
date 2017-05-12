package App::Fotagger::Deleter;

use strict;
use warnings;
use 5.010;

use Moose;

extends 'App::Fotagger';

has 'dry_run' => ( isa => 'Bool', is => 'ro', default=>0);
has 'verbose' => ( isa => 'Bool', is => 'ro', default=>0);
has 'ask'  => ( isa => 'Bool', is => 'ro', default=>0);

no Moose;
__PACKAGE__->meta->make_immutable;

sub delete_tagged_images {
    my $self = shift;
    $self->get_images;
    my $count=0;

    foreach my $file (@{$self->images}) {
        my $image = App::Fotagger::Image->new({file=>$file});
        $image->read;
        if ($image->tags ~~ /TO_DELETE/) {
            if ($self->ask) {
                print "delete $file? (y/N) ";
                my $answer = <STDIN>;
                chomp $answer;
                next unless $answer ~~ /y/i;
            }
            unless ($self->dry_run) {
                unlink($file) || say "Couldn't unlink $file";
                $count++;
            }
            say "deleted $file" if $self->verbose;
        }
    }
    say "deleted $count file".($count>1?'s':'');
}

q{ listening to:
    Soap & Skin - Lovetune For Vacuum
};

