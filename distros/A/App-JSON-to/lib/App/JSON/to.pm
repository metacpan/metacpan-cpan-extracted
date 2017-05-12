use strict;
use warnings;

package App::JSON::to;
# ABSTRACT: Convert JSON data to various formats

our $VERSION = '1.000';

use JSON::MaybeXS qw<decode_json>;

sub run
{
    my ($to, @args) = @_;
    $to = lc $to;

    die "missing target format\n" unless defined $to;
    die "invalid target format '$to'\n"
	unless $to =~ /\A[a-z]+\z/ && eval { require "App/JSON/to/$to.pm"; 1 };
    my $class = __PACKAGE__ . '::' . $to;
    my $obj = $class->can('new') ? $class->new : $class;

    # TODO parse options
    # GetOptions($obj->options);

    binmode(STDIN, ':raw');
    my $data = decode_json do { local $/; <STDIN> };

    if (my $enc_meth = $obj->can('encoding')) {
	binmode(STDOUT, ':encoding('.$obj->$enc_meth().')');
    }

    print $obj->dump($data);
}

1;
__END__

=encoding UTF-8

=head1 NAME

App::JSON::to - Backend module for the C<json-to> script

=head1 VERSION

version 1.000

=head1 DESCRIPTION

See the L<json-to> script.

=head1 AUTHOR

Olivier MENGUÉ, L<mailto:dolmen@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Olivier MENGUÉ.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
