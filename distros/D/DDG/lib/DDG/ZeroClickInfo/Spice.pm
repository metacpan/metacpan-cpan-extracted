package DDG::ZeroClickInfo::Spice;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: DuckDuckGo server side used ZeroClickInfo Spice result class
$DDG::ZeroClickInfo::Spice::VERSION = '1017';
use Moo;
with 'DDG::IsControllable';


has call => (
	is => 'ro',
	predicate => 'has_call',
);

has call_type => (
	is => 'ro',
	predicate => 'has_call_type',
);

has call_data => (
	is => 'ro',
	predicate => 'has_call_data',
);

# LEGACY
sub call_path { shift->call }

1;

__END__

=pod

=head1 NAME

DDG::ZeroClickInfo::Spice - DuckDuckGo server side used ZeroClickInfo Spice result class

=head1 VERSION

version 1017

=head1 SYNOPSIS

  my $zci_spice = DDG::ZeroClickInfo::Spice->new(
    caller => 'DDGTest::Spice::SomeThing',
    call => '/js/spice/some_thing/a%23%23a/b%20%20b/c%23%3F%3Fc',
  );

=head1 DESCRIPTION

This is the extension of the L<WWW::DuckDuckGo::ZeroClickInfo> class, how it
is used on the server side of DuckDuckGo. It adds attributes to the
ZeroClickInfo class which are not required for the "output" part of it.

It is also a L<DDG::IsControllable>.

=head1 ATTRIBUTES

=head2 call

The URL on DuckDuckGo that should be called for the spice. It is not required
to set a call.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
