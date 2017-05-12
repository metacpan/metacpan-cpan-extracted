=head1 NAME

Asterisk::LCR::Importer - Provider's rates importer base class

=head1 SYNOPSIS

Asterisk::LCR::Importer is just a base class. To write your own importer:

  package MyOwnImporter;
  use base qw /Asterisk::LCR::Importer/;
  use warnings;
  use strict;
  
  sub new
  {
    my $class = shift;
    my $self  = $class->SUPER::new (@_);
    $self->{prefix_locale}            = 'us'
    $self->{prefix_position}          = '0'
    $self->{label_position}           = '1'
    $self->{rate_position}            = '4'
    $self->{first_increment_position} = '2'
    $self->{increment_position}       = '3'
    $self->{connection_fee}           = '0'
    $self->{currency}                 = 'USD'
    $self->{uri}                      = 'http://www.plainvoip.com/ratedump.php'
    $self->{separator}                = '(?:,|(?<=\d)\/(?=\d))'
    return $self;
  }
    
  1;
  
  __END__


In your config file:

  [import:myownprovider]
  package    = MyOwnProvider
  dialstring = IAX2/jhiver@plainvoip/REPLACEME

  
=head1 METHODS

=cut
package Asterisk::LCR::Importer;
use base qw /Asterisk::LCR::Object/;
use Asterisk::LCR::Locale;
use Asterisk::LCR::Route;
use LWP::Simple;
use warnings;
use strict;


=head2 $self->uri();

Returns the URI which $self should fetch.
If not overriden, returns $self->{uri}

=cut
sub uri { shift->{uri} || 'http://example.com/YOU_FORGOT_TO_SPECIFY_THE_RATES_URI' }



=head2 $self->target();

Returns a 'target', i.e. a name file to fill with
the current Importer's rates.

Returns $self->provider() + ".csv" by default.
If $self->{target} is defined, returns it instead.

=cut
sub target
{
    my $self = shift;
    return $self->{target} || do { $self->provider() . '.csv' }
}


=head2 $self->get_data();

Fetches the data contained in $self->uri(). Returns an
array of lines.

=cut
sub get_data
{
    my $self = shift;
    my $data = LWP::Simple::get ($self->uri());
    $data || die "Could not retrieve " . $self->uri();
    
    my @data = split /\n\r|\r\n|\n|\r/, $data;
    return \@data;
}


=head2 $self->separator();

Returns the CSV separator, which is ',' by default.
If $self->{separator} is defined, returns it instead.

=cut
sub separator { my $self = shift; $self->{separator} || '\,' }


=head2 $self->prefix ($rec);

Extracts and returns the prefix from $rec.

=cut
sub prefix
{
    my $self = shift;
    my $rec  = shift;
    my $pos  = $self->prefix_pos();
    my $loc  = $self->prefix_locale();
    
    my $res  = $rec->[$pos];
    if ($loc)
    {
        $res = $loc->local_to_global ($res);
        $res = $loc->normalize ($res);
    }
    
    return $res;
}


=head2 $self->prefix_pos();

Returns the position of the field which contains the prefix in the CSV data.
By default, returns 0.
If $self->{prefix_position} is defined, returns it instead.

=cut
sub prefix_pos { my $self = shift; return defined $self->{prefix_position} ? $self->{prefix_position} : 0 }


=head2 $self->prefix_locale();

Returns the locale which should be used for normalizing / translating the prefix.

Returns undef unless $self->{prefix_locale} is defined.

See L<Asterisk::LCR::Locale> for more details.

=cut
sub prefix_locale
{
    my $self = shift;
    $self->{prefix_locale} || return;
    $self->{prefix_locale_obj} ||= Asterisk::LCR::Locale->new ( $self->{prefix_locale} );
    return $self->{prefix_locale_obj};
}


=head2 $self->label ($rec);

Extracts and returns the label from $rec.

=cut
sub label
{
    my $self = shift;
    my $rec  = shift;
    my $pos  = $self->label_pos();
    return $rec->[$pos];
}


=head2 $self->label_pos();

Returns the position of the field which contains the prefix in the CSV data.
By default, returns 1.
If $self->{prefix_position} is defined, returns it instead.

=cut
sub label_pos  { my $self = shift; return defined $self->{label_position} ? $self->{label_position} : 1 }



=head2 $self->provider();

Returns a sensible string to designate the provider.

For example, for 'VoIPJet' should return something called "voipjet'.

By default, the result is derived from the domain name contained in $self->uri().
If $self->{provider} is defined, returns it instead.

=cut
sub provider
{
    my $self = shift;
    $self->{provider} ||= do {
        my $uri = $self->uri();
        $uri =~ s/^.*\:\/\/(www\.)?//;
        $uri =~ s/\..*//;
        $uri =~ s/.*\///;
        $uri;
    };
    
    return $self->{provider};
}


=head2 $self->currency();

Returns the currency which this Importer's provider uses.

Returns 'EUR' unless $self->{currency} is defined, in which
case it returns the latter instead.

=cut
sub currency
{
    my $self = shift;
    return $self->{currency} || 'EUR';
}


=head2 $self->rate ($rec);

Extracts and return the rate from $rec.

=cut
sub rate
{
    my $self = shift;
    my $rec  = shift;
    my $pos  = $self->rate_pos();
    return $rec->[$pos];
}


=head2 $self->rate_pos();

Returns the position of the field which contains the rate in the CSV data.
By default, returns 2.
If $self->{rate_position} is defined, returns it instead.

=cut
sub rate_pos  { my $self = shift; return defined $self->{rate_position} ? $self->{rate_position} : 2 }


=head2 $self->connection_fee ($rec);

Extracts and returns the connection_fee for $rec.
If $self->{connection_fee} is defined, returns it instead.

=cut
sub connection_fee
{
    my $self = shift;
    defined $self->{connection_fee} and return $self->{connection_fee};
    
    my $rec  = shift;
    my $pos  = $self->connection_fee_pos();
    return $rec->[$pos];
}


=head2 $self->connection_fee_pos();

Returns the position of the field which contains the connection fee in the CSV data.
By default, returns 3.

=cut
sub connection_fee_pos  { my $self = shift; return defined $self->{connection_fee_position} ? $self->{connection_fee_position} : 3 }


=head2 $self->first_increment ($rec);

Extracts and returns the first_increment for $rec.
If $self->{first_increment} is defined, returns it instead.

=cut
sub first_increment
{
    my $self = shift;
    defined $self->{first_increment} and return $self->{first_increment};
    my $rec  = shift;
    my $pos  = $self->first_increment_pos();
    return $rec->[$pos];
}


=head2 $self->first_increment_pos();

Returns the position of the field which contains the first increment in the CSV data.
By default, returns 3.

=cut
sub first_increment_pos  { my $self = shift; return defined $self->{first_increment_position} ? $self->{first_increment_position} : 4 }


=head2 $self->increment ($rec);

Extracts and returns the increment for $rec.
If $self->{increment} is defined, returns it instead.

=cut
sub increment
{
    my $self = shift;
    defined $self->{increment} and return $self->{increment};
    
    my $rec  = shift;
    my $pos  = $self->increment_pos();
    return $rec->[$pos];
}


=head2 $self->increment_pos();

Returns the position of the field which contains the increment in the CSV data.
By default, returns 3.

=cut
sub increment_pos  { my $self = shift; return defined $self->{increment_position} ? $self->{increment_position} : 5 }


=head2 $self->filter();

Returns a filter which matches all the CSV lines which are valid.
Returns $self->{filter}, or '^\d+,' by default

=cut
sub filter { return shift->{filter} || '^\d+,' }


=head2 $self->rates();

Imports and returns this Importer's rates.

=cut
sub rates
{
    my $self   = shift;
    $self->{rates} and return $self->{rates};
    
    my $data   = $self->get_data();
    my $filter = $self->filter();
    my $comma  = $self->separator();

    my $locale = Config::Mini::get ("dialer", "locale");
    my $loc    = $locale ? Asterisk::LCR::Locale->new ($locale) : undef;
    my $res    = {};

    for (@{$data})
    {
        /$filter/ or do {
            print "IGNORED: $_ (doesn't match /$filter/)\n";
            next;
        };
        my $rec = [ split /\s*$comma\s*/, $_ ];
        my $pfx = $self->prefix ($rec);
        $pfx = $loc->normalize ($pfx) if ($loc);
        $res->{$pfx} = Asterisk::LCR::Route->new (
            prefix          => $pfx,
            label           => $self->label ($rec),
            provider        => $self->provider ($rec),
            currency        => $self->currency ($rec),
            rate            => $self->rate ($rec),
            connection_fee  => $self->connection_fee ($rec),
            first_increment => $self->first_increment ($rec),
            increment       => $self->increment ($rec),
	);
    }
    
    $self->{rates} = $res;
    return $res;
}


=head2 $self->prefixes();

Returns a list of all available prefixes.

=cut
sub prefixes
{
    my $self = shift;
    my $rates = $self->rates();
    return keys %{$rates};
}


=head2 $self->fetch_rate ($prefix);

Returns  a list of rates matching $prefix exactly.

=cut
sub fetch_rate
{
    my $self = shift;
    my $prefix = shift;
    my $rates = $self->rates();
    return $rates->{$prefix};
}


=head2 $self->search_rate ($prefix);

Say $prefix = 12345. If 12345 has a list of rates, return the list.
If 1234 has a list of rates, return the list.
If 123 has a list of rates, return the list.
etc.

=cut
sub search_rate
{
    my $self = shift;
    my $prefix = shift;

    defined $prefix or return;
    $prefix ne ''   or return;

    return $self->fetch_rate ($prefix) || do {
        chop ($prefix);
        $self->search_rate ($prefix);
    };
}


1;


__END__
