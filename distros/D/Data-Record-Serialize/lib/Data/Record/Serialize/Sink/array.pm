package Data::Record::Serialize::Sink::array;

# ABSTRACT: append encoded data to an array.

use v5.12;
use Moo::Role;

use Data::Record::Serialize::Error { errors => ['::create'] }, -all;

our $VERSION = '1.07';

use IO::File;

use namespace::clean;

## no critic( Subroutines::ProhibitBuiltinHomonyms )
## no critic( NamingConventions::ProhibitAmbiguousNames )











has output => (
    is      => 'ro',
    clearer => 1,
    default => sub { [] },
);








sub print { push @{ shift->{output} }, @_ }
sub say;
*say = \&print;

sub close { }

with 'Data::Record::Serialize::Role::Sink';

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

Data::Record::Serialize::Sink::array - append encoded data to an array.

=head1 VERSION

version 1.07

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'array', ?(output => \@output), ... );

    $s->send( \%record );

    # last encoded record is here
    $encoded = $s->output->[-1];

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::sink> appends encoded data to an array.

It performs the L<Data::Record::Serialize::Role::Sink> role.

=head1 OBJECT ATTRIBUTES

=head2 output

  $array = $s->output;

The array into which the encoded record is stored.  The last record sent is at

   $s->output->[-1]

=head1 INTERNALS

=for Pod::Coverage print
 say
 close

=head1 CONSTRUCTOR OPTIONS

=over

=item output => I<arrayref>

Optional. Where to write the data. An arrayref is provided if not specified.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>

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
