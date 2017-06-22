package Data::Record::Serialize::Sink::null;

# ABSTRACT: send output to nowhere.

use Moo::Role;

use namespace::clean;

our $VERSION = '0.12';

#pod =begin pod_coverage
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

sub print { }
sub say   { }
sub close { }


with 'Data::Record::Serialize::Role::Sink';

1;

=pod

=head1 NAME

Data::Record::Serialize::Sink::null - send output to nowhere.

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'null', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> sends data to the bitbucket.

It performs the L<B<Data::Record::Serialize::Role::Sink>> role.

=begin pod_coverage

=head3 print

=head3 say

=head3 close

=end pod_coverage

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
#pod     my $s = Data::Record::Serialize->new( sink => 'null', ... );
#pod
#pod     $s->send( \%record );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Record::Serialize::Sink::stream> sends data to the bitbucket.
#pod
#pod It performs the L<B<Data::Record::Serialize::Role::Sink>> role.
