use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Test::Base;

use Code::TidyAll::Plugin::Spellunker::Pod;
use Path::Tiny qw/path/;

sub provide {
    Code::TidyAll::Plugin::Spellunker::Pod->new(
        name      => 'Spellunker',
        tidyall   => Test::MockObject->new,
        stopwords => 'karupanerura',
    );
}

plan tests => 1 * blocks;

for my $block (blocks) {
    my $plugin = provide();

    eval { $plugin->validate_source($block->input) };
    my $e = $@;

    is $@, $block->expected;
}

__END__
=== Valid
--- input
package Valid;
use strict;
use warnings;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Valid - The valid module

=head1 SYNOPSIS

    use Valid;

=head1 DESCRIPTION

This is valid!

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

--- expected

=== Invalid
--- input
package Invalid;
use strict;
use warnings;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Invalid - The invalid module

=head1 SYNOPSIS

    use Invalid;

=head1 DESCRIPTION

This is invaliddddd!

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

--- expected
Errors:
    22: invaliddddd
