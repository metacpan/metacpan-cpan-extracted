package App::DDNS::Namecheap;
{
  $App::DDNS::Namecheap::VERSION = '0.014';
}

use Moose;
use LWP::Simple qw($ua get);
$ua->agent("");
use Mozilla::CA;

has domain => ( is => 'ro', isa => 'Str', required => 1 );
has password => ( is => 'ro', isa => 'Str', required => 1 );
has hosts => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has ip => ( is => 'ro', isa => 'Str', required => 0 );

sub update {
  my $self = shift;
  foreach ( @{ $self->{hosts} } ) {
    my $url = "https://dynamicdns.park-your-domain.com/update?domain=$self->{domain}&password=$self->{password}&host=$_";
    $url .= "&ip=$self->{ip}" if $self->{ip};
    if ( my $return = get($url) ) {
      unless ( $return =~ /<errcount>0<\/errcount>/is ) {
	$return = ( $return =~ /<responsestring>(.*)<\/responsestring>/is ? $1 : "unknown error" );
        print "failure submitting host \"$_\.$self->{domain}\": $return\n";
	return;
      }
    }
  }
}

no Moose;

1;

__END__

=head1 NAME

App::DDNS::Namecheap - Dynamic DNS update utility for Namecheap registered domains

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    my $domain =  App::DDNS::Namecheap->new(
                      domain   => 'mysite.org',
         	      password => 'abcdefghijklmnopqrstuvwxyz012345',
		      hosts    => [ "@", "www", "*" ],
                      ip       => '127.0.0.1',    #optional -- defaults to external ip
    );

    $domain->update();

=head1 DESCRIPTION

This module provides a method for setting the address records of your Namecheap hosted 
domains. 

=head1 METHODS

=over 4

=item B<update>

Updates Namecheap A records using the attributes listed above. The optional ip attribute 
can be set statically; otherwise the ip where the script is running will be used.

=back

=head1 AUTHOR

David Watson <dwatson@cpan.org>

=head1 SEE ALSO

scripts/ in the distribution

=head1 COPYRIGHT AND LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut
