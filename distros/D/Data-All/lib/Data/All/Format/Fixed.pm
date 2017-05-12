package Data::All::Format::Fixed;


#   $Id: Fixed.pm,v 1.1.1.1 2005/05/10 23:56:20 dmandelbaum Exp $


use strict;
use warnings;

use Data::Dumper;
use Data::All::Format::Base;

use vars qw(@EXPORT $VERSION);

@EXPORT = qw();
$VERSION = 0.11;

use base 'Exporter';
our @EXPORT = qw(new internal attribute populate error init);

attribute 'lengths' => [];
attribute 'break'   => "\n";    #   currently useless b/c it's hardcoded below

attribute 'type';

sub expand($);
sub contract(\@);


#   TODO: Forward look to defined lengths if they are blank

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

    #   NOTE: Line break is hardcoded to \n
    return pack($template, @{ $values })."\n";
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