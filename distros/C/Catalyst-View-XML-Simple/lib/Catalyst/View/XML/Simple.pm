package Catalyst::View::XML::Simple;

use Moose;
our $VERSION = '0.022';
use 5.008_001;

extends qw(Catalyst::View);


sub process {
    my($self, $c, $stash_key) = @_;
    use XML::Simple;
    my $xs = XML::Simple->new();
    my $output;

    my $data = { map { ($_ => $c->stash->{$_}) }
                  keys %{$c->stash} };
    eval {
        $output = $xs->XMLout($data);
    };
    return $@ if $@;

    $c->res->output($output);
    return 1;  # important

}


1;
__END__

=head1 NAME

Catalyst::View::XML::Simple - XML view for your data

=head1 SYNOPSIS

  # lib/MyApp/View/XML.pm
  package MyApp::View::XML::Simple;
  use base qw( Catalyst::View::XML::Simple );
  1;

  sub hello : Local {
      my($self, $c) = @_;
      $c->stash->{message} = 'Hello World!';
      $c->forward('View::XML::Simple');
  }

=head1 DESCRIPTION

Catalyst::View::XML::Simple is a Catalyst View handler that returns stash
data in XML format using XML::Simple.


=head1 AUTHOR

Lindolfo 'Lorn' Rodrigues  E<lt>lorn at cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 Thanks

Thanks do Tatsuhiko Miyagawa for Catalyst::View::JSON :)

=cut
