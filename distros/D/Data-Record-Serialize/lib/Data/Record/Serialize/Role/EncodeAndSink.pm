package Data::Record::Serialize::Role::EncodeAndSink;

# ABSTRACT: Both an Encode and Sink. handle unwanted/unused required routines

use strict;
use warnings;

our $VERSION = '0.28';

use Data::Record::Serialize::Error { errors => [ qw( internal  ) ] }, -all;

use Moo::Role;

use namespace::clean;

( *say, *print, *encode ) = map {
    my $stub = $_;
    sub { error ( 'internal', "internal error: stub method <$stub> invoked" ) }
} qw( say print encode );

sub close {}

with 'Data::Record::Serialize::Role::Sink';
with 'Data::Record::Serialize::Role::Encode';

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Role::EncodeAndSink - Both an Encode and Sink. handle unwanted/unused required routines

=head1 VERSION

version 0.28

=for Pod::Coverage say
print
encode
close

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
