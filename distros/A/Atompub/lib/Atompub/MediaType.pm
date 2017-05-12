package Atompub::MediaType;

use strict;
use warnings;

use Atompub;
use MIME::Types;
use Perl6::Export::Attrs;

use base qw(Class::Accessor::Fast);

my %ATOM_TYPE = (
    entry      => 'application/atom+xml;type=entry',
    feed       => 'application/atom+xml;type=feed',
    service    => 'application/atomsvc+xml',
    categories => 'application/atomcat+xml',
);

__PACKAGE__->mk_accessors(qw(type subtype parameters));

use overload (
    q{""}    => \&as_string,
    eq       => \&is_a,
    ne       => \&is_not_a,
    fallback => 1,
);

sub new {
    my($class, $arg) = @_;
    my $media_type = $ATOM_TYPE{$arg} || $arg or return;
    my($type, $subtype, $param) = split m{[/;]}, $media_type;
    bless {
	type       => $type,
	subtype    => $subtype,
	parameters => $param,
    }, $class;
}

sub media_type :Export { __PACKAGE__->new(@_) }

sub subtype_major {
    my($self) = @_;
    $self->subtype =~ /\+(.+)/ ? $1 : $self->subtype;
}

sub without_parameters {
    my($self) = @_;
    join '/', $self->type, $self->subtype;
}

sub as_string {
    my($self) = @_;
    join ';', grep { defined $_ } $self->without_parameters, $self->parameters;
}

sub extensions {
    my($self) = @_;
    my $mime = MIME::Types->new->type($self->without_parameters) or return;
    my @exts = $mime->extensions;
    wantarray ? @exts : $exts[0];
}

sub extension { scalar shift->extensions }

sub is_a {
    my($self, $test) = @_;
    $test = __PACKAGE__->new($test) unless UNIVERSAL::isa($test, __PACKAGE__);
    return 1 if $test->type eq '*';
    return 0 unless $test->type eq $self->type;
    return 1 if $test->subtype eq '*';
    if ($test->subtype eq $test->subtype_major) { # ex. application/xml
	return 0 unless $test->subtype_major eq $self->subtype_major;
    }
    else { # ex. application/atom+xml
	return 0 unless $test->subtype eq $self->subtype;
    }
    return 1 if ! $test->parameters || ! $self->parameters;
    return $test->parameters eq $self->parameters;
}

sub is_not_a {
    my($self, @args) = @_;
    !$self->is_a(@args);
}

1;
__END__

=head1 NAME

Atompub::MediaType - a media type object for the Atom Publishing Protocol

=head1 SYNOPSIS

    use Atompub::MediaType qw(media_type);

    my $type = media_type('image/png');

    "$type";                        # 'image/png'
    $type->type;                    # 'image'
    $type->subtype;                 # 'png'

    $type->extension;               # 'png'

    $type->is_a('image/*');         # true
    $type->is_a('image/gif');       # false

    my $type = media_type('entry');

    "$type";                        # 'application/atom+xml;type=entry'
    $type->type;                    # 'application'
    $type->subtype;                 # 'atom+xml'
    $type->parameters;              # 'type=entry'

    $type->subtype_major;           # 'xml'

    $type->extension;               # 'atom'

    $type->is_a('application/xml'); # true
    $type->is_a('feed');            # false

=head1 METHODS

=head2 Atompub::MediaType->new([ $type ])

Returns a media type object representing the time $type.

$type is string representing media type like 'image/png'.
Some aliases are defined for Atom, 'entry', 'feed', 'service', and 'categories'.

=head2 media_type([ $str ])

Alias for Atompub::MediaType->new

=head2 $type->type

=head2 $type->subtype

=head2 $type->parameters

=head2 $type->subtype_major

=head2 $type->extensions

=head2 $type->extension

=head2 $type->is_a

=head2 $type->is_not_a

=head2 $type->as_string

=head2 $type->without_parameters


=head1 SEE ALSO

L<Atompub>


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
