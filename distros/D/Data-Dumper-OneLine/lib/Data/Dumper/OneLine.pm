package Data::Dumper::OneLine;
use 5.008005;
use strict;
use warnings;
use Data::Dumper ();
use Data::Recursive::Encode;
use parent qw(Exporter);
our @EXPORT = qw(Dumper);

our $VERSION = "0.06";
our $Encoding;

sub Dumper {
    my $stuff = shift;
    local $Data::Dumper::Indent    = 0;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 1;

    if ($Encoding) {
        $stuff = Data::Recursive::Encode->encode_utf8($stuff);
    }

    my $str = Data::Dumper::Dumper($stuff);
    $str =~ s/[\n\r]/ /g;
    return $str;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Dumper::OneLine - Dumps data as one line string

=head1 SYNOPSIS

    use Data::Dumper::OneLine;

    Dumper(
        {
            foo => {
                bar => {},
            },
        }
    );
    #=> {foo => {bar => {}}}

=head1 LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroki Honda E<lt>cside.story@gmail.comE<gt>

=cut

