package CPE;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.02';

for my $accessor_name (qw(
    cpe_version
    part  vendor  product  version  update  edition
    language  sw_edition  target_sw  target_hw  other)
) {
    my $sub = sub {
        die "method '$accessor_name' takes 0 or 1 arguments, not " . scalar(@_ - 1) if @_ > 2;
        my ($self, $new) = @_;
        my $old = $self->{$accessor_name};

        if (@_ == 2) {
            my $validator = $accessor_name eq 'cpe_version' ? qr/\A2\.3\z/
                          : $accessor_name eq 'part'? qr/\A[aoh]\z/
                          : qr/\A[a-z0-9\._\-~%]*\z/;
            die  "invalid value '$new' for '$accessor_name'"
                unless $new =~ $validator;
            $self->{$accessor_name} = $new;
        }
        return $old;
    };
    { no strict 'refs'; *$accessor_name = $sub; }
}

sub is_equal    { die 'TODO' }
sub is_subset   { die 'TODO' }
sub is_superset { die 'TODO' }
sub is_disjoint { die 'TODO' }

sub as_string { die 'TODO' }
sub as_wfn    { die 'TODO' }
sub as_uri    { die 'TODO' }

sub new {
    my ($class, @args) = @_;
    my $self = @args == 1 ? _from_string($args[0]) : _from_hash(@args);
    return bless $self, $class;
}

sub _from_string {
    my ($str) = @_;

    if ($str =~ m{cpe:/
                  (?<part>[aoh])?
                  (?: \: (?<vendor>     [^:]*) )?
                  (?: \: (?<product>    [^:]*) )?
                  (?: \: (?<version>    [^:]*) )?
                  (?: \: (?<update>     [^:]*) )?
                  (?: \: (?<edition>    [^:]*) )?
                  (?: \: (?<language>   [^:]*) )?
                  (?: \: (?<sw_edition> [^:]*) )?
                  (?: \: (?<target_sw>  [^:]*) )?
                  (?: \: (?<target_hw>  [^:]*) )?
                  (?: \: (?<other>      [^:]*) )?
                }ix
    ) {
        my %data = %+;
        foreach my $k (keys %data) {
            if ($data{$k} eq '') {
                $data{$k} = 'ANY';
            }
            elsif ($data{$k} eq '-') {
                $data{$k} = 'NA';
            }
            elsif ($data{$k} =~ /\%/) {
                # URI CPEs may have percent-encoded special characters
                # which must be decoded to proper values.
                my %decoded = (
                    '21' => '!', '22' => '"', '23' => '#', '24' => '$',
                    '25' => '%', '26' => '&', '27' => q('), '28' => '(',
                    '29' => ')', '2a' => '*', '2b' => '+', '2c' => ',',
                    '2f' => '/', '3a' => ':', '3b' => ';', '3c' => '<',
                    '3d' => '=', '3e' => '>', '3f' => '?', '40' => '@',
                    '5b' => '[', '5c' => '\\', '5d' => ']', '5e' => '^',
                    '60' => '`', '7b' => '{', '7c' => '|', '7d' => '}',
                    '7e' => '~',
                );
                $data{$k} =~ s{\%01}{?}g if index($data{$k}, '%01') >= 0;
                $data{$k} =~ s{\%02}{*}g if index($data{$k}, '%02') >= 0;
                foreach my $special (keys %decoded) {
                    if (index($data{$k}, '%' . $special) >= 0) {
                        $data{$k} =~ s{\%$special}{\\$decoded{$special}}ig;
                    }
                }
            }
        }
        # this is a compatibility layer between CPE 2.2 and 2.3.
        # URIs using 2.3 format will have the 'edition' field starting
        # with a '~' and with '~' dividing all the new 2.3 fields within.
        # In 2.2 this is not done, and those fields don't exist.
        if (defined $data{edition} && substr($data{edition}, 0, 1) eq '~') {
            (undef,
             $data{edition},
             $data{sw_edition},
             $data{target_sw},
             $data{target_hw},
             $data{other},
            ) = map { $_ eq '' ? 'ANY' : $_ eq '-' ? 'NA' : $_ }
                # split() ignores empty values unless there is a defined
                # value afterwards, so we add an extra '!' element to the list
                # and ignore it:
                split /\~/ => $data{edition} . '~!';
        }
        return _from_hash(cpe_version => 2.3, %data);
    }
    die 'sorry, only URI CPEs can be parsed at this point. Patches welcome!';
}

sub _from_hash {
    my (%args) = @_;
    my $self = { cpe_version => '2.3', part => 'ANY' };
    foreach my $key (qw(vendor product version update edition
                        language sw_edition target_sw target_hw other)
    ) {
        if (!exists $args{$key}) {
            $self->{$key} = 'ANY';
            next;
        }
        Carp::croak "invalid characters '$args{$key}' in '$key' field."
            unless $args{$key} =~ m/\A(?:[
                a-z 0-9 \. _   # regular characters
                \- \~          # special meaning characters
                \* \?          # quantifiers
                # or any of the following special characters:
                ! " \# \$ \% \& ' \( \) \+ , \/ \:
                ; \< \= \> \@ \[ \\ \] \^ \` \{ \| \}
               ]*
               | ANY | NA     # 'ANY' and 'NA' are special values
            )\z/x;
        $self->{$key} = $args{$key};
    }
    if (exists $args{'part'}) {
        Carp::croak "'part' field must be 'a', 'o' or 'h'."
            unless $args{'part'} =~ m/\A[aoh]\z/;
        $self->{'part'} = $args{'part'};
    }
    if (exists $args{'cpe_version'}) {
        Carp::croak "only cpe_version 2.2 and 2.3 are accepted"
            unless $args{'cpe_version'} =~ m/\A2\.[23]\z/;
        $self->{'cpe_version'} = $args{'cpe_version'};
    }
    return $self;
}

1;
__END__

=head1 NAME

CPE - Common Platform Enumeration identifiers

=head1 SYNOPSIS

    use CPE;

    # parse CPEs in 'URI' format:
    my $cpe = CPE->new( 'cpe:/o:linux:linux_kernel:6.2.12' );

    # or create the object directly yourself:
    my $cpe2 = CPE->new(
        part    => 'o',
        vendor  => 'linux',
        type    => 'linux_kernel',
        version => '6.2.12',
    );

    # later on you query items individually:
    say $cpe->vendor;  # 'linux'
    say $cpe->product; # 'linux_kernel'
    say $cpe->version; # '6.2.12'

    # TODO: parse CPEs in "formatted string binding" format:
    my $cpe = CPE->new( 'cpe:2.3:o:linux:linux_kernel:6.2.12:*:*:*:*:*:*:*' );

    # TODO:  parse CPEs in "well-formed name" (WFN) format:
    my $cpe = CPE->new( 'wfn:[part="o",vendor="linux",product="linux_kernel",version="6.2.12"]' );

    # TODO: convert back to the source formats:
    say $cpe->as_string;  # 'cpe:2.3:o:linux...'
    say $cpe->as_wfn;     # 'wfn:[part="o",vendor=...'
    say $cpe->as_uri;     # 'cpe:/o:linux...'

    # TODO: test CPE equivalence:
    $cpe1->is_equal( $cpe2 );
    $cpe1->is_subset( $cpe2 );
    $cpe1->is_superset( $cpe2 );
    $cpe1->is_disjoint( $cpe2 );

=head1 WARNING: UNSTABLE API

This code is not stable enough and subject to backwards incompatible
changes in future releases. You have been warned.

=head1 DESCRIPTION

This module implements the CPE class, which represents
"Common Platform Enumeration" identifiers, as specified by
L<< CPE version 2.3|https://cpe.mitre.org/specification/ >>
in NIST IR 7695 and 7696.

CPE is a structured naming scheme for information technology systems,
software and packages, designed by L<NIST|http://csrc.nist.gov/>.

=head1 CONSTRUCTORS

=head2 new()

=head2 new( 'cpe_string' );

=head2 new( %arguments );

Creates a new CPE object from either the format string representation of
the CPE URI format or a set of key/value pairs that represent the CPE.

TODO: future versions will also be able to parse the general CPE 2.3 format
string, and the string representation of the WFN.

=head1 ACCESSORS

You may use the following accessors to get or set each CPE attribute.
If you set any of them to a new value, the old value will be returned.

=head2 cpe_version()

The CPE version used. This module currently only understands
version 2.3, which is the default, so you'll get a fatal error if you try
to set this to anything else.

=head2 part()

The type of the CPE. Can be either 'a' (application), 'h' (hardware) or
'o' (operating system).

=head2 vendor()

The identity of the person or organization that created the product.

=head2 product()

The name of the system, package or component.

=head2 version()

Vendor-specific alphanumeric string characterizing the particular release
version of the product.

=head2 update()

Vendor-specific alphanumeric strings characterizing the particular update,
service pack, or point release of the product.

=head2 edition()

Deprecated. In 2.3 it always falls back to 'ANY'.

=head2 language()

Language+region (RFC 5646) supported in the user interface of the product.

=head2 sw_edition()

How the product is tailored to a particular market or class of end users.

=head2 target_sw()

Software computing environment within which the product operates.

=head2 target_hw()

Instruction set architecture (e.g., x86) on which the product operates.

=head2 other()

Any other general descriptive or identifying information which is
vendor- or product-specific and which does not logically fit anywhere else.

=head1 TRANSFORMATIONS (TODO)

=head2 as_string()

=head2 as_wfn()

=head2 as_uri()

=head1 COMPARISON OPERATIONS (TODO)

=head2 is_equal( $cpe )

=head2 is_subset( $cpe )

=head2 is_superset( $cpe )

=head2 is_disjoint( $cpe )

=head1 LICENSE AND COPYRIGHT

Copyright 2023- Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
