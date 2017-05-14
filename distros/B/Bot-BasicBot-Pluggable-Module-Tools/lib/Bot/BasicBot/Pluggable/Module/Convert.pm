package Bot::BasicBot::Pluggable::Module::Convert;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Math::Units;
use Finance::Currency::Convert::XE;


sub init {
    my $self = shift;
    $self->{converter} = Finance::Currency::Convert::XE->new();
    $self->set("user_scientific_limit", 999999999) unless $self->get("user_scientific_limit"); 
    $self->unset("user_scientific_limit");

}

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    return unless $body =~  /^\s*(?:ex)?(?:change|convert)\s+([\d\.\,]+)\s*(\S+)\s+(?:into|to|for)\s+(\S+)/i;
    my ($amount, $from, $to) = ($1,$2,$3);


    # first try and convert units

     my $val = eval {  Math::Units::convert($amount, $from, $to) };
     goto CURRENCY if $@;

     my $limit = $self->get("user_scientific_limit");

     if (defined $limit && $limit < $val) {
     	$val = sprintf "%e", $val;
     }


     return "Dunno about that" unless defined $val && $val !~ m!^\s*$!;

     return "$amount $from is $val $to";
     CURRENCY:

     my $obj = $self->{converter};
     return "Currency conversion not working" unless $obj;
        
     $from = uc($from);
     $to   = uc($to);
     $val = $obj->convert( 
                  'source' => $from,
                  'target' => $to,
                  'value'  => $amount,
                  'format' => 'number'
                );

     return "Couldn't out what to do with with the units $from and $to" unless defined $val;
     return "$amount $from is $val $to";
}

sub help {
    return "Commands: 'convert <quantity> <unit> to <other unit>' or 'exchange <quantity> <currency> to <other currency>'";
}

1;


__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Convert - convert between units

=head1 SYNOPSIS

Uses C<Math::Units> to convert between various formats. You do

    18:14 <muttley> convert 1 m into miles
    18:14 <dipsy> 1 m is 0.000621371192237334 miles
    18:14 <muttley> convert 1 min to seconds
    18:14 <dipsy> 1 min is 60 seconds

and

    18:14 <muttley> convert 1 gallon into cm^3
    18:14 <dipsy> 1 gallon is 3785.411784 cm^3

and even

    18:13 <muttley> convert 100 hz into rpm
    18:13 <dipsy> 100 hz is 6000 rpm

Or can use C<Finance::Currency::Convert::XE> to convert between currencies:

    15:30 <muttley> change 10 GBP to USD
    15:30 <dipsy> 10 GBP is 18.91 USD

Which is cool. 

=head1 IRC USAGE

    convert <quantity> <unit> to <other unit>
    
    exchange <quantity> <currency> to <other currency>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Math::Units>

=cut 

