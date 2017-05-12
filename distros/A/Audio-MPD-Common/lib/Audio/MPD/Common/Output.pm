#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Audio::MPD::Common::Output;
# ABSTRACT: class representing MPD output
$Audio::MPD::Common::Output::VERSION = '2.003';
use Moose;
use MooseX::Has::Sugar;


# -- public attributes


has id          => ( ro, isa=>"Int",  required );
has name        => ( ro, isa=>"Str",  required );
has enabled     => ( ro, isa=>"Bool", required );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::MPD::Common::Output - class representing MPD output

=head1 VERSION

version 2.003

=head1 DESCRIPTION

The MPD server can have various outputs defined, generally one per sound
card. Those output can be queried with the mpd modules. Some of those
information are served to you as an L<Audio::MPD::Common::Output>
object.

An L<Audio::MPD::Common::Output> object does B<not> update itself
regularly, and thus should be used immediately.

Note: one should B<never> ever instantiate an
L<Audio::MPD::Common::Output> object directly - use the mpd modules
instead.

=head1 ATTRIBUTES

=head2 $output->id;

Internal MPD id for the output.

=head2 $output->name;

Friendly-name for the output.

=head2 $output->enabled;

Boolean stating whether the output is enabled or not.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
