package Const::Common::Generator;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Text::MicroTemplate;

sub generate {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $package = $args{package};
    my @constants = @{ $args{constants} };

    my @consts;
    while (my ($name, $value) = splice @constants, 0, 2) {
        my $comment;
        if (ref $value) {
            $comment = $value->{comment};
            $value   = $value->{value};
        }

        push @consts, {
            name  => $name,
            value => $value,
            (defined($comment) ? (comment => $comment) : ()),
        };
    }

    my $gen = Text::MicroTemplate->new(
        template    => $class->_template,
        escape_func => sub {shift},
    )->build;

    $gen->(
        package => $package,
        consts  => \@consts
    )->as_string;
}

sub _template {
    <<'...';
? my %args = @_;
? use Scalar::Util qw/looks_like_number/;
package <?= $args{package} ?>;
use strict;
use warnings;
use utf8;

use Const::Common (
? for my $const (@{ $args{consts} }) {
? my $v = $const->{value};
    <?= $const->{name} ?> => <?= looks_like_number($v) ? '' : "'" ?><?= $v ?><?= looks_like_number($v) ? '' : "'" ?>,<? if ($const->{comment}) { ?> # <?= $const->{comment} ?><? } ?>
? }
);

1;
...
}

1;
__END__

=encoding utf-8

=head1 NAME

Const::Common::Generator - Auto generate constant package of Const::Common

=head1 SYNOPSIS

    use Const::Common::Generator;
    my $pm = Const::Common::Generator->generate(
        package => 'Hoge::Piyo',
        constants => [
            HO => 'GE',
            FU => {
                value => 'GA',
                comment => 'fuga',
            },
            PI => 3.14,
        ],
    ),

=head1 DESCRIPTION

Const::Common::Generator is a module for generating constant package of Const::Common

=head1 METHOD

=head2 C<< $str = Const::Common::Generator->generate(%opt) >>

=over

=item C<package>

=item C<constants>

=back

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

