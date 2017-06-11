package DDG::ZeroClickInfo::Spice::Data;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Data that gets delivered additional to the spice call into the Javascript of the HTML
$DDG::ZeroClickInfo::Spice::Data::VERSION = '1017';
use Moo;


has data => (
	is => 'ro',
	required => 1,
);


sub add_data {
	my ( $self, $data ) = @_;
	die "can only handle DDG::ZeroClickInfo::Spice::Data" unless ref $data eq 'DDG::ZeroClickInfo::Spice::Data';
	$self->data->{$_} = $data->data->{$_} for (keys %{$data->data});
}

1;

__END__

=pod

=head1 NAME

DDG::ZeroClickInfo::Spice::Data - Data that gets delivered additional to the spice call into the Javascript of the HTML

=head1 VERSION

version 1017

=head1 SYNOPSIS

Inside your spice handler

  return $path_part_one, $path_part_two, data(
    key => "value",
    more_key => "more value",
    most_key => "most value - buy now!",
  );

=head1 ATTRIBUTES

=head2 data

Needs a hashref of the data you want to access inside the javascript.

=head1 METHODS

=head2 add_data

Integrates the given B<DDG::ZeroClickInfo::Spice::Data> into data object. The
newer one always overrides variables already set.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
