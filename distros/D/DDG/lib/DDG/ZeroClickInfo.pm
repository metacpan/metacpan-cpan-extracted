package DDG::ZeroClickInfo;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: DuckDuckGo server side used ZeroClickInfo result class
$DDG::ZeroClickInfo::VERSION = '1017';
use Moo;
extends qw( WWW::DuckDuckGo::ZeroClickInfo );
with 'DDG::IsControllable';


has structured_answer => (
    is        => 'ro',
    predicate => 1,
);


1;

__END__

=pod

=head1 NAME

DDG::ZeroClickInfo - DuckDuckGo server side used ZeroClickInfo result class

=head1 VERSION

version 1017

=head1 SYNOPSIS

  my $zci = DDG::ZeroClickInfo->new(
    answer => "I'm a little teapot!",
    is_cached => 1,
    ttl => 500,
  );

=head1 DESCRIPTION

This is the extension of the L<WWW::DuckDuckGo::ZeroClickInfo> class, how it
is used on the server side of DuckDuckGo. It adds attributes to the
ZeroClickInfo class which are not required for the client side usage.

So far all required attributes get injected via L<DDG::IsControllable>.

=head1 SEE ALSO

L<WWW::DuckDuckGo::ZeroClickInfo>

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
