package Catmandu::Fix::timestamp;
use Catmandu::Sane;
use Time::HiRes;
use Moo;
use Catmandu::Fix::Has;

our $VERSION = "0.0132";

with 'Catmandu::Fix::Base';

has path => ( fix_arg => 1 );

sub emit {

    my($self,$fixer) = @_;

    my $path = $fixer->split_path($self->path);

    $fixer->emit_create_path($fixer->var,$path,sub{

        my $var = shift;
        "${var} = Time::HiRes::time;";

    });

}

1;
__END__

=head1 NAME

Catmandu::Fix::timestamp - Catmandu fix that stores the current unix time, in high resolution

=head1 SYNOPSIS

  #set the key 'timestamp' to the current time (unix timestamp)
  timestamp('timestamp')

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
