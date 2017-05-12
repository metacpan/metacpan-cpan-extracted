package Data::All::Format::XML;


#   $Id: XML.pm,v 1.1.1.1 2005/05/10 23:56:20 dmandelbaum Exp $


use strict;
use warnings;

use Data::All::Format::Base;

use vars qw(@EXPORT $VERSION);

@EXPORT = qw();
$VERSION = 0.10;

use base 'Exporter';
our @EXPORT = qw(new internal attribute populate error init	_load_format);

attribute 'format'  => '';
attribute 'encoding' => '';

attribute 'type';

sub expand($);
sub contract(\@);




sub expand($)
{
    my $self = shift;
    my $record = shift;
    my $template = $self->pack_template();
    
    return unpack($template, $record);
}

sub contract(\@)
{
    my $self = shift;
    my $values = shift;
    my $template = $self->pack_template();
    
    return pack($template, @{ $values });
}


sub pack_template()
{
    my $self = shift;
    my @template;
    
    foreach my $e (@{ $self->lengths })
    {
        push(@template, "A$e");
    }
    
    return !wantarray ? join(' ', @template) : @template; 
}








1;