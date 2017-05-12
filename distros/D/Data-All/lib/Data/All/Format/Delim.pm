package Data::All::Format::Delim;


#   $Id: Delim.pm,v 1.1.1.1 2005/05/10 23:56:20 dmandelbaum Exp $

#   TODO: fully implement add_quotes attribute

use strict;
use warnings;

use base 'Exporter';

use Data::All::Format::Base;
use Text::ParseWords qw(quotewords);

use vars qw(@EXPORT $VERSION);

@EXPORT = qw();
$VERSION = 0.10;

attribute 'delim'   => ',';
attribute 'quote'   => '"';
attribute 'escape'  => '\\';
attribute 'break'   => "\n";
attribute 'add_quotes' => 1;

attribute 'type';

sub expand($);
sub contract(\@);


sub expand($)
#   TODO: There are likely better ways to do this. Iterate through 
#   each character? This way is too complex and likely buggy. (slow?) 
{
    my ($self, $raw) = @_;
    my $record = $raw;
    
    $record =~ s/\"\"(..)\'\'/$1/;
    #   BUG: in Text::Parsewords work around
    $record =~ s/'/\\'/g if ($raw =~ /'/);
    
    my $values = $self->parse(\$record);
    
    return !wantarray ? $values : @{ $values };
}

sub parse(\$)
{
    my ($self, $record) = @_;
    my @values;
    
    my ($d, $q, $e) = ($self->delim, $self->quote, $self->escape);
    
    @values = quotewords($d,0, $$record);
    
    return \@values;
}

sub parse3(\$)
{
    my ($self, $record) = @_;
    my @values;
    
#    my ($d, $q, $e) = ($self->delim, $self->quote, $self->escape);
    
    #use Regexp::Common qw /delimited/;
    #while ($$record =~ /$RE{delimited}{-delim=>quotemeta($d)}{-keep}/g)
    #{
    #    push (@values, $1);
    #}
    
    
        
    
    #warn Dumper(\@values);
    #return \@values;
}

sub parse2(\$)
#   A bad solution, CSV only!
{
    my ($self, $record) = @_;
    my @values;
    
    my ($d, $q, $e) = ($self->delim, $self->quote, $self->escape);
   
    #   From: http://xrl.us/bvci (Experts Exchange)
    push (@values, $+) while $$record =~ m{
      "([^\"\\]*(?:\\.[^\"\\]*)*)",?  # groups the phrase inside the quotes
    | ([^,]+),?
    | ,
    }gx;
    
    push(@values, '') if substr($$record,-1,1) eq $d;

    
    return \@values;
}

sub contract(\@)
{
    my ($self, $values) = @_;
    my @values;

    my $d = $self->delim;
    my $q = $self->quote;
    my $e = $self->escape;

    foreach (@{ $values })
    {
        $_ ||= '';
        
        $_ =~ s/$q/$e.$q/gx
            if ($q);            #   Escape quotes with the values
     
        ($self->add_quotes())
            ? push(@values, "$q$_$q")     #   Add quotes...
            : push(@values, $_);        #   ...for alphanumeric strings only
    }

    return CORE::join($d, @values).$self->break;
}










1;