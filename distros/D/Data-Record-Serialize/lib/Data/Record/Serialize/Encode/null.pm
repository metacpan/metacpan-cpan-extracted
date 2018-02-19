package Data::Record::Serialize::Encode::null;

# ABSTRACT: infinite bitbucket

use Moo::Role;

our $VERSION = '0.13';

use namespace::clean;


#pod =begin pod_coverage
#pod
#pod =head3 encode
#pod
#pod =head3 send
#pod
#pod =head3 print
#pod
#pod =head3 say
#pod
#pod =head3 close
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub encode { }
sub send {  }
sub print { }
sub say { }
sub close { }

with 'Data::Record::Serialize::Role::Encode';
with 'Data::Record::Serialize::Role::Sink';

1;

=pod

=head1 NAME

Data::Record::Serialize::Encode::null - infinite bitbucket

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'null', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::null> is both an encoder and a sink.
All records sent using it will disappear.

It performs both the L<B<Data::Record::Serialize::Role::Encode>> and
L<B<Data::Record::Serialize::Role::Sink>> roles.

=begin pod_coverage

=head3 encode

=head3 send

=head3 print

=head3 say

=head3 close

=end pod_coverage

=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize::new>|Data::Record::Serialize/new>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

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

__END__

#pod =head1 SYNOPSIS
#pod
#pod     use Data::Record::Serialize;
#pod
#pod     my $s = Data::Record::Serialize->new( encode => 'null', ... );
#pod
#pod     $s->send( \%record );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Record::Serialize::Encode::null> is both an encoder and a sink.
#pod All records sent using it will disappear.
#pod
#pod It performs both the L<B<Data::Record::Serialize::Role::Encode>> and
#pod L<B<Data::Record::Serialize::Role::Sink>> roles.
#pod
#pod =head1 INTERFACE
#pod
#pod There are no additional attributes which may be passed to
#pod L<B<Data::Record::Serialize::new>|Data::Record::Serialize/new>.
