package Data::Frame::Autobox::Hash;

# ABSTRACT: Additional Hash role for Moose::Autobox

use Moose::Role;

use List::AllUtils qw(pairmap);
use Ref::Util;
use namespace::autoclean;


sub isempty { keys %{ $_[0] } == 0 }


sub names { [ keys %{ $_[0] } ] }


sub set {
    my ( $hash, $key, $value ) = @_;
    $hash->{$key} = $value;
}


sub rename {
    my ( $hash, $href_or_coderef ) = @_;

    my %new_hash;
    if ( Ref::Util::is_coderef($href_or_coderef) ) {
        %new_hash = pairmap { ( $href_or_coderef->($a) // $a ) => $b } %$hash;
    }
    else {
        %new_hash = pairmap { ( $href_or_coderef->{$a} // $a ) => $b } %$hash;
    }
    return \%new_hash;
}



sub copy { { %{ $_[0] } } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Autobox::Hash - Additional Hash role for Moose::Autobox

=head1 VERSION

version 0.0049

=head1 SYNOPSIS

    use Moose::Autobox;

    Moose::Autobox->mixin_additional_role(
        HASH => "Data::Frame::Autobox::Hash"
    );

    { one => 1 }->names;            # [ 'one' ]
    { one => 1 }->isempty;          # false

=head1 DESCRIPTION

This is an additional Hash role for Moose::Autobox.

=head1 METHODS

=head2 isempty

    my $isempty = $hash->isempty;

Returns a boolean value for if the hash ref is empty.

=head2 names

    my $keys = $hash->names;

This is same as the C<keys> method of Moose::Autobox::Hash.

=head2 set

    $hash->set($key, $value)

This is same as the C<put> method of Moose::Autobox::Hash.

=head2 rename

    rename($hashref_or_coderef)

It can take either,

=over 4

=item *

A hashref of key mappings.

If a keys does not exist in the mappings, it would not be renamed. 

=item *

A coderef which transforms each key.

=back

    my $new_href1 = $href->rename( { $from_key => $to_key, ... } );
    my $new_href2 = $href->rename( sub { $_[0] . 'foo' } );

=head2 copy

Shallow copy.

=head1 SEE ALSO

L<Moose::Autobox>

L<Moose::Autobox::Hash>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
