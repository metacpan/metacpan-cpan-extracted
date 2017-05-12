package Config::Maker::Schema;

use utf8;
use warnings;
use strict;

use Carp;

use Config::Maker;
use Config::Maker::Type;

sub type {
    Config::Maker::Type->new(@_);
}

# Top-level element "schema"

my $schema = type(
    name => 'schema',
    format => ['anon_group'],
    contexts => [any => '/', any => '*'],
    actions => [\&process_schema],
);

# Global 'type' element

my $type = type(
    name => 'type',
    format => [named_group => ['identifier']],
    contexts => [any => $schema],
    actions => [\&process_type],
);

# Local 'type' element and 'contains' element

my $itype = type(
    name => 'type',
    format => [named_group => [pair => ['identifier'], ['identifier']]],
    contexts => [any => $type],
    actions => [\&process_itype],
);
$itype->add(any => $itype);

my $contains = type(
    name => 'contains',
    format => [simple => [pair => ['identifier'], ['identifier']]],
    contexts => [any => $type, any => $itype],
);

# Format elements

my $simple = type(
    name => 'simple',
    format => [simple => [nested_list => 'string']],
    contexts => [opt => $type, opt => $itype],
);

my $anon_group = type(
    name => 'anon_group',
    format => [simple => ['void']],
    contexts => [opt => $type, opt => $itype],
);

my $named_group = type(
    name => 'named_group',
    format => [simple => [nested_list => 'string']],
    contexts => [opt => $type, opt => $itype],
);
$type->addchecks(one => 'simple|anon_group|named_group');
$itype->addchecks(one => 'simple|anon_group|named_group');

# "toplevel" modifier
my $top_level = type(
    name => 'toplevel',
    format => [simple => ['void']],
    contexts => [opt => $type, opt => $itype],
);

# Action elements

my $action = type(
    name => 'action',
    format => [simple => ['perlcode']],
    contexts => [any => $type, any => $itype],
);

# Processing schema. Ugh!

sub _get_format {
    my ($fmt) = $_->get1('simple|anon_group|named_group');
    [ "$fmt->{-type}", $fmt->{-value} ];
}

sub _do_type {
    $_{format} = _get_format();
    $_{children} = [ map {
	$_->{-value}->[0], $_->{-data}
    } $_->get('type') ];
    push @{$_{contexts}}, any => '/' if $_->get('toplevel');
    $_{actions} = [ map {
	Config::Maker::exe("sub $_->{-value}");
    } $_->get('action') ];
    $_->{-data} = type(\%_);
}

sub process_itype
{
    local ($_) = @_;
    local %_;
    $_{name} = $_[0]->{-value}->[1];
    $_{contexts} = [];
    &_do_type;
}

sub process_type
{
    local ($_) = @_;
    local %_;
    $_{name} = $_[0]->{-value};
    $_{contexts} = [any => '*'],
    &_do_type;
}

sub process_schema
{
    local ($_) = @_;
    # Types are already processed!
    # But now we need to process cross-refs...
    for my $type ($_->get('**/type')) {
	DBG "Type $type->{-data}...";
	for my $cont ($type->get('contains')) {
	    DBG "Contains $cont->{-value}[0] $cont->{-value}[1]";
	    $type->{-data}->add(@{$cont->{-value}})
	}
    }
}

1;

__END__

=head1 NAME

Config::Maker::Schema - defines the schema directive

=head1 SYNOPSIS

  # Only used internaly from Config::Maker

=head1 DESCRIPTION

This file defines schema directive and it's subdirectives for use in the
metaconfig. For syntax and semantics of these directives see L<configit(1)>.

The schema directive is processed from a type action at the point where parsing
is finished. It means, that it can even be used at the begining of the config,
not just in metaconfig.

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: b9c3feb4-a46a-4c0f-9100-bcc6b5b1ebb7
