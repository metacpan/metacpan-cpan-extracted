package DBIx::Class::EncodedColumn::Crypt;

use strict;
use warnings;

our $VERSION = '0.01';

sub make_encode_sub {
    my ($class, $col, $args) = @_;
    my $gen_salt_meth = $args->{'salt'};
    die "Valid 'salt' is a coderef which returns the salt string."
        unless ref $gen_salt_meth eq 'CODE';

    return sub {
        my ($plain_text, $salt) = @_;
        $salt ||= $gen_salt_meth->();
        return crypt($plain_text, $salt);
    };
}

sub make_check_sub {
    my($class, $col, $args) = @_;
    #fast fast fast
    return eval qq^ sub {
        my \$col_v = \$_[0]->get_column('${col}');
        \$_[0]->_column_encoders->{${col}}->(\$_[1], \$col_v) eq \$col_v;
    } ^ || die($@);
}

1;

__END__;

=head1 NAME

DBIx::Class::EncodedColumn::Crypt - Encrypt columns using crypt()

=head1 SEE ALSO

L<crypt|http://perldoc.perl.org/functions/crypt.html>

=head1 AUTHOR

wreis: Wallace reis <wreis@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
