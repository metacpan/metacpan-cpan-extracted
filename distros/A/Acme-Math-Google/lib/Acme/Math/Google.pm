package Acme::Math::Google;
use 5.008001;
use strict;
use warnings;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
use URI;
use LWP::UserAgent;

sub new{
    my $class = shift;
    my $self  = shift || {};
    $self->{base_uri} ||= 'http://www.google.com/search';
    unless ($self->{ua}){
	my $ua = LWP::UserAgent->new;
	$ua->agent( __PACKAGE__ . '/' . $VERSION );
	$self->{ua} = $ua;
    }
    return bless $self, $class;
}

sub calc{
    my $self  = shift;
    my $query = shift;
    my $as_equation = shift;
    my $uri = URI->new($self->{base_uri});
    $uri->query_form( q => $query);
    my $res = $self->{ua}->get($uri);
    return unless $res->code == 200;
    my $ans = $res->content;
    $ans =~ s{.*/images/calc_img.gif}{}xmso;
    $ans =~ s{.*?<b>}{}xmso;
    $ans =~ s{</b>.*}{}xmso;
    return $ans if $as_equation;
    $ans =~ s{.*=\s+}{}xmso;
    return $ans;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::Math::Google - Let Google do the math

=head1 SYNOPSIS

  use Acme::Math::Google;
  my $amg = Acme::Math::Google->new;
  print $amg->calc('e**(i*pi)');    # -1
  print $amg->calc('e**(i*pi)', 1); # 'e ** (i * pi) = -1'
                                    # WWW::Google::Calculator compat

=head1 DESCRIPTION

Need I say more than above?

=head2 EXPORT

None.

=head2 Acme::Math::Google vs. WWW::Google::Calculator

Darn, another wheel reinvented.  This module does essentially the same
as L<WWW::Google::Calculator> but much simpler.  All you need is
L<URI> and L<LWP::UserAgent> whereas L<WWW::Google::Calculator>
demands L<WWW::Mechanize>, L<HTML::TokeParser> and
L<Class::Accessor::Fast>.

=head1 SEE ALSO

L<WWW::Google::Calculator>

L<http://www.google.com/intl/en/help/features.html#calculator>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
