package Catalyst::Plugin::StripScripts;

use strict;
use warnings;
use HTML::StripScripts::Parser;

our $VERSION = '0.1';

sub strip_scripts {
    my $c = shift;
    my $html = shift;

    return if !$html;

    my $config = $c->config->{strip_scripts};

    return if !ref($config) eq 'ARRAY';

    my $hss = HTML::StripScripts::Parser->new(@$config);

    return $hss->filter_html($html);
}

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::StripScripts - XSS filter plugin

=head1 SYNOPSIS

  # In App.pm
  use Catalyst qw(StripScripts);
  __PACKAGE__->config({ strip_scripts => [
                                            {
                                               Context => 'Inline',
                                            },
                                            strict_comment => 1,
                                            strict_names   => 1,
                                          ] });

  # In App/Controller/YourController.pm
  sub index : Private {
     my ($self, $c) = @_;

     $c->strip_scripts($html);
     $c->forward('View::TT');
  }

=head1 DESCRIPTION

This module adds the ability of removing unwanted html tags from your
website output. It is based on L<HTML::StripScripts::Parser>. The
configurations in App.pm will be used when you invoke
I<strip_scripts>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yung-chung Lin (henearkrxern@gmail.com)

=cut
