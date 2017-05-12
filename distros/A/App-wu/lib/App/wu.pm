use strict;
use warnings;
package App::wu;
$App::wu::VERSION = '0.05';
use WWW::Wunderground::API 0.06;
use Cache::FileCache;
use Carp;
use Try::Tiny;

#ABSTRACT: Terminal app that provides an hourly weather forecast using Weather Underground API




sub new
{
  croak 'Incorrect number of args passed to constructor' unless @_ == 3;
  my ($class, $location, $api_key) = @_;

  my $wu = new WWW::Wunderground::API(
    location => $location,
    api_key  => $api_key,
    auto_api => 1,
    cache    => Cache::FileCache->new({
      namespace          => 'wundercache',
      default_expires_in => 2400 }),
  );

  return bless { wu => $wu }, $class;
}

sub print_hourly
{
  my $self = shift;
  my $wu = $self->{wu};

  try {
    my @hourly_results = @{ $wu->hourly };

    # print header
    binmode STDOUT, ':utf8'; # for degrees symbol
    printf "%-10s%-4s%-4s%-8s%-20s\n",
           'Time',
           "\x{2109}",
           "\x{2103}",
           'Rain %',
           'Conditions';

    # print hourly
    for (@hourly_results)
    {
      printf "%8s%4i%4i%8i  %-30s\n",
             $_->{FCTTIME}{civil},
             $_->{temp}{english},
             $_->{temp}{metric},
             $_->{pop},
             $_->{condition};
    }
  } catch
  {   # see if there is an error message to display
    if (exists $wu->{data}{hourly}{response}{error}{description})
    {
      print "$wu->{data}{hourly}{response}{error}{description}\n";
    }
    else
    {
      print "Error connecting to Wunderground API (is your Internet connection active?)\n";
    }
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::wu - Terminal app that provides an hourly weather forecast using Weather Underground API

=head1 VERSION

version 0.05

=head1 SYNOPSIS

This module installs the C<wu> command which prints a 36 hour weather forecast at the command line using the Wunderground API. You'll need to get a Wunderground API key (they're free) and set the environment variable C<WU_API_KEY>. Optionally you can set the environment variable C<WU_HOME_LOCATION> which sets the default location for C<wu>.

    $ wu London, UK
    Retrieving weather forecast for London, UK ...

    Time      ℉   ℃   Rain %  Conditions
     2:00 AM  56  13       5  Clear
     3:00 AM  55  13       6  Partly Cloudy
     4:00 AM  55  13       6  Partly Cloudy
     5:00 AM  54  12       6  Partly Cloudy
     6:00 AM  54  12       7  Partly Cloudy
     7:00 AM  55  13       7  Partly Cloudy
    ...

=head1 BUGS

Windows PowerShell and cmd.exe both corrupt the Fareinheit and Celsius degrees symbols, but other than that work fine.

=head1 SEE ALSO

=over

=item *

L<WWW::Wunderground::API> - the fabulous module that powers this app!

=item *

My PerlTricks.com L<article|http://perltricks.com/article/114/2014/9/11/Get-a-weather-report-at-the-terminal-with-Perl> about this script

=back

=head1 THANKS

Thanks to John Lifsey for writing L<WWW::Wunderground::API>

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
