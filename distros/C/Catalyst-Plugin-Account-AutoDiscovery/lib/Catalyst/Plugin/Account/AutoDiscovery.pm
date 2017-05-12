package Catalyst::Plugin::Account::AutoDiscovery;

use strict;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::Account::AutoDiscovery - Catalyst Plugin for Account Auto-Discovery

=head1 SYNOPSIS

  use Catalyst qw/Account::AutoDiscovery/;

  # setting
  $c->config(
      account_autodiscovery => {
          name => 'typester',
	  is_xml => 0,
      },
  );

  # output
  $c->account_autodiscovery;

  # in View::TT
  [% c.account_autodiscovery %]

=head1 DESCRIPTION

This is a simple Catalyst plugin for Account Auto-Discovery.

=head1 METHODS

=head2 account_autodiscovery

=cut

sub account_autodiscovery {
    my $c = shift;

    my $url = $c->config->{account_autodiscovery}->{base_url} || $c->config->{base_url} || $c->req->base;
    $url .= $c->req->path;

    my $name = $c->config->{account_autodiscovery}->{name};
    my $service = $c->config->{account_autodiscovery}->{service} || 'http://www.hatena.ne.jp/';
    my $is_xml = defined $c->config->{account_autodiscovery}->{is_xml} ? $c->config->{account_autodiscovery}->{is_xml} : 1;

    my $xml = <<"";
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/">
  <rdf:Description rdf:about="$url">
    <foaf:maker rdf:parseType="Resource">
      <foaf:holdsAccount>
        <foaf:OnlineAccount foaf:accountName="$name">
          <foaf:accountServiceHomepage rdf:resource="$service" />
        </foaf:OnlineAccount>
      </foaf:holdsAccount>
    </foaf:maker>
  </rdf:Description>
</rdf:RDF>

    $xml = "<!--\n".$xml."-->" if $is_xml;
    
    $xml;
}

=head1 SEE ALSO

L<Catalyst>.

Hatena Bookmark http://b.hatena.ne.jp/help?mode=tipjar

=head1 AUTHOR

Daisuke Murase, E<lt>typester@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
