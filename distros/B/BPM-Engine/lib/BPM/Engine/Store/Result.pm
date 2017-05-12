package BPM::Engine::Store::Result;
BEGIN {
    $BPM::Engine::Store::Result::VERSION   = '0.01';
    $BPM::Engine::Store::Result::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use MooseX::NonMoose;
extends qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

## no critic (ProhibitUnusedPrivateSubroutines)
# override call from within DBIx::Class::InflateColumn::DateTime
sub _inflate_to_datetime {
    my ($self, @args) = @_;
    
    my $val = $self->next::method(@args);
    return bless $val, 'BPM::Engine::DateTime';
    }

sub TO_JSON {
    my($self, $level) = @_;

    my %parms = map { $_ => $self->$_ } grep { $self->$_ }
        $self->result_source->columns; # $self->columns;

    return \%parms;
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

## no critic (ProhibitMultiplePackages)
{
package BPM::Engine::DateTime;

use strict;
use warnings;
use parent 'DateTime';

sub TO_JSON {
    my $dt = shift; 
    return "$dt";
    }
}

1;
__END__