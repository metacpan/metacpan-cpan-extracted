# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package Alien::CodePress;

use strict;
use warnings;
use 5.00600;

use Carp;
use File::Spec;
use File::Copy      qw(copy);
use File::Path      qw(mkpath);
use File::Basename  qw(dirname);
use Archive::Extract;
use vars qw($VERSION);

use Alien::CodePress::Archive;

$VERSION = 1.03;

my @PROPERTIES = qw(
    path
);


__PACKAGE__->make_accessors(@PROPERTIES);


sub new {
    my ($class, $options_ref) = @_;
    my $self = { };

    bless $self, $class;

    $self->init_properties();
    $self->set_properties($options_ref);
   
    return $self;
}

sub version {
    return Alien::CodePress::Archive->version;
}

sub files {
    my ($self) = @_;
    my $path   = $self->get_path;
    my $source = File::Spec->catfile(
        $path,
        Alien::CodePress::Archive->filename()
    );

    my $ae = Archive::Extract->new( archive => $source );
    my @file_list = $ae->files;

    return @file_list;
}

sub install {
    my ($self, $destdir) = @_;
    my $path             = $self->get_path;
    $destdir           ||= File::Spec->curdir();

    my $source = File::Spec->catfile(
        $path,
        Alien::CodePress::Archive->filename()
    );

    my $ae = Archive::Extract->new( archive => $source );
    $ae->extract( to => $destdir );
        
    return;
}

sub init_path {
    my $module_filename =  __PACKAGE__ . q{.pm};
       $module_filename =~ s{::}{/}xmsg;
    my $base =  $INC{$module_filename};
       $base =~ s{\.pm\z}{}xms;

    return $base;
}



my %properties;
sub make_accessors {
    my ($class, @properties) = @_;
    
    for my $property (@properties) {
        no strict 'refs'; ## no critic
        my $get_fqdn   = join q{::}, $class, "get_$property";
        my $set_fqdn   = join q{::}, $class, "set_$property";
        *{ $get_fqdn } = sub {
            my ($self) = @_;
            return $self->{$property};
        };
        *{ $set_fqdn } = sub {
            my ($self, $value) = @_;
            $self->{$property} = $value;
            return;
        };
        $properties{$class}{$property} = 1;
    }

    return;
}

sub init_properties {
    my ($self) = @_;

    for my $property (keys %{ $properties{ ref $self } }) {
        my $init_property = "init_$property";
        my $set_property  = "set_$property";
        if ($self->can($init_property)) {
            $self->$set_property( $self->$init_property );
        }
    }

    return;
}

sub set_properties {
    my ($self, $properties_ref) = @_;
    return if not ref $properties_ref eq 'HASH';
    
    while (my ($property, $value) = each %{ $properties_ref }) {
        my $set_value = "set_$property";
        $self->$set_value($value);
    }

    return;
}


BEGIN {
    my $this_module =  __PACKAGE__;
       $this_module =~ s{::}{/}xmsg;
       $this_module = quotemeta $this_module;
    if ( __FILE__ !~ m{$this_module\.pm \z}xms ) {
        require Carp;
        Carp::croak(sprintf
            'Wrong case in name for module %s. ' .
            'Sure you did not mean `use %s` instead?',
            __PACKAGE__, __PACKAGE__
        );
    }
}

1;

__END__


=pod

=for stopwords  CodePress namespace Init Solem

=head1 NAME

Alien::CodePress - Installing and finding CodePress.

=head1 VERSION

This document describes Alien::CodePress version v1.0

=head1 SYNOPSIS

    use Alien::CodePress;

    my $codepress = Alien::CodePress->new();

    # ... 

    my $version = $codepress->version;
    my $path    = $codepress->get_path();

    # ...

    $codepress->install( $my_destination_directory );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

=head1 SUBROUTINES/METHODS


=head2 CONSTRUCTOR


=head3  C<-E<gt>new( )>

Create a new Alien::CodePress object.

=head2 ATTRIBUTES

=head3 C<get_path()>

Returns the path to the available CodePress tarball.

=head3 C<set_path()>

Set a custom path to a CodePress tarball.

=head3 C<init_path()>

Reset path to it's default value.

=head2 CLASS METHODS

=head3 C<version()>

Get the current CodePress version number.

=head2 INSTANCE METHODS

=head3 C<install( $destination_dir )>

Install CodePress into specified directory.

CodePress will be installed into the current directory if no directory
specified.

=head3 C<files()>

Returns the list of files that are installed by Alien::CodePress.

=head2 PRIVATE METHODS

=head3 C<make_accessors(@properties)>

Create object accessors for a list of properties.
These can then be accessed with get_C<property> and set with set_C<property>.

=head3 C<set_properties( $hash-ref )>

Iterates trough the hashref keys and if there is a same-named property it sets
it to the hash keys value.

=head3 C<init_properties()>

Init default property values.

=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

=head1 DEPENDENCIES


=over 4

=item * [Archive::Extract]

=item * [Module::Build]

=back



=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-alien-codepress@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item * L<http://www.codepress.org>

The official CodePress home page.

=item * L<Alien>

The manifesto of the Alien namespace.

=back

=head1 AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
