#!perl
package MY::TypeLib::MooXTypesMooseLike;
use 5.006;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use MooX::Types::MooseLike;
use MooX::Types::MooseLike::Base qw(Int);

use base qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS;

my $type_definitions = [
    {
        name => 'MediumInteger',
        subtype_of => 'Int',
        from => 'MooX::Types::MooseLike::Base',
        test => sub { $_[0] >= 10 and $_[0] < 20 },
        message => sub { 'an integer on [10,19]' },
    },
];

MooX::Types::MooseLike::register_types($type_definitions, __PACKAGE__);

# Sanity checks
my $av = eval { is_MediumInteger(15) };
die "Unexpected is_ sanity-check failure: $@" if $@ or not $av;
$av = is_MediumInteger(0);
die "Unexpected is_ sanity-check success" if $av;

my $coderef = MediumInteger();
$av = eval { $coderef->(15); 1 };
die "Unexpected sanity-check failure: $@" if $@ or not $av;
$av = eval { $coderef->(0); 1 };
die "Unexpected sanity-check success" if $av or not $@;

$EXPORT_TAGS{all} = [@EXPORT, @EXPORT_OK];
1;
