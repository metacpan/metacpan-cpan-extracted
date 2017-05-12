package App::mio;
BEGIN {
  $App::mio::AUTHORITY = 'cpan:DBR';
}
{
  $App::mio::VERSION = '0.1.0';
}

use strict;
use warnings;

# sub commify straight from Perl Cookbook,
# Chapter 2.17. "Putting Commas in Numbers"
sub commify {
    my $self = shift;
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

'true will do';


__END__
=pod

=encoding utf-8

=head1 NAME

App::mio

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

See L<App::mio> for usage.

=for Pod::Coverage commify

=head1 AUTHOR

DBR <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DBR.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

