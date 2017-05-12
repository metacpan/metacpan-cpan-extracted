package Data::Apache::mod_status::Workers;

=head1 NAME

Data::Apache::mod_status::Workes - workers summary object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use warnings;
use strict;

our $VERSION = '0.02';

use Moose;
use Moose::Util::TypeConstraints;

=head1 PROPERTIES

=cut

subtype 'XML_LibXML_Element'
    => as 'Object'
    => where { $_[0]->isa('XML::LibXML::Element') };

has 'workers_tag'  => ( 'is' => 'rw', 'isa' => 'XML_LibXML_Element', 'required' => 1 );
has 'waiting'      => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('waiting') });
has 'starting'     => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('starting') });
has 'reading'      => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('reading') });
has 'sending'      => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('sending') });
has 'keepalive'    => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('keepalive') });
has 'dns_lookup'   => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('dns_lookup') });
has 'closing'      => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('closing') });
has 'logging'      => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('logging') });
has 'finishing'    => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('finishing') });
has 'idle_cleanup' => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('idle_cleanup') });
has 'open_slot'    => ( 'is' => 'rw', 'isa' => 'Int', 'lazy' => 1, 'default' => sub { $_[0]->_update('open_slot') });


=head1 METHODS

=cut

sub _update {
    my $self   = shift;
    my $tag = shift;
    
    my $workers_tag = $self->workers_tag;

    return int($self->workers_tag->findvalue($tag));
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
