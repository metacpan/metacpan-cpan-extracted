package App::BitBucketCli::Base;

# Created on: 2015-09-16 16:41:19
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use App::BitBucketCli::Links;
use App::BitBucketCli::Link;

our $VERSION = 0.006;

has [qw/
    id
    link
    links
/] => (
    is  => 'rw',
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    my $args
        = !@args     ? {}
        : @args == 1 ? { %{ $args[0] } }
        :              {@args};

    if ( $args->{links} && ! blessed $args->{links} ) {
        $args->{links} = App::BitBucketCli::Links->new(%{ $args->{links} });
    }

    if ( $args->{link} && ! blessed $args->{link} ) {
        $args->{link} = App::BitBucketCli::Link->new(%{ $args->{link} });
    }

    return $class->$orig($args);
};

sub TO_JSON {
    my ($self) = @_;
    return { %{ $self } };
}

1;

__END__

=head1 NAME

App::BitBucketCli::Base - Parent class for other BitBucket objects

=head1 VERSION

This documentation refers to App::BitBucketCli::Base version 0.006

=head1 SYNOPSIS

   package App::BitBucket::SomeObject;

   extends qw/App::BitBucketCli::Base/;

   # class will automatically get id, link and links attributes
   # Also will autmatically be dumpable by L<JSON::XS>


=head1 DESCRIPTION

This is the base class for L<App::BitBucket::Project>, L<App::BitBucket::Repositories>,
L<App::BitBucket::Repository>, ...

=head1 SUBROUTINES/METHODS

=head2 C<BUILDARGS ()>

=head2 C<TO_JSON ()>

Used by L<JSON::XS> for dumping the object

=head1 ATTRIBUTES

=head2 id

Most BitBucket objects return an ID

=head2 link

Usually the URL to access this resource.

=head2 links

Usually a list of URLs for the object.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
