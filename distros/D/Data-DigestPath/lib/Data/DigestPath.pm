package Data::DigestPath;
use strict;
use warnings;
use Digest::MD5 qw//;

our $VERSION = '0.04';

use Class::Accessor::Lite (
    rw  => [qw/ salt depth delim digest trancate /],
);

sub new {
    my ($class, %args) = @_;

    my $opt = {
        salt   => defined $args{salt}  ? delete $args{salt} : '',
        depth  => defined $args{depth} ? int( delete $args{depth} ) : 4,
        delim  => defined $args{delim} ? delete $args{delim} : '/',
        digest => ref $args{digest} eq 'CODE' ? delete $args{digest}
                    : sub { Digest::MD5::md5_hex(@_) },
        trancate => defined $args{trancate} ? delete $args{trancate} : undef,
    };

    bless $opt, $class;
}

sub make_path {
    my ($self, $key, $length) = @_;

    $key = '' unless defined $key;

    my $hash = $self->digest->($self->salt . $key);
    my $path = join(
        $self->delim,
        (split '', $hash)[ 0 .. $self->depth - 1 ],
        $length
            ? substr($hash, $self->trancate ? $self->depth : 0, $length)
            : substr($hash, $self->trancate ? $self->depth : 0)
    );

    return $path;
}


1;

__END__

=head1 NAME

Data::DigestPath - the path generator as digest hash


=head1 SYNOPSIS

    use Data::DigestPath;

    my $dp   = Data::DigestPath->new;
    my $path = $dp->make_path('foo'); # a/c/b/d/acbd18db4cc2f85cedef654fccc4a4d8

There are all options.

    use Digest::SHA1 qw//;
    use Data::DigestPath;

    my $dp = Data::DigestPath->new(
        salt   => 'bar',
        depth  => 2,
        delim  => '-',
        digest => sub { Digest::SHA1::sha1_hex(@_) },
    );
    warn $dp->make_path('baz'); # 3-2-32b1bf1853e6c39e4a1c3dae941ab7094ff1d293


=head1 DESCRIPTION

Data::DigestPath makes the path as digest hash.


=head1 METHODS

=head2 new(%options)

the object constructor

=head3 %options

=over

=item C<< salt => $string // '' >>

=item C<< depth => $integer // 4 >>

=item C<< delim => $string // '/' >>

=item C<< digest => $code_ref // sub { Digest::MD5::md5_hex(@_) } >>

=item C<< trancate => $bool // undef >>

If you set the trancate param TRUE value, then the last delimited string will trancate(= remove the delimited path strings from last string)

    use Data::DigestPath;

    my $dp = Data::DigestPath->new;
    warn $dp->make_path; # d/4/1/d/d41d8cd98f00b204e9800998ecf8427e

    $dp->trancate(1);
    warn $dp->make_path; # d/4/1/d/8cd98f00b204e9800998ecf8427e


=back

=head2 make_path($key[, $length])

generate the path

=over

=item C<< $key => $string // '' >>

=item C<< $length => $file_length // full length >>

=back


=head1 REPOSITORY

Data::DigestPath is hosted on github
<http://github.com/bayashi/Data-DigestPath>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
