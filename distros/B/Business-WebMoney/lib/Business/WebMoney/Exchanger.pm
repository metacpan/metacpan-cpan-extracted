package Business::WebMoney::Exchanger;

use 5.008000;
use strict;
use warnings;

use Business::WebMoney;

our $VERSION = '0.02';

use Carp;
use LWP::UserAgent;
use XML::LibXML;
use HTTP::Request;

sub new
{
	my ($class, @args) = @_;

	my $opt = Business::WebMoney::parse_args(\@args, {
		timeout => 20,
	});

	my $self = {
		timeout => $opt->{timeout},
	};

	return bless $self, $class;
}

sub best_rates
{
	my ($self, @args) = @_;

	$self->{errstr} = undef;
	$self->{errcode} = undef;

	my $req_fields = Business::WebMoney::parse_args(\@args, {
		debug_response => undef,
	});

	my $res = eval {

		local $SIG{__DIE__};
       
		my $res_content;

		unless ($res_content = $req_fields->{debug_response}) {

			my $ua = LWP::UserAgent->new;
			$ua->timeout($self->{timeout});
			$ua->env_proxy;

			my $req = HTTP::Request->new;
			$req->method('GET');
			$req->uri('https://wm.exchanger.ru/asp/XMLbestRates.asp');

			my $res = $ua->request($req);

			unless ($res->is_success) {

				$self->{errcode} = $res->code;
				$self->{errstr} = $res->message;
				return undef;
			}

			$res_content = $res->content;
		}

		my $parser = XML::LibXML->new;

		my $doc = $parser->parse_string($res_content);

		my %result;

		for my $node ($doc->getElementsByTagName('row')) {

			my ($from, $to, %row);

			for my $attr ($node->attributes) {

				my $key = $attr->name;
				my $value = $attr->value;

				if ($key eq 'Direct') {

					($from, $to) = ($value =~ /^(\S+?)\s*-\s*(\S+)$/);

				} elsif ($key eq 'BaseRate') {

					$row{rate} = ($value > 0) ? ($value + 0) : (-1 / $value);

				} elsif (my ($percent) = ($key =~ /^Plus(\d+)$/)) {

					# 005 => 0.05
					# 01 => 0.1
					# 02 => 0.2
					# ...
					# 1 => 1
					# 2 => 2
					# ...
					$percent =~ s/^0(0*)/0.$1/;

					$row{$percent} = $value;

				} else {

					$row{$key} = $value;
				}
			}

			if ($from && $to && $row{rate}) {

				$result{$from}->{$to} = \%row;
			}
		}

		\%result;
	};

	if ($@) {

		$self->{errcode} = -1000;
		$self->{errstr} = $@;
		return undef;
	}

	return $res;
}

sub errcode
{
	my ($self) = @_;

	return $self->{errcode};
}

sub errstr
{
	my ($self) = @_;

	return $self->{errstr};
}

1;

__END__

=head1 NAME

Business::WebMoney::Exchanger - Perl API to WebMoney Exchanger

=head1 SYNOPSIS

  use Business::WebMoney::Exchanger;

  my $wmex = Business::WebMoney::Exchanger->new;
  my $best_rates = $wmex->best_rates;

  print $best_rates->{WMZ}->{WMR}->{rate} . "\n";

=head1 DESCRIPTION

Business::WebMoney::Exchanges provides simple API to the WebMoney Exchanger
system. Currently it provides an interface to the stock rates of WebMoney
currencies.

=head1 METHODS

=head2 Constructor

  my $wmex = Business::WebMoney::Exchanger->new(
    timeout => 30,			# Request timeout in seconds (optional, default 20)
  );

=head2 best_rates - interface to query current exchange rates

  my $rates = $wmex->best_rates;

On error returns undef ($wmex->errcode and $wmex->errstr are set to the error code and description accordingly). On success returns reference to the following structure:

  {
    WMZ => {
      WMR => {
        rate => 27.5199,	# exchange rate WMZ->WMR defined by Central Bank of Russia or National Bank of Ukraine
				# (or corresponding cross-rates)
	0.1 => 0,		# amount of WMZ you can buy for WMR with rate better than 27.5474 (= 27.5199 + 0.1%)
	0.2 => 79572.31,	# amount of WMZ you can buy for WMR with rate better than 27.5749 (= 27.5199 + 0.2%)
	...
	10 => 378769.89,	# amount of WMZ you can buy for WMR with rate better than 30.2718 (= 27.5199 + 10%)
	exchtype => 1,		# ID of the exchange direction (used in further interfaces)
      },
      ...
    },
    ...
  }

Available rate ranges: 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 2, 3, 5, 10.

=head1 ENVIRONMENT

=over 4

=item * C<http_proxy> - proxy support, http://host_or_ip:port

=back

=head1 SEE ALSO

L<http://wm.exchanger.ru/asp/rules_xml.asp> - WebMoney Exchanger API specification (in Russian only)

=head1 AUTHOR

Alexander Lourier, E<lt>aml@rulezz.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alexander Lourier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
